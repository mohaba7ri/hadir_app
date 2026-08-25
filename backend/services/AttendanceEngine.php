<?php
require_once __DIR__ . '/../models/AttendanceCalculator.php';
require_once __DIR__ . '/../models/Setting.php';
require_once __DIR__ . '/../models/Employee.php';

class AttendanceEngine
{
    private $db;

    public function __construct($db)
    {
        $this->db = $db;
    }

    public function getMonthlySummary($employee_id, $month, $year)
    {
        $month = (int) $month;
        $year = (int) $year;

        // 1. Calculate Cycle Dates (25th to 24th)
        if ($month == 1) {
            $start_month = 12;
            $start_year = $year - 1;
        } else {
            $start_month = $month - 1;
            $start_year = $year;
        }
        $cycle_start = sprintf('%04d-%02d-25', $start_year, $start_month);
        $cycle_end = sprintf('%04d-%02d-24', $year, $month);

        // Fetch snapshots for this month cycle
        $stmt = $this->db->prepare("SELECT * FROM atk_monthly_payrolls WHERE employee_id = :emp_id AND month = :month AND year = :year ORDER BY start_date ASC");
        $stmt->execute([':emp_id' => $employee_id, ':month' => $month, ':year' => $year]);

        $snapshots = [];
        $latest_snapshot_end = null;

        $final_days = [];
        $totals = [
            'present_days' => 0,
            'absent_days' => 0,
            'off_days' => 0,
            'holiday_days' => 0,
            'vacation_days' => 0,
            'late_count' => 0,
            'total_late_minutes' => 0,
            'total_early_exit_minutes' => 0,
            'absence_deduction' => 0.0,
            'late_deduction' => 0.0,
            'early_exit_deduction' => 0.0,
            'total_deduction' => 0.0,
            'total_overtime_minutes' => 0,
            'overtime_bonus' => 0.0,
        ];

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $snapshots[] = $row;
            if ($latest_snapshot_end === null || $row['end_date'] > $latest_snapshot_end) {
                $latest_snapshot_end = $row['end_date'];
            }

            $snap_totals = json_decode($row['totals_json'], true);
            $snap_days = json_decode($row['daily_data_json'], true);

            foreach (array_keys($totals) as $key) {
                if (isset($snap_totals[$key])) {
                    $totals[$key] += $snap_totals[$key];
                }
            }
            if (is_array($snap_days)) {
                $final_days = array_merge($final_days, $snap_days);
            }
        }

        // Determine the dynamic calculation period
        $dynamic_start = $cycle_start;
        if ($latest_snapshot_end !== null) {
            $dt = new DateTime($latest_snapshot_end);
            $dt->modify('+1 day');
            $dynamic_start = $dt->format('Y-m-d');
        }

        $dynamic_result = null;
        $current_salary = 0;
        $current_work_days = 0;
        $employee_name = '';

        if ($dynamic_start <= $cycle_end) {
            $dynamic_result = $this->calculatePeriod($employee_id, $dynamic_start, $cycle_end, $month, $year);

            $current_salary = $dynamic_result['employee']['salary'];
            $current_work_days = $dynamic_result['employee']['work_days_per_week'];
            $employee_name = $dynamic_result['employee']['name'];

            if (empty($snapshots)) {
                // No snapshots, use dynamic entirely
                $totals = $dynamic_result['totals'];
                $final_days = $dynamic_result['days'];
            } else {
                // Combine dynamic with snapshots
                $dyn_totals = $dynamic_result['totals'];
                foreach (array_keys($totals) as $key) {
                    if (isset($dyn_totals[$key])) {
                        $totals[$key] += $dyn_totals[$key];
                    }
                }
                $final_days = array_merge($final_days, $dynamic_result['days']);
            }
        } else {
            // Completely snapshotted month
            $empModel = new Employee($this->db);
            $employee = $empModel->readOne($employee_id);
            $current_salary = $employee['salary'] ?? 0;
            $current_work_days = $employee['work_days_per_week'] ?? 6;
            $employee_name = $employee['name'] ?? '';
        }

        // Finalize net salary using current latest salary as base
        $totals['net_salary'] = max(0, $current_salary - $totals['total_deduction'] + $totals['overtime_bonus']);

        // Rounding
        $totals['absence_deduction'] = round($totals['absence_deduction'], 2);
        $totals['late_deduction'] = round($totals['late_deduction'], 2);
        $totals['early_exit_deduction'] = round($totals['early_exit_deduction'], 2);
        $totals['total_deduction'] = round($totals['total_deduction'], 2);
        $totals['overtime_bonus'] = round($totals['overtime_bonus'], 2);
        $totals['net_salary'] = round($totals['net_salary'], 2);

        return [
            'employee' => [
                'id' => $employee_id,
                'name' => $employee_name,
                'salary' => $current_salary,
                'work_days_per_week' => $current_work_days
            ],
            'cycle' => [
                'start' => $cycle_start,
                'end' => $cycle_end,
                'month' => $month,
                'year' => $year
            ],
            'days' => $final_days,
            'totals' => $totals,
            'is_split' => count($snapshots) > 0
        ];
    }

    public function getCycleForDate($date_str)
    {
        $dt = new DateTime($date_str);
        $day = (int) $dt->format('d');
        $month = (int) $dt->format('m');
        $year = (int) $dt->format('Y');

        if ($day >= 25) {
            $month++;
            if ($month > 12) {
                $month = 1;
                $year++;
            }
        }
        return ['month' => $month, 'year' => $year];
    }

    public function autoClosePastMonths($employee_id, $start_date, $target_end_date)
    {
        if (!$start_date) {
            $stmt = $this->db->prepare("SELECT MIN(date) FROM atk_attendance WHERE employee_id = ?");
            $stmt->execute([$employee_id]);
            $start_date = $stmt->fetchColumn();
        }

        if (!$start_date || $start_date > $target_end_date) {
            return ['status' => 'error', 'message' => 'لا توجد سجلات حضور للموظف أو أن تاريخ الإغلاق يسبق تاريخ البداية.', 'duplicates' => []];
        }

        $start_cycle = $this->getCycleForDate($start_date);
        $end_cycle = $this->getCycleForDate($target_end_date);

        $current_month = $start_cycle['month'];
        $current_year = $start_cycle['year'];

        $duplicates = [];
        $created_count = 0;

        while (true) {
            if ($current_year > $end_cycle['year'] || ($current_year == $end_cycle['year'] && $current_month > $end_cycle['month'])) {
                break;
            }

            $cycle_end = sprintf('%04d-%02d-24', $current_year, $current_month);
            $is_target_cycle = ($current_year == $end_cycle['year'] && $current_month == $end_cycle['month']);
            $split_date = $is_target_cycle ? $target_end_date : $cycle_end;

            $is_start_cycle = ($current_year == $start_cycle['year'] && $current_month == $start_cycle['month']);
            $override_start = $is_start_cycle ? $start_date : null;

            // Let splitPayroll handle duplicate/overlap detection internally.
            // It will find the latest snapshot and start from after it,
            // or return false if the period is already fully covered.
            $res = $this->splitPayroll($employee_id, $current_month, $current_year, $split_date, $override_start);
            if ($res) {
                $created_count++;
            } else {
                $duplicates[] = sprintf('%04d-%02d', $current_year, $current_month);
            }

            $current_month++;
            if ($current_month > 12) {
                $current_month = 1;
                $current_year++;
            }
        }

        if ($created_count > 0) {
            return ['status' => 'success', 'created' => $created_count, 'duplicates' => $duplicates];
        } else {
            return ['status' => 'duplicate', 'created' => 0, 'duplicates' => $duplicates];
        }
    }

    public function splitPayroll($employee_id, $month, $year, $split_end_date, $override_start_date = null)
    {
        $summary = $this->getMonthlySummary($employee_id, $month, $year);
        if (!$summary)
            return false;

        // Check if there's already a snapshot for this end date
        $stmt = $this->db->prepare("SELECT id FROM atk_monthly_payrolls WHERE employee_id = :emp_id AND end_date = :end_date");
        $stmt->execute([':emp_id' => $employee_id, ':end_date' => $split_end_date]);
        if ($stmt->fetch()) {
            return false; // Already snapshotted
        }

        // Re-calculate strictly up to the split_end_date
        // We find the last snapshot end date
        $stmtLatest = $this->db->prepare("SELECT MAX(end_date) as last_end FROM atk_monthly_payrolls WHERE employee_id = :emp_id AND month = :month AND year = :year");
        $stmtLatest->execute([':emp_id' => $employee_id, ':month' => $month, ':year' => $year]);
        $lastSnap = $stmtLatest->fetch(PDO::FETCH_ASSOC);

        if ($month == 1) {
            $start_month = 12;
            $start_year = $year - 1;
        } else {
            $start_month = $month - 1;
            $start_year = $year;
        }
        $cycle_start = sprintf('%04d-%02d-25', $start_year, $start_month);
        $cycle_end = sprintf('%04d-%02d-24', $year, $month);

        if ($split_end_date < $cycle_start || $split_end_date > $cycle_end) {
            return false; // Out of bounds for this month cycle
        }

        $dynamic_start = $cycle_start;
        if (!empty($lastSnap['last_end'])) {
            // Check if the requested split date is already covered by existing snapshots
            if ($split_end_date <= $lastSnap['last_end']) {
                return false; // Already snapshotted
            }
            $dt = new DateTime($lastSnap['last_end']);
            $dt->modify('+1 day');
            $dynamic_start = $dt->format('Y-m-d');
        }

        if ($override_start_date && $override_start_date > $dynamic_start) {
            $dynamic_start = $override_start_date;
        }

        if ($dynamic_start > $split_end_date) {
            return false; // Invalid split date
        }

        $partial_result = $this->calculatePeriod($employee_id, $dynamic_start, $split_end_date, $month, $year);

        // Save to DB (INSERT IGNORE guarantees zero duplicate insertions at the database engine level)
        $stmtIns = $this->db->prepare("INSERT IGNORE INTO atk_monthly_payrolls (employee_id, month, year, start_date, end_date, salary_snapshot, work_days_per_week_snapshot, totals_json, daily_data_json) VALUES (:emp, :mo, :yr, :sd, :ed, :sal, :wd, :tot, :day)");
        $stmtIns->execute([
            ':emp' => $employee_id,
            ':mo' => $month,
            ':yr' => $year,
            ':sd' => $dynamic_start,
            ':ed' => $split_end_date,
            ':sal' => $partial_result['employee']['salary'],
            ':wd' => $partial_result['employee']['work_days_per_week'],
            ':tot' => json_encode($partial_result['totals']),
            ':day' => json_encode($partial_result['days'])
        ]);

        return true;
    }

    private function calculatePeriod($employee_id, $start_date, $end_date, $month, $year)
    {
        // ... (This will contain the logic from the old getMonthlySummary)
        // I will implement the exact same logic as before but using $start_date and $end_date
        $settingModel = new Setting($this->db);
        $settings = $settingModel->getSettings();

        $empModel = new Employee($this->db);
        $employee = $empModel->readOne($employee_id);

        $work_days_per_week = (int) ($employee['work_days_per_week'] ?? 6);
        $salary = (float) ($employee['salary'] ?? 0);

        // Fetch Weekly Holidays
        $stmtWH = $this->db->query("SELECT day_name FROM atk_weekly_holidays");
        $weekly_holidays = [];
        while ($row = $stmtWH->fetch(PDO::FETCH_ASSOC)) {
            $weekly_holidays[] = strtolower($row['day_name']);
        }

        // Fetch Public Holidays
        $stmtH = $this->db->prepare("SELECT date, end_date FROM atk_holidays WHERE date <= :ed AND (end_date IS NULL OR end_date >= :sd)");
        $stmtH->execute([':sd' => $start_date, ':ed' => $end_date]);
        $holidays = [];
        while ($row = $stmtH->fetch(PDO::FETCH_ASSOC)) {
            $sd = new DateTime($row['date']);
            $ed = $row['end_date'] ? new DateTime($row['end_date']) : clone $sd;
            while ($sd <= $ed) {
                $holidays[] = $sd->format('Y-m-d');
                $sd->modify('+1 day');
            }
        }

        // Fetch Approved Vacations
        $stmtV = $this->db->prepare("SELECT start_date, end_date, is_hourly, total_minutes, reason FROM atk_vacations WHERE employee_id = :emp_id AND status = 'approved' AND start_date <= :ed AND end_date >= :sd");
        $stmtV->execute([':emp_id' => $employee_id, ':sd' => $start_date, ':ed' => $end_date]);
        $full_vacations = [];
        $hourly_late = [];
        $hourly_early = [];
        $hourly_both = [];
        while ($row = $stmtV->fetch(PDO::FETCH_ASSOC)) {
            if ($row['is_hourly']) {
                $reason = $row['reason'] ?? '';
                if (strpos($reason, '[COVER_EARLY]') !== false) {
                    if (!isset($hourly_early[$row['start_date']]))
                        $hourly_early[$row['start_date']] = 0;
                    $hourly_early[$row['start_date']] += (int) $row['total_minutes'];
                } else if (strpos($reason, '[COVER_LATE]') !== false) {
                    if (!isset($hourly_late[$row['start_date']]))
                        $hourly_late[$row['start_date']] = 0;
                    $hourly_late[$row['start_date']] += (int) $row['total_minutes'];
                } else {
                    if (!isset($hourly_both[$row['start_date']]))
                        $hourly_both[$row['start_date']] = 0;
                    $hourly_both[$row['start_date']] += (int) $row['total_minutes'];
                }
            } else {
                $sd = new DateTime($row['start_date']);
                $ed = new DateTime($row['end_date']);
                while ($sd <= $ed) {
                    $full_vacations[] = $sd->format('Y-m-d');
                    $sd->modify('+1 day');
                }
            }
        }

        // Fetch Approved Corrections
        $stmtC = $this->db->prepare("SELECT date, type, requested_time FROM atk_attendance_corrections WHERE employee_id = :emp_id AND status = 'approved' AND date >= :sd AND date <= :ed");
        $stmtC->execute([':emp_id' => $employee_id, ':sd' => $start_date, ':ed' => $end_date]);
        $corrections = [];
        while ($row = $stmtC->fetch(PDO::FETCH_ASSOC)) {
            if (!isset($corrections[$row['date']]))
                $corrections[$row['date']] = [];
            $corrections[$row['date']][$row['type']] = $row['requested_time'];
        }

        // Fetch Approved Overtime
        $stmtO = $this->db->prepare("SELECT SUM(total_minutes) as total_ot FROM atk_overtime_requests WHERE employee_id = :emp_id AND status = 'approved' AND date >= :sd AND date <= :ed");
        $stmtO->execute([':emp_id' => $employee_id, ':sd' => $start_date, ':ed' => $end_date]);
        $overtime_row = $stmtO->fetch(PDO::FETCH_ASSOC);
        $total_overtime_minutes = (int) ($overtime_row['total_ot'] ?? 0);

        // Fetch Raw Attendance
        $stmtA = $this->db->prepare("SELECT * FROM atk_attendance WHERE employee_id = :emp_id AND date >= :sd AND date <= :ed");
        $stmtA->execute([':emp_id' => $employee_id, ':sd' => $start_date, ':ed' => $end_date]);
        $raw_attendance = [];
        while ($row = $stmtA->fetch(PDO::FETCH_ASSOC)) {
            $raw_attendance[$row['date']] = $row;
        }

        // Generate Calendar Loop
        $current = new DateTime($start_date);
        $end_dt = new DateTime($end_date);
        $today = (new DateTime())->format('Y-m-d');

        $raw_days = [];

        while ($current <= $end_dt) {
            $dateStr = $current->format('Y-m-d');
            $dayName = strtolower($current->format('l'));

            if (in_array($dayName, $weekly_holidays) && $work_days_per_week != 7) {
                $current->modify('+1 day');
                continue;
            }

            $is_holiday = in_array($dateStr, $holidays);
            $is_vacation = in_array($dateStr, $full_vacations);

            if (isset($raw_attendance[$dateStr]) || isset($corrections[$dateStr])) {
                $record = $raw_attendance[$dateStr] ?? [
                    'employee_id' => $employee_id,
                    'date' => $dateStr,
                    'check_in' => null,
                    'check_out' => null,
                    'late_minutes' => 0,
                    'early_exit_minutes' => 0,
                    'status' => 'absent',
                    'notes' => ''
                ];

                if (isset($corrections[$dateStr])) {
                    $corr = $corrections[$dateStr];
                    if (isset($corr['check_in']) || isset($corr['missing_check_in'])) {
                        $newIn = $corr['check_in'] ?? $corr['missing_check_in'];
                        $record['check_in'] = $dateStr . ' ' . $newIn;
                    }
                    if (isset($corr['check_out']) || isset($corr['missing_check_out'])) {
                        $newOut = $corr['check_out'] ?? $corr['missing_check_out'];
                        $record['check_out'] = $dateStr . ' ' . $newOut;
                    }
                }

                // ALWAYS CALCULATE ON THE FLY!
                $calc = AttendanceCalculator::calculate($record['check_in'], $record['check_out'], $dateStr, $employee, $settings);
                $record['late_minutes'] = $calc['late_minutes'];
                $record['early_exit_minutes'] = $calc['early_exit_minutes'];
                $record['status'] = $calc['status'];

                $record['is_holiday'] = $is_holiday;
                $record['is_vacation'] = $is_vacation;
                $raw_days[] = $record;
            } else {
                $status = 'empty';
                if ($is_vacation)
                    $status = 'vacation';
                else if ($is_holiday)
                    $status = 'holiday';
                else if ($dateStr > $today)
                    $status = 'pending';

                $raw_days[] = [
                    'employee_id' => $employee_id,
                    'date' => $dateStr,
                    'status' => $status,
                    'check_in' => null,
                    'check_out' => null,
                    'late_minutes' => 0,
                    'early_exit_minutes' => 0,
                    'notes' => ''
                ];
            }
            $current->modify('+1 day');
        }

        // Pass 2: Group by Week and enforce work_days_per_week
        $weeks = [];
        $refDate = new DateTime('2000-01-02');
        foreach ($raw_days as &$day) {
            $dt = new DateTime($day['date']);
            $weekId = intdiv($dt->diff($refDate)->days, 7);
            $weeks[$weekId][] = &$day;
        }

        $final_days = [];
        $requiredDaysPerWeek = min(7, $work_days_per_week);

        foreach ($weeks as $weekId => &$daysInWeek) {
            $presentCount = 0;
            $emptyDays = [];

            foreach ($daysInWeek as &$d) {
                if (!in_array($d['status'], ['empty', 'pending', 'absent'])) {
                    $presentCount++;
                } else if (in_array($d['date'], $full_vacations)) {
                    $presentCount++;
                }

                if ($d['status'] === 'empty' || $d['status'] === 'absent') {
                    $emptyDays[] = &$d;
                }
            }

            $absentAllowed = max(0, $requiredDaysPerWeek - $presentCount);

            foreach ($emptyDays as &$emptyDay) {
                if ($absentAllowed > 0) {
                    $emptyDay['status'] = 'absent';
                    $absentAllowed--;
                } else {
                    $emptyDay['status'] = 'off';
                }
            }

            foreach ($daysInWeek as $d2) {
                $final_days[] = $d2;
            }
        }

        // Pass 3: Financial Calculations
        $work_duration = AttendanceCalculator::getWorkDayDuration($employee, $settings);
        $daysInMonthParam = cal_days_in_month(CAL_GREGORIAN, $month, $year);
        $divisor = ($work_days_per_week == 7) ? $daysInMonthParam : 26;
        if ($divisor <= 0)
            $divisor = 30;

        $totals = [
            'present_days' => 0,
            'absent_days' => 0,
            'off_days' => 0,
            'holiday_days' => 0,
            'vacation_days' => 0,
            'late_count' => 0,
            'total_late_minutes' => 0,
            'total_early_exit_minutes' => 0,
            'absence_deduction' => 0.0,
            'late_deduction' => 0.0,
            'early_exit_deduction' => 0.0,
            'total_deduction' => 0.0,
            'total_overtime_minutes' => $total_overtime_minutes,
            'overtime_bonus' => 0.0,
        ];

        $minuteRate = ($divisor > 0 && $work_duration > 0) ? ($salary / $divisor / $work_duration) : 0;
        $totals['overtime_bonus'] = $total_overtime_minutes * $minuteRate;

        foreach ($final_days as &$d) {
            $discount = 0.0;
            $late = (int) $d['late_minutes'];
            $early = (int) $d['early_exit_minutes'];

            $hl = $hourly_late[$d['date']] ?? 0;
            $he = $hourly_early[$d['date']] ?? 0;
            $hb = $hourly_both[$d['date']] ?? 0;

            // Removed the block that converts absent to late

            $effectiveLate = max(0, $late - $hl);
            $effectiveEarly = max(0, $early - $he);

            $hb_used_for_late = min($hb, $effectiveLate);
            $effectiveLate = max(0, $effectiveLate - $hb_used_for_late);
            $hbRemaining = max(0, $hb - $hb_used_for_late);
            $effectiveEarly = max(0, $effectiveEarly - $hbRemaining);

            $lateDiscount = 0.0;
            $earlyDiscount = 0.0;

            if ($effectiveLate > 0 && ($d['status'] === 'present' || $d['status'] === 'late' || $d['status'] === 'early_exit' || $d['status'] === 'incomplete')) {
                if ($d['status'] !== 'incomplete')
                    $d['status'] = 'late';
                $lateDiscount = AttendanceCalculator::calculateDiscount($salary, $effectiveLate, 0, $work_duration, $daysInMonthParam);
                $totals['late_count']++;
                $totals['total_late_minutes'] += $effectiveLate;
                $totals['late_deduction'] += $lateDiscount;
            }

            if ($effectiveEarly > 0) {
                if ($d['status'] !== 'incomplete')
                    $d['status'] = 'early_exit';
                $earlyDiscount = AttendanceCalculator::calculateDiscount($salary, 0, $effectiveEarly, $work_duration, $daysInMonthParam);
                $totals['total_early_exit_minutes'] += $effectiveEarly;
                $totals['early_exit_deduction'] += $earlyDiscount;
            }

            if ($d['status'] === 'absent' && !in_array($d['date'], $full_vacations)) {
                $total_hv = $hl + $he + $hb;
                $dailyAbsenceRate = ($daysInMonthParam > 0) ? ($salary / $daysInMonthParam) : 0;
                $minuteAbsenceRate = ($work_duration > 0) ? ($dailyAbsenceRate / $work_duration) : 0;
                
                if ($total_hv > 0) {
                    $remaining_mins = max(0, $work_duration - $total_hv);
                    if ($remaining_mins > 0) {
                        $discount = $remaining_mins * $minuteAbsenceRate;
                        $d['notes'] = trim(($d['notes'] ?? '') . ' غياب مغطى جزئياً');
                    } else {
                        $discount = 0;
                        $d['status'] = 'vacation';
                        $totals['vacation_days']++;
                        $d['notes'] = trim(($d['notes'] ?? '') . ' غياب مغطى بالكامل كإجازة');
                        $d['late_discount'] = $lateDiscount;
                        $d['early_exit_discount'] = $earlyDiscount;
                        $d['discount'] = $discount + $lateDiscount + $earlyDiscount;
                        $d['late_minutes'] = $effectiveLate;
                        $d['early_exit_minutes'] = $effectiveEarly;
                        continue; // Skip the absent_days logic since it's fully covered
                    }
                } else {
                    $discount = $dailyAbsenceRate;
                }
                
                $totals['absent_days']++;
                $totals['absence_deduction'] += $discount;
            } else if ($d['status'] === 'off') {
                $totals['off_days']++;
            } else if ($d['status'] === 'holiday') {
                $totals['holiday_days']++;
            } else if ($d['status'] === 'vacation') {
                $totals['vacation_days']++;
            } else if ($d['status'] === 'present' || $d['status'] === 'late' || $d['status'] === 'early_exit') {
                $totals['present_days']++;
            }

            $d['late_discount'] = $lateDiscount;
            $d['early_exit_discount'] = $earlyDiscount;
            $d['discount'] = $discount + $lateDiscount + $earlyDiscount;
            $d['late_minutes'] = $effectiveLate;
            $d['early_exit_minutes'] = $effectiveEarly;
        }

        $totals['total_deduction'] = $totals['absence_deduction'] + $totals['late_deduction'] + $totals['early_exit_deduction'];

        return [
            'employee' => [
                'id' => $employee_id,
                'name' => $employee['name'],
                'salary' => $salary,
                'work_days_per_week' => $work_days_per_week
            ],
            'days' => $final_days,
            'totals' => $totals
        ];
    }

    public function autoRunMonthlyPayrollClosingForAll()
    {
        $settingModel = new Setting($this->db);
        $settings = $settingModel->getSettings();

        if (empty($settings['auto_monthly_payroll_enabled']) || $settings['auto_monthly_payroll_enabled'] == 0) {
            return ['status' => 'disabled', 'message' => 'الإغلاق التلقائي غير مفعل.'];
        }

        $today = new DateTime();
        $currentDay = (int) $today->format('d');
        
        if ($currentDay >= 25) {
            $targetMonth = (int) $today->format('m');
            $targetYear = (int) $today->format('Y');
        } else {
            $prevMonthDate = (new DateTime())->modify('-1 month');
            $targetMonth = (int) $prevMonthDate->format('m');
            $targetYear = (int) $prevMonthDate->format('Y');
        }

        $targetMonthStr = sprintf('%04d-%02d', $targetYear, $targetMonth);

        if (!empty($settings['last_auto_closing_month']) && $settings['last_auto_closing_month'] === $targetMonthStr) {
            return ['status' => 'already_run', 'message' => 'تم تنفيذ الإغلاق التلقائي لهذا الشهر مسبقاً.', 'month' => $targetMonthStr];
        }

        $empStmt = $this->db->query("SELECT id, name FROM atk_employees WHERE status = 'active'");
        $employees = $empStmt->fetchAll(PDO::FETCH_ASSOC);

        $targetEndDate = sprintf('%04d-%02d-24', $targetYear, $targetMonth);

        $results = [];
        $totalProcessed = 0;

        foreach ($employees as $emp) {
            $res = $this->autoClosePastMonths($emp['id'], null, $targetEndDate);
            $results[] = [
                'employee_id' => $emp['id'],
                'name' => $emp['name'],
                'result' => $res
            ];
            $totalProcessed++;
        }

        $settingModel->updateLastAutoClosingMonth($targetMonthStr);

        return [
            'status' => 'success',
            'month' => $targetMonthStr,
            'processed' => $totalProcessed,
            'details' => $results
        ];
    }
}
?>
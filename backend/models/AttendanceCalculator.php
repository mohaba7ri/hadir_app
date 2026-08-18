<?php
/**
 * Centralized Attendance Calculation Logic
 * Ensures consistency across API controllers and biometric receiver.
 */
class AttendanceCalculator
{

    /**
     * Calculates attendance metrics based on timings, settings and employee type.
     */
    public static function calculate($checkIn, $checkOut, $date, $empInfo, $settings)
    {
        $default_start = $settings['default_start_time'] ?? '08:00:00';
        $default_end = $settings['default_end_time'] ?? '16:00:00';
        $allowed_late = $settings['allowed_late_minutes'] ?? 15;

        // Handle Ramadan Mode
        if (isset($settings['ramadan_mode']) && ($settings['ramadan_mode'] == 1 || $settings['ramadan_mode'] === true)) {
            $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
            $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
        }

        // Determine effective work hours
        $work_start = $default_start;
        $work_end = $default_end;

        if (!empty($empInfo['special_start_time'])) {
            $work_start = $empInfo['special_start_time'];
            $work_end = !empty($empInfo['special_end_time']) ? $empInfo['special_end_time'] : $default_end;
        }

        $late_minutes = 0;
        $early_exit_minutes = 0;

        $isFlex = (int) ($empInfo['is_flexible'] ?? 0);
        $reqHours = (float) ($empInfo['required_hours'] ?? 8.00);

        $checkInTs = strtotime($checkIn);
        $checkOutTs = $checkOut ? strtotime($checkOut) : null;

        if ($isFlex) {
            // Flexible Schedule Logic: Focus on duration
            if ($checkOutTs) {
                $durationMins = ($checkOutTs - $checkInTs) / 60;
                $reqMins = $reqHours * 60;
                if ($durationMins < $reqMins) {
                    $early_exit_minutes = (int) floor($reqMins - $durationMins);
                }
            }
        } else {
            // Standard Schedule Logic: Focus on fixed times
            $expectedIn = strtotime($date . ' ' . $work_start);
            if ($checkInTs > $expectedIn) {
                $late_minutes = (int) floor(($checkInTs - $expectedIn) / 60);
            }

            if ($checkOutTs) {
                $expectedOut = strtotime($date . ' ' . $work_end);
                // Handle night shifts (cross-midnight)
                if (strtotime($work_end) < strtotime($work_start)) {
                    $expectedOut = strtotime($date . ' ' . $work_end . ' +1 day');
                }
                if ($checkOutTs < $expectedOut) {
                    $early_exit_minutes = (int) floor(($expectedOut - $checkOutTs) / 60);
                }
            }
        }

        // Determine Status
        $status = 'present';
        if ($isFlex) {
            if ($early_exit_minutes > 0)
                $status = 'early_exit';
        } else {
            if ($late_minutes > $allowed_late) {
                $late_minutes -= $allowed_late;
                $status = 'late';
            } else {
                $late_minutes = 0; // Within grace period
            }
            if ($early_exit_minutes > 0 && $status === 'present') {
                $status = 'early_exit';
            }
        }

        if (!$checkOut)
            $status = 'incomplete';

        return [
            'late_minutes' => $late_minutes,
            'early_exit_minutes' => $early_exit_minutes,
            'status' => $status,
            'work_start' => $work_start,
            'work_end' => $work_end
        ];
    }

    /**
     * Calculates the monetary discount for a given attendance record.
     */
    public static function calculateDiscount($salary, $lateMinutes, $earlyExitMinutes, $workDayMinutes, $daysInMonth)
    {
        if ($salary <= 0 || $workDayMinutes <= 0 || $daysInMonth <= 0)
            return 0.0;

        $minuteRate = $salary / $daysInMonth / $workDayMinutes;
        return ($lateMinutes + $earlyExitMinutes) * $minuteRate;
    }

    /**
     * Gets the expected work duration in minutes for an employee on a given day.
     */
    public static function getWorkDayDuration($empInfo, $settings)
    {
        $default_start = $settings['default_start_time'] ?? '08:00:00';
        $default_end = $settings['default_end_time'] ?? '16:00:00';

        if (isset($settings['ramadan_mode']) && ($settings['ramadan_mode'] == 1 || $settings['ramadan_mode'] === true)) {
            $default_start = $settings['ramadan_start_time'] ?? '10:00:00';
            $default_end = $settings['ramadan_end_time'] ?? '15:00:00';
        }

        $work_start = !empty($empInfo['special_start_time']) ? $empInfo['special_start_time'] : $default_start;
        $work_end = !empty($empInfo['special_end_time']) ? $empInfo['special_end_time'] : $default_end;

        $startTs = strtotime("2000-01-01 " . $work_start);
        $endTs = strtotime("2000-01-01 " . $work_end);

        $diff = ($endTs - $startTs) / 60;
        if ($diff < 0)
            $diff += 24 * 60; // Handle overnight shifts

        return $diff > 0 ? $diff : 480; // Fallback to 8 hours
    }
}

# 🏢 ProAttend / Hadir (حاضر) - Biometric Attendance & Payroll Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![PHP](https://img.shields.io/badge/PHP-7.4%2B%20%2F%208.x-777BB4?logo=php)](https://www.php.net)
[![MySQL](https://img.shields.io/badge/MySQL-MariaDB-4479A1?logo=mysql)](https://www.mysql.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

**ProAttend (حاضر)** is an enterprise-grade Attendance, Payroll, and Vacation Management Solution built with a modern **Flutter (Web & Mobile)** frontend, a high-performance **PHP PDO REST API** backend, and real-time **ZKTeco Biometric Hardware Receiver** integration.

---

## 🌟 Key Features

- ⏱️ **Biometric Hardware Sync**: Real-time attendance logs ingested directly from ZKTeco biometric fingerprint/face devices.
- 💵 **Automated Monthly Payroll Engine**: Automatic closing of payroll cycles on the 25th of every month with full snapshot preservation.
- 🌴 **Cumulative Roll-Over Annual Leave Engine**: Dynamic, month-by-month capped roll-over engine starting from Month 8/2026 (`2026-07-25`). Unused credit rolls over while past overages do not penalize future month quotas.
- 🔔 **FCM v1 Push Notifications**: Instant real-time alerts for leave approvals, attendance updates, and administrative notices.
- 📊 **Flexible & Standard Shift Models**: Custom work schedules, flexible required hours, dynamic minute-discount penalty rates, and automatic early exit/late calculations.
- 📱 **Cross-Platform**: Responsive Web Admin Dashboard and Mobile App (Android/iOS) for Employees.

---

## 📐 System Architecture

```mermaid
graph TD
    subgraph Client Layer
        A[Flutter Web Admin Dashboard]
        B[Flutter Employee Mobile App]
    end

    subgraph Backend REST API
        C[PHP PDO REST Controller]
        D[AttendanceEngine Service]
        E[VacationController & Calculator]
    end

    subgraph Integration & Hardware
        F[ZKTeco Biometric Receiver]
        G[Firebase Cloud Messaging v1]
    end

    subgraph Database Layer
        H[(MySQL / MariaDB Database)]
    end

    A <-->|HTTP REST JSON| C
    B <-->|HTTP REST JSON| C
    F -->|ADMS / HTTP Push| C
    C <--> D
    C <--> E
    D <--> H
    E <--> H
    C -->|Push Notifications| G
```

---

## 🔄 Monthly Payroll Cycle (25th to 24th)

The payroll cycle runs from the **25th of Month $M-1$** to the **24th of Month $M$**.

```mermaid
flowchart LR
    A["Cycle Start (25th Month M-1)"] --> B["Daily Biometric Ingestion & Attendance Log"]
    B --> C["On-The-Fly Penalty & Deduction Calculation"]
    C --> D["25th New Month Arrives"]
    D --> E{"Auto-Payroll Enabled?"}
    E -- Yes --> F["Execute Auto-Payroll Snapshot & Close Month M-1"]
    E -- No --> G["Manual Admin Monthly Payroll Review"]
    F --> H["Save to atk_monthly_payrolls (Unique Key Safe)"]
    G --> H
```

---

## 🌴 Cumulative Roll-Over Leave Engine

Effective from **Month 8 of 2026 (`2026-07-25`)**, the leave engine dynamically calculates remaining limits on the fly:

```mermaid
flowchart TD
    Start["Request / View Month (Y, M)"] --> BaselineCheck{"Date >= 2026-07-25?"}
    BaselineCheck -- No --> SingleMonth["Single Cycle Limit (monthly_annual_leave_limit_minutes)"]
    BaselineCheck -- Yes --> LoopStart["Start Month-by-Month Loop from Month 8/2026"]
    
    LoopStart --> Grant["Add Monthly Base Quota (+monthly_annual_leave_limit_minutes)"]
    Grant --> Subtract["Subtract Used Annual Vacations in Month"]
    Subtract --> CapCheck{"Is Running Balance < 0?"}
    CapCheck -- Yes --> ResetZero["Cap Balance at 0 (Ignore Past Debt/Overage)"]
    CapCheck -- No --> KeepBalance["Keep Positive Unused Balance (Roll Over)"]
    
    ResetZero --> NextMonth{"Target Month Reached?"}
    KeepBalance --> NextMonth
    
    NextMonth -- No --> Grant
    NextMonth -- Yes --> Output["Return Current Month Available Balance"]
```

---

## 🗄️ Database Schema & Key Tables

```mermaid
erDiagram
    atk_employees ||--o{ atk_attendance : "has logs"
    atk_employees ||--o{ atk_vacations : "requests"
    atk_employees ||--o{ atk_monthly_payrolls : "receives"
    atk_departments ||--o{ atk_employees : "belongs to"

    atk_employees {
        int id PK
        string name
        decimal salary
        int monthly_annual_leave_limit_minutes
        int vacation_credit
        int work_days_per_week
        string status
    }

    atk_vacations {
        int id PK
        int employee_id FK
        date start_date
        date end_date
        string vacation_type
        int total_minutes
        string status
    }

    atk_monthly_payrolls {
        int id PK
        int employee_id FK
        int month
        int year
        date start_date
        date end_date
        text totals_json
        longtext daily_data_json
        string status
    }
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Web Server**: Apache / Nginx with PHP 7.4+ or PHP 8.x (XAMPP supported)
- **Database**: MySQL 5.7+ or MariaDB 10.4+
- **Frontend**: Flutter SDK 3.x+

### 2. Backend Installation
1. Clone the repository into your web server directory (`htdocs` or `/var/www/html`):
   ```bash
   git clone https://github.com/mohaba7ri/hadir_app.git attendace
   ```
2. Import the database schema:
   - Import `backend/database/schema.sql` into MySQL database `attendance`.
   - Run migration script: `backend/database/alter_auto_payroll_settings.sql`.

3. Configure database connection in `backend/database/db.php`:
   ```php
   private $local_db_name = "attendance";
   private $local_username = "root";
   private $local_password = "";
   ```

### 3. Frontend Installation
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   flutter pub get
   ```
2. Run locally in debug mode:
   ```bash
   flutter run -d chrome
   ```
3. Build production web bundle:
   ```bash
   flutter build web --release
   ```

---

## 🛡️ License

Proprietary Software - All Rights Reserved © 2026 ProAttend / Hadir Team.

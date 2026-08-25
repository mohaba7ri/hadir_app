<div align="center">

# 🏢 ProAttend / Hadir (حاضر)
### Next-Generation Enterprise Attendance, Payroll & Leave Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![PHP](https://img.shields.io/badge/PHP-7.4%2B%20%2F%208.x-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net)
[![MySQL](https://img.shields.io/badge/MySQL-MariaDB-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM%20v1-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![ZKTeco](https://img.shields.io/badge/Hardware-ZKTeco%20ADMS-00A859?style=for-the-badge&logo=hardware&logoColor=white)]()

<p align="center">
  <b>A state-of-the-art biometric workforce management solution featuring real-time hardware sync, automated monthly payroll closing, and an intelligent month-by-month capped roll-over annual leave engine.</b>
</p>

[Key Features](#-key-features) • [System Architecture](#-system-architecture) • [Core Engines](#-core-engines) • [Database Schema](#-database-schema) • [API Guide](#-api-endpoints) • [Setup Guide](#-getting-started)

---
</div>

## 🌟 Key Features

| Feature Module | Description & Capabilities |
| :--- | :--- |
| ⏱️ **Biometric Hardware Sync** | Real-time ADMS ingestion from ZKTeco fingerprint, facial recognition, and RFID hardware devices. |
| 💵 **Automated Payroll Engine** | Automatic monthly cycle closing (25th to 24th) with complete salary & attendance data snapshots. |
| 🌴 **Capped Roll-Over Leave Engine** | Month-by-month annual leave engine where positive unused limit rolls over, but past overages never penalize future months. |
| 🔔 **FCM v1 Push Notifications** | Instant alerts for leave requests, approvals, shift reminders, and admin announcements. |
| 📊 **Flexible & Fixed Shift Models** | Dynamic support for standard hours, flexible shifts, custom required hours, and minute-discount penalty rates. |
| 📱 **Cross-Platform UI** | High-performance Web Dashboard for Administrators & Responsive Mobile App for Employees. |

---

## 📐 System Architecture

```mermaid
graph TB
    subgraph Client Layer
        A[Flutter Web Admin Dashboard]
        B[Flutter Employee Mobile App]
    end

    subgraph API Gateway & Authentication
        C[PHP REST API Gateway]
        D[JWT / Session Authentication]
    end

    subgraph Core Computation Services
        E[AttendanceEngine Service]
        F[VacationController & Roll-Over Engine]
        G[Setting & Payroll Controller]
    end

    subgraph Integration & Hardware Pipeline
        H[ZKTeco Biometric Hardware Devices]
        I[ZKTeco Push Receiver Handler]
        J[Firebase Cloud Messaging FCM v1 Engine]
    end

    subgraph Database Layer
        K[(MySQL / MariaDB Database)]
    end

    A <-->|HTTPS / REST API| C
    B <-->|HTTPS / REST API| C
    H -->|ADMS Push Logs| I
    I -->|Ingest Logs| K
    C <--> D
    C <--> E
    C <--> F
    C <--> G
    E <--> K
    F <--> K
    G <--> K
    F -->|Trigger Notifications| J
```

---

## ⚡ Core Engines & Business Logic

### 1. Real-Time Biometric Log Ingestion Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Employee
    participant ZKTeco Device
    participant PHP Receiver
    participant AttendanceEngine
    participant Database

    Employee->>ZKTeco Device: Scan Fingerprint / Face ID
    ZKTeco Device->>PHP Receiver: Send Real-Time ADMS Push Payload
    PHP Receiver->>Database: Insert Log into atk_attendance / RAW Logs
    PHP Receiver->>AttendanceEngine: Trigger Daily Calculation Pipeline
    AttendanceEngine->>Database: Calculate Late, Early Exit, Flexible Hours & Discounts
```

---

### 2. Monthly Payroll Cycle (25th to 24th) Flowchart

```mermaid
flowchart TD
    Start["Cycle Period: 25th Month M-1 to 24th Month M"] --> DailyLogs["Daily Attendance Log Aggregation"]
    DailyLogs --> CalcPenalties["Calculate Delay, Early Exit & Absence Deductions"]
    CalcPenalties --> SystemLoad{"25th New Month Arrives?"}
    
    SystemLoad -- Yes --> CheckSetting{"auto_monthly_payroll_enabled == 1?"}
    CheckSetting -- Yes --> CheckAlreadyRun{"Check last_auto_closing_month"}
    CheckAlreadyRun -- Not Closed Yet --> ExecuteEngine["Run AttendanceEngine::autoRunMonthlyPayrollClosingForAll()"]
    
    ExecuteEngine --> SaveSnapshot["Save Salary & Daily Data Snapshot to atk_monthly_payrolls"]
    SaveSnapshot --> UpdateLastRun["Update last_auto_closing_month = YYYY-MM"]
    UpdateLastRun --> Complete["Payroll Closed Successfully with UNIQUE KEY Protection"]
```

---

### 3. Month-by-Month Capped Annual Leave Roll-Over Engine

```mermaid
flowchart TD
    Request["Request / Check Annual Leave for Month (Y, M)"] --> BaselineCheck{"Cycle Date >= 2026-07-25 (Month 8/2026)?"}
    
    BaselineCheck -- No --> StandardCycle["Apply Single Cycle Limit (monthly_annual_leave_limit_minutes)"]
    BaselineCheck -- Yes --> InitLoop["Initialize Loop from Month 8/2026 (curY=2026, curM=8)"]
    
    InitLoop --> GrantQuota["Add Monthly Base Quota (+monthly_annual_leave_limit_minutes)"]
    GrantQuota --> QueryUsed["Query Used Annual Vacations in (curY, curM) Cycle"]
    
    QueryUsed --> TargetCheck{"Is (curY, curM) == Target (Y, M)?"}
    
    TargetCheck -- Target Month --> CheckRequest["Verify (Used + Requested) <= Available Balance"]
    CheckRequest -- Exceeds --> Reject["Reject Request with Exact Remaining Feedback"]
    CheckRequest -- Within Balance --> Approve["Approve / Allow Request Submission"]
    
    TargetCheck -- Past Month --> CapDebt["Subtract Used & Apply Cap: balance = max(0, balance - used)"]
    CapDebt --> AdvanceMonth["Advance to Next Month (curM++)"]
    AdvanceMonth --> LoopCondition{"curY > Y OR curM > M?"}
    LoopCondition -- No --> GrantQuota
    LoopCondition -- Yes --> Finish["Return Running Balance for Target Month"]
```

---

## 🗄️ Entity-Relationship Diagram (ERD)

```mermaid
erDiagram
    atk_departments ||--o{ atk_employees : "contains"
    atk_employees ||--o{ atk_attendance : "logs"
    atk_employees ||--o{ atk_vacations : "requests"
    atk_employees ||--o{ atk_monthly_payrolls : "receives"
    atk_settings ||--|| atk_monthly_payrolls : "manages cycle"

    atk_employees {
        int id PK
        string name
        decimal salary
        int monthly_annual_leave_limit_minutes
        int vacation_credit
        int work_days_per_week
        string status
        time special_start_time
        time special_end_time
    }

    atk_vacations {
        int id PK
        int employee_id FK
        date start_date
        date end_date
        string vacation_type
        int total_minutes
        int total_days
        string status
        string attachment
    }

    atk_monthly_payrolls {
        int id PK
        int employee_id FK
        int month
        int year
        date start_date
        date end_date
        decimal salary_snapshot
        text totals_json
        longtext daily_data_json
        string status
    }

    atk_settings {
        int id PK
        int auto_monthly_payroll_enabled
        string last_auto_closing_month
        time default_start_time
        time default_end_time
    }
```

---

## 📡 Key API Endpoints

| Method | Endpoint | Description | Role / Auth |
| :--- | :--- | :--- | :--- |
| `POST` | `/backend/index.php?route=login` | Employee & Admin Login | Public |
| `GET` | `/backend/index.php?route=employees` | Fetch List of Employees | Admin |
| `GET` | `/backend/index.php?route=attendance` | Query Attendance & Penalties | Admin / Employee |
| `POST` | `/backend/index.php?route=vacations` | Submit Vacation Request | Admin / Employee |
| `PUT` | `/backend/index.php?route=vacations/{id}` | Approve / Reject Vacation | Admin |
| `GET` | `/backend/index.php?route=settings` | Query System Settings | Admin |
| `PUT` | `/backend/index.php?route=settings` | Update Auto-Payroll Settings | Admin |

---

## 🚀 Getting Started

### 1. Prerequisites
- **Web Server**: Apache / Nginx with PHP 7.4+ or PHP 8.x
- **Database**: MySQL 5.7+ / MariaDB 10.4+
- **Development**: Flutter SDK 3.x+ & Dart 3.x+

### 2. Backend Setup
1. Clone the repository into your server root (`htdocs` or `/var/www/html`):
   ```bash
   git clone https://github.com/mohaba7ri/hadir_app.git attendace
   ```
2. Import Database Schema & Migrations:
   - Import `backend/database/schema.sql`.
   - Run migration: `backend/database/alter_auto_payroll_settings.sql`.
3. Configure `backend/database/db.php`:
   ```php
   private $local_db_name = "attendance";
   private $local_username = "root";
   private $local_password = "";
   ```

### 3. Frontend Setup
1. Open terminal in the `frontend` folder:
   ```bash
   cd frontend
   flutter pub get
   ```
2. Launch in Debug Mode:
   ```bash
   flutter run -d chrome
   ```
3. Build Web Production Bundle:
   ```bash
   flutter build web --release
   ```

---

<div align="center">
  <b>Built with ❤️ by ProAttend Engineering Team</b><br>
  <i>Proprietary Software - All Rights Reserved © 2026</i>
</div>

# ProAttend - Professional Attendance & Leave Management System

A highly robust, comprehensive, and natively localized (Arabic) Enterprise Attendance Management System. ProAttend is engineered to bridge the gap between complex HR logic and user-friendly interfaces, offering seamless employee tracking, automated financial penalty calculations, and highly customizable shift structures. 

Built with **Flutter** for a beautiful, responsive, cross-platform frontend and powered by a highly optimized custom **PHP API** backend, this system eliminates the need for manual HR calculations while providing unparalleled transparency for both employees and management.

---

## 🌟 Why ProAttend?

Traditional attendance systems often just record "check-in" and "check-out" times, leaving HR to manually calculate delays, early exits, and their respective salary deductions. ProAttend automates this entire pipeline. From the moment an employee punches in to the moment payroll is generated, every minute is tracked, calculated, and financially accounted for based on dynamic, customizable rules.

---

## 🚀 Core Features

### 📊 Comprehensive Admin Dashboard & Analytics
- **Live Monitoring:** Real-time visibility into the daily workforce status (Present, Absent, Late, Early Exit, Holiday).
- **Data Filtering:** Advanced search and filtering mechanisms by employee, department, and custom month/year date ranges.
- **Monthly Employee Summaries:** Deep dive into individual employee records with a unified view of their monthly attendance, total late minutes, total early exits, and exact calculated financial discounts.

### 💰 Automated Financial Deductions Engine
- **Minute-by-Minute Salary Calculus:** Automatically calculates the exact financial value of a single working minute based on the employee's monthly salary and the configured working days.
- **Smart Penalty Application:** Automatically applies financial discounts for unexcused late arrivals, unapproved early exits, and full-day unexcused absences.
- **Override Capabilities:** Administrators can override automatic penalties by converting absences into approved leaves or excusing specific delays on a case-by-case basis.

### 🏖️ Advanced Vacation & Coverage Workflows
- **Multi-Tiered Leave Policies:** Native support for Annual Leaves, Business Missions, Sick Leaves, and Unpaid Leaves.
- **Hourly Vacations (Delay Coverage):** A standout feature that allows employees to request "partial vacations" (e.g., 45 minutes) specifically to cover a late arrival or early exit, automatically reversing the financial penalty without consuming a full day of their leave balance.
- **Secure Attachments:** Built-in file and image upload support for leave requests, allowing employees to easily attach medical reports or official documents for management review.
- **Automated Balance Tracking:** The system strictly enforces leave limits, automatically calculating remaining vacation credit (in days and minutes) and preventing over-requesting.

### ⏱️ Dynamic Shift & Working Hours Management
- **Flexible Shift Support:** Accommodates both fixed-schedule employees (e.g., 08:00 AM - 04:00 PM) and flexible-schedule employees who simply need to complete a set number of hours per day.
- **Custom Individual Shifts:** Ability to override global company hours and assign unique start and end times to specific employees.
- **Ramadan Mode:** A one-click global setting that instantly switches the entire organization's logic to a custom, reduced-hour schedule for the holy month of Ramadan.
- **National & Recurring Holidays:** Easily define company-wide holidays (one-time or annually recurring) where employee absence is fully excused.

### 🔄 Data Synchronization & Correction
- **Machine Integration Ready:** Built-in JSON import endpoints designed to seamlessly sync raw punch data from external fingerprint or facial recognition machines.
- **Correction Requests:** Employees who forget to punch in or out can submit formal "Correction Requests" through their portal. Once approved by an admin, the system dynamically recalculates their attendance and financial status for that day.

### 👥 Role-Based Portals
- **Employee Portal:** A clean, intuitive dashboard where employees can track their own attendance, view their exact financial deductions, check their remaining leave balance, and submit requests.
- **Admin Portal:** A powerful command center with full control over organizational data, department management, employee settings, and a unified inbox for all pending approvals.

---

## 🛠️ Technology Highlights

ProAttend leverages modern technologies to ensure lightning-fast performance, rock-solid stability, and a seamless user experience.

- **Cross-Platform Frontend:** Built with **Flutter**, allowing the application to run beautifully and natively across Desktop, Web, and Mobile from a single, unified codebase.
- **Reactive State Management:** Utilizes **GetX** to deliver an incredibly smooth, highly responsive, and dynamic user interface.
- **High-Performance Backend:** Powered by a highly optimized, lightweight **PHP REST API** designed for ultimate speed and reliability, seamlessly handling massive attendance aggregations.
- **Scalable Database:** Uses **MySQL** for robust, secure, and efficient data storage capable of handling complex enterprise queries.
- **Premium UI/UX Design:** Features a polished, modern aesthetic with contextual dialogs, intuitive interfaces, and clear visual data presentation.

---

*Designed and developed to set a new standard in localized HR software solutions.*

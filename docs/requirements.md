# NPD Fuel Monitoring System — Requirements

## Problem
NPD Ltd Rwanda allocates fuel monthly to employees.
Employees misuse fuel (finishes early). Management cannot verify or prove misuse.

## Constraints
- NO GPS tracking
- NO IoT hardware
- Mobile-first (Android & iOS)
- Must work in low-connectivity (Rwanda)
- Low-cost and practical
- Must use AI for prediction and anomaly detection

---

## User Roles

| Role        | Permissions |
|-------------|-------------|
| SUPER_ADMIN | Full access. Manage users, vehicles, allocations, reports |
| MANAGER     | Approve/reject requests. View team usage. See anomalies |
| DRIVER      | Submit fuel requests. Upload receipts. Log odometer |
| FINANCE     | View allocations and reports only |

---

## Core Features (MVP Order)

1. Authentication (login, JWT, refresh)
2. Fuel allocation (admin sets monthly liters + amount per driver)
3. Fuel request & approval workflow
4. Receipt upload (image)
5. Odometer capture (image)
6. Basic reporting
7. Rule-based anomaly detection

Post-MVP:
- OCR for receipts and odometer
- AI consumption prediction
- Advanced fraud detection

---

## User Flows

### Driver
Login → Dashboard → Create Fuel Request →
Upload Odometer Photo → Await Approval →
Fuel Received → Upload Receipt → Done

### Manager
Login → Dashboard (anomaly alerts) →
Review Pending Requests → Approve/Reject →
View Usage Analytics → Generate Reports

### Admin
Login → Manage Users → Set Monthly Allocations →
View All Activity → Configure Thresholds → Export Reports

---

## Non-Functional Requirements

| Concern         | Decision |
|-----------------|----------|
| Offline support | Flutter local DB (Drift), sync queue when online |
| Low connectivity| Compressed image uploads, retry queues |
| Auth            | JWT access (15min) + refresh token (7 days) |
| Image storage   | Cloudinary |
| Security        | Role-based guards, input validation, rate limiting |
| Currency        | RWF (Rwandan Franc) |
| Language        | English (Kinyarwanda future) |

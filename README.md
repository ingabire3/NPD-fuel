# NPD Fuel Monitoring System

AI-powered mobile app for fuel monitoring and management — NPD Ltd Rwanda.

Drivers request fuel allocations, finance/admin approve them, and the system tracks receipts, odometer readings, and flags anomalies using AI.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Mobile App Setup (Flutter)](#mobile-app-setup-flutter)
- [Backend Setup (NestJS)](#backend-setup-nestjs)
- [User Roles & Test Accounts](#user-roles--test-accounts)
- [How Driver Registration Works](#how-driver-registration-works)
- [Docs](#docs)

---

## Project Overview

NPD Ltd was losing track of monthly fuel usage. This system adds full accountability:

- Drivers submit fuel requests with destination and estimated distance
- Finance/Admin approve or reject requests
- Drivers upload fuel receipts after refueling
- Odometer readings are tracked monthly
- AI detects anomalies (e.g. receipt amount doesn't match allocation)

---

## Tech Stack

| Layer    | Technology                          |
|----------|-------------------------------------|
| Mobile   | Flutter + Riverpod + Go Router      |
| Database | Supabase (PostgreSQL)               |
| Auth     | Supabase Auth                       |
| Backend  | NestJS + Prisma (API layer)         |
| Storage  | Cloudinary (receipt images)         |
| AI       | FastAPI + Tesseract + Scikit-learn  |

> **Note:** The mobile app connects **directly to Supabase** — it does not go through the NestJS backend. The NestJS backend is used for advanced features (AI, reports, etc.).

---

## Project Structure

```
NPD Fuel Tracking/
├── mobile/                  # Flutter mobile app
│   ├── lib/
│   │   ├── core/            # shared models, router, theme, widgets
│   │   └── features/        # auth, dashboard, requests, receipts, etc.
│   └── pubspec.yaml
├── backend/                 # NestJS API
│   ├── src/                 # controllers, services, modules
│   ├── prisma/              # database schema and migrations
│   └── .env.example         # copy this to .env and fill in values
├── docs/                    # requirements, architecture, API spec, DB schema
└── README.md
```

---

## Prerequisites

Install these before doing anything else:

| Tool           | Version      | Download                                      |
|----------------|--------------|-----------------------------------------------|
| Flutter SDK    | 3.x or later | https://docs.flutter.dev/get-started/install  |
| Dart           | Included with Flutter                                       |
| Node.js        | 18.x or later| https://nodejs.org                            |
| Git            | Any          | https://git-scm.com                           |
| Android Studio | Latest       | For Android emulator                          |

---

## Mobile App Setup (Flutter)

The mobile app is the main product. Start here.

### 1. Clone the repo

```bash
git clone https://github.com/ingabire3/NPD-fuel.git
cd "NPD-fuel/mobile"
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Supabase is already configured

The app connects to the shared Supabase project. No `.env` file needed for mobile — the URL and anon key are already in:

```
mobile/lib/core/supabase/supabase_config.dart
```

> Do **not** commit new secrets to this file. Ask the project owner for keys if they change.

### 4. Run the app

**On Android emulator or physical device:**

```bash
flutter run
```

**Check connected devices first:**

```bash
flutter devices
```

**Run on specific device:**

```bash
flutter run -d <device-id>
```

### 5. Build APK (for testing on real device)

```bash
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## Backend Setup (NestJS)

Only needed if you are working on API features, reports, or AI integration.

### 1. Navigate to backend

```bash
cd backend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Set up environment variables

```bash
cp .env.example .env
```

Then open `.env` and fill in real values:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/npd_fuel"
JWT_SECRET="any-long-random-string"
JWT_EXPIRES_IN="15m"
REFRESH_TOKEN_EXPIRES_DAYS=7
CLOUDINARY_CLOUD_NAME=""        # from cloudinary.com dashboard
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""
PORT=3000
NODE_ENV=development
```

> Ask the project owner for real Cloudinary credentials.

### 4. Run database migrations

```bash
npx prisma migrate dev
```

### 5. Seed test data (optional)

```bash
npx prisma db seed
```

### 6. Start the backend

```bash
# Development (auto-reload on file change)
npm run start:dev

# Production
npm run build
npm run start
```

API will be available at: `http://localhost:3000`

---

## User Roles & Test Accounts

| Role    | Email               | Password      | Can Do                                          |
|---------|---------------------|---------------|-------------------------------------------------|
| Admin   | admin@npd.rw        | Admin@1234    | Manage users, vehicles, approve requests        |
| Finance | finance@npd.rw      | Finance@1234  | View all requests, allocations, reports         |
| Driver  | Register via app    | Set on signup | Submit fuel requests, upload receipts           |

> Drivers must **register through the app** and wait for admin approval before they can log in.

---

## How Driver Registration Works

1. Driver opens app → taps "New Driver? Sign Up"
2. Fills in personal info, work location, and vehicle details
3. Account is created with status **PENDING**
4. Admin logs in → goes to Users → approves the driver
5. Driver can now log in

> A driver trying to log in before approval will be silently signed out with no access.

---

## Docs

| File                    | Contents                              |
|-------------------------|---------------------------------------|
| `docs/requirements.md`  | Full requirements and user flows      |
| `docs/db-schema.md`     | All database entities and fields      |
| `docs/api-spec.md`      | All API endpoints with request/response|
| `docs/architecture.md`  | Tech decisions and system design      |

---

## Common Issues

**`flutter pub get` fails**
→ Make sure Flutter SDK is in your PATH: `flutter --version`

**App shows blank screen on launch**
→ Check internet connection — app needs Supabase to load

**"Invalid email or password" on login**
→ Confirm you are using accounts from the table above, or register as a new driver

**Backend: `DATABASE_URL` error**
→ Make sure PostgreSQL is running and `.env` values are correct

**Backend: Prisma migration fails**
→ Run `npx prisma generate` first, then retry `npx prisma migrate dev`

---

## Contact

For access, credentials, or questions — contact the project owner:
**Josiane Ingabire** — ingabirejosiane003@gmail.com

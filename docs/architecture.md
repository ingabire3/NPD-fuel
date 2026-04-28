# System Architecture

## Tech Stack

| Layer       | Technology         | Reason |
|-------------|--------------------|--------|
| Backend     | NestJS (Node.js)   | Modular, TypeScript, production-ready |
| Database    | PostgreSQL         | Relational, reliable, free on Supabase |
| ORM         | Prisma             | Type-safe, migrations, easy schema |
| Mobile      | Flutter            | Single codebase Android + iOS |
| AI Service  | FastAPI (Python)   | Fast, easy ML integration |
| OCR         | Tesseract + OpenCV | Free, runs locally |
| ML          | Scikit-learn       | Lightweight, no GPU needed |
| Images      | Cloudinary         | Free tier, CDN, transformations |
| Hosting     | Render (MVP)       | Free tier, simple deploy |
| DB Hosting  | Supabase (MVP)     | Free managed PostgreSQL |

---

## System Diagram

  Flutter App (Android/iOS)
        |
        | HTTPS/REST
        v
  NestJS API (port 3000)
        |              |
   Prisma ORM     HTTP Client
        |              |
  PostgreSQL    FastAPI AI Service (port 8000)
                       |
                  Cloudinary (images)

---

## Auth Flow

1. POST /auth/login  ->  validate password (bcrypt)
2. Return: accessToken (JWT 15min) + refreshToken (UUID, stored in DB, 7 days)
3. Every request: Authorization: Bearer <accessToken>
4. accessToken expired: POST /auth/refresh -> new accessToken
5. Logout: delete refreshToken from DB

JWT payload: { sub: userId, email, role }

---

## AI Service Communication

- Internal only. NOT exposed to mobile.
- NestJS calls AI service with shared X-Internal-Key header.
- AI failures are non-blocking (request proceeds without OCR data).

Calls:
  After receipt upload:
    POST /ocr/receipt { imageUrl } -> { stationName, liters, amount, date, confidence }

  After request fulfilled:
    POST /anomaly/detect { userId, requestId, odometerBefore, odometerAfter, liters }
    -> { anomalies: [{ type, severity, description }] }

---

## Offline Strategy (Mobile)

- Local SQLite via Drift package stores unsynced operations
- Sync queue: FIFO order, max 3 retries per item, processes on reconnect
- Reads: local first, refresh server data when online
- User sees "Saved offline" indicator when queued

---

## Anomaly Detection Rules (MVP - Rule-Based)

Rule 1: Odometer decreased             -> ODOMETER_MISMATCH   HIGH
Rule 2: Fuel usage >50% above expected -> EXCESS_CONSUMPTION  MEDIUM/HIGH
Rule 3: >3 requests in 7 days          -> FREQUENCY_ABUSE     MEDIUM
Rule 4: Receipt liters differ >20%     -> FAKE_RECEIPT        HIGH
Rule 5: OCR confidence <40%            -> FAKE_RECEIPT        MEDIUM

Post-MVP upgrade: Replace rules with ML model trained on historical data.

---

## Folder Structure

npd-fuel-tracking/
  backend/          NestJS API
    src/
    prisma/
  mobile/           Flutter app
    lib/
  ai-service/       FastAPI
    app/
  docs/             Documentation

---

## MVP Build Order

1. Auth
2. Users + Vehicles
3. Allocations
4. Fuel Requests workflow
5. Receipts upload
6. Anomaly detection
7. Notifications
8. Mobile app
9. AI/OCR (post-MVP upgrade)

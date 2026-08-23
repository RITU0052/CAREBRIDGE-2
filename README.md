# CareBridge AI — MVP

**"Because caring shouldn't depend on distance."**

A working MVP with a real backend (Node.js + Express + PostgreSQL + JWT auth) and a Flutter mobile app covering:
- Registration & login (roles: Child/Caregiver, Parent)
- Child ↔ Parent account linking
- Child dashboard (list of linked parents + medicine status summary)
- Parent dashboard (large-button, elderly-friendly UI)
- Medicine reminders (add by child, mark Taken/Skipped by parent, synced both ways)

This has been tested end-to-end on the backend (registration, login, linking, medicine add/update, and role-based access control all verified working).

---

## 1. Backend Setup

### Requirements
- Node.js 18+
- PostgreSQL 14+

### Steps

```bash
cd backend
npm install
```

Create a database and load the schema:

```bash
createdb carebridge_db
psql -d carebridge_db -f database/schema.sql
```

Copy `.env.example` to `.env` and fill in your own values:

```bash
cp .env.example .env
```

```
PORT=5000
DATABASE_URL=postgresql://username:password@localhost:5432/carebridge_db
JWT_SECRET=replace_with_a_long_random_string
JWT_EXPIRES_IN=7d
```

Start the server:

```bash
npm start
```

You should see:
```
CareBridge backend running on http://localhost:5000
```

Test it's alive:
```bash
curl http://localhost:5000/api/health
```

### API Endpoints (MVP)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | No | Register as `child` or `parent` |
| POST | `/api/auth/login` | No | Login, returns JWT |
| GET | `/api/auth/me` | Yes | Get current user |
| GET | `/api/parent/my-parents` | Yes (child) | List linked parent profiles + today's meds |
| GET | `/api/parent/dashboard` | Yes (parent) | Own profile + today's meds |
| POST | `/api/medicine` | Yes | Add a medicine to a parent profile |
| GET | `/api/medicine/:parent_profile_id` | Yes | Today's medicine list + status |
| PUT | `/api/medicine/status` | Yes | Mark `taken` / `skipped` |

**Registering a parent and linking to a child:** when a `parent` registers, pass `child_email` in the request body with the child's already-registered email — this creates the link automatically.

---

## 2. Mobile App Setup (Flutter)

### Requirements
- Flutter SDK 3.3+ ([install guide](https://docs.flutter.dev/get-started/install))
- Android Studio (for Android emulator) or Xcode (for iOS simulator)

### Steps

```bash
cd mobile
flutter pub get
```

### Point the app at your backend

Edit `lib/services/api_service.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
}
```

- **Android emulator** → keep `10.0.2.2` (this maps to your computer's `localhost`)
- **iOS simulator** → change to `http://127.0.0.1:5000/api` or `http://localhost:5000/api`
- **Real physical device** → change to your computer's LAN IP, e.g. `http://192.168.1.5:5000/api` (device and computer must be on the same Wi-Fi network)

### Run it

```bash
flutter run
```

---

## 3. Project Structure

```
carebridge/
├── backend/
│   ├── config/db.js              # PostgreSQL connection
│   ├── controllers/              # auth, parent, medicine logic
│   ├── middleware/auth.js        # JWT verify + role guard
│   ├── models/                   # DB query layer
│   ├── routes/                   # Express routers
│   ├── database/schema.sql       # table definitions
│   └── server.js                 # entry point
│
└── mobile/
    ├── lib/
    │   ├── main.dart              # app entry, Provider setup
    │   ├── models/                # AppUser, Medicine, ParentProfile
    │   ├── services/
    │   │   ├── api_service.dart   # all backend HTTP calls
    │   │   └── auth_provider.dart # session state (JWT persisted locally)
    │   └── screens/
    │       ├── splash_screen.dart
    │       ├── auth/              # login, register
    │       ├── child/             # child dashboard, parent detail (add meds)
    │       └── parent/            # parent's simple big-button dashboard
    └── pubspec.yaml
```

---

## 4. What's Next (Not Yet Built)

This MVP covers Auth + Dashboards + Medicine Reminders as agreed. Natural next additions, in rough priority order for an investor demo:

1. **Emergency/SOS module** — the SOS button currently shows "coming soon"; wire it to capture GPS location and notify the linked child (push notification via Firebase Cloud Messaging)
2. **Health monitoring** (BP, sugar, etc.) with simple trend charts
3. **Push notifications** for missed medicines (Firebase Cloud Messaging)
4. **Doctor/appointment booking module**
5. **AI report analysis** (OCR + LLM) — needs an OpenAI/Gemini API key and a file upload flow
6. **Production hardening**: input validation (`express-validator` is already installed but not yet wired into routes), rate limiting, HTTPS, refresh tokens, forgot-password flow

## 5. Security Notes Before Going Live

- Change `JWT_SECRET` to a long random value and never commit `.env`
- Add HTTPS (e.g. via a reverse proxy like Nginx + Let's Encrypt) before handling real health data
- Add rate limiting on `/api/auth/login` to prevent brute-force attempts
- Consider AES-256 field-level encryption for `medical_history` given it's sensitive health data (per your original architecture doc)

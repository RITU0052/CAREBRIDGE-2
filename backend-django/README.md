# CareBridge AI — Django Backend

Same functionality as the Node.js version (auth, roles, parent-child linking, medicine reminders), rebuilt in **Python + Django + Django REST Framework**. Verified end-to-end with the same test flow: register child, register linked parent, add medicine, mark taken, confirm sync, confirm access control blocks cross-account access.

## Requirements
- Python 3.10+
- PostgreSQL 14+

## Setup

```bash
cd backend-django
pip install -r requirements.txt
```

Create the database:
```bash
createdb carebridge_django_db
```

Copy `.env.example` to `.env` and fill in your values:
```bash
cp .env.example .env
```
```
DJANGO_SECRET_KEY=replace_with_a_long_random_string
DEBUG=True
DB_NAME=carebridge_django_db
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
```

Run migrations and start the server:
```bash
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Test it:
```bash
curl http://localhost:8000/api/health
```

Optional — create a superuser to browse data in Django Admin (`/admin`):
```bash
python manage.py createsuperuser
```

## API Endpoints (identical shape to the Node version)

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | No | Register as `child` or `parent` |
| POST | `/api/auth/login` | No | Login, returns JWT |
| GET | `/api/auth/me` | Yes | Get current user |
| GET | `/api/parent/my-parents` | Yes (child) | Linked parent profiles + today's meds |
| GET | `/api/parent/dashboard` | Yes (parent) | Own profile + today's meds |
| POST | `/api/medicine` | Yes | Add a medicine to a parent profile |
| GET | `/api/medicine/<parent_profile_id>` | Yes | Today's medicine list + status |
| PUT | `/api/medicine/status` | Yes | Mark `taken` / `skipped` |

## Connecting the Flutter app

In `mobile/lib/services/api_service.dart`, just change the port from `5000` to `8000`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
```

Everything else in the Flutter app works unchanged — the JSON response shapes match exactly.

## Architecture notes

- Custom `User` model (`core/models.py`) extends Django's built-in auth, adding `role` and `phone`, with `email` as the login field instead of `username`.
- Auth uses `djangorestframework-simplejwt` — same Bearer token pattern as the Node version.
- `ParentProfile.child` is the link between a caregiver's account and the parent they monitor, set automatically at registration via `child_email`.
- Access control (`can_access_profile` in `views.py`) mirrors the Node middleware: a `parent` can only touch their own profile, a `child` only profiles they're linked to.

## Why Django here (vs. the Node version)

- One language (Python) across backend **and** the AI/ML pieces from your original architecture doc (OCR, risk prediction, report analysis) — no need for a second service in another language.
- Django Admin gives you a free, working data browser/editor out of the box — useful while demoing to investors.
- Django REST Framework's serializers double as request validation, similar to `express-validator` but built in.

Both backends (`backend/` for Node, `backend-django/` for Django) are functionally identical from the mobile app's point of view — use whichever you prefer, or run both against separate databases while you decide.

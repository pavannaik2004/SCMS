# SCMS — Smart Complaint Management System

A campus complaint-management platform for **RVCE**. Students raise complaints (with geo-tagged, watermarked photo/video evidence), Student Representatives (SRs) review and route them, staff resolve them, and admins monitor everything through analytics — with AI assisting on grammar, categorization, and duplicate detection.

The system is split into three services:

```
┌─────────────────────┐
│   scms_flutter/     │   Flutter mobile app (Android)
│   Student · SR ·    │
│   Staff · Admin     │
└──────────┬──────────┘
           │  HTTPS, JWT Bearer
           ▼
┌─────────────────────┐
│   scms_backend/     │   Node.js / Express REST API  (:3000)
│   Prisma ORM        │────────────┐
└──────────┬──────────┘            │  internal HTTP only
           │                       ▼
           │            ┌─────────────────────┐
           │            │  scms_ai_service/   │  Python / FastAPI  (:8000)
           │            │  grammar · categorize│──────▶  Google Gemini
           │            │  embed · duplicate   │
           │            └──────────┬──────────┘
           ▼                       │
┌───────────────────────────────────────────────┐
│   PostgreSQL 16 + pgvector   (:5432)           │
│   complaints · users · embeddings (768-d)      │
└───────────────────────────────────────────────┘
```

> **The Flutter app never calls the Python AI service directly** — it always goes through the Node.js backend (`routes/ai.js` → `services/aiProxy.js`). The AI service is a best-effort augmentation and fails safe (safe defaults, never a hard 500) so the core flow keeps working if Gemini or the DB are unavailable.

---

## Features

- **Google OAuth sign-in only**, restricted to the `rvce.edu.in` hosted domain — no email/password login.
- **Role-based access** — `ROLE_USER` (student), `ROLE_SR` (student representative), `ROLE_STAFF`, `ROLE_ADMIN` — with per-role dashboards and routing.
- **Rich complaint submission** — geo-tagged photos/videos, GPS + datetime watermarking, offline draft support (Hive), and live AI assistance (grammar check + auto-categorization, debounced while typing).
- **AI augmentation** via Gemini — grammar correction, category suggestion, description embeddings, and **duplicate-complaint detection** using pgvector cosine similarity.
- **SR review → staff resolution → student rating** lifecycle, with a full status-change timeline per complaint.
- **SLA tracking** and **SR auto-approval** background jobs (`node-cron`).
- **Push + in-app notifications** via Firebase Cloud Messaging with deep-link navigation.
- **Analytics dashboards** (fl_chart) and Excel export for admins.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile** | Flutter 3.22+, Dart 3.4+, BLoC/Cubit, go_router, Dio, Hive, Firebase Messaging |
| **Backend** | Node.js, Express, Prisma ORM, JWT, google-auth-library, firebase-admin, Multer, node-cron, Zod |
| **AI service** | Python, FastAPI, google-genai SDK, psycopg2 + pgvector |
| **Database** | PostgreSQL 16 with the `pgvector` extension (`pgvector/pgvector:pg16`) |
| **AI model** | Google Gemini — `gemini-2.0-flash` (text), `models/gemini-embedding-004` (768-d embeddings) |

---

## Repository Layout

```
SCMS/
├── scms_flutter/       Flutter mobile app (clean-architecture-ish: core / data / domain / presentation)
├── scms_backend/       Node.js + Express API, Prisma schema & migrations, cron jobs
├── scms_ai_service/    Python FastAPI microservice (grammar, categorize, embed, duplicate)
├── docker-compose.yml  Postgres (pgvector) + backend + ai_service
├── docs/               Additional documentation
├── scripts/            Helper scripts
├── CLAUDE.md           Guidance for AI coding assistants (architecture deep-dive)
├── CONTEXT.md          Single source of truth for project state / changelog
├── SCMS_PRD.md         Full product requirements (spec of record)
└── TEAM_WORKDIVISION.md  File-ownership boundaries between team members
```

---

## Getting Started

### Prerequisites

- **Flutter** 3.22+ / Dart 3.4+
- **Node.js** 18+
- **Python** 3.10+
- **Docker** (for the pgvector-enabled Postgres)
- A **Google Cloud OAuth client** (for `rvce.edu.in` sign-in) and a **Google Gemini API key**

### 1. Database (from repo root)

```bash
docker-compose up postgres -d
```

Starts PostgreSQL 16 + pgvector on `localhost:5432` (`scms_user` / `scms_pass` / `scms_db`).

### 2. Backend — `scms_backend/`

```bash
cd scms_backend
npm install
cp .env.example .env            # fill GOOGLE_CLIENT_ID, FIREBASE_SERVICE_ACCOUNT_PATH, DATABASE_URL, etc.
npx prisma migrate dev          # apply schema migrations
node prisma/seed.js             # seed departments / categories / zones / tags / allowed domains
node prisma/seed_sample_data.js # (optional) seed demo users + demo complaints
npm run dev                     # nodemon on :3000
```

Useful extras: `npx prisma studio` (DB GUI), `npm start` (production).

### 3. AI service — `scms_ai_service/`

```bash
cd scms_ai_service
python -m venv venv
venv\Scripts\activate            # Windows  (source venv/bin/activate on macOS/Linux)
pip install -r requirements.txt
cp .env.example .env             # set a real GEMINI_API_KEY
uvicorn main:app --reload --port 8000
```

Interactive API docs: `http://localhost:8000/docs`. On startup the service calls `ensure_embedding_column()` to guarantee the pgvector `embedding` column exists.

### 4. Flutter app — `scms_flutter/`

```bash
cd scms_flutter
flutter pub get
flutter run                      # run on a connected device / emulator
```

Point the app's API base URL at your running backend (in-app **Server URL** dialog on the login page, or the `.env` asset).

> **Note on Hive:** `hive_generator` / `build_runner` were deliberately removed (they conflicted with `bloc_test`). The `TypeAdapter`s in `complaint_local_datasource.dart` are **hand-written** and must be kept in sync manually when models change — there is no codegen step.

### Full stack via Docker Compose

```bash
docker-compose up --build        # postgres + backend + ai_service
```

(Requires `.env` files present in `scms_backend/` and `scms_ai_service/`.)

---

## Development Notes

### Response envelope convention
The backend wraps **every** response through `sendSuccess` / `sendError`:

```jsonc
{ "success": true,  "data": { ... } }
{ "success": false, "error": { "message": "...", "code": 500, "details": null } }
```

On the Flutter side, `DioClient`'s `_UnwrapInterceptor` strips the envelope, so data sources receive the raw `data` payload directly. Any new endpoint must go through `sendSuccess` / `sendError`; any new Flutter data source can assume `response.data` is already unwrapped.

### Dev-only mock auth
`authenticate.js` has a **development-only** mock-token path: when `NODE_ENV === 'development'` and the bearer token looks like `mock_..._ROLE_<ROLE>`, it auto-provisions/looks-up a demo user with that role — handy for local testing without Google OAuth. This must never be reachable outside development.

### Verification
- **Flutter:** `flutter analyze` must show *No issues found*; run `flutter test` for the suite.
- **Backend / AI service:** no automated test suite yet — verify by hitting endpoints directly (Flutter app, curl, or Postman) against a running dev server.

---

## Project Docs

- **`CONTEXT.md`** — mandatory reading before writing code; tracks project state, known issues/decisions, and a running changelog.
- **`SCMS_PRD.md`** — full product requirements and the spec of record for behavior, fields, and endpoints.
- **`TEAM_WORKDIVISION.md`** — file-ownership boundaries between the four team members (Pavan, Prabhava, Prem, Pramath).
- **`CLAUDE.md`** — architecture deep-dive and conventions for AI coding assistants.

---

## Team

Built as an MCA project at **RVCE** by a four-member team: **Pavan · Prabhava · Prem · Pramath**.

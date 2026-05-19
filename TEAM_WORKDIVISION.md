# SCMS — Team Work Division Guide
## 4-Member Collaborative Development Protocol

**Project:** Smart Complaint Management System (SCMS)
**Team:** Pavan · Prabhava · Prem · Pramath
**Maintained by:** Pavan (Project Lead)
**Read this before writing a single line of code.**

---

## The Golden Rules

1. **You own your files. You do not touch anyone else's files.** If you need something from another person's file, raise it in the team chat — they make the change.
2. **The AI agent working for you reads only your section of this document** + the PRD + `TEAM_LOG.md`. It should not attempt work outside your ownership list.
3. **Pavan completes Day 0 (folder scaffold) before anyone else starts.** Everyone else waits until Day 0 is merged into `main`.
4. **TEAM_LOG.md is the source of truth** for what is done, in progress, or blocked. Update it every session.
5. **Never commit to `main` directly.** Always use your personal branch and open a PR.

---

## Team Structure Overview

```
SCMS Project
│
├── Pavan       →  Flutter: Foundation + Core + Student Flow + AI Widgets
├── Prabhava    →  Flutter: Staff + SR + Admin + Settings + Notifications
├── Prem        →  Node.js Backend (all routes, auth, SLA, FCM)
└── Pramath     →  Python AI Service (all Gemini + embeddings + duplicate)
```

Two people (Pavan + Prabhava) work on Flutter but in **completely separate folders**. Prem owns the entire Node.js backend. Pramath owns the entire Python AI service. The boundaries are strict.

---

## Day 0 — Pavan's Responsibility (Do This First, Before Anyone Else Starts)

Pavan creates the **complete folder structure** with **empty placeholder files** for all three services. This gives everyone a clean base to branch from.

### Step D0.1 — Initialize the monorepo

```bash
mkdir scms_project && cd scms_project
git init
echo "# SCMS Project" > README.md
git add . && git commit -m "chore: init monorepo"
```

### Step D0.2 — Scaffold Flutter project

```bash
flutter create scms_flutter --org com.scms --platforms android
cd scms_flutter
```

Create every folder and empty `.dart` placeholder file listed in PRD Section 8. For each file, the content is just:
```dart
// TODO: [OwnerName] — implement
```

The owner name written in the TODO must match this table exactly so the AI agent knows who owns it.

### Step D0.3 — Scaffold Node.js backend

```bash
mkdir scms_backend && cd scms_backend
npm init -y
# Install all dependencies from PRD Section 7.2
npx prisma init
```

Create folder structure:
```
scms_backend/
├── src/
│   ├── routes/
│   │   ├── auth.js          // TODO: Prem
│   │   ├── complaints.js    // TODO: Prem
│   │   ├── sr.js            // TODO: Prem
│   │   ├── analytics.js     // TODO: Prem
│   │   ├── ai.js            // TODO: Prem (proxy to Python)
│   │   ├── departments.js   // TODO: Prem
│   │   └── tags.js          // TODO: Prem
│   ├── middleware/
│   │   ├── authenticate.js  // TODO: Prem
│   │   ├── requireRole.js   // TODO: Prem
│   │   └── upload.js        // TODO: Prem
│   ├── services/
│   │   ├── fcm.js           // TODO: Prem
│   │   ├── storage.js       // TODO: Prem
│   │   └── aiProxy.js       // TODO: Prem
│   ├── jobs/
│   │   └── slaScheduler.js  // TODO: Prem
│   ├── utils/
│   │   ├── logger.js        // TODO: Prem
│   │   └── complaintNumber.js // TODO: Prem
│   └── app.js               // TODO: Prem
├── prisma/
│   └── schema.prisma        // TODO: Prem (base schema from PRD)
├── .env.example
├── .gitignore
└── server.js                // TODO: Prem
```

### Step D0.4 — Scaffold Python AI service

```bash
mkdir scms_ai_service && cd scms_ai_service
python3 -m venv venv
```

Create folder structure:
```
scms_ai_service/
├── routers/
│   ├── grammar.py       // TODO: Pramath
│   ├── categorize.py    // TODO: Pramath
│   ├── embed.py         // TODO: Pramath
│   └── duplicate.py     // TODO: Pramath
├── services/
│   ├── gemini_client.py // TODO: Pramath
│   └── db_client.py     // TODO: Pramath
├── models/
│   └── schemas.py       // TODO: Pramath
├── main.py              // TODO: Pramath
├── requirements.txt     // TODO: Pramath
├── .env.example
└── .gitignore
```

### Step D0.5 — Create shared config files

Create all `.env.example` files (from PRD Section 21.1) — never the real `.env` files.

Add to `.gitignore` at project root:
```
**/.env
**/node_modules/
**/__pycache__/
**/venv/
**/build/
**/.dart_tool/
scms_backend/firebase-service-account.json
```

### Step D0.6 — Create Docker Compose

Write `docker-compose.yml` at project root (from PRD Section 22 Phase 0, Step 0.6).

### Step D0.7 — Commit scaffold and notify team

```bash
git add .
git commit -m "chore(scaffold): complete folder structure — Day 0 done"
git push origin main
```

**Send message to team:** "Day 0 complete. Pull `main` and create your branch. Start work."

---

## Member Work Assignments

---

## 🧑‍💻 PAVAN — Flutter: Foundation + Core + Student Flow

**Branch name:** `pavan/core-and-student-flow`

### What You Own

#### Phase 1 — Foundation (Do first, others depend on this)

| File | Status |
|---|---|
| `pubspec.yaml` | — |
| `lib/main.dart` | — |
| `lib/app.dart` | — |
| `lib/core/constants/api_constants.dart` | — |
| `lib/core/constants/app_constants.dart` | — |
| `lib/core/constants/route_constants.dart` | — |
| `lib/core/constants/tag_constants.dart` | — |
| `lib/core/theme/app_colors.dart` | — |
| `lib/core/theme/app_text_styles.dart` | — |
| `lib/core/theme/app_theme.dart` | — |
| `lib/core/utils/date_formatter.dart` | — |
| `lib/core/utils/validators.dart` | — |
| `lib/core/utils/extensions.dart` | — |
| `lib/core/utils/logger.dart` | — |
| `lib/core/utils/watermark_painter.dart` | — |
| `lib/core/errors/exceptions.dart` | — |
| `lib/core/errors/failures.dart` | — |
| `lib/core/network/dio_client.dart` | — |
| `lib/core/network/network_info.dart` | — |

#### Phase 2 — Data Layer

| File | Status |
|---|---|
| `lib/data/models/user_model.dart` | — |
| `lib/data/models/complaint_model.dart` | — |
| `lib/data/models/complaint_update_model.dart` | — |
| `lib/data/models/department_model.dart` | — |
| `lib/data/models/category_model.dart` | — |
| `lib/data/models/rating_model.dart` | — |
| `lib/data/models/analytics_model.dart` | — |
| `lib/data/models/grammar_correction_model.dart` | — |
| `lib/data/models/duplicate_check_model.dart` | — |
| `lib/data/models/sr_review_model.dart` | — |
| `lib/data/datasources/remote/auth_remote_datasource.dart` | — |
| `lib/data/datasources/remote/complaint_remote_datasource.dart` | — |
| `lib/data/datasources/local/auth_local_datasource.dart` | — |
| `lib/data/datasources/local/complaint_local_datasource.dart` | — |
| `lib/data/repositories/auth_repository.dart` | — |
| `lib/data/repositories/complaint_repository.dart` | — |
| `lib/domain/entities/user_entity.dart` | — |
| `lib/domain/entities/complaint_entity.dart` | — |
| `lib/domain/usecases/login_usecase.dart` | — |
| `lib/domain/usecases/submit_complaint_usecase.dart` | — |
| `lib/domain/usecases/get_my_complaints_usecase.dart` | — |
| `lib/domain/usecases/get_analytics_usecase.dart` | — |

#### Phase 3 — BLoC / State (Auth + Complaint + Submit)

| File | Status |
|---|---|
| `lib/presentation/bloc/auth/auth_bloc.dart` | — |
| `lib/presentation/bloc/auth/auth_event.dart` | — |
| `lib/presentation/bloc/auth/auth_state.dart` | — |
| `lib/presentation/bloc/complaint/complaint_bloc.dart` | — |
| `lib/presentation/bloc/complaint/complaint_event.dart` | — |
| `lib/presentation/bloc/complaint/complaint_state.dart` | — |
| `lib/presentation/bloc/submit_complaint/submit_complaint_cubit.dart` | — |
| `lib/presentation/bloc/submit_complaint/submit_complaint_state.dart` | — |

#### Phase 4 — Common Widgets (Prabhava depends on all of these)

| File | Status |
|---|---|
| `lib/presentation/widgets/common/scms_button.dart` | — |
| `lib/presentation/widgets/common/scms_text_field.dart` | — |
| `lib/presentation/widgets/common/scms_chip.dart` | — |
| `lib/presentation/widgets/common/loading_overlay.dart` | — |
| `lib/presentation/widgets/common/error_widget.dart` | — |
| `lib/presentation/widgets/common/empty_state_widget.dart` | — |
| `lib/presentation/widgets/complaint/complaint_card.dart` | — |
| `lib/presentation/widgets/complaint/status_badge.dart` | — |
| `lib/presentation/widgets/complaint/sla_timer_widget.dart` | — |
| `lib/presentation/widgets/complaint/media_capture_widget.dart` | — |
| `lib/presentation/widgets/complaint/category_selector_widget.dart` | — |
| `lib/presentation/widgets/complaint/tag_selector_widget.dart` | — |
| `lib/presentation/widgets/complaint/grammar_correction_banner.dart` | — |
| `lib/presentation/widgets/complaint/duplicate_warning_banner.dart` | — |
| `lib/presentation/widgets/complaint/grouped_complaint_card.dart` | — |
| `lib/presentation/widgets/notification/notification_badge.dart` | — |

#### Phase 5 — Services (Camera, GPS, Watermark, Grammar)

| File | Status |
|---|---|
| `lib/services/camera_service.dart` | — |
| `lib/services/watermark_service.dart` | — |
| `lib/services/location_service.dart` | — |
| `lib/services/grammar_service.dart` | — |
| `lib/services/storage_service.dart` | — |

#### Phase 6 — Student-Facing Screens

| File | Status |
|---|---|
| `lib/presentation/pages/splash/splash_page.dart` | — |
| `lib/presentation/pages/onboarding/onboarding_page.dart` | — |
| `lib/presentation/pages/auth/login_page.dart` | — |
| `lib/presentation/pages/home/home_page.dart` | — |
| `lib/presentation/pages/complaint/my_complaints_page.dart` | — |
| `lib/presentation/pages/complaint/submit_complaint_page.dart` | — |
| `lib/presentation/pages/complaint/complaint_detail_page.dart` | — |
| `lib/presentation/pages/complaint/duplicate_complaints_page.dart` | — |
| `lib/presentation/pages/complaint/rating_page.dart` | — |

### What You Must NOT Touch

```
lib/presentation/pages/staff/      → Prabhava
lib/presentation/pages/admin/      → Prabhava
lib/presentation/pages/sr/         → Prabhava
lib/presentation/pages/settings/   → Prabhava
lib/presentation/widgets/analytics/ → Prabhava
lib/services/notification_service.dart → Prabhava
lib/presentation/bloc/sr_review/   → Prabhava
lib/presentation/bloc/analytics/   → Prabhava
scms_backend/                       → Prem
scms_ai_service/                    → Pramath
```

### Your AI Agent Instructions

When you open a new Claude/Cursor session, paste this prompt:

```
You are helping Pavan build the Flutter mobile app for the SCMS project.

READ FIRST:
1. SCMS_PRD.md — Sections 7, 8, 10 (screens 10.1-10.9), 11, 13, 14, 15, 16, 18
2. TEAM_LOG.md — Check what Pavan has marked as DONE and what is IN PROGRESS

YOUR SCOPE — only work on files listed under "PAVAN" in TEAM_WORKDIVISION.md.
Do NOT create or modify any file outside Pavan's ownership list.

After completing each file, remind Pavan to update TEAM_LOG.md.
```

### Dependency Outputs (What Prabhava needs from you before she can start)

Prabhava cannot start until these are DONE and merged:
1. All files in `lib/core/` (theme, constants, errors, network).
2. All files in `lib/presentation/widgets/common/` (shared components).
3. All complaint widget files (complaint_card, status_badge, etc.).
4. `lib/app.dart` (GoRouter setup — she needs routes to exist).
5. `lib/data/models/` (she needs model classes to build screens).

Notify Prabhava in team chat when Phase 1–4 above are merged into `main`.

---

## 🧑‍💻 PRABHAVA — Flutter: Staff + SR + Admin + Settings + Notifications

**Branch name:** `prabhava/staff-sr-admin`

**START ONLY AFTER Pavan notifies that Phases 1–4 are merged.**

### What You Own

#### BLoC / State

| File | Status |
|---|---|
| `lib/presentation/bloc/sr_review/sr_review_bloc.dart` | — |
| `lib/presentation/bloc/sr_review/sr_review_event.dart` | — |
| `lib/presentation/bloc/sr_review/sr_review_state.dart` | — |
| `lib/presentation/bloc/analytics/analytics_cubit.dart` | — |
| `lib/presentation/bloc/analytics/analytics_state.dart` | — |

#### Data Sources & Repositories

| File | Status |
|---|---|
| `lib/data/datasources/remote/sr_review_remote_datasource.dart` | — |
| `lib/data/repositories/sr_review_repository.dart` | — |
| `lib/domain/usecases/sr_approve_complaint_usecase.dart` | — |
| `lib/domain/usecases/sr_reject_complaint_usecase.dart` | — |
| `lib/domain/usecases/update_complaint_status_usecase.dart` | — |

#### Screens

| File | Status |
|---|---|
| `lib/presentation/pages/sr/sr_dashboard_page.dart` | — |
| `lib/presentation/pages/sr/sr_review_detail_page.dart` | — |
| `lib/presentation/pages/staff/staff_dashboard_page.dart` | — |
| `lib/presentation/pages/staff/staff_complaint_detail_page.dart` | — |
| `lib/presentation/pages/admin/admin_dashboard_page.dart` | — |
| `lib/presentation/pages/admin/admin_complaints_list_page.dart` | — |
| `lib/presentation/pages/settings/settings_page.dart` | — |

#### Widgets (Analytics)

| File | Status |
|---|---|
| `lib/presentation/widgets/analytics/stats_card.dart` | — |
| `lib/presentation/widgets/analytics/complaints_chart.dart` | — |

#### Services

| File | Status |
|---|---|
| `lib/services/notification_service.dart` | — |
| `lib/services/analytics_service.dart` | — |

#### Tests (your screens)

| File | Status |
|---|---|
| `test/widget/sr_dashboard_test.dart` | — |
| `test/widget/staff_dashboard_test.dart` | — |

### What You Must NOT Touch

```
lib/core/                              → Pavan
lib/data/models/                       → Pavan (read only)
lib/presentation/bloc/auth/            → Pavan
lib/presentation/bloc/complaint/       → Pavan
lib/presentation/bloc/submit_complaint/ → Pavan
lib/presentation/widgets/common/       → Pavan (read only, use but don't edit)
lib/presentation/widgets/complaint/    → Pavan (read only, use but don't edit)
lib/presentation/pages/auth/          → Pavan
lib/presentation/pages/complaint/     → Pavan
lib/presentation/pages/home/          → Pavan
scms_backend/                          → Prem
scms_ai_service/                       → Pramath
```

**If you need a change to a shared widget** (e.g., `ComplaintCard` needs a new parameter for the staff view) — message Pavan, describe the change, he makes it and commits.

### Your AI Agent Instructions

```
You are helping Prabhava build the Staff, SR, and Admin screens for the SCMS Flutter app.

READ FIRST:
1. SCMS_PRD.md — Sections 10 (screens 10.7-10.15), 13 (SrReviewBloc, AnalyticsCubit)
2. TEAM_LOG.md — Confirm Pavan's Phase 1-4 are marked DONE before proceeding

YOUR SCOPE — only work on files listed under "PRABHAVA" in TEAM_WORKDIVISION.md.
Import and USE widgets from Pavan's files freely, but never edit them.
If you need a change to a shared widget, output a comment: "// REQUEST TO PAVAN: need X change in Y widget"

After completing each file, remind Prabhava to update TEAM_LOG.md.
```

### Dependency on Pavan

Before you can build any screen, you need these from Pavan (check TEAM_LOG.md):
- `lib/presentation/widgets/common/` — all common widgets.
- `lib/presentation/widgets/complaint/complaint_card.dart` — used in all your dashboards.
- `lib/data/models/` — all model classes.
- `lib/core/theme/` — colors and text styles.

Before you can build `admin_dashboard_page.dart`:
- Pavan's `complaint_detail_page.dart` must be DONE (shared navigation target).

---

## 🧑‍💻 PREM — Node.js Backend (All Routes + Auth + SLA + FCM)

**Branch name:** `prem/nodejs-backend`

**Can start in parallel with Pavan — no Flutter dependency.**

### What You Own — Every file inside `scms_backend/`

#### Core Setup

| File | Status |
|---|---|
| `scms_backend/server.js` | — |
| `scms_backend/src/app.js` | — |
| `scms_backend/prisma/schema.prisma` | — |
| `scms_backend/.env.example` | — |
| `scms_backend/package.json` | — |

#### Routes

| File | Status |
|---|---|
| `src/routes/auth.js` | — |
| `src/routes/complaints.js` | — |
| `src/routes/sr.js` | — |
| `src/routes/analytics.js` | — |
| `src/routes/ai.js` | — |
| `src/routes/departments.js` | — |
| `src/routes/tags.js` | — |
| `src/routes/zones.js` | — |
| `src/routes/users.js` | — |

#### Middleware

| File | Status |
|---|---|
| `src/middleware/authenticate.js` | — |
| `src/middleware/requireRole.js` | — |
| `src/middleware/upload.js` | — |
| `src/middleware/validateBody.js` | — |
| `src/middleware/errorHandler.js` | — |

#### Services

| File | Status |
|---|---|
| `src/services/fcm.js` | — |
| `src/services/storage.js` | — |
| `src/services/aiProxy.js` | — |
| `src/services/googleAuth.js` | — |
| `src/services/complaintNumber.js` | — |

#### Jobs

| File | Status |
|---|---|
| `src/jobs/slaScheduler.js` | — |
| `src/jobs/srAutoApprove.js` | — |

#### Utilities

| File | Status |
|---|---|
| `src/utils/logger.js` | — |
| `src/utils/jwtHelper.js` | — |
| `src/utils/responseHelper.js` | — |

### Your Build Order (follow this sequence)

```
1. prisma/schema.prisma       (copy from PRD Section 22 Step D0.4 — full schema)
2. npx prisma migrate dev
3. src/app.js                 (Express app setup, middleware registration)
4. src/utils/                 (logger, jwt, response helpers)
5. src/middleware/authenticate.js + requireRole.js
6. src/routes/auth.js         (Google OAuth — most critical, Flutter unblocked)
7. src/routes/departments.js + tags.js + zones.js  (seed data endpoints)
8. src/routes/complaints.js   (CRUD)
9. src/routes/sr.js
10. src/routes/analytics.js
11. src/routes/ai.js          (proxy to Pramath's Python service)
12. src/jobs/slaScheduler.js
13. src/jobs/srAutoApprove.js
14. src/services/fcm.js
```

### API Contract Reference

Every endpoint you build must exactly match PRD Section 12. Request/response JSON schemas are specified there. Do not invent new schemas.

### Integration Point with Pramath

Route `POST /api/ai/*` must proxy to `http://localhost:8000/*` (Python AI service). This is your only external dependency. Build the proxy route with a try-catch that returns safe defaults if Pramath's service is down. Do not let AI service failures break your API.

```javascript
// src/routes/ai.js
router.post('/grammar-check', authenticate, async (req, res) => {
  try {
    const { data } = await aiProxy.post('/grammar-check', req.body);
    res.json(data);
  } catch {
    // Safe default — AI down, form still works
    res.json({ hasCorrections: false, correctedText: req.body.text, diffs: [] });
  }
});
```

### Your AI Agent Instructions

```
You are helping Prem build the Node.js + Express backend for the SCMS project.

READ FIRST:
1. SCMS_PRD.md — Sections 6 (6.2-6.4), 7.2 (Node.js stack), 12 (API Contract), 19 (Security)
2. TEAM_LOG.md — Check current status

YOUR SCOPE — only work on files inside scms_backend/.
Do NOT touch scms_flutter/ or scms_ai_service/.

Key constraint: POST /api/auth/google is the most critical endpoint.
Build it first. Flutter is blocked until auth works.

After completing each file, remind Prem to update TEAM_LOG.md.
```

### What Prem Needs to Notify the Team About

When these are ready and tested with Postman, notify the team by updating TEAM_LOG.md:

| Milestone | Notifies |
|---|---|
| `POST /api/auth/google` working | Pavan (Flutter auth can be tested) |
| All complaint CRUD endpoints working | Pavan + Prabhava |
| `POST /api/ai/*` proxy working | Pavan (AI banner features can be tested) |
| All SR endpoints working | Prabhava |
| Analytics endpoints working | Prabhava |

---

## 🧑‍💻 PRAMATH — Python AI Microservice

**Branch name:** `pramath/ai-service`

**Can start in parallel with everyone — no dependency on Flutter or Node.js.**

### What You Own — Every file inside `scms_ai_service/`

| File | Status |
|---|---|
| `scms_ai_service/main.py` | — |
| `scms_ai_service/requirements.txt` | — |
| `scms_ai_service/.env.example` | — |
| `routers/grammar.py` | — |
| `routers/categorize.py` | — |
| `routers/embed.py` | — |
| `routers/duplicate.py` | — |
| `services/gemini_client.py` | — |
| `services/db_client.py` | — |
| `models/schemas.py` | — |

### Your Build Order

```
1. requirements.txt           (install dependencies)
2. .env + .env.example        (Gemini API key, DB URL)
3. models/schemas.py          (Pydantic models for all request/response shapes)
4. services/gemini_client.py  (Gemini SDK singleton — used by all routers)
5. routers/grammar.py         (simplest — test this first with Postman)
6. routers/categorize.py      (JSON mode structured output)
7. services/db_client.py      (PostgreSQL connection for embeddings)
8. routers/embed.py           (gemini-embedding-001)
9. routers/duplicate.py       (cosine similarity — most complex, do last)
10. main.py                   (wire all routers, startup)
```

### Full Specification Reference

Every endpoint is fully specified in PRD Section 16:
- Grammar check: Section 16.3 — exact system prompt + Gemini call code given.
- Categorization: Section 16.4 — exact prompt + JSON mode config given.
- Embedding: Section 16.5 — exact API call given.
- Duplicate detection: Section 16.6 — full algorithm with numpy code given.

**Copy the code from the PRD as your starting point.** It is complete and tested logic.

### How to Test Each Endpoint Independently

```bash
# Start the service
uvicorn main:app --reload --port 8000

# Test grammar-check
curl -X POST http://localhost:8000/grammar-check \
  -H "Content-Type: application/json" \
  -d '{"text": "the light is not wurking form 2 days"}'

# Expected: { hasCorrections: true, correctedText: "...", diffs: [...] }

# Test categorize
curl -X POST http://localhost:8000/categorize \
  -d '{"text": "The tube light has been flickering for 3 days"}'

# Expected: { categoryName: "Electrical", severity: "MEDIUM", ... }
```

Test each endpoint independently with curl or Postman. Do not wait for Prem's backend to be ready.

### Database Dependency (pgvector)

`routers/duplicate.py` and `routers/embed.py` need PostgreSQL with pgvector running. Use Docker for local dev:

```bash
docker run -d \
  -e POSTGRES_USER=scms_user \
  -e POSTGRES_PASSWORD=scms_pass \
  -e POSTGRES_DB=scms_db \
  -p 5432:5432 \
  pgvector/pgvector:pg16
```

This is your own local PostgreSQL — you don't need Prem's backend running.

### Your AI Agent Instructions

```
You are helping Pramath build the Python FastAPI AI microservice for SCMS.

READ FIRST:
1. SCMS_PRD.md — Section 7.3 (Python stack), Section 16 (complete AI spec with code)
2. TEAM_LOG.md — Check current status

YOUR SCOPE — only work on files inside scms_ai_service/.
Do NOT touch scms_flutter/ or scms_backend/.

Build order: grammar → categorize → embed → duplicate (simplest to hardest).
Test each with curl before moving to the next.

The complete code for each endpoint is in PRD Section 16. Use it.

After completing each file, remind Pramath to update TEAM_LOG.md.
```

### What Pramath Needs to Notify the Team About

| Milestone | Notifies |
|---|---|
| `POST /grammar-check` working | Prem (can wire proxy route) |
| `POST /categorize` working | Prem |
| `POST /embed` working | Prem |
| `POST /check-duplicate` working | Prem |
| All 4 endpoints running together | Prem + Pavan |

---

## Conflict Zones — Shared Files (Read Carefully)

These files are **shared** and need special care:

| File | Owner | Others |
|---|---|---|
| `lib/app.dart` (GoRouter) | Pavan | Prabhava adds her routes here — she submits a PR, Pavan reviews and merges |
| `lib/main.dart` (MultiBlocProvider) | Pavan | Prabhava's BLoCs added here — same process |
| `pubspec.yaml` | Pavan | Anyone who needs a new package messages Pavan, he adds it |
| `TEAM_LOG.md` | Everyone updates | Use GitHub's edit on web to avoid conflicts — each person edits their own section |
| `docker-compose.yml` | Pavan (scaffold) | Prem can update backend service config |

**Rule for `lib/app.dart`:** Prabhava creates her routes in a separate file `route_helpers.dart` inside her branch and Pavan integrates them during a merge session. This avoids both editing `app.dart` simultaneously.

---

## Git Workflow

### Branch setup (each person does this after Day 0)

```bash
git pull origin main
git checkout -b pavan/core-and-student-flow    # Pavan
git checkout -b prabhava/staff-sr-admin        # Prabhava
git checkout -b prem/nodejs-backend            # Prem
git checkout -b pramath/ai-service             # Pramath
```

### Daily workflow

```bash
# Start of day — sync with main
git fetch origin
git rebase origin/main   # or git merge origin/main

# Work on your files
# ...

# End of day — push your branch
git add .
git commit -m "feat(pavan): implement submit complaint BLoC"
git push origin pavan/core-and-student-flow
```

### Commit message format

```
feat(name): short description          ← new feature
fix(name): short description           ← bug fix
chore(name): short description         ← setup/config
docs(name): short description          ← docs/comments
```

### When to open a PR into `main`

Open a PR when a **milestone** is complete (not every commit). Milestones:
- Pavan: after Phase 1-4 (foundation + widgets) — critical PR.
- Pavan: after Phase 5-6 (student screens) — second PR.
- Prabhava: after all staff/SR/admin screens.
- Prem: after all routes + auth working.
- Pramath: after all 4 AI endpoints working.

### PR Review rule

- Pavan reviews Prabhava's PRs (Flutter shared knowledge).
- Pramath reviews Prem's AI proxy routes (knows what the Python service returns).
- Everyone reviews their own PR for self-check first.

---

## Integration Testing Week (Final Week)

Once all four branches are merged into `main`, this is the integration test plan:

| Test | Who leads | What to verify |
|---|---|---|
| Google Sign-In end-to-end | Pavan | Flutter → Node.js → Google API → SCMS JWT → navigate to home |
| Submit complaint with GPS photo | Pavan | Flutter → Node.js → Python AI → PostgreSQL → FCM |
| SR review flow | Prabhava | SR approves → complaint moves to OPEN → staff FCM |
| Staff resolves complaint | Prabhava | Status update → resolved → student FCM |
| Duplicate detection | Pavan | Submit similar complaint → duplicate banner shown |
| Grammar correction | Pavan | Type bad grammar → correction banner appears |
| Admin analytics | Prabhava | Charts load with real data |
| SLA breach | Prem | Manually expire SLA → FCM sent to admin |

---

## Communication Protocol

- **Daily standup message** in group chat (5 lines max):
  ```
  ✅ Done today: [what you completed]
  🔄 In progress: [what you're working on]
  ❌ Blocked by: [if anything]
  📤 Ready for: [what you're handing off]
  📥 Waiting for: [what you need from someone]
  ```

- **Never silently edit someone else's file.** Always ask first.
- **Update TEAM_LOG.md after every session.** This is how AI agents know what's done.
- **If you're stuck for > 30 minutes**, post in group chat. Don't lose hours alone.

---

*This document is maintained by Pavan. Last updated: v3.0.0*

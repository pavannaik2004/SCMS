# SCMS Project — Context & Progress Log
## Single Source of Truth for All AI Agents & Team Members

> **⚠️ EVERY AI AGENT SESSION MUST READ THIS FILE FIRST before writing any code.**
> After completing work, UPDATE this file with what was done.

---

## 📋 Project Summary

**Project:** Smart Complaint Management System (SCMS)
**Type:** Cross-platform mobile app (Flutter) + Node.js backend + Python AI microservice
**Team:** 4 members — Pavan, Prabhava, Prem, Pramath
**Academic:** MCA II Semester project at RVCE

**Key Documents:**
- `SCMS_PRD.md` — Full product requirements (3378 lines, the single source of truth)
- `TEAM_WORKDIVISION.md` — Who owns what files, build order, dependencies
- `PROMPT_PAVAN.md` — AI agent prompt for Pavan's scope
- `PROMPT_PRABHAVA.md` — AI agent prompt for Prabhava's scope

---

## 🏗️ Architecture at a Glance

```
Flutter App (scms_flutter/)    →  Node.js API (scms_backend/:3000)  →  Python AI (scms_ai_service/:8000)
                                         ↓                                    ↓
                                   PostgreSQL + pgvector              Google AI Studio (Gemini)
```

- **Auth:** Google OAuth 2.0 only — `hostedDomain: "rvce.edu.in"` in GoogleSignIn. NO email/password.
- **State:** flutter_bloc (BLoC + Cubit pattern)
- **Routing:** go_router with role-based redirects in `app.dart`
- **Storage:** FlutterSecureStorage (JWT tokens), Hive (offline drafts — manual TypeAdapters, NO code-gen)
- **AI flow:** Flutter → Node.js → Python AI service (Flutter NEVER calls Python directly)
- **Notifications:** Firebase Cloud Messaging (FCM) — `NotificationService` singleton with in-app banner overlay

---

## 👥 Team Ownership & Status

| Member | Scope | Branch | Status |
|---|---|---|---|
| **Pavan** | Flutter: Foundation + Core + Data + Widgets + Student Screens + Integration | `main` | ✅ All Flutter integration DONE |
| **Prabhava** | Flutter: Staff + SR + Admin + Settings + Notifications | `prabhava/staff-sr-admin` | ✅ **MERGED to main** |
| **Prem** | Node.js backend: All routes, auth, SLA, FCM | `prem/nodejs-backend` | ✅ **COMPLETE** |
| **Pramath** | Python AI: FastAPI, Gemini, embeddings, duplicate detection | `pramath/ai-service` | ✅ All 4 endpoints DONE |

---

## 📊 Progress Tracker

### Day 0 — Monorepo Scaffold
**Status: ✅ COMPLETE** | Date: 2026-05-19

| Task | Status |
|---|---|
| `flutter create scms_flutter` | ✅ |
| Full dir structure (98 placeholder .dart files) | ✅ |
| `scms_backend/` scaffold (26 placeholder files) | ✅ |
| `scms_ai_service/` scaffold (9 placeholder files) | ✅ |
| `pubspec.yaml` (all PRD §21.4 deps) | ✅ |
| `scms_backend/package.json` | ✅ |
| `scms_backend/prisma/schema.prisma` (full schema) | ✅ |
| All `.env.example` files (Flutter, Node, Python) | ✅ |
| `docker-compose.yml` | ✅ |
| Root `.gitignore` | ✅ |

### Phase 1 — Foundation (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/main.dart` | ✅ Entry point + DI + Firebase init + NotificationService |
| `lib/app.dart` | ✅ GoRouter + role-based redirect + navigatorKey for FCM |
| `lib/core/constants/api_constants.dart` | ✅ All PRD §12 endpoints |
| `lib/core/constants/app_constants.dart` | ✅ SLA, form limits, timeouts |
| `lib/core/constants/route_constants.dart` | ✅ All named routes |
| `lib/core/constants/tag_constants.dart` | ✅ 14 predefined tags |
| `lib/core/theme/app_colors.dart` | ✅ Full palette + helpers |
| `lib/core/theme/app_text_styles.dart` | ✅ Typography + AppSpacing |
| `lib/core/theme/app_theme.dart` | ✅ Light + Dark ThemeData |
| `lib/core/utils/date_formatter.dart` | ✅ |
| `lib/core/utils/validators.dart` | ✅ |
| `lib/core/utils/extensions.dart` | ✅ |
| `lib/core/utils/logger.dart` | ✅ |
| `lib/core/utils/watermark_painter.dart` | ✅ |
| `lib/core/errors/exceptions.dart` | ✅ |
| `lib/core/errors/failures.dart` | ✅ |
| `lib/core/network/dio_client.dart` | ✅ Auth interceptor + 401 refresh |
| `lib/core/network/network_info.dart` | ✅ |
| `analysis_options.yaml` | ✅ |

### Phase 2 — Data Layer (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/data/models/user_model.dart` | ✅ fromJson/toJson/copyWith/role helpers |
| `lib/data/models/complaint_model.dart` | ✅ Full model with canRate/isSlaActive |
| `lib/data/models/complaint_update_model.dart` | ✅ |
| `lib/data/models/department_model.dart` | ✅ |
| `lib/data/models/category_model.dart` | ✅ |
| `lib/data/models/rating_model.dart` | ✅ |
| `lib/data/models/analytics_model.dart` | ✅ With DepartmentStat + CategoryStat |
| `lib/data/models/grammar_correction_model.dart` | ✅ With diff types |
| `lib/data/models/duplicate_check_model.dart` | ✅ With DuplicateMatch |
| `lib/data/models/sr_review_model.dart` | ✅ |
| `lib/data/datasources/remote/auth_remote_datasource.dart` | ✅ Full Google OAuth flow |
| `lib/data/datasources/remote/complaint_remote_datasource.dart` | ✅ CRUD + AI + Analytics |
| `lib/data/datasources/remote/sr_review_remote_datasource.dart` | ✅ getPendingReviews + approve + reject |
| `lib/data/datasources/local/auth_local_datasource.dart` | ✅ FlutterSecureStorage |
| `lib/data/datasources/local/complaint_local_datasource.dart` | ✅ Hive + manual TypeAdapter |
| `lib/data/repositories/auth_repository.dart` | ✅ |
| `lib/data/repositories/complaint_repository.dart` | ✅ With offline draft fallback |
| `lib/data/repositories/sr_review_repository.dart` | ✅ |
| `lib/domain/entities/user_entity.dart` | ✅ |
| `lib/domain/entities/complaint_entity.dart` | ✅ |
| `lib/domain/usecases/login_usecase.dart` | ✅ |
| `lib/domain/usecases/submit_complaint_usecase.dart` | ✅ |
| `lib/domain/usecases/get_my_complaints_usecase.dart` | ✅ |
| `lib/domain/usecases/get_analytics_usecase.dart` | ✅ |
| `lib/domain/usecases/sr_approve_complaint_usecase.dart` | ✅ |
| `lib/domain/usecases/sr_reject_complaint_usecase.dart` | ✅ |
| `lib/domain/usecases/update_complaint_status_usecase.dart` | ✅ |

### Phase 3 — State Management (Pavan + Prabhava)
**Status: ✅ COMPLETE** | Date: 2026-06-02

| File | Author | Status |
|---|---|---|
| `lib/presentation/bloc/auth/auth_bloc.dart` | Pavan | ✅ GoogleSignIn + AppStarted + Logout |
| `lib/presentation/bloc/auth/auth_event.dart` | Pavan | ✅ |
| `lib/presentation/bloc/auth/auth_state.dart` | Pavan | ✅ |
| `lib/presentation/bloc/complaint/complaint_bloc.dart` | Pavan | ✅ |
| `lib/presentation/bloc/complaint/complaint_event.dart` | Pavan | ✅ |
| `lib/presentation/bloc/complaint/complaint_state.dart` | Pavan | ✅ |
| `lib/presentation/bloc/submit_complaint/submit_complaint_cubit.dart` | Pavan | ✅ 800ms debounce grammar + AI |
| `lib/presentation/bloc/submit_complaint/submit_complaint_state.dart` | Pavan | ✅ |
| `lib/presentation/bloc/sr_review/sr_review_bloc.dart` | Prabhava | ✅ Load + Approve + Reject |
| `lib/presentation/bloc/sr_review/sr_review_event.dart` | Prabhava | ✅ |
| `lib/presentation/bloc/sr_review/sr_review_state.dart` | Prabhava | ✅ |
| `lib/presentation/bloc/analytics/analytics_cubit.dart` | Prabhava | ✅ loadSummary + empty/error states |
| `lib/presentation/bloc/analytics/analytics_state.dart` | Prabhava | ✅ |

### Phase 4 — Common Widgets (Pavan)
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status |
|---|---|
| `lib/presentation/widgets/common/scms_button.dart` | ✅ 4 variants + loading |
| `lib/presentation/widgets/common/scms_text_field.dart` | ✅ |
| `lib/presentation/widgets/common/scms_chip.dart` | ✅ Animated selected state |
| `lib/presentation/widgets/common/loading_overlay.dart` | ✅ |
| `lib/presentation/widgets/common/error_widget.dart` | ✅ With retry |
| `lib/presentation/widgets/common/empty_state_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/complaint_card.dart` | ✅ Full card with SLA |
| `lib/presentation/widgets/complaint/status_badge.dart` | ✅ |
| `lib/presentation/widgets/complaint/sla_timer_widget.dart` | ✅ Real-time ticker |
| `lib/presentation/widgets/complaint/media_capture_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/category_selector_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/tag_selector_widget.dart` | ✅ |
| `lib/presentation/widgets/complaint/grammar_correction_banner.dart` | ✅ Diff view |
| `lib/presentation/widgets/complaint/duplicate_warning_banner.dart` | ✅ |
| `lib/presentation/widgets/complaint/grouped_complaint_card.dart` | ✅ |
| `lib/presentation/widgets/notification/notification_badge.dart` | ✅ |
| `lib/presentation/widgets/analytics/complaints_chart.dart` | ✅ (Prabhava) |
| `lib/presentation/widgets/analytics/stats_card.dart` | ✅ (Prabhava) |

### Phase 5 — Services (Prabhava + Pavan)
**Status: ✅ COMPLETE** | Date: 2026-06-09

| File | Author | Status |
|---|---|---|
| `lib/services/notification_service.dart` | Prabhava | ✅ FCM + local notifications + in-app banner overlay |
| `lib/services/analytics_service.dart` | Prabhava | ✅ Error handler + screen/event logging |
| `lib/firebase_options.dart` | Pavan | ✅ Generated from google-services.json (real values) |
| `lib/services/camera_service.dart` | Pavan | ✅ ImagePicker (camera + gallery), permission handling, multi-pick, size validation |
| `lib/services/watermark_service.dart` | Pavan | ✅ Flutter Canvas pipeline — stamps GPS + datetime strip onto photos using WatermarkPainter |
| `lib/services/location_service.dart` | Pavan | ✅ Geolocator + Geocoding — permission check, getCurrentPosition, reverse geocode, LocationData bundle |
| `lib/services/grammar_service.dart` | Pavan | ✅ Standalone AI grammar-check service — hits `/api/ai/grammar-check`, fails gracefully |
| `lib/services/storage_service.dart` | Pavan | ✅ Local `complaint_drafts/` folder management — save, list, delete, clear after submit |

### Phase 6 — Student Screens (Pavan)
**Status: ✅ FUNCTIONALLY COMPLETE** | Date: 2026-05-19

| File | Status | Notes |
|---|---|---|
| `splash_page.dart` | ✅ | Fade-in + auto-navigate |
| `onboarding_page.dart` | ✅ | 3-slide PageView + dots |
| `login_page.dart` | ✅ | Google Sign-In only |
| `home_page.dart` | ✅ | 3-tab + FAB + stats |
| `my_complaints_page.dart` | ✅ | Filter chips + pull-to-refresh |
| `submit_complaint_page.dart` | ✅ | Form + AI + severity + photos |
| `complaint_detail_page.dart` | ✅ | Full detail + timeline |
| `duplicate_complaints_page.dart` | 🔄 Stub | Router entry exists, logic TODO |
| `rating_page.dart` | ✅ | Star rating + comment |

### Phase 7 — Staff / SR / Admin Screens (Prabhava)
**Status: ✅ COMPLETE — MERGED to main** | Date: 2026-06-02

| File | Status |
|---|---|
| `lib/presentation/pages/staff/staff_dashboard_page.dart` | ✅ |
| `lib/presentation/pages/staff/staff_complaint_detail_page.dart` | ✅ |
| `lib/presentation/pages/sr/sr_dashboard_page.dart` | ✅ |
| `lib/presentation/pages/sr/sr_review_detail_page.dart` | ✅ Approve + Reject with rejection reason |
| `lib/presentation/pages/admin/admin_dashboard_page.dart` | ✅ Analytics dashboard |
| `lib/presentation/pages/admin/admin_complaints_list_page.dart` | ✅ |
| `lib/presentation/pages/settings/settings_page.dart` | ✅ |
| `lib/presentation/pages/route_helpers.dart` | ✅ `prabhavaRoutes` list (all 7 routes) |

**Integration into main (done by Pavan):**
- `main.dart`: `SrReviewBloc` + `AnalyticsCubit` registered in `MultiBlocProvider` with full DI chain
- `main.dart`: Firebase initialized + `NotificationService.instance.initialize(navigatorKey:)`
- `app.dart`: `prabhavaRoutes` spread into GoRouter, `navigatorKey` threaded through for FCM deep-link navigation

**`flutter analyze` result: ✅ No issues found**

---

### Prem — Node.js Backend
**Status: ✅ COMPLETE**

All routes, auth handlers, upload handlers, SLA/SR scheduler crons, and seeding logic have been successfully implemented, database migrations run, and local postgres connectivity verified.

**Start immediately with:**
1. `cd scms_backend && npm install`
2. Copy `.env.example` → `.env`, fill real values (see below)
3. `npx prisma migrate dev` (needs PostgreSQL running via `docker-compose up postgres -d`)
4. Implement `POST /api/auth/google` FIRST — this unblocks Flutter auth testing

**Critical `.env` values for Prem:**
```
GOOGLE_CLIENT_ID=182336575222-252rq8mp7br1178te3ugao4radr2onnv.apps.googleusercontent.com
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json   ← download from Firebase Console → Project Settings → Service Accounts
FIREBASE_STORAGE_BUCKET=scms-campus-app.firebasestorage.app
```

**Priority build order:**
```
server.js → src/app.js → src/middleware/authenticate.js
→ src/routes/auth.js (POST /api/auth/google) ← DO FIRST
→ src/routes/complaints.js → src/routes/ai.js
→ src/services/aiProxy.js → src/jobs/slaScheduler.js
```

### Pramath — Python AI Service
**Status: ✅ COMPLETE** | Date: 2026-05-19

| File | Status | Notes |
|---|---|---|
| `requirements.txt` | ✅ | google-genai, fastapi, uvicorn, psycopg2-binary, pgvector, pydantic, numpy, httpx |
| `.env` | ✅ | Copy `.env.example`, set real `GEMINI_API_KEY` from AI Studio |
| `models/schemas.py` | ✅ | All Pydantic schemas: Grammar, Categorize, Embed, Duplicate |
| `services/gemini_client.py` | ✅ | New `google-genai` SDK; grammar + categorize + embed, all with try/except fallbacks |
| `services/db_client.py` | ✅ | psycopg2 pool + pgvector; store_embedding + find_similar_complaints |
| `routers/grammar.py` | ✅ | POST /grammar-check with word-level EQUAL/DELETE/INSERT diffs |
| `routers/categorize.py` | ✅ | POST /categorize; maps AI output to category/dept IDs |
| `routers/embed.py` | ✅ | POST /embed; generates + stores 768-d vector in complaints.embedding |
| `routers/duplicate.py` | ✅ | POST /check-duplicate; cosine similarity >= SIMILARITY_THRESHOLD |
| `main.py` | ✅ | CORS, all routers, /health probe, startup pgvector migration |

**Notes for Prem (Node.js):**
- Service runs on port 8000 (configurable via PORT env var)
- All endpoints return safe defaults on failure — never crash with 500
- `/embed` must be called by Node.js AFTER saving complaint to DB (`complaintId` required)
- Category/dept IDs in `/categorize` are placeholder slugs — update once Prem seeds DB UUIDs
- Gemini: `gemini-2.0-flash` (text), `models/gemini-embedding-004` (768-d)

**To start:**
```bash
cd scms_ai_service && venv\Scripts\activate
# Set real GEMINI_API_KEY in .env
uvicorn main:app --reload --port 8000
```

---

## 🔥 Firebase Configuration (Pavan — DONE)

**Firebase project:** `scms-campus-app` (Spark plan)
**Android package:** `com.scms.scms_flutter`

| Asset | Location | Status |
|---|---|---|
| `google-services.json` | `android/app/google-services.json` | ✅ With OAuth client |
| `firebase_options.dart` | `lib/firebase_options.dart` | ✅ Real values, androidClientId set |
| Google Services Gradle plugin | `settings.gradle.kts` + `app/build.gradle.kts` | ✅ v4.4.2 applied |
| FCM (Cloud Messaging) | Firebase Console | ✅ Enabled |
| Google Sign-In | Firebase Console → Authentication | ✅ Enabled |

**OAuth Web Client ID (for Prem's backend — `GOOGLE_CLIENT_ID` in `scms_backend/.env`):**
```
182336575222-252rq8mp7br1178te3ugao4radr2onnv.apps.googleusercontent.com
```

**Still needed before full end-to-end auth works:**
- Prem must download `firebase-service-account.json` from Firebase Console → Project Settings → Service Accounts
  and place it at `scms_backend/firebase-service-account.json` (already in `.gitignore`)

---

## ⚠️ Known Issues & Decisions

| Date | Issue | Resolution |
|---|---|---|
| 2026-05-19 | `hive_generator ^2.0.1` conflicts with `bloc_test ^9.1.7` | Removed `hive_generator` + `build_runner`. Hive TypeAdapters written **manually** in `complaint_local_datasource.dart`. |
| 2026-05-19 | `AuthFailure` name collision (failures.dart vs auth_state.dart) | `auth_bloc.dart` uses `import ... as failures` to disambiguate. |
| 2026-05-19 | `withOpacity` deprecated in Flutter | Added `deprecated_member_use: ignore` in `analysis_options.yaml`. Replace with `.withValues(alpha: x)` when upgrading Flutter. |
| 2026-06-02 | `analytics_service.dart` used `import 'dart:ui'` but `FlutterError` is in flutter framework | Fixed: replaced with `import 'package:flutter/foundation.dart'`. |
| 2026-06-02 | `sr_review_detail_page.dart` had unused `extensions.dart` import | Fixed: removed unused import. |
| 2026-06-02 | `flutterfire configure` requires Firebase CLI (not installed) | Worked around: `firebase_options.dart` hand-crafted from `google-services.json` values. Re-run `flutterfire configure` if project settings change. |

---

## 📁 Project Structure (Current State)

```
d:\projects\SCMS\
├── SCMS_PRD.md                         ← Source of truth for all specs
├── TEAM_WORKDIVISION.md                ← Ownership rules
├── CONTEXT.md                          ← THIS FILE
├── PROMPT_PAVAN.md                     ← Pavan's AI agent prompt
├── PROMPT_PRABHAVA.md                  ← Prabhava's AI agent prompt
├── docker-compose.yml                  ← Postgres + Backend + AI
├── .gitignore
│
├── scms_flutter/                       ← Flutter app ✅ ALL PHASES COMPLETE
│   ├── analysis_options.yaml
│   ├── pubspec.yaml                    ← All deps installed
│   ├── .env                            ← Real values set (GOOGLE_SERVER_CLIENT_ID filled)
│   ├── .env.example
│   ├── android/
│   │   ├── app/
│   │   │   ├── build.gradle.kts        ✅ google-services plugin applied
│   │   │   └── google-services.json    ✅ Real Firebase config with OAuth client
│   │   └── settings.gradle.kts        ✅ google-services plugin v4.4.2 declared
│   └── lib/
│       ├── main.dart                   ✅ Firebase init + NotificationService + all BLoC DI
│       ├── app.dart                    ✅ GoRouter + role redirect + navigatorKey
│       ├── firebase_options.dart       ✅ Real values from google-services.json
│       ├── core/                       ✅ All foundation files
│       ├── data/models/                ✅ 10 models with fromJson/toJson
│       ├── data/datasources/           ✅ Remote (auth + complaint + sr_review) + local
│       ├── data/repositories/          ✅ Auth + Complaint + SrReview
│       ├── domain/                     ✅ Entities + 7 use-cases
│       ├── services/                   ✅ NotificationService + AnalyticsService + CameraService + WatermarkService + LocationService + GrammarService + StorageService
│       ├── presentation/bloc/          ✅ Auth + Complaint + SubmitComplaint + SrReview + Analytics
│       ├── presentation/widgets/       ✅ Common + complaint + notification + analytics widgets
│       └── presentation/pages/
│           ├── splash/                 ✅
│           ├── onboarding/             ✅
│           ├── auth/                   ✅ Google Sign-In only
│           ├── home/                   ✅ 3-tab
│           ├── complaint/              ✅ my list + submit + detail + rating
│           ├── staff/                  ✅ dashboard + complaint detail
│           ├── admin/                  ✅ dashboard + complaints list
│           ├── sr/                     ✅ dashboard + review detail (approve/reject)
│           ├── settings/               ✅
│           └── route_helpers.dart      ✅ prabhavaRoutes (all 7 role routes)
│
├── scms_backend/                       ← Node.js API ✅ PREM COMPLETE (merged 2026-06-09)
│   ├── package.json                    ✅ All deps
│   ├── prisma/schema.prisma            ✅ Full schema + migrations
│   ├── prisma/seed.js                  ✅ Departments, categories, zones, tags, allowed domains
│   ├── .env.example                    ✅
│   └── src/                            ✅ All routes + middleware + services + jobs implemented
│
└── scms_ai_service/                    ← Python FastAPI ✅ PRAMATH COMPLETE
    ├── .env.example                    ✅
    ├── requirements.txt                ✅
    └── routers/ services/ models/      ✅ All 4 endpoints implemented
```

---

## 🔄 How to Resume as AI Agent

1. **Read this file first** — understand current state
2. **Read `SCMS_PRD.md` §§ relevant to your work** (don't read all 3378 lines)
3. **Read `TEAM_WORKDIVISION.md`** — never touch other members' files
4. **Check the progress tracker above** — find your first ⬜ item
5. **Update this file** after completing work
6. **Run `flutter analyze`** — must show "No issues found"

### Quick Start Commands
```bash
# Flutter (Android) — all Firebase config is in place
cd d:\projects\SCMS\scms_flutter
flutter pub get
flutter run

# Node.js backend (Prem)
cd d:\projects\SCMS\scms_backend
cp .env.example .env          # fill real values (see Firebase section above for GOOGLE_CLIENT_ID)
npm install
docker-compose up postgres -d  # from root
npx prisma migrate dev
npm run dev

# Python AI service (Pramath)
cd d:\projects\SCMS\scms_ai_service
python -m venv venv
venv\Scripts\activate          # Windows
cp .env.example .env           # fill GEMINI_API_KEY
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

---

*Last updated: 2026-06-16 by Claude Code (AI agent) — Full-stack integration fixes + UI redesign:*
*### Critical integration bugs fixed (app compiled but crashed/failed against the real backend)*
*• Flutter `DioClient`: added `_UnwrapInterceptor` — backend wraps every response in `{success, data}`; data sources read the raw payload now (fixes auth/me, categories, departments, analytics, complaint-by-id, sr/pending, etc.).*
*• Flutter `complaint_remote_datasource`: list endpoints now read the nested `data.complaints` (was casting a Map to List → runtime crash). Added `_parseComplaintList` helper.*
*• Flutter submit payload was using wrong field names → every submission failed: `subject`→`title`, photo field `photos`→`media` (multer expects `media`), tags now JSON-encoded. Status update `newStatus`→`status`, rating `comment`→`ratingComment`. Verified rating + status flows via live API.*
*• Flutter `AnalyticsModel.fromJson` read keys that didn't exist (`totalActiveComplaints`, `byDepartment`…); remapped to backend keys (`activeComplaints`, `slaBreachedCount`, `departmentStats`, `categoryStats`) with computed resolution rate. Admin dashboard now populates.*
*• Backend: added `src/utils/enrichComplaints.js` — complaints had no category/department/assignee relation, so `categoryName`/`departmentName`/`submittedByName`/`assignedToName`/`photoUrls` came back empty. Wired into `/complaints/my`, `/complaints`, `/complaints/:id`, and `/sr/pending`.*
*• Android `build.gradle.kts`: enabled core library desugaring (+ desugar_jdk_libs) — `flutter_local_notifications` requires it; release/debug APK builds were failing before this.*
*### Database / runtime*
*• Baselined the `20260605083336_init` migration (schema already present), ran `seed.js` + new `seed_sample_data.js` (4 mock users + 5 demo complaints). Backend verified serving real data on :3000 with mock tokens.*
*### UI redesign (cohesive, modern, beautiful)*
*• New `AppColors.primaryGradient`/`accentGradient`; new `CategoryIcons` helper; new reusable `GradientAppBar`.*
*• `ComplaintCard` redesigned: status accent stripe, category icon tile, severity/category pills, shadow.*
*• `home_page`: gradient hero header + greeting + avatar, glass stat cards, NavigationBar, redesigned profile tab with logout.*
*• `complaint_detail_page`: gradient SliverAppBar hero, sectioned info cards, vertical connected timeline, rating card.*
*• Staff + SR dashboards now use `GradientAppBar`; admin dashboard analytics populate.*
*• `flutter analyze`: No issues found. Debug APK build validated.*
*---*
*Earlier (2026-06-15T19:20): Bug fixes + missing UI:*
*• Backend: Fixed ReferenceError — `status` was undefined in `GET /api/complaints/my` handler (jwtHelper.js was also parsing mock token roles incorrectly — `split('_').pop()` gave `'ADMIN'` not `'ROLE_ADMIN'`; fixed with regex `/_ROLE_(\w+)$/`).*
*• Backend: Fixed POST `/api/complaints` — `departmentId` was required but Flutter never sent it; now auto-resolved from `category.defaultDepartmentId` in PostgreSQL.*
*• Flutter: Added `CategorySelectorWidget` to `submit_complaint_page.dart` (loaded from `ComplaintRepository.getCategories()` via FutureBuilder) — submissions no longer fail with empty categoryId.*
*• Flutter: Added `_AiPreviewBanner` inline widget to submit page — shows Gemini suggestions with Accept/Change buttons.*
*• Flutter: Fixed `DuplicateWarningBanner.onViewDuplicates` — now shows a `ModalBottomSheet` with the duplicate match list (tapping navigates to complaint detail).*
*• Flutter: Fixed `duplicate_complaints_page.dart` navigation — was using `Routes.complaintDetail` (path template `/complaint/:id`) as a push URL; now correctly uses `/complaint/${match.id}`.*
*• Flutter: Added `MultiRepositoryProvider` wrapping in `main.dart` — `ComplaintRepository`, `AuthRepository`, `SrReviewRepository` now accessible via `context.read<T>()`; removed inline `ComplaintRepository` instantiation from `staff_dashboard_page.dart`.*
*• Flutter: Fixed `FontWeight.extrabold` → `FontWeight.w900` in `login_page.dart` (compile error).*
*• `flutter analyze`: No issues found.*

---

*Last updated: 2026-06-17 by Claude Code (AI agent) — Premium glassmorphism UI rework (design-system-first, all roles):*
*### Brand & design system*
*• Refreshed brand from blue/teal → indigo/violet: `AppColors.primary` #4F46E5, `primaryLight` #818CF8, `primaryDark` #3730A3, `accent` #8B5CF6; `primaryGradient` now indigo→violet. Status/severity/confidence colors kept (semantic). Note: `statusPendingSrReview` (#8B5CF6) now shares the accent hue — harmless in practice.*
*• Added glass tokens to `AppColors` (`glassFillLight/Dark`, `glassBorderLight/Dark`, `glassBlurSigma`) + soft `backdropLight/Dark` scaffold gradients.*
*• `app_theme.dart`: cards 20-radius/elevation 0, buttons 14-radius/height 54, filled translucent inputs — both light & dark.*
*### New reusable widgets*
*• `common/glass_container.dart` + `glass_card.dart` (BackdropFilter frosted surfaces), `common/app_scaffold.dart` (backdrop-gradient scaffold), `common/section_header.dart`; `gradient_app_bar.dart` gained a `glass: true` frosted mode.*
*• `ScmsButton` primary is now a gradient pill; `StatsCard` + `ComplaintCard` restyled (glass tile / gradient status stripe).*
*### Richer dashboard widgets (`widgets/dashboard/`, all derive from existing BLoC state — no new API calls)*
*• `status_breakdown_ring.dart` (donut + legend), `attention_card.dart` (SLA-at-risk highlight), `quick_actions_row.dart` (glass shortcuts), `trend_sparkline.dart` (7-day line), `sr_summary_header.dart` (SR queue hero).*
*• Student home: quick actions + attention card + status ring. Staff dash: glass stat tiles + attention + trend + workload ring. SR dash (was a bare list): summary hero. Admin dash: indigo gradient header (kept analytics; no per-day series in model to chart).*
*### Cohesion + cleanup*
*• Converted remaining pages to `AppScaffold` + glass `GradientAppBar`: my_complaints, settings, admin_complaints_list, submit/rating/duplicate, staff & SR detail.*
*• Removed dead route constants `register` + `notificationHistory` (unused, no pages).*
*### Made non-functional Settings controls actually work*
*• Added `core/app_preferences.dart` — a `ChangeNotifier` singleton holding `themeMode` + `notificationsEnabled` (in-memory; resets on cold start — persistence is a future enhancement).*
*• `app.dart`: wrapped `MaterialApp.router` in `ListenableBuilder(AppPreferences.instance)` and bound `themeMode` to it — the Settings theme dropdown (System/Light/Dark) now switches the live app theme.*
*• `settings_page.dart`: theme dropdown + notifications switch now read/write `AppPreferences` (were dead local-only state).*
*• `notification_service.dart`: `onMessage` now bails early when `AppPreferences.instance.notificationsEnabled` is false — the Settings toggle actually suppresses in-app banners + local notifications.*
*• `flutter analyze`: No issues found. Debug APK build validated (`app-debug.apk`).*

---

*Last updated: 2026-06-17 by Claude Code (AI agent) — Enriched staff/SR/admin dashboards (they felt bland vs the student home):*
*• New reusable `widgets/dashboard/dashboard_hero.dart` (`DashboardHero` — the gradient greeting hero + role badge + avatar + translucent stat cards, mirroring the student header) and `widgets/dashboard/breakdown_bars.dart` (`BreakdownBars` — horizontal-bar distribution, e.g. pending-by-category).*
*• Staff dashboard: replaced the glass app bar with a `DashboardHero` (Assigned / In Progress / Done Today live stats); kept attention card + 7-day trend + workload ring + task list. Removed the now-duplicate stat-tile row.*
*• SR dashboard: rebuilt `sr_summary_header.dart` into a `DashboardHero` (Pending / High / Oldest) + a "pending by category" `BreakdownBars`, then the review queue. Dropped the redundant glass app bar.*
*• Admin dashboard: replaced the plain `SliverAppBar` with a `DashboardHero` (Active / Breaches 7d / Resolution rate); kept the 4 KPI `StatsCard`s + department/category charts + recent SLA breaches.*
*• All hero stats derive from existing BLoC/analytics state — no new API calls. `flutter analyze`: No issues found.*

---

*Last updated: 2026-06-18 by Claude Code (AI agent) — App-wide premium (no-gradient) finish + full feature parity across all roles. NOTE: this crosses team file-ownership lines (Prabhava's staff/SR/admin pages + `route_helpers.dart`, shared backend `analytics.js`/`complaints.js`/`users.js`) — done deliberately at the user's request for an end-to-end upgrade.*
*### Design system — gradients removed (solid + frosted glass)*
*• `AppColors`: `primaryGradient`/`accentGradient` flattened to single-tone (legacy/no on-screen gradient); `backdropLight/Dark` flattened to solid tints; added `primarySurface`/`primaryDeep`. Solid `AppColors.primary` now fills `DashboardHero`, `GradientAppBar` (non-glass), `ScmsButton` primary, `ComplaintCard` status stripe, complaint-detail & login headers. `stats_card`/`quick_actions_row` icon tiles + `trend_sparkline` area fill use solid tints. `grep LinearGradient lib/` shows only the unused legacy constants.*
*### Backend — read-only global access + analytics for everyone*
*• `analytics.js`: dropped the `ROLE_ADMIN/ROLE_DEPT_HEAD` gate (now any authenticated user); `/summary` also returns `recentSlaBreaches` (last 7d, enriched) so `AnalyticsModel.recentSlaBreaches` finally populates.*
*• `complaints.js`: `GET /` gained opt-in `scope=all` (bypasses role-scoping for the shared feed), plus `severity` + text `q` (title/description/complaintNumber) filters; default behaviour unchanged. `GET /:id` read RBAC relaxed — any authenticated user can READ a complaint; all write routes (status/assign/rating/SR approve-reject) stay guarded.*
*• `users.js`: added `GET /api/users?role=ROLE_STAFF` (Admin/Dept-Head only) for the assignment picker (selects incl. `createdAt`/`lastLogin` so Flutter `UserModel` parses).*
*### Flutter — shared role shell + 3 cross-role screens*
*• `pages/shell/main_shell.dart`: every role now lands in one bottom-nav shell — role-specific Dashboard + shared All / Stats / Profile tabs (lazy-built, so unopened tabs don't fire network calls). `app.dart` (student) + `route_helpers.dart` (staff/SR/admin) route to `MainShell`. New routes: `/complaints/all`, `/stats`, `/complaints/mine`.*
*• `bloc/all_complaints/` (`AllComplaintsCubit`+state): isolated from `ComplaintBloc`; owns query/pagination for the global feed (reuses `repo.getAllComplaints` → `scope=all`).*
*• `pages/complaints/all_complaints_page.dart`: read-only system-wide feed for all roles — debounced search, status chips, category/department/severity filter sheet, infinite scroll. Self-provides its cubit (works as tab or pushed drill-down via `?categoryName=`/`?status=`). Supersedes `admin_complaints_list_page.dart` (route removed; file left orphaned).*
*• `pages/stats/stats_page.dart`: analytics for every role — KPIs + by-dept/by-category charts + recent SLA breaches (from `AnalyticsCubit`), a recent-inflow sparkline (page-scoped feed cubit), tappable category drill-down, and CSV copy-to-clipboard export.*
*• `pages/profile/profile_page.dart`: unified premium profile for all roles (replaces student's inline tab) — solid header + glass cards, personal activity stats, working notifications/theme toggles (`AppPreferences`), Settings + Logout.*
*• `home_page.dart`: reworked into `StudentDashboardView` (shell tab 1) using `DashboardHero`; "See all"/quick actions push `/complaints/mine` and `/complaints/all`.*
*### Per-role workflow upgrades*
*• Staff: long-press multi-select → bulk Mark In-Progress/Resolve (contextual bottom bar); detail page gained an Activity Timeline from `complaint.updates[]`.*
*• SR: severity filter chips over the pending queue (client-side).*
*• Admin: assign/reassign-to-staff from the complaint detail (staff picker sheet → `PATCH /:id/assign`); chart category drill-down; CSV export of analytics.*
*• Data layer: `ComplaintRemoteDataSource`/`ComplaintRepository` gained `getStaff()` + `assignComplaint()`; `getAllComplaints` now sends `scope=all` + `q`.*
*• `flutter analyze`: No issues found. Backend routes pass `node --check`.*

---

*Last updated: 2026-06-19 by Claude Code (AI agent) — Owner edit/delete feature + code-review fixes. Crosses team ownership lines (backend `complaints.js`/`analytics.js`, Prabhava's `profile`/`stats`/`settings` already touched in prior commit) — done at user's request.*
*### Feature — submitter can edit & delete their own complaint*
*• `complaints.js`: added owner-only `PATCH /:id` (edit title/description/location/category/severity/tags; re-resolves department on category change; logs a timeline entry; refreshes the pgvector embedding when description changes) and `DELETE /:id` (deletes media + updates first since schema has no cascade). Both 403 for non-submitters.*
*• `ComplaintRemoteDataSource`/`ComplaintRepository`: added `updateComplaint()` + `deleteComplaint()`.*
*• `complaint_detail_page.dart`: owner-only Edit (bottom-sheet form) + Delete (confirm dialog) actions in the app bar; reload-on-edit, pop-on-delete.*
*### Code-review fixes (from /code-review high)*
*• SECURITY: `analytics.js` `recentSlaBreaches` no longer exposes submitter `email` (kept name/picture) — was leaking PII to every authenticated role.*
*• `all_complaints_cubit.dart`: non-`Failure` error during `loadMore` no longer leaves `loadingMore:true` stuck forever (mirrors the `on Failure` append-recovery).*
*• `main_shell.dart`: dashboard tab cache now invalidated on role change (was caching a wrong-role/`ROLE_USER` dashboard permanently).*
*• `analytics_model.dart`: fixed `as num?` operator-precedence so the primary `averageResolutionTimeHours` key is cast, not passed through `??` uncast.*
*• `app.dart`: pushed `/complaint/:id` + `/complaints/mine` routes now get their own scoped `ComplaintBloc` so opening a detail / filtering never wipes the kept-alive dashboard's list state; `GoRouterRefreshStream` + `_router` now disposed in `_ScmsAppState.dispose()`.*
*• `submit_complaint`: AI-suggestion and grammar banners' "dismiss" buttons now work (`dismissAiPreview()`/`dismissGrammar()` + `grammarDismissed` flag) — were no-ops.*
*• Cleanup: extracted shared `String.toRoleLabel()`/`toRoleBadge()` (extensions.dart) adopted by profile/stats/all-complaints (removed 3 duplicated role switches); `status_breakdown_ring` legend now uses canonical `toStatusLabel()` instead of its own `_pretty()`.*
*• `flutter analyze`: No issues found. Backend routes pass `node --check`.*

---

*Last updated: 2026-07-04 by Claude Code (AI agent) — **iOS-clean UI/UX redesign, Phase A (foundation)**. Cross-cutting presentation-only change (touches shared theme + widgets across all owners) — done at user's request. Spec: `docs/superpowers/specs/2026-07-04-ios-clean-ui-redesign-design.md`; plan: `docs/superpowers/plans/2026-07-04-ios-clean-ui-redesign.md`.*
*### Phase A — design-system foundation (Apple system-blue, iOS-clean)*
*• `app_colors.dart`: remapped tokens to the Apple system palette (accent `#007AFF`/`#0A84FF`, grouped backgrounds `#F2F2F7`/`#000000`, surfaces, hairline separators, system red/orange/green/etc.); status/severity/confidence colors now derive from system colors. Public API kept stable; added `groupedBackground*`, `separator*`, `system*`, `fillTinted()`.*
*• `app_text_styles.dart` + `app_theme.dart`: retuned to the iOS type scale (Large Title 34 … Caption 12); themes now use grouped scaffold bg, transparent centered app bars, 12px flat cards/buttons (50px min), pill chips, 0.5px hairline dividers, and a Cupertino `PageTransitionsTheme` on both light & dark.*
*• New shared components: `PressableScale` (0.98 press feedback), `InsetGroupedSection` + `InsetListRow` (iOS grouped list), `LargeTitleScaffold` (collapsing blurred large-title nav), `CupertinoSegmentedTabs` (segmented filter).*
*• Restyled `ScmsButton` (filled/tinted/destructive/text, flat), `StatusBadge` (tinted pill), `StatsCard` (surface card + count-up value), `DashboardHero` (large-title greeting + light stat tiles; no more indigo block).*
*• `flutter analyze`: No issues found.*
*### Phase B — student flow screens (iOS-clean)*
*• Splash/onboarding/login: content on grouped background, accent app-icon tiles, Cupertino spinner; login drops the heavy glass card; all auth logic (Google + mock role bypass) unchanged.*
*• Home dashboard: inherits the large-title `DashboardHero`, surface-card quick actions (press-scale), restyled complaint cards; blocs unchanged.*
*• Submit: transparent app bar with Cancel, severity via `CupertinoSegmentedTabs`; cubit/debounce/AI banners/field names unchanged.*
*• My/All Complaints: clean app bars, pill filter chips; card + pagination/search/filter logic unchanged.*
*• Detail: removed the solid-indigo header for a transparent app bar + large title + status pill; sections are soft surface cards; timeline/edit/delete/assign preserved. Rating + duplicates: clean app bars, surface cards, press-scale.*
*• Shared: `ComplaintCard`, `QuickActionsRow`, and `GlassContainer` (→ every glass consumer) converted to solid iOS surface cards. `flutter analyze`: No issues found.*
*### Phase C — staff/SR/admin/stats screens (iOS-clean)*
*• Staff, SR, and admin dashboards required no structural change — they inherit the restyled `DashboardHero`, `SrSummaryHeader`, `StatsCard`, `ComplaintCard`, `ScmsButton`, and pill chips from Phase A (the payoff of the shared-component approach).*
*• Swapped the remaining `GradientAppBar`s for clean transparent `AppBar`s on: staff task detail, SR review detail, admin complaints list, and the shared Statistics page (kept CSV/refresh actions; dropped the role-badge chrome). All BLoC events, status-update payloads (`status`), approve/reject flows, and CSV export unchanged. `flutter analyze`: No issues found.*

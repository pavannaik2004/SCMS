# SCMS — Rebuild Specification (Single Source of Truth)

> **Purpose of this file.** This is a complete, self-contained blueprint for rebuilding the
> **Smart Complaint Management System (SCMS)** from scratch. Hand this file to an AI/engineer in
> an empty project and they have everything needed to reconstruct the system: features, data
> model, every endpoint with request/response shapes, env variables (with real values), reference
> data, constants, and the integration contracts between the three services.
>
> **Visual design is specified in §17** (Material Design 3, light-default with dark toggle, a
> social-feed aesthetic). §1–§16 stay design-agnostic — they define data/behavior contracts;
> apply the §17 design language on top of them.
>
> **This is a "canonical" spec, not a verbatim copy.** The original codebase contains internal
> contradictions (drifted endpoint paths, conflicting SLA values, a couple of real bugs). Those
> are resolved into one authoritative set of values here; §16 lists each contradiction and the
> chosen resolution so the rebuild does not reproduce the drift.

---

## 1. Overview & Goal

SCMS is a **campus complaint management app for an engineering college (RV College of
Engineering)**. Students submit complaints (electrical, plumbing, IT, housekeeping, etc.) with
photos/video and GPS; Student Representatives (SRs) review/approve them; staff resolve them;
admins assign work and watch analytics. AI augments the flow with grammar correction, automatic
categorization/severity, and duplicate-complaint detection.

**Hard product rules**
- **Auth is Google OAuth 2.0 only**, restricted to the `rvce.edu.in` email domain. No
  email/password login exists.
- Complaints move through a **review → resolve → rate** lifecycle with **SLA tracking** and two
  automated background jobs (SR auto-approve, SLA-breach detection).
- **AI is best-effort augmentation**, never a hard dependency — every AI call fails safe.
- Push notifications via Firebase Cloud Messaging (FCM) keep all parties informed.
- **Light social engagement:** each complaint supports a **"Me too" upvote** (one per user — "this
  affects me too", a popularity/severity signal) and **comment threads**, so the feed reads like a
  social app. (Added for the §17 social design; new tables/endpoints in §6.6 and §7.5.1.)

**Goal of the rebuild:** same features, same stack, cleaner implementation, a Material Design 3
social-feed visual design (§17).

---

## 2. System Architecture

Three services:

```
┌─────────────────────┐
│  scms_flutter        │  Flutter mobile app (Android/iOS)
│  (mobile client)     │
└──────────┬──────────┘
           │  HTTPS, JWT Bearer, JSON  (base: API_BASE_URL + /api)
           ▼
┌─────────────────────┐
│  scms_backend        │  Node.js / Express REST API   (port 3000)
│  (system of record)  │  ── Prisma ORM ──▶ PostgreSQL + pgvector (port 5432)
└──────────┬──────────┘
           │  internal HTTP only (AI_SERVICE_URL), best-effort
           ▼
┌─────────────────────┐
│  scms_ai_service     │  Python / FastAPI            (port 8000)
│  (AI microservice)   │  ──▶ Google Gemini (google-genai SDK)
└─────────────────────┘            └──▶ same PostgreSQL/pgvector (reads/writes `embedding`)
```

**Architectural invariants (must hold in the rebuild):**
1. **Flutter never calls the Python AI service directly.** It only talks to the Node backend; the
   backend proxies to Python via `AI_SERVICE_URL`.
2. **The Node backend owns the database** (Prisma migrations, all business writes). The Python
   service only reads/writes the single `complaints.embedding` pgvector column.
3. **Response envelope convention** (see §7.1): every backend response is wrapped; the Flutter Dio
   client unwraps it before models see the payload.
4. **AI fails safe:** if Gemini or the AI service is down, the backend returns safe defaults and
   the user flow continues uninterrupted.
5. **The Python service must be reachable by the backend after a complaint row exists** —
   embeddings are generated *after* insert (they need the complaint `id`).

---

## 3. Tech Stack (pinned)

### 3.1 Flutter app (`scms_flutter/`)
- Dart SDK `>=3.4.0 <4.0.0`, Flutter `>=3.22.0`. App version `1.0.0+1`.
- Key packages (versions from the original `pubspec.yaml`):
  - State/routing: `flutter_bloc ^8.1.5`, `go_router ^13.2.0`, `provider ^6.1.2`
  - Network: `dio ^5.4.3`, `flutter_dotenv ^5.1.0`, `connectivity_plus ^6.0.3`
  - Auth/secure: `google_sign_in ^6.2.1`, `flutter_secure_storage ^9.0.0`
  - Media/location: `image_picker ^1.1.2`, `camera ^0.11.0`, `geolocator ^12.0.0`,
    `geocoding ^3.0.0`, `image ^4.1.3` (watermark), `video_player ^2.8.6`,
    `video_compress ^3.1.2`, `permission_handler ^11.3.1`
  - Firebase/notif: `firebase_core ^2.30.0`, `firebase_messaging ^14.9.1`,
    `flutter_local_notifications ^17.1.2`
  - Offline/UI: `hive ^2.2.3`, `hive_flutter ^1.1.0`, `cached_network_image ^3.3.1`,
    `fl_chart ^0.68.0`, `lottie ^3.1.0`, `shimmer ^3.0.0`, `google_fonts ^6.2.1`,
    `diff_match_patch ^0.4.1`, `intl ^0.19.0`, `path_provider ^2.1.3`
  - Dev: `flutter_lints ^4.0.0`, `bloc_test ^9.1.7`, `mocktail ^1.0.4`
- **No Hive codegen.** `TypeAdapter`s are hand-written (codegen conflicted with `bloc_test`).
  Keep adapters in sync with models manually.

### 3.2 Node.js backend (`scms_backend/`)
- Node + Express `^4.19.2`. Entry `server.js` → `src/app.js`.
- `prisma ^5.14.0` / `@prisma/client ^5.14.0` (PostgreSQL provider).
- `jsonwebtoken ^9.0.2`, `google-auth-library ^9.11.0`, `multer ^1.4.5-lts.1`,
  `node-cron ^3.0.3`, `firebase-admin ^12.2.0`, `axios ^1.7.2`, `zod ^3.23.8`,
  `cors ^2.8.5`, `helmet ^7.1.0`, `morgan ^1.10.0`, `dotenv ^16.4.5`, `uuid ^10.0.0`,
  `bcryptjs ^2.4.3` (present but unused — no password auth). Dev: `nodemon ^3.1.3`.
- Scripts: `start` (`node server.js`), `dev` (`nodemon server.js`),
  `prisma:migrate`, `prisma:generate`, `prisma:studio`, prisma seed → `node prisma/seed.js`.

### 3.3 Python AI service (`scms_ai_service/`)
- FastAPI `>=0.111.0`, `uvicorn[standard] >=0.30.1`.
- **`google-genai >=2.4.0`** (the new GenAI SDK — NOT the deprecated `google-generativeai`).
- `psycopg2-binary >=2.9.10`, `pgvector >=0.3.6`, `python-dotenv >=1.0.1`, `numpy >=2.0.0`,
  `pydantic >=2.9.0`, `httpx >=0.27.0`.

### 3.4 Infra
- PostgreSQL image **`pgvector/pgvector:pg16`** (pgvector extension required). `docker-compose.yml`
  at repo root brings up Postgres (+ optionally backend and ai_service). Default dev DB creds in
  compose: `scms_user` / `scms_pass` / db `scms_db` on `:5432`.

---

## 4. User Roles & Permissions

Role is a **free-text string** on `User.role` (not a DB enum). Values use the `ROLE_*`
convention:

| Role | Who | Can do |
|------|-----|--------|
| `ROLE_USER` | Students (default for new signups) | Submit/edit/delete own complaints, track status, rate resolved complaints, browse global feed (read-only), view stats |
| `ROLE_STAFF` | Maintenance staff | See complaints assigned to them, update status (`ASSIGNED→IN_PROGRESS→RESOLVED…`), add timeline notes; plus all read-only feed/stats |
| `ROLE_SR` | Student Representatives | Review `PENDING_SR_REVIEW` queue, approve (→`OPEN`) or reject (with cause) |
| `ROLE_ADMIN` | Administrators | Everything: list all complaints, assign staff, view full analytics, edit any record |
| `ROLE_DEPT_HEAD` | Department heads | Same routing/home as admin; can list users and assign staff |

**Role assignment at signup:** new users default to `ROLE_USER`. The original code has a demo
shortcut: emails starting with `admin@` become `ROLE_ADMIN` on first login. (For the rebuild,
treat role elevation as an admin action; keep or drop the `admin@` shortcut as a dev convenience.)

**Role-based home routing (Flutter):** after login the app redirects to a role home, but all role
homes render the same `MainShell` (a 4-tab scaffold) whose first tab swaps by role:
- `ROLE_ADMIN` / `ROLE_DEPT_HEAD` → Admin dashboard
- `ROLE_STAFF` → Staff dashboard
- `ROLE_SR` → SR dashboard
- `ROLE_USER` (default) → Student dashboard

**Dev-only mock auth (must never be reachable in production):** when `NODE_ENV=development`, a
bearer token starting with `mock_` and encoding `..._ROLE_<ROLE>` auto-provisions/looks-up a demo
user with that role, bypassing Google. Used for local testing. Gate strictly on
`NODE_ENV==='development'`.

---

## 5. Complaint Lifecycle / State Machine

`Complaint.status` is a **free-text string** (not an enum). Canonical status set and transitions:

```
                 submit
                   │
                   ▼
        ┌───────────────────────┐
        │   PENDING_SR_REVIEW    │ ── SR reject (cause) ──────────────▶ REJECTED (terminal)
        └───────────┬───────────┘
        SR approve  │  OR  auto-approve after 24h (cron)
                    ▼
                 ┌──────┐   admin assigns staff
                 │ OPEN │ ─────────────────────────▶ ASSIGNED
                 └──────┘                              │ staff starts
                                                       ▼
                                                  IN_PROGRESS
                                                       │ staff resolves
                                                       ▼
                                                   RESOLVED ── submitter rates (1–5) ──▶ CLOSED (terminal)
```

**Status values:** `PENDING_SR_REVIEW`, `OPEN`, `ASSIGNED`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`,
`REJECTED`. (Plus the transient label `SUBMITTED` used only as the `previousStatus` on the first
timeline entry.)

**Who triggers what**
- **Create** → status `PENDING_SR_REVIEW`; a `ComplaintUpdate` row logs `SUBMITTED →
  PENDING_SR_REVIEW`; SRs are notified via FCM.
- **SR approve** (`POST /sr/:id/approve`) → `OPEN`, sets `slaDeadline`, may override
  department/category/severity; notifies submitter.
- **SR reject** (`POST /sr/:id/reject`) → `REJECTED`, stores `srRejectionCause`; notifies submitter.
- **Admin assign** (`PATCH /complaints/:id/assign`) → `ASSIGNED`, sets `assignedToId`; notifies
  assigned staff + submitter.
- **Staff/Admin status update** (`PATCH /complaints/:id/status`) → one of
  `ASSIGNED|IN_PROGRESS|RESOLVED|CLOSED|REJECTED`; notifies submitter. Authorization: caller must
  be the assigned staff **or** an admin.
- **Submitter rate** (`POST /complaints/:id/rating`) → only allowed when status is `RESOLVED`;
  sets `rating`+`ratingComment` and transitions to `CLOSED`.

**Automated transitions (cron, see §10)**
- **SR auto-approve:** complaints stuck in `PENDING_SR_REVIEW` for **> 24h** → `OPEN` (+SLA),
  logged as a `SYSTEM` update; submitter notified.
- **SLA breach:** active complaints (not RESOLVED/CLOSED/REJECTED) whose `slaDeadline` has passed
  and `isSlaBreached=false` → set `isSlaBreached=true`, log a `SYSTEM` update, notify admins +
  assigned staff. (Breach is a one-shot flag; it does not change `status`.)

**Canonical SLA model (see §16 for the resolved conflict):** compute `slaDeadline` at the moment a
complaint becomes `OPEN`, based on **severity**:
- `HIGH` → 4 hours, `MEDIUM` → 24 hours, `LOW` → 72 hours.
(The original backend used a flat 48h; the Flutter constants used 4/24/72. The rebuild adopts the
severity-based 4/24/72 model consistently on the server, and the SLA scheduler keys off
`slaDeadline` as before.)

---

## 6. Data Model (canonical — Prisma / PostgreSQL)

All tables use UUID string primary keys (`@default(uuid())`). `@@map` names are the actual SQL
table names (snake/lower). pgvector extension required.

### 6.1 `User` → table `users`
| field | type | notes |
|------|------|-------|
| id | String PK (uuid) | |
| googleId | String unique | from Google profile `sub` |
| name | String | |
| email | String unique | must be on an allowed domain |
| picture | String? | Google avatar URL |
| role | String, default `ROLE_USER` | see §4 |
| zoneId | String? | optional campus zone |
| departmentId | String? | for staff/dept-head |
| fcmToken | String? | current device push token; cleared on logout |
| isApproved | Boolean default `true` | set false to deactivate |
| createdAt | DateTime default now | |
| lastLogin | DateTime? | updated each Google login |
| complaints | Complaint[] | relation (submittedBy) |

### 6.2 `Complaint` → table `complaints`
| field | type | notes |
|------|------|-------|
| id | String PK (uuid) | |
| complaintNumber | String unique | human ID, format `SCMS-YYYY-NNNNN` (5-digit, per-year counter) |
| title | String | (Flutter model calls this `subject`; backend field is `title`) |
| description | String | |
| location | String | free-text location label |
| gpsLatitude | Float? | |
| gpsLongitude | Float? | |
| gpsPlaceName | String? | reverse-geocoded name |
| categoryId | String | FK→Category (string, not enforced relation in schema) |
| departmentId | String | resolved from category default if omitted on create |
| severity | String | `LOW` \| `MEDIUM` \| `HIGH` |
| status | String default `PENDING_SR_REVIEW` | see §5 |
| tags | String[] | array of tag names |
| submittedById | String FK→User | relation `submittedBy` |
| assignedToId | String? | staff user id |
| reviewedBySrId | String? | SR who reviewed (present in schema/model; wire it up on approve/reject) |
| srRejectionCause | String? | |
| isGrammarCorrected | Boolean default false | |
| isAiCategorized | Boolean default false | |
| aiConfidenceScore | Float? | |
| duplicateGroupId | String? | links duplicates |
| slaDeadline | DateTime? | set when `OPEN` |
| isSlaBreached | Boolean default false | one-shot |
| rating | Float? | 1–5 |
| ratingComment | String? | |
| createdAt | DateTime default now | |
| updatedAt | DateTime @updatedAt | |
| **embedding** | `vector(768)` | **pgvector column, added/maintained by the Python service** (not in the Prisma schema file — created via `CREATE EXTENSION vector` + `ALTER TABLE … ADD COLUMN IF NOT EXISTS embedding vector(768)`; see §16 note) |
| mediaItems | MediaItem[] | |
| updates | ComplaintUpdate[] | timeline |

> **Add for the rebuild:** put `zoneId String?` on `Complaint` and index it. The AI duplicate
> query filters by `complaints."zoneId"`, but the original Prisma schema never declared it — a real
> bug (see §16). Declaring it makes zone-scoped duplicate detection actually work.

> **Engagement derived fields (for the social design, §17).** Complaint-returning endpoints also
> expose three computed fields (not stored on the row): `meTooCount` (count of `ComplaintVote`
> rows), `commentCount` (count of `Comment` rows), and `hasVoted` (whether `req.user` has a vote).
> These are added by `enrichComplaints` (§7.10). Backing tables in §6.6.

### 6.3 `MediaItem` → table `media_items`
| field | type | notes |
|------|------|-------|
| id | String PK | |
| complaintId | String FK→Complaint | |
| url | String | served from `/Storage/...` |
| mediaType | String | `IMAGE` \| `VIDEO` |
| thumbnailUrl | String? | |
| gpsLatitude | Float | (0.0 if unknown) |
| gpsLongitude | Float | (0.0 if unknown) |
| gpsPlaceName | String | ("Unknown Location" if unknown) |
| capturedAt | DateTime | |
| isWatermarked | Boolean default false | server sets `true` (Flutter paints watermark before upload) |
| fileSizeBytes | Int | |

### 6.4 `ComplaintUpdate` → table `complaint_updates` (status timeline)
| field | type | notes |
|------|------|-------|
| id | String PK | |
| complaintId | String FK→Complaint | |
| updatedById | String | user id, or `"SYSTEM"` for cron |
| updatedByName | String | user email or system engine name |
| updatedByRole | String | role or `"SYSTEM"` |
| previousStatus | String | |
| newStatus | String | |
| notes | String? | human-readable note |
| timestamp | DateTime default now | |

### 6.5 Reference tables
- `Department` → `departments`: `id`, `name` (unique), `code` (unique), `headName?`, `createdAt`.
- `Category` → `categories`: `id`, `name` (unique), `iconName?`, `defaultDepartmentId`, `createdAt`.
- `Zone` → `zones`: `id`, `name` (unique), `description?`, `createdAt`.
- `Tag` → `tags`: `id`, `name` (unique), `createdAt`.
- `AllowedDomain` → `allowed_domains`: `id`, `domain` (unique), `description?`, `createdAt`.
- `RefreshToken` → `refresh_tokens`: `id`, `token` (unique), `userId`, `expiresAt`, `createdAt`.

> **No cascade deletes** in the schema. When deleting a complaint, delete its `media_items`,
> `complaint_updates`, `complaint_votes`, and `comments` first (the backend does this in a
> transaction).

### 6.6 Engagement tables (NEW — for the §17 social design)

**`ComplaintVote` → table `complaint_votes`** ("Me too" upvotes)
| field | type | notes |
|------|------|-------|
| id | String PK (uuid) | |
| complaintId | String FK→Complaint | |
| userId | String FK→User | |
| createdAt | DateTime default now | |
| | | `@@unique([complaintId, userId])` — one "Me too" per user per complaint (toggle on/off) |

**`Comment` → table `comments`** (discussion threads)
| field | type | notes |
|------|------|-------|
| id | String PK (uuid) | |
| complaintId | String FK→Complaint | |
| authorId | String FK→User | |
| body | String | 1–500 chars |
| parentId | String? | optional — points to another `Comment.id` for a single level of replies (flat thread otherwise) |
| createdAt | DateTime default now | |
| updatedAt | DateTime @updatedAt | |

---

## 7. Backend API Reference (Node/Express)

Base URL = `API_BASE_URL` (e.g. `http://localhost:3000`) + prefix **`/api`**. All routers mounted
in `src/app.js`. Static media served at **`/Storage`** (note capital S).

Middleware order in `app.js`: `cors()` → `helmet({crossOriginResourcePolicy:false})` →
`morgan('dev')` → `express.json()` + `urlencoded` → static `/Storage` → routers → `errorHandler`.

### 7.1 Response envelope (MANDATORY for every endpoint)
Implemented in `utils/responseHelper.js`:
```json
// success
{ "success": true, "data": <payload> }
// error
{ "success": false, "error": { "message": "...", "code": <httpStatus>, "details": <any|null> } }
```
- `sendSuccess(res, data, status=200)` and `sendError(res, status, message, details=null)`.
- **Flutter unwraps this** in a Dio interceptor, so Flutter data sources receive `<payload>`
  directly. Any new endpoint MUST use these helpers.

### 7.2 Auth & validation building blocks
- `authenticate` middleware: requires `Authorization: Bearer <jwt>`; verifies via `jwtHelper`,
  injects `req.user = { id, role, email, departmentId }`. Dev mock-token path as in §4.
- `requireRole(...roles)`: HOF guard, 403 if `req.user.role` not in list.
- `validateBody(zodSchema)`: validates JSON body (skipped for multipart create).
- `upload` = Multer `dest ./Storage`, used as `upload.array('media', 5)`.
- JWT payload: `{ userId, role, email, departmentId }`. Access token TTL `JWT_ACCESS_EXPIRES_IN`
  (1h), refresh `JWT_REFRESH_EXPIRES_IN` (30d). Signed with `APP_JWT_SECRET`.

### 7.3 Auth routes — `/api/auth`
| Method | Path | Auth | Body | Returns |
|---|---|---|---|---|
| POST | `/google` | public | `{ idToken, fcmToken? }` | `{ accessToken, refreshToken, isNewUser, user{ id,email,name,picture,role,departmentId,zoneId } }` |
| POST | `/refresh` | public | `{ refreshToken }` | `{ accessToken, refreshToken }` (rotates refresh token) |
| GET | `/me` | bearer | — | `{ id,email,name,picture,role,departmentId,zoneId }` |
| POST | `/logout` | bearer | `{ refreshToken }` | `{ message }` (revokes refresh token, clears fcmToken) |

`/google` behavior: verify Google ID token via `google-auth-library`, require `email_verified` and
allowed domain (`rvce.edu.in` ∪ `allowed_domains` table) — else 403 (`DOMAIN_NOT_ALLOWED` /
`EMAIL_NOT_VERIFIED`). Create or update the user, store refresh token row, return tokens + profile.
If `isApproved=false` → 403.

### 7.4 Complaints routes — `/api/complaints` (all require bearer; router-level `authenticate`)
| Method | Path | Role | Body / Query | Returns |
|---|---|---|---|---|
| GET | `/my` | any | query: `page`(default 0), `limit`/`size`(default 10), `status?` | `{ complaints[], pagination{ page,limit,total,totalPages } }`. Role-scoped: USER→own, STAFF→assigned, ADMIN/DEPT_HEAD→all |
| GET | `/` | any | query: `page`,`limit`/`size`,`status?`,`departmentId?`,`categoryId?`,`severity?`,`q?`(text search title/description/complaintNumber),`scope?` | same paginated shape. `scope=all` bypasses role-scoping → system-wide read-only feed |
| GET | `/:id` | any | — | enriched complaint (incl. `submittedBy`, `mediaItems`, `updates` desc) |
| POST | `/` | any | **multipart/form-data** (see §7.5) | created complaint, status 201 |
| PATCH | `/:id/status` | assigned staff or ADMIN | `{ status: ASSIGNED\|IN_PROGRESS\|RESOLVED\|CLOSED\|REJECTED, notes? }` | updated complaint; logs timeline; notifies submitter |
| PATCH | `/:id/assign` | ADMIN, DEPT_HEAD | `{ assignedToId: uuid }` | sets `assignedToId`, status→`ASSIGNED`; notifies staff+submitter (assignee must be STAFF/ADMIN) |
| POST | `/:id/rating` | submitter only | `{ rating: 1..5, ratingComment? }` | sets rating, status→`CLOSED`; only if currently `RESOLVED` |
| PATCH | `/:id` | submitter only | any of `{ title?, description?, location?, categoryId?, severity?, tags?[] }` (≥1) | edits own complaint; re-resolves dept if category changes; refreshes embedding if description changes |
| DELETE | `/:id` | submitter only | — | `{ id, deleted:true }`; deletes media + updates + votes + comments + complaint in a txn |
| POST | `/:id/vote` | any (not own) | — | toggles caller's "Me too"; `{ voted: bool, meTooCount: int }` |
| GET | `/:id/comments` | any | query: `page?`,`size?` | `{ comments:[{id,authorId,authorName,authorPicture,authorRole,body,parentId,createdAt}], pagination }` |
| POST | `/:id/comments` | any | `{ body (1..500), parentId? }` | created comment; notifies submitter (FCM `COMMENT`) unless author is submitter |
| DELETE | `/:id/comments/:commentId` | comment author or ADMIN | — | `{ id, deleted:true }` |

### 7.5 Create-complaint multipart contract (important field-name gotchas)
`POST /api/complaints`, `Content-Type: multipart/form-data`, files under field **`media`** (max 5):
- Text fields: `title` (**not** `subject`), `description`, `location`, `categoryId`, `severity`
  (`LOW|MEDIUM|HIGH`), optional `departmentId` (resolved from category default if omitted),
  optional `gpsLatitude`, `gpsLongitude`, `gpsPlaceName`.
- `tags`: a **JSON-encoded string** (server `JSON.parse`s it, falling back to CSV).
- Files: field name **`media`**, images ≤ canonical limit, videos ≤ canonical limit (see §14).
- Side effects: generates `complaintNumber`, creates `MediaItem` rows (server marks
  `isWatermarked=true`), logs initial timeline entry, **fires `POST {AI}/embed` in the background**
  (non-blocking), notifies all SRs with FCM tokens.

### 7.5.1 Engagement endpoints — "Me too" & comments (NEW)
Implements the social-design features (§17). All require bearer auth; available to every role on
any complaint they can read (the feed is system-wide read-only).
- **`POST /api/complaints/:id/vote`** — toggles the caller's "Me too". If a `complaint_votes` row
  exists for `(id, req.user.id)` it's deleted (un-vote); otherwise it's created. Submitters cannot
  "Me too" their own complaint (no-op/400). Returns `{ voted, meTooCount }`. (Optionally notify the
  submitter on the first vote — keep it quiet by default to avoid noise.)
- **`GET /api/complaints/:id/comments`** — newest-first list, each enriched with author
  `name`/`picture`/`role` (never email). Supports `parentId` for one level of replies; render as a
  flat thread with indented replies. Paginated (`page`,`size`, default size 20).
- **`POST /api/complaints/:id/comments`** — body `{ body (1–500 chars), parentId? }`. Creates the
  comment and FCM-notifies the complaint submitter (`type: COMMENT`) unless the author *is* the
  submitter.
- **`DELETE /api/complaints/:id/comments/:commentId`** — only the comment's author or an admin.

> These endpoints go through `enrichComplaints`-style joins for author display fields, and the
> complaint detail/list payloads include `meTooCount`, `commentCount`, `hasVoted` (§6.2 note).

### 7.6 SR routes — `/api/sr` (router guards: `authenticate` + `requireRole('ROLE_SR')`)
| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/pending` | — | array of enriched `PENDING_SR_REVIEW` complaints (desc) |
| POST | `/:id/approve` | `{ departmentId?, categoryId?, severity? }` | status→`OPEN`, sets `slaDeadline`; optional overrides; notifies submitter |
| POST | `/:id/reject` | `{ rejectionCause }` (min 3 chars) | status→`REJECTED`, stores cause; notifies submitter |

### 7.7 Analytics routes — `/api/analytics` (bearer; any role — read-only system-wide)
| Method | Path | Returns |
|---|---|---|
| GET | `/summary` | `{ totalComplaints, activeComplaints, resolvedComplaints, slaBreachedCount, averageResolutionTimeHours, departmentStats[{departmentId,departmentName,count}], categoryStats[{categoryId,categoryName,count}], recentSlaBreaches[ enriched complaints, last 7 days, max 10, submitter name/picture only — no email ] }` |

> Only `/summary` exists. The Flutter `api_constants.dart` references `/analytics/by-department`,
> `/analytics/by-category`, `/analytics/sla-breaches` — **these are not implemented** (see §16).
> The rebuild should either implement them or drop the constants; `/summary` already carries the
> department/category distributions and recent breaches.

### 7.8 AI proxy routes — `/api/ai` (bearer)
| Method | Path | Body | Returns (proxied from Python, safe-defaulted) |
|---|---|---|---|
| POST | `/grammar-check` | `{ text }` | `{ hasCorrections, correctedText, diffs[] }` |
| POST | `/categorize` | `{ text }` | `{ suggestedCategory, suggestedSeverity, confidenceScore, reasoning }` (see §16 field-shape note) |
| POST | `/check-duplicate` | `{ text, zoneId? }` | `{ isDuplicate, similarCount, topMatch, allMatches[] }` |

Implemented in `services/aiProxy.js` (axios, baseURL `AI_SERVICE_URL`, **5s timeout**). On any
failure each returns safe defaults (so the endpoint never 500s on AI outage). There is also an
internal `generateAndStoreEmbedding(text, complaintId)` → `POST {AI}/embed` used by create/edit.

### 7.9 Reference-data & user routes
| Method | Path | Role | Returns |
|---|---|---|---|
| GET | `/api/departments` | bearer | list of departments |
| GET | `/api/categories` | bearer | list of categories |
| GET | `/api/tags` | bearer | list of tags |
| GET | `/api/zones` | bearer | list of zones |
| GET | `/api/users?role=ROLE_STAFF` | ADMIN, DEPT_HEAD | `{ users:[{ id,name,email,picture,role,departmentId,departmentName,createdAt,lastLogin }] }` |
| PATCH | `/api/users/fcm-token` | bearer | `{ fcmToken: string\|null }` → `{ message }` |

> Reference-list endpoints return a **raw array** as the `data` payload (Flutter reads
> `response.data as List`). Keep them simple `GET` lists ordered sensibly.

### 7.10 `enrichComplaints` helper
Any complaint-listing/detail response is passed through `utils/enrichComplaints.js`, which joins
category/department/assignee and flattens media to populate the denormalized display fields the
Flutter model expects: `categoryName`, `departmentName`, `submittedByName`, `assignedToName`,
`photoUrls`, plus the engagement fields `meTooCount`, `commentCount`, `hasVoted` (§6.2 note).
**Every new complaint-returning endpoint must enrich** rather than return raw Prisma rows.

---

## 8. Python AI Service Reference (FastAPI)

App: `main.py`, title "SCMS AI Service" v1.0.0, `docs_url=/docs`, `redoc_url=/redoc`, CORS
`allow_origins=["*"]` (restrict to backend in prod). Mounts 4 routers + `/health`. On startup runs
`ensure_embedding_column()` (idempotent, non-fatal if DB down). Listens on `PORT` (default 8000).
**Called only by the Node backend.**

**Fail-safe rule:** every endpoint returns HTTP 200 with safe defaults on Gemini/DB failure —
never 4xx/5xx for operational errors.

### 8.1 Endpoints
| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/health` | — | `{ status:"ok", service:"scms-ai-service", version:"1.0.0" }` |
| POST | `/grammar-check` | `{ text }` | `{ hasCorrections: bool, correctedText: str, diffs: [{type, text}] }` — default: `{false, <original>, []}` |
| POST | `/categorize` | `{ text }` | `{ suggestedCategoryId, suggestedCategoryName, suggestedDepartmentId, suggestedSeverity(HIGH/MEDIUM/LOW), confidenceScore(0..1), reasoning }` — default on empty/fail: category `Other`, severity `MEDIUM`, confidence `0.0` |
| POST | `/embed` | `{ text, complaintId }` | `{ success: bool, dimensions: int }` — stores 768-d vector into `complaints.embedding` |
| POST | `/check-duplicate` | `{ text, zoneId?, tags?[] }` | `{ isDuplicate, similarCount, topMatch{id,complaintNumber,title,status,score}\|null, allMatches[], groupId\|null }` — default: not duplicate |

### 8.2 Gemini integration (`services/gemini_client.py`)
- SDK: `from google import genai` (`google-genai`). Client built once from `GEMINI_API_KEY`.
- **Text model:** `GEMINI_TEXT_MODEL` (default & canonical **`gemini-2.5-flash`**), called with
  `response_mime_type="application/json"`. Used for grammar + categorize.
- **Embedding model:** `GEMINI_EMBED_MODEL` (default **`models/gemini-embedding-004`**),
  `task_type="SEMANTIC_SIMILARITY"`, **768-dimensional** output.
- JSON parsing strips ```` ```json ```` fences before `json.loads`.
- **Dev mock mode:** if `GEMINI_API_KEY` is empty, grammar/categorize use small keyword heuristics
  and embed returns a constant `[0.1]*768` vector — so the service runs offline for local dev.

**Grammar prompt (verbatim intent):** "grammar correction assistant for complaint submissions at an
engineering college. Correct ONLY grammar and spelling errors. Do NOT change meaning, add info, or
alter technical terms. Return ONLY valid JSON `{"correctedText":"...","hasCorrections":true}`."

**Categorize prompt:** given the fixed category list, return JSON
`{suggestedCategory, suggestedSeverity(HIGH|MEDIUM|LOW), confidenceScore(0..1), reasoning}`.
Severity guide: HIGH = safety hazard / affects many / urgent infra failure; MEDIUM = inconvenient,
routine maintenance; LOW = minor cosmetic/non-urgent. Returned category is validated against the
known list (falls back to `Other`).

### 8.3 DB / pgvector (`services/db_client.py`)
- `psycopg2.pool.ThreadedConnectionPool(min=1,max=5)`, lazy init from `DATABASE_URL`;
  `register_vector(conn)` per connection enables the `<=>` operator and list↔vector conversion.
- `ensure_embedding_column()`: `CREATE EXTENSION IF NOT EXISTS vector;` +
  `ALTER TABLE complaints ADD COLUMN IF NOT EXISTS embedding vector(768);`
- `store_embedding(id, vec)`: `UPDATE complaints SET embedding = %s::vector WHERE id=%s`.
- `find_similar_complaints(vec, zoneId?, limit=5)`: cosine similarity
  `1 - (embedding <=> query::vector) AS score`, filtering `embedding IS NOT NULL` and
  `status NOT IN ('RESOLVED','CLOSED','REJECTED')` (and `"zoneId" = ...` when provided), order by
  score desc, then keep rows with `score >= SIMILARITY_THRESHOLD` (default **0.75**), score rounded
  to 4 decimals.
- `get_duplicate_group_id(id)`: returns `duplicateGroupId` of the top match (for grouping).

### 8.4 Category → Department canonical map (used by categorize)
| Category | Default department |
|---|---|
| Electrical | Electrical Department |
| Plumbing | Civil & Maintenance Department |
| Civil | Civil & Maintenance Department |
| IT/Network | IT Department |
| Housekeeping | Housekeeping Department |
| Security | Security Department |
| Mess/Cafeteria | Mess Committee |
| Transport | Transport Department |
| Library | Library Department |
| Sports | Sports Department |
| Other | Administration |

> **Canonical fix:** in the original, the categorize router returns *placeholder* IDs like
> `cat-electrical`/`dept-admin` that don't match the real seeded UUIDs (see §16). In the rebuild,
> the categorize endpoint should look up real category/department IDs from the DB (or the backend
> should map the returned **name** to its own IDs), so suggestions are directly usable.

---

## 9. Flutter App Reference

Clean-architecture-ish layering under `lib/`:
`core/` (constants, theme, network, errors, utils) · `data/` (models, datasources remote+local,
repositories) · `domain/` (entities, usecases) · `presentation/` (bloc, pages) · `services/`.
DI/wiring in `main.dart` (Firebase init → repositories via `MultiRepositoryProvider` → BLoCs via
`MultiBlocProvider`, global `navigatorKey` for notification deep-links).

### 9.1 Screens (by role/flow — describe function, not visuals)
**Auth/onboarding:** `SplashPage` (init Firebase/notifications, check auth, min 2s),
`OnboardingPage` (first-run intro), `LoginPage` (Google sign-in restricted to `rvce.edu.in`; dev
mock sign-in).

**Student flow:** Student dashboard (quick actions, recent complaints, SLA overview);
`SubmitComplaintPage` (title/description/location/category/severity, photos+video with GPS
watermark; live debounced grammar check + AI categorize; duplicate warning before submit);
`MyComplaintsPage` (own list with status filter); `ComplaintDetailPage` (timeline, status, SLA
badge, assigned info); `DuplicateComplaintsPage` (AI-detected similar list); `RatingPage`
(1–5 + comment, post-resolution).

**Staff flow:** Staff dashboard (assigned workload, SLA breaches); `StaffComplaintDetailPage`
(status-update UI + notes).

**SR flow:** SR dashboard (pending-approval queue); `SrReviewDetailPage` (approve / reject with
cause).

**Admin flow:** Admin dashboard (system metrics, distributions, controls); assignment picker
(lists staff via `/users?role=ROLE_STAFF`).

**Shared (all roles, via `MainShell` bottom-nav tabs):** tab 0 = role dashboard, tab 1 =
`AllComplaintsPage` (global read-only feed with status/department/category/severity facets +
search, paginated, `scope=all`), tab 2 = `StatsPage` (charts from `/analytics/summary`), tab 3 =
`ProfilePage`. Plus `SettingsPage` (theme, notifications, offline toggle).

`MainShell` builds tabs lazily and keeps them alive; the dashboard tab cache is invalidated if the
auth role changes.

### 9.2 Routing (`go_router` in `app.dart` + `route_helpers.dart`)
Route constants (`core/constants/route_constants.dart`):
```
/                         splash
/login                    login
/onboarding               onboarding
/home/user                MainShell (student)
/home/staff               MainShell (staff)
/home/sr                  MainShell (SR)
/home/admin               MainShell (admin)
/complaint/submit         submit
/complaint/:id            detail
/complaint/:id/duplicates duplicates
/complaint/:id/rate       rating
/complaints/all           all-complaints feed   (query: status, categoryName)
/complaints/mine          my-complaints
/stats                    stats
/sr/review/:id            SR review detail
/staff/complaint/:id      staff complaint detail
/settings                 settings
```
**Redirect logic:** while `AuthInitial`/`AuthLoading` → no redirect. If not logged in and not on an
auth page (`/`, `/login`, `/onboarding`) → `/login`. If logged in and on an auth page → role home
(`_getRoleHome(role)`). `GoRouterRefreshStream` listens to `AuthBloc` so redirects re-run on auth
changes.

### 9.3 State management (BLoC/Cubit, `presentation/bloc/`)
- **AuthBloc** — events: `AppStarted`, `GoogleSignInRequested`, `LogoutRequested`,
  `TokenRefreshRequested`, mock sign-in. States: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`
  (`user`), `AuthUnauthenticated` (`showOnboarding?`), `AuthFailure`.
- **ComplaintBloc** — load my/all complaints, detail, filter, refresh. States: initial/loading/
  myLoaded/detailLoaded/allLoaded/error.
- **AllComplaintsCubit** — immutable query state (status/dept/category/severity/search) + pagination
  (`hasMore`) + active-facet count.
- **SubmitComplaintCubit** — form state + live AI results (`grammarResult`, `aiPreview`,
  `duplicateResult`) with per-call loading flags; draft save/restore; `copyWith` immutability;
  debounces grammar 800ms / search 500ms.
- **SrReviewBloc** — load/refresh pending; approve/reject (tracks `processingId`, `actionError`).
- **AnalyticsCubit** — loads `AnalyticsModel`; initial/loading/empty/loaded/error.
- **EngagementCubit** (NEW) — per-complaint "Me too" + comments: `toggleVote` (optimistic update of
  `hasVoted`/`meTooCount`), `loadComments` (paginated), `addComment`, `deleteComment`. Used on the
  feed card and complaint detail page.

### 9.4 Data models (JSON contracts, `data/models/`)
Models mirror backend payloads (post-unwrap). Notable: **`ComplaintModel`** maps backend `title`
↔ model `subject` (reads `subject` then falls back to `title`); fields include
`complaintNumber, description, location, gps*, categoryId/Name, departmentId/Name, severity, status,
tags[], submittedById/Name, assignedToId/Name, reviewedBySrId, srRejectionCause, photoUrls[]
(from mediaItems[].url), createdAt, updatedAt, slaDeadline, isSlaBreached, isGrammarCorrected,
isAiCategorized, aiConfidenceScore, duplicateGroupId, rating, ratingComment, updates[]`. Helpers:
`canRate` (RESOLVED & unrated), `isSlaActive`. `ComplaintModel` also carries the engagement fields
`meTooCount`, `commentCount`, `hasVoted` (NEW). Other models: `UserModel`, `CategoryModel`,
`DepartmentModel`, `ComplaintUpdateModel`, `RatingModel`, `DuplicateCheckModel`,
`GrammarCorrectionModel`, `SrReviewModel`, `AnalyticsModel`, and **`CommentModel`** (NEW —
`id, complaintId, authorId, authorName, authorPicture, authorRole, body, parentId?, createdAt`).

### 9.5 Network layer (`core/network/dio_client.dart`)
- Base `API_BASE_URL` + `/api`; connect 10s, receive 30s; JSON default header.
- **_AuthInterceptor:** attaches `Authorization: Bearer <access>` (except `/auth/google`); on 401,
  reads refresh token from secure storage, `POST /auth/refresh`, updates access token, retries; on
  refresh failure clears tokens and throws `TokenExpiredException`.
- **_UnwrapInterceptor:** strips `{success, data}` → returns `data` (so models never see the
  envelope).
- **_LoggingInterceptor:** debug logging.

### 9.6 Services (`lib/services/`)
- **NotificationService** — FCM init + local notifications + in-app banner overlay; deep-link nav
  using global `navigatorKey` (payload `type` ∈ ESCALATION/STATUS_UPDATE/ASSIGNED/SLA_BREACHED/
  COMMENT, `complaintId`).
- **CameraService** — permissions + capture/pick photo & video (`image_picker`/`camera`).
- **WatermarkService** — stamps GPS + datetime onto a photo (CustomPainter / `image`) before upload.
- **LocationService** — current GPS (`geolocator`) + reverse-geocode to place name (`geocoding`).
- **GrammarService** — calls `/ai/grammar-check`; skips if text shorter than threshold.
- **StorageService** — Hive offline drafts in box `drafts` (hand-written `TypeAdapter`s).
- **AnalyticsService** — Firebase Analytics event/screen logging.

### 9.7 Offline & secure storage
- Offline drafts: Hive box `drafts`; `ComplaintRepository` falls back to a saved draft when offline.
- Tokens/user in `FlutterSecureStorage` keys: `access_token`, `refresh_token`, `user_data`,
  `onboarding_complete`.

---

## 10. Background Jobs (node-cron, started in `server.js`)
| Job | Schedule (cron) | Action |
|---|---|---|
| **slaScheduler** | `*/15 * * * *` (every 15 min) | Find active complaints (`status NOT IN RESOLVED/CLOSED/REJECTED`) with `slaDeadline <= now` and `isSlaBreached=false`; set `isSlaBreached=true`; log a `SYSTEM` timeline entry; FCM-notify admins + assigned staff |
| **srAutoApprove** | `0 * * * *` (hourly) | Find `PENDING_SR_REVIEW` older than 24h; set `OPEN` + `slaDeadline`; log `SYSTEM` entry; notify submitter |

Both bootstrap after `prisma.$connect()` succeeds.

---

## 11. Cross-cutting Integrations

**Google OAuth (auth):** Flutter `google_sign_in` restricted to `rvce.edu.in` → obtains Google ID
token → `POST /api/auth/google` → backend verifies with `google-auth-library` (checks
`email_verified` + allowed domain) → issues app JWTs. `GOOGLE_CLIENT_ID` (backend, must match the
Google Cloud OAuth Web Client) and `GOOGLE_SERVER_CLIENT_ID` (Flutter) must be the same web client.

**JWT:** access + refresh, `ROLE_*` in payload, refresh tokens persisted in `refresh_tokens` and
rotated on use; logout deletes the row and clears `fcmToken`.

**FCM (push):** `firebase-admin` (`services/fcm.js`) sends `{notification:{title,body}, data:{...}}`
(data stringified). Requires `FIREBASE_SERVICE_ACCOUNT_PATH`; if the file is missing it runs in a
**mock mode** (logs instead of sending) so the backend still boots. Notification triggers: new
complaint→SRs, approve/reject/assign/status→submitter, assign→staff, SLA breach→admins+staff.

**Media storage:** Multer writes uploads to `./Storage`; served statically at `/Storage/<file>`;
`MediaItem.url` stores that path. `helmet` is configured with
`crossOriginResourcePolicy:false` so the app can load these assets.

---

## 12. Configuration & Environment (REAL values from the project)

> ⚠️ **Secrets included as requested.** These are the actual values from the project's `.env`
> files. **Do not commit this file to a public repo, and rotate the Gemini key / OAuth client and
> DB password before any real deployment.**

### 12.1 Backend `scms_backend/.env`
```
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://postgres:2004@localhost:5432/postgres
APP_JWT_SECRET=your_super_secret_jwt_key_here          # CHANGE for prod — currently a placeholder
JWT_ACCESS_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=30d
GOOGLE_CLIENT_ID=xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com  # placeholder in .env; use the real Web Client ID (same as Flutter's GOOGLE_SERVER_CLIENT_ID)
ALLOWED_DOMAINS=rvce.edu.in
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
AI_SERVICE_URL=http://localhost:8000
FIREBASE_STORAGE_BUCKET=scms-campus-app.appspot.com
```

### 12.2 AI service `scms_ai_service/.env`
```
GEMINI_API_KEY=AIzaSyDXCNL9G6reLtnX8AA8NpEfmI4Pzffo6y0   # REAL key — rotate before sharing
GEMINI_TEXT_MODEL=gemini-2.5-flash                       # gemini-2.0-flash had 0 free-tier quota on this project
# GEMINI_EMBED_MODEL defaults to models/gemini-embedding-004 (768-d) if unset
DATABASE_URL=postgresql://postgres:2004@localhost:5432/postgres
SIMILARITY_THRESHOLD=0.75
PORT=8000
```

### 12.3 Flutter `scms_flutter/.env` (bundled as an asset)
```
API_BASE_URL=http://localhost:3000
GOOGLE_SERVER_CLIENT_ID=182336575222-252rq8mp7br1178te3ugao4radr2onnv.apps.googleusercontent.com
FIREBASE_PROJECT_ID=scms-campus-app
```
> For a physical device/emulator, set `API_BASE_URL` to the host machine's LAN IP (e.g.
> `http://192.168.1.100:3000`), not `localhost`.

### 12.4 Ports / URLs summary
| Service | URL/Port | Env var |
|---|---|---|
| Backend API | `http://localhost:3000` (+`/api`) | `PORT`, Flutter `API_BASE_URL` |
| AI service | `http://localhost:8000` | `PORT`, backend `AI_SERVICE_URL` |
| PostgreSQL (+pgvector) | `localhost:5432` | `DATABASE_URL` |
| Static media | `http://localhost:3000/Storage/<file>` | — |
| AI docs (dev) | `http://localhost:8000/docs` | — |

### 12.5 `docker-compose.yml` (repo root)
- `postgres`: image `pgvector/pgvector:pg16`, env `POSTGRES_USER=scms_user` /
  `POSTGRES_PASSWORD=scms_pass` / `POSTGRES_DB=scms_db`, port `5432`, volume `pgdata`.
- `backend`: builds `./scms_backend`, port 3000, `env_file ./scms_backend/.env`, depends on postgres.
- `ai_service`: builds `./scms_ai_service`, port 8000, `env_file ./scms_ai_service/.env`.
> Note: compose's Postgres creds (`scms_user/scms_pass/scms_db`) differ from the `.env`
> `DATABASE_URL` (`postgres:2004@.../postgres`). Pick ONE for the rebuild and make compose + both
> `.env` files agree (see §16).

---

## 13. Reference / Seed Data (`prisma/seed.js`)

**Allowed domain:** `rvce.edu.in`.

**Departments** (`name`, `code`) — 10:
EE→Electrical Department · CIVIL→Civil & Maintenance Department · IT→IT Department ·
HK→Housekeeping Department · SEC→Security Department · MESS→Mess Committee ·
TRANS→Transport Department · LIB→Library Department · SPORTS→Sports Department ·
ADMIN→Administration.

**Categories** (`name` → default department) — 11:
Electrical→Electrical Dept · Plumbing→Civil & Maintenance · Civil→Civil & Maintenance ·
IT/Network→IT · Housekeeping→Housekeeping · Security→Security · Mess/Cafeteria→Mess Committee ·
Transport→Transport · Library→Library · Sports→Sports · Other→Administration.
(`iconName` = lowercased category name.)

**Zones** — Hostel Block A, Hostel Block B, Main Academic Block, MCA Department Block,
Library Building, Sports Complex.

**Tags** — Leakage, Broken, PowerOutage, Internet, Cleanliness, Safety, Noise, Hardware,
Software, Furniture, Light, Water, Fan, AC.

**Demo users** (`prisma/seed_sample_data.js`, dev only): `demo.user@rvce.edu.in` (ROLE_USER),
`demo.sr@rvce.edu.in` (ROLE_SR), `demo.staff@rvce.edu.in` (ROLE_STAFF, EE dept),
`demo.admin@rvce.edu.in` (ROLE_ADMIN), plus sample complaints.

---

## 14. App-wide Constants (canonical, from Flutter `app_constants.dart`)

- **SLA (canonical, severity-based):** HIGH 4h · MEDIUM 24h · LOW 72h. Progress UI: >50% time left
  = green, 20–50% = orange, <20% = red.
- **Complaint form limits (canonical):** max **3** photos · photo ≤ **5 MB** · video ≤ **30 MB** ·
  description 20–500 chars · subject/title 5–100 chars. (The backend currently enforces image
  ≤10 MB / video ≤100 MB and `media` array max 5 — align the server to these client limits, or
  vice-versa; see §16.)
- **AI:** grammar debounce 800ms · search debounce 500ms · min chars for grammar 30 · min chars for
  categorize 20 · high confidence ≥0.80 · medium ≥0.60 · `SIMILARITY_THRESHOLD` 0.75.
- **Engagement (NEW):** comment body 1–500 chars · comments page size 20 · "Me too" is a one-per-user
  toggle · counts shown abbreviated (e.g. 1.2k).
- **Pagination:** default page size 10 · max 50. (Feed list uses size 20.)
- **Timeouts:** connect 10s · receive 30s · AI 5s.
- **Misc:** allowed domain `rvce.edu.in` · splash min 2000ms · notification banner 4s.
- **Storage keys:** Hive box `drafts`; secure-storage `access_token`, `refresh_token`, `user_data`,
  `onboarding_complete`.

---

## 15. Build & Run Order (local, end-to-end)

1. **Database:** `docker-compose up postgres -d` (pgvector image). Ensure `DATABASE_URL` matches
   the compose creds you settle on (§16).
2. **Backend:** `cd scms_backend && npm install && cp .env.example .env` (fill values) →
   `npx prisma migrate dev` → `node prisma/seed.js` (+ `node prisma/seed_sample_data.js` for demo) →
   `npm run dev` (`:3000`). Verify: `GET http://localhost:3000/api/departments` (with a dev mock or
   real token) returns the seeded list.
3. **AI service:** `cd scms_ai_service && python -m venv venv && venv\Scripts\activate &&
   pip install -r requirements.txt && cp .env.example .env` (set real `GEMINI_API_KEY`) →
   `uvicorn main:app --reload --port 8000`. Verify: `GET http://localhost:8000/health` →
   `{status:"ok"}`; `/docs` lists the 4 endpoints.
4. **Flutter:** `cd scms_flutter && flutter pub get` → set `.env` (`API_BASE_URL` reachable from the
   device) → `flutter run`. Sanity: `flutter analyze` should report no issues; `flutter build apk
   --debug` builds.
5. **End-to-end smoke test:** sign in with an `@rvce.edu.in` Google account → submit a complaint
   with a photo → confirm it appears in SR pending queue → approve → assign → resolve → rate →
   closed. Confirm grammar/categorize/duplicate calls return (or safe-default) and an `embedding`
   row is written (`SELECT id FROM complaints WHERE embedding IS NOT NULL`).

**Verification tooling:** backend has no automated tests — verify via the app/curl/Postman. AI
service has no tests — verify via `/docs`. Flutter has widget/bloc tests (`flutter test`).

---

## 16. Canonical Decisions & Resolved Inconsistencies

The original code disagreed with itself in the following places. The rebuild adopts the
**Resolution** column everywhere.

| # | Inconsistency (as found) | Resolution for rebuild |
|---|---|---|
| 1 | **SLA timing.** Flutter constants = severity-based 4/24/72h; backend `sr.approve` & `srAutoApprove` set a flat **48h**. | Use **severity-based 4/24/72h**, computed when the complaint becomes `OPEN`. Update both the SR-approve path and the auto-approve cron to use it. |
| 2 | **Embedding model.** `db_client.py` docstring says `gemini-embedding-001`; `gemini_client.py` uses `models/gemini-embedding-004`; CLAUDE.md mentioned `gemini-2.0-flash`. | **`models/gemini-embedding-004`, 768-d.** Fix docstrings to match. |
| 3 | **Text model.** `gemini_client.py` docstring says `gemini-2.0-flash`; default + `.env` = `gemini-2.5-flash`. | **`gemini-2.5-flash`** (2.0-flash had no free-tier quota on this project). |
| 4 | **Analytics endpoints.** Flutter `api_constants` references `/analytics/by-department`, `/by-category`, `/sla-breaches`; backend only implements `/analytics/summary`. | Treat **`/summary` as the source of truth** (it already returns department/category stats + recent breaches). Either drop the unused constants or implement the extra endpoints. |
| 5 | **Auth/complaints constants.** Flutter references `/auth/allowed-domains` and `/complaints/ai-preview` that the backend does not implement (the AI preview actually calls `/ai/categorize`). | Drop `/auth/allowed-domains` and `/complaints/ai-preview`; AI preview = `POST /ai/categorize`. |
| 6 | **Duplicate query column.** `db_client.find_similar_complaints` filters `complaints."zoneId"`, but `Complaint` has **no `zoneId`** in the Prisma schema → zone-scoped query would error. | **Add `zoneId String?` to `Complaint`** (and set it on create from the user's zone or a form field). Then zone filtering works. |
| 7 | **Categorize returns fake IDs.** `routers/categorize.py` returns placeholder IDs (`cat-electrical`, `dept-admin`) that don't match seeded UUIDs. | Look up **real IDs from the DB** (or have the backend map the returned category **name** → its own IDs). Suggestions must be directly usable by the client. |
| 8 | **AI categorize response shape mismatch.** Python returns `suggestedCategoryName/Id/DepartmentId`; the Node `aiProxy.categorize` *safe default* returns `suggestedCategory` (name only). | Standardize on the Python shape (`suggestedCategoryId`, `suggestedCategoryName`, `suggestedDepartmentId`, `suggestedSeverity`, `confidenceScore`, `reasoning`); make the Node safe-default match it. |
| 9 | **Media size limits.** Backend enforces image ≤10 MB / video ≤100 MB, array max 5; Flutter constants say 3 photos, ≤5 MB, video ≤30 MB. | Adopt the **Flutter limits** (3 photos · 5 MB · 30 MB) as canonical and enforce them on **both** client and server. |
| 10 | **DB credentials differ.** `docker-compose` uses `scms_user/scms_pass/scms_db`; the real `.env` uses `postgres:2004@.../postgres`. | Pick one (recommend the compose creds `scms_user/scms_pass/scms_db`) and make compose + all `.env` files agree. |
| 11 | **`embedding` column not in Prisma schema.** It's created out-of-band by the Python service, so `prisma migrate` doesn't know about it. | Either add an unmanaged-column note, or declare it via raw SQL migration in Prisma, so the column's lifecycle is owned in one place (recommended: keep the Python `ensure_embedding_column` as the creator, document it as Prisma-ignored). |
| 12 | **Field naming.** Flutter model uses `subject`; backend uses `title`. Multipart file field is `media`; rating comment is `ratingComment`; status field is `status`. | Keep backend names authoritative (`title`, `media`, `status`, `ratingComment`); the client maps `subject`→`title`. Document at the boundary (done in §7.5). |

---

## 17. Design Guidelines — Material Design 3, "Social Feed for Complaints"

The app uses **Material Design 3 (Material You)** at **standard density**, **light theme by
default** with a user toggle to **dark** (and a "follow system" option). The product metaphor is a
**social feed, but for campus complaints**: each complaint is a "post" in a scrollable feed with an
author header, media, metadata chips, a status/SLA badge, and an **engagement bar** ("Me too"
upvote + comments + share). Build with Flutter's `useMaterial3: true` and an explicit
`ColorScheme` (tokens below) — do **not** auto-generate from a single seed, since the light scheme
is hand-tuned.

### 17.1 Design principles
1. **Feed-first.** The home/dashboard and the global "All" tab are vertical card feeds. Reading a
   complaint feels like reading a social post; acting on it (Me too / comment) is one tap away.
2. **Status is always legible.** Every complaint surface shows a colored **status pill** and, when
   open, an **SLA badge** (countdown or breach). Color encodes urgency consistently everywhere.
3. **Calm, tonal, MD3.** Use tonal surface containers for elevation (not heavy shadows). Rounded
   shapes, generous spacing, large tap targets.
4. **Privacy-aware social.** Show author **name + avatar + role**, never email. Aggregated/feed
   contexts never leak contact info.
5. **AI is ambient, not blocking.** Grammar/category/duplicate hints appear as gentle inline chips
   and banners in the composer — never modal gates.

### 17.2 Color system — LIGHT (default, hand-tuned, authoritative)
Apply these exactly to the Flutter light `ColorScheme` (MD3 roles). Seed/brand = **`#6750A4`**.

| Role | Hex | | Role | Hex |
|---|---|---|---|---|
| primary | `#6750A4` | | onPrimary | `#FFFFFF` |
| primaryContainer | `#B39DDB` | | onPrimaryContainer | `#5C488A` |
| primaryFixed | `#D0BCFF` | | primaryFixedDim | `#B39DDB` |
| onPrimaryFixed | `#21005D` | | onPrimaryFixedVariant | `#4F378B` |
| secondary | `#707084` | | onSecondary | `#FFFFFF` |
| secondaryContainer | `#CBC8DD` | | onSecondaryContainer | `#4B4B63` |
| secondaryFixed | `#D7D5E8` | | secondaryFixedDim | `#C5C4DA` |
| onSecondaryFixed | `#1D1B34` | | onSecondaryFixedVariant | `#47465C` |
| tertiary | `#86468C` | | onTertiary | `#FFFFFF` |
| tertiaryContainer | `#D9A0DF` | | onTertiaryContainer | `#713378` |
| tertiaryFixed | `#E3B1E8` | | tertiaryFixedDim | `#C88ACC` |
| onTertiaryFixed | `#4A0055` | | onTertiaryFixedVariant | `#7A397F` |
| error | `#BA1A1A` | | onError | `#FFFFFF` |
| errorContainer | `#F2D7D5` | | onErrorContainer | `#8C2D24` |
| surfaceDim | `#E5E0E8` | | surface | `#FEF7FF` |
| surfaceBright | `#FFFBFF` | | surfaceContainerLowest | `#FFFFFF` |
| surfaceContainerLow | `#F7F2FA` | | surfaceContainer | `#F2ECF4` |
| surfaceContainerHigh | `#ECE6EE` | | surfaceContainerHighest | `#E6E0E9` |
| onSurface | `#1D1B20` | | onSurfaceVariant | `#49454F` |
| outline | `#79747E` | | outlineVariant | `#CAC4D0` |
| inverseSurface | `#322F35` | | inverseOnSurface | `#F5EFF7` |
| inversePrimary | `#D0BCFF` | | scrim / shadow | `#000000` |

### 17.3 Color system — DARK (toggle; standard MD3 baseline for seed `#6750A4`)
Derived dark scheme that pairs with the light tokens. (If you later hand-tune a dark scheme,
override these — keep the role names.)

| Role | Hex | | Role | Hex |
|---|---|---|---|---|
| primary | `#D0BCFF` | | onPrimary | `#381E72` |
| primaryContainer | `#4F378B` | | onPrimaryContainer | `#EADDFF` |
| secondary | `#CCC2DC` | | onSecondary | `#332D41` |
| secondaryContainer | `#4A4458` | | onSecondaryContainer | `#E8DEF8` |
| tertiary | `#EFB8C8` | | onTertiary | `#492532` |
| tertiaryContainer | `#633B48` | | onTertiaryContainer | `#FFD8E4` |
| error | `#F2B8B5` | | onError | `#601410` |
| errorContainer | `#8C1D18` | | onErrorContainer | `#F9DEDC` |
| surfaceDim | `#141218` | | surface | `#141218` |
| surfaceBright | `#3B383E` | | surfaceContainerLowest | `#0F0D13` |
| surfaceContainerLow | `#1D1B20` | | surfaceContainer | `#211F26` |
| surfaceContainerHigh | `#2B2930` | | surfaceContainerHighest | `#36343B` |
| onSurface | `#E6E0E9` | | onSurfaceVariant | `#CAC4D0` |
| outline | `#938F99` | | outlineVariant | `#49454F` |
| inverseSurface | `#E6E0E9` | | inverseOnSurface | `#322F35` |
| inversePrimary | `#6750A4` | | scrim / shadow | `#000000` |

### 17.4 Semantic status colors (app-level extension, both themes)
MD3 has no "success/warning" role, so define a small `ThemeExtension` (`AppStatusColors`) and map
complaint status + SLA to it. Status pill = filled chip using the container/on-container pair:

| Meaning | Statuses | Light (bg / fg) | Dark (bg / fg) |
|---|---|---|---|
| Pending review | `PENDING_SR_REVIEW` | tertiaryContainer `#D9A0DF` / `#713378` | `#633B48`-tone / `#FFD8E4` |
| Active | `OPEN`, `ASSIGNED`, `IN_PROGRESS` | primaryContainer `#B39DDB` / `#5C488A` | `#4F378B` / `#EADDFF` |
| Success | `RESOLVED`, `CLOSED` | success `#B7E2C8` / `#0C5132` | `#1E4D34` / `#A6F4C5` |
| Negative | `REJECTED`, SLA breach | errorContainer `#F2D7D5` / `#8C2D24` | `#8C1D18` / `#F9DEDC` |

SLA badge color follows §14 thresholds: **green** >50% time left, **amber** 20–50%, **red** <20%;
**breached** = error. Severity dot/label: HIGH = error, MEDIUM = tertiary, LOW = secondary.

### 17.5 Typography
Use the **MD3 type scale**. Default font **Roboto** (MD3 baseline). For a slightly more "social"
feel you may use a `google_fonts` family for display/headlines (e.g. *Plus Jakarta Sans* or
*Inter*) with Roboto for body — keep body legible. Scale (sp / weight):

| Token | Size/Line | Weight | Used for |
|---|---|---|---|
| displaySmall | 36/44 | 400 | rare hero numbers (e.g. big stats) |
| headlineSmall | 24/32 | 400 | screen titles, empty-state headlines |
| titleLarge | 22/28 | 400 | app bar title |
| titleMedium | 16/24 | 500 | complaint card **title**, dialog titles |
| bodyLarge | 16/24 | 400 | complaint description, comment body |
| bodyMedium | 14/20 | 400 | secondary text, metadata |
| labelLarge | 14/20 | 500 | buttons, tab labels, "Me too" |
| labelMedium / labelSmall | 12/16 · 11/16 | 500 | chips, timestamps, counts |

### 17.6 Shape, elevation & spacing
- **Corner radius:** cards & sheets 16dp · chips/buttons full (stadium) or 8dp · text fields 12dp ·
  avatars full circle · media thumbnails 12dp · FAB 16dp.
- **Elevation = tonal.** Feed background `surface`; cards on `surfaceContainerLow`; app bar/bottom
  bar `surfaceContainer`; bottom sheets `surfaceContainerHigh`. Avoid heavy drop shadows.
- **Spacing scale:** 4 / 8 / 12 / 16 / 24 / 32. Card padding 16; gap between cards 8–12; screen
  horizontal padding 16.
- **Dividers:** `outlineVariant`, hairline; prefer spacing over rules where possible.

### 17.7 Theming & dark-mode mechanics (Flutter)
- `MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: <pref>)`.
- `themeMode` is persisted by `AppPreferences` (already exists): `system` / `light` / `dark`,
  default **light**. Toggle lives in **Settings** and is also reachable from **Profile**.
- Build each `ThemeData` with `useMaterial3: true`, the explicit `ColorScheme` from §17.2/§17.3,
  the `AppStatusColors` theme extension (§17.4), `textTheme` from §17.5, and `NavigationBarTheme` /
  `ChipTheme` / `CardTheme` aligned to the shapes above.

### 17.8 Navigation & compose pattern
- **Bottom navigation (`NavigationBar`, MD3) with a center-docked compose FAB.** 4 destinations
  split around a central **`+` FAB** that opens the Submit-complaint ("new post") flow. Use a
  `Scaffold` with `floatingActionButtonLocation: centerDocked` + a `BottomAppBar` notch, or a
  `NavigationBar` with the FAB floating centered — the docked center "+" is the signature
  social-compose affordance.
- **Tabs** (role-aware first tab via `MainShell`, §9.1):
  `[ Home/Feed ] [ All ] (＋) [ Stats ] [ Profile ]` — icons: `home`, `dynamic_feed`/`list_alt`,
  `bar_chart`, `person` (Material Symbols Rounded, outlined→filled on selection).
- **App bar:** small/center MD3 top app bar; on the feed it can be a pinned search/filter bar.
- **Compose FAB** is hidden for roles that don't submit (staff/SR/admin keep it only if you want
  them filing complaints too — default: visible to all, since anyone can submit).

### 17.9 Core components ("social feed for complaints")
Define these as reusable widgets:

1. **ComplaintFeedCard** (the "post") — on `surfaceContainerLow`, radius 16, padding 16:
   - **Header:** `CircleAvatar` (author `picture`, fallback initials) · author **name** ·
     small **role chip** · `time-ago` (e.g. "2h") · trailing overflow `⋮` menu (share, report,
     edit/delete if owner).
   - **Body:** **title** (`titleMedium`) + description excerpt (2–3 lines, `bodyMedium`,
     ellipsized).
   - **Media:** full-width preview — single image rounded 12dp; multiple → 2×2 grid / horizontal
     carousel with count badge; video → thumbnail with centered play overlay. Tap → fullscreen
     viewer (hero transition). Uses `cached_network_image` + shimmer placeholder.
   - **Meta chips row:** category, department, and **location/zone** as hashtag-like
     `assist`/`suggestion` chips; severity dot.
   - **Status & SLA:** status pill (§17.4) + SLA badge when open.
   - **EngagementBar** (below): see #2.
2. **EngagementBar** (NEW) — a row of text-buttons with leading icons + counts:
   - **Me too** — `thumb_up`/`group` icon; filled/primary when `hasVoted`, outlined otherwise;
     tapping calls `EngagementCubit.toggleVote` (optimistic). Shows `meTooCount` (abbreviated).
   - **Comment** — `mode_comment` icon + `commentCount`; opens the comments view.
   - **Share** — `share` icon; shares the complaint number/deeplink.
   - Disabled "Me too" with a tooltip on the user's own complaint.
3. **CommentsSection** — under the complaint detail (or a bottom sheet from the card):
   - **Comment tile:** avatar · name · role · `time-ago` · body (`bodyLarge`); one level of indented
     **replies** (`parentId`); owner/admin can delete via overflow.
   - **Composer:** sticky bottom `TextField` (outlined, radius 12, max 500 chars, counter) + send
     `IconButton`. Optimistic insert.
   - Empty state: friendly "Be the first to comment".
4. **StatusPill** & **SlaBadge** — small filled chips per §17.4.
5. **FilterBar / FilterSheet** — horizontally scrollable **filter chips** (status, department,
   category, severity) above the "All" feed, plus a bottom-sheet for advanced filters + search
   field (debounced 500ms). Active-facet count shown as a badge on a filter button.
6. **Composer screen (Submit = "new post")** — title + description fields; **media picker row**
   (camera/gallery, with GPS watermark applied); inline **AI affordances**: a dismissible
   *grammar-suggestion banner* (accept/ignore with `diff_match_patch` highlighting), an *AI category
   suggestion chip* (tap to apply, shows confidence), and a *duplicate-warning bottom sheet*
   listing similar complaints before submit; category/severity selectors; tag chips; location chip
   (auto-filled from GPS). Submit = primary `FilledButton`.
7. **Shared:** skeleton loaders (`shimmer`) for feeds; pull-to-refresh; `SnackBar` for confirms;
   MD3 `Dialog`/bottom sheets for actions; empty/error states with an illustration (`lottie`) +
   retry; `Badge` for unread notifications on the app bar.

### 17.10 Screen → component mapping
- **Home/Feed (per-role tab 0):** vertical list of `ComplaintFeedCard` (role-scoped) + header
  summary (student: my open/SLA; staff: assigned workload; SR: pending count; admin: KPIs).
- **All tab:** `FilterBar` + paginated `ComplaintFeedCard` feed (`scope=all`).
- **Complaint detail:** full card (no excerpt clamp) + status timeline (`ComplaintUpdate` list as a
  vertical stepper) + `EngagementBar` + `CommentsSection`; action buttons by role (staff: status
  update sheet; SR: approve/reject; admin: assign; submitter: edit/delete/rate).
- **Submit:** Composer screen (#6) opened by the center FAB.
- **Stats:** `fl_chart` cards (status distribution donut, by-department/category bars, SLA gauge)
  using scheme tones.
- **Profile/Settings:** avatar header, theme toggle (light/dark/system), notification toggle,
  logout.
- **SR review / Staff detail:** detail layout with a prominent action sheet/segmented buttons.

### 17.11 Iconography, motion, accessibility, imagery
- **Icons:** Material Symbols **Rounded** (outlined unselected → filled selected), matching the
  existing rounded icon usage.
- **Motion:** MD3 emphasized easing; shared-axis transitions between tabs; container-transform when
  a feed card opens into detail; hero on media; subtle scale/heart-fill animation on "Me too".
- **Accessibility:** all tokens meet MD3 contrast; min tap target 48×48dp; semantic labels on
  icon-only buttons (Me too/comment/share); respect text scaling; status conveyed by **label +
  color** (never color alone); dark mode fully supported.
- **Imagery:** user media is the hero; provide rounded avatars with initial fallbacks; use `lottie`
  only for empty/onboarding states; keep chrome minimal so complaint photos lead.

---

## 18. Quick Reference — Endpoint Index

```
AUTH        POST   /api/auth/google           public
            POST   /api/auth/refresh          public
            GET    /api/auth/me               bearer
            POST   /api/auth/logout           bearer
COMPLAINTS  GET    /api/complaints/my         bearer (role-scoped)
            GET    /api/complaints            bearer (scope=all for feed)
            GET    /api/complaints/:id        bearer
            POST   /api/complaints            bearer (multipart, field 'media')
            PATCH  /api/complaints/:id/status assigned-staff|admin
            PATCH  /api/complaints/:id/assign admin|dept_head
            POST   /api/complaints/:id/rating submitter (RESOLVED→CLOSED)
            PATCH  /api/complaints/:id        submitter
            DELETE /api/complaints/:id        submitter
ENGAGEMENT  POST   /api/complaints/:id/vote               bearer (toggle Me too)
            GET    /api/complaints/:id/comments           bearer
            POST   /api/complaints/:id/comments           bearer
            DELETE /api/complaints/:id/comments/:cid       author|admin
SR          GET    /api/sr/pending            ROLE_SR
            POST   /api/sr/:id/approve        ROLE_SR
            POST   /api/sr/:id/reject         ROLE_SR
ANALYTICS   GET    /api/analytics/summary     bearer
AI (proxy)  POST   /api/ai/grammar-check      bearer
            POST   /api/ai/categorize         bearer
            POST   /api/ai/check-duplicate    bearer
REF/USERS   GET    /api/departments|categories|tags|zones   bearer
            GET    /api/users?role=...        admin|dept_head
            PATCH  /api/users/fcm-token       bearer
AI SERVICE  GET    /health
            POST   /grammar-check
            POST   /categorize
            POST   /embed
            POST   /check-duplicate
```

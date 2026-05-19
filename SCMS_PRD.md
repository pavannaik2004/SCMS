# Product Requirements Document (PRD)
## Smart Complaint Management System (SCMS)
### Mobile Application — Flutter

---

**Document Version:** 3.0.0
**Previous Version:** 2.0.0 (Spring Boot + basic auth)
**Status:** Final — Ready for AI Agent Build
**Subject:** Mobile Application Development (MCA Program)
**Platform:** Flutter (Cross-platform — Android Primary)
**Backend:** Node.js + Express.js + Prisma
**Auth:** Google OAuth 2.0 (domain-restricted to @rvce.edu.in)
**AI:** Google Gemini 2.5 Flash + gemini-embedding-001 + Python AI microservice
**Database:** PostgreSQL + pgvector
**Team Size:** 4 Members
**Academic Level:** MCA II Semester

### Changelog v3.0.0
| Change | Section | Description |
|---|---|---|
| Backend replaced | §6, §7, §22 | Spring Boot → Node.js + Express.js + Prisma ORM |
| Auth replaced | §7, §12, §19 | Password auth → Google OAuth 2.0 with @rvce.edu.in domain restriction |
| Database updated | §7, §24 | MySQL → PostgreSQL + pgvector extension for embeddings |
| AI/NLP fully specified | §7, §16 | Gemini 2.5 Flash (grammar + categorization), gemini-embedding-001, Python cosine similarity |
| New Python AI service | §6, §7, §16 | Dedicated FastAPI microservice for all Gemini + embedding calls |
| .env updated | §21 | New env vars for Google OAuth, Gemini API, pgvector |

---

## Table of Contents

1. [Document Purpose & How to Use This PRD](#1-document-purpose--how-to-use-this-prd)
2. [Project Overview](#2-project-overview)
3. [Problem Statement & Motivation](#3-problem-statement--motivation)
4. [Goals & Success Metrics](#4-goals--success-metrics)
5. [Stakeholders & User Personas](#5-stakeholders--user-personas)
6. [System Architecture Overview](#6-system-architecture-overview)
7. [Tech Stack & Tooling](#7-tech-stack--tooling)
8. [Project Directory Structure](#8-project-directory-structure)
9. [Feature Catalog](#9-feature-catalog)
10. [Detailed Screen Specifications](#10-detailed-screen-specifications)
11. [Data Models](#11-data-models)
12. [API Contract](#12-api-contract)
13. [State Management Architecture](#13-state-management-architecture)
14. [Navigation Architecture](#14-navigation-architecture)
15. [UI/UX Design System](#15-uiux-design-system)
16. [AI/NLP Integration](#16-ainlp-integration)
17. [Notifications & Real-time Updates](#17-notifications--real-time-updates)
18. [Error Handling & Offline Strategy](#18-error-handling--offline-strategy)
19. [Security Requirements](#19-security-requirements)
20. [Testing Strategy](#20-testing-strategy)
21. [Build & Deployment](#21-build--deployment)
22. [Step-by-Step Implementation Plan for AI Agent](#22-step-by-step-implementation-plan-for-ai-agent)
23. [Acceptance Criteria & Definition of Done](#23-acceptance-criteria--definition-of-done)
24. [Appendix](#24-appendix)

---

## 1. Document Purpose & How to Use This PRD

### 1.1 Purpose

This PRD is the single source of truth for the Smart Complaint Management System (SCMS) mobile application. It is written to serve a **dual purpose**:

1. **As a standard PRD** — for developers, designers, and evaluators to understand what is being built and why.
2. **As an AI agent build prompt** — Section 22 provides a strict, sequenced step-by-step implementation plan that an AI coding agent (such as Claude Code, Cursor, or GitHub Copilot) can follow to produce the complete Flutter project from scratch.

### 1.2 How an AI Agent Should Use This Document

Read the entire document before writing a single line of code. Use the following order:

1. **Section 7** → Set up the tech stack and tooling.
2. **Section 8** → Scaffold the project directory exactly as specified.
3. **Section 11** → Define all data models first (Dart classes).
4. **Section 15** → Implement the Design System (theme, colors, typography).
5. **Section 14** → Set up navigation.
6. **Section 13** → Set up state management providers/blocs.
7. **Section 10** → Build screens one by one in the prescribed order.
8. **Section 12** → Wire up API calls.
9. **Section 16** → Integrate AI classification feature.
10. **Section 17** → Add push notifications.
11. **Section 20** → Write tests.

**Non-negotiable rules for the AI agent:**
- Never skip a section.
- If any ambiguity arises, default to the most explicit specification in this document.
- Preserve the folder structure exactly.
- All placeholder strings (API base URLs, Firebase config) must be placed in a `.env` or `constants.dart` file — never hardcoded inside widgets.

---

## 2. Project Overview

### 2.1 What Is SCMS?

The **Smart Complaint Management System (SCMS)** is a cross-platform mobile application built in Flutter that enables students, faculty, and staff of an educational institution to report, track, and resolve infrastructure complaints in a streamlined, transparent, and accountable manner.

Think of it as a **"Zomato for campus complaints"** — you raise a ticket, it gets assigned to the right "restaurant" (department), you can track the progress in real-time, and you get notified when your issue is resolved.

### 2.2 Core Value Proposition

| Role | Value Delivered |
|---|---|
| Student / Faculty | Submit complaints in < 60 seconds with photo evidence; track resolution status live |
| Ground Staff | Receive clear, categorized task assignments with location & photos; no guesswork |
| Administrator | Real-time dashboard with analytics; SLA enforcement; department performance visibility |

### 2.3 Scope — What This App Covers

**In Scope:**
- Student/Faculty mobile app (Flutter) for complaint submission and tracking.
- Admin/Staff mobile app views (role-based UI within same Flutter app).
- AI-powered automatic complaint categorization and severity scoring.
- Real-time complaint status tracking (FCM push notifications).
- Photo evidence capture and upload.
- SLA timer display and escalation alerts.
- Rating/feedback after resolution.
- Offline draft saving.

**Out of Scope (for this version):**
- Web admin dashboard (separate future project).
- Payment integrations.
- Third-party ticketing system integrations (Jira, Freshdesk).
- Voice-to-text complaint submission.

---

## 3. Problem Statement & Motivation

### 3.1 Current Landscape

Educational institutions operate as micro-cities. Infrastructure failures—broken pipes, faulty projectors, Wi-Fi outages, damaged furniture—are daily occurrences. The current grievance redressal process at most institutions is:

- A physical complaint register at the warden's office.
- Sending emails to generic department addresses.
- Verbally informing maintenance staff.

### 3.2 Identified Pain Points

| Pain Point | Impact |
|---|---|
| **The "Black Box" Effect** | Students get zero feedback after complaint submission; leads to duplicate complaints and frustration |
| **No Accountability Trail** | Complaints "fall through the cracks" with no digital audit log |
| **Manual Triage** | Admins manually read and route complaints — slow and error-prone |
| **No Analytics** | Administration cannot identify recurring failures or measure resolution performance |
| **No SLA Enforcement** | No defined response or resolution time commitment |

### 3.3 Hypothesis

> *If students can submit complaints digitally with photo evidence, and if the system automatically routes them to the right department with a defined SLA, then average complaint resolution time will drop by at least 60% and student satisfaction scores will increase.*

---

## 4. Goals & Success Metrics

### 4.1 Primary Goals

- **G1:** Reduce average complaint resolution time from ~72 hours to < 24 hours.
- **G2:** Eliminate lost/forgotten complaints through a digital audit trail.
- **G3:** Automate complaint triage with >85% categorization accuracy via NLP.
- **G4:** Deliver a production-grade Flutter app that demonstrates MCA-level software engineering competency.

### 4.2 Key Performance Indicators (KPIs)

| KPI | Target |
|---|---|
| Complaint submission time | < 60 seconds end-to-end |
| Auto-categorization accuracy | > 85% |
| App crash rate | < 0.5% of sessions |
| Push notification delivery rate | > 95% |
| User satisfaction rating (post-resolution) | > 4.0 / 5.0 |
| First build pass rate (CI) | > 90% |

### 4.3 Academic Objectives

This project must demonstrate:
- Flutter widget lifecycle management.
- State management using Provider or BLoC.
- REST API integration using Dio.
- Firebase Cloud Messaging (FCM) integration.
- Secure local storage.
- Unit testing and widget testing.

---

## 5. Stakeholders & User Personas

### 5.1 Personas

---

**Persona 1: Arjun — The Student**
- Age: 21, MCA 1st year, hostel resident.
- Frustration: Reported a bathroom leak 3 weeks ago. Nothing happened.
- Goal: Submit complaint quickly, know it's being handled.
- Device: Mid-range Android phone (4GB RAM), sometimes on slow campus Wi-Fi.
- Needs: One-tap photo upload, real-time status badge.

---

**Persona 2: Meena — The Maintenance Supervisor**
- Age: 38, manages 6 electricians and 4 plumbers.
- Frustration: Receives complaints verbally from 20 different people; no clarity on priority.
- Goal: See categorized tasks assigned specifically to her department.
- Device: Basic Android phone, primarily used for WhatsApp.
- Needs: Simple task list, mark-as-done button, no complex UI.

---

**Persona 3: Dr. Rao — The Administrative Officer**
- Age: 52, responsible for campus operations.
- Frustration: Has no aggregate view of pending complaints; can't tell which department is underperforming.
- Goal: See analytics, approve escalations, get alerted on SLA breaches.
- Device: Samsung Galaxy S-series, tablet too.
- Needs: Dashboard with charts, escalation alerts, filter by department.

---

### 5.2 Role Definitions

| Role | Code | Access Level |
|---|---|---|
| Student / Faculty | `ROLE_USER` | Submit, view own complaints, rate resolution |
| Ground Staff | `ROLE_STAFF` | View assigned complaints, update status |
| Department Head | `ROLE_DEPT_HEAD` | View all department complaints, reassign within dept |
| Administrator | `ROLE_ADMIN` | Full access — all complaints, analytics, user management |

---

## 6. System Architecture Overview

### 6.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     FLUTTER MOBILE APP                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  Student │  │Student   │  │  Staff   │  │ Admin / Dept │ │
│  │   View   │  │   Rep    │  │   View   │  │  Head View   │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘ │
│                         │                                     │
│              ┌──────────▼──────────┐                         │
│              │  State Management   │                         │
│              │  (BLoC / Cubit)     │                         │
│              └──────────┬──────────┘                         │
│                         │                                     │
│     ┌───────────────────┼──────────────────────┐             │
│     │                   │                       │             │
│  ┌──▼──────────┐  ┌─────▼──────────┐  ┌────────▼─────────┐  │
│  │  Dio API    │  │ google_sign_in  │  │  camera +        │  │
│  │  Client     │  │ (Google OAuth)  │  │  geolocator      │  │
│  └──┬──────────┘  └─────┬──────────┘  └────────┬─────────┘  │
└─────┼─────────────────── ┼─────────────────────┼─────────────┘
      │ HTTPS/REST         │ Google ID Token      │ GPS + media
      │                    │                      │
      ▼                    ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│            NODE.JS + EXPRESS MAIN API (Port 3000)           │
│                                                             │
│  ┌──────────────┐  ┌────────────┐  ┌───────┐  ┌─────────┐  │
│  │  Auth Route  │  │ Complaint  │  │  SR   │  │Analytics│  │
│  │  + Google    │  │  Router    │  │Router │  │ Router  │  │
│  │  OAuth verif │  │            │  │       │  │         │  │
│  └──────────────┘  └────────────┘  └───────┘  └─────────┘  │
│                                                             │
│  ┌──────────────┐  ┌────────────┐                           │
│  │  node-cron   │  │  Multer    │                           │
│  │ (SLA timers) │  │ (uploads)  │                           │
│  └──────────────┘  └────────────┘                           │
│                                                             │
│              ┌──────────────────────┐                       │
│              │   Prisma ORM         │                       │
│              └──────────┬───────────┘                       │
└─────────────────────────┼───────────────────────────────────┘
                          │
          ┌───────────────▼────────────────┐
          │   PostgreSQL 16 + pgvector      │
          │   (complaints, users, groups,   │
          │    embeddings as vector columns) │
          └────────────────────────────────┘
                          │
      ┌───────────────────┼────────────────────────┐
      │                   │                         │
      ▼                   ▼                         ▼
┌──────────┐   ┌──────────────────────┐   ┌─────────────────┐
│ Firebase │   │  PYTHON AI SERVICE   │   │  Firebase /     │
│  FCM     │   │  FastAPI (Port 8000) │   │  Cloudinary     │
│(Push     │   │                      │   │  Media Storage  │
│ Notif.)  │   │  • /grammar-check    │   └─────────────────┘
└──────────┘   │    → Gemini 2.5 Flash│
               │  • /categorize        │
               │    → Gemini 2.5 Flash│
               │    (JSON output mode) │
               │  • /embed             │
               │    → gemini-embedding │
               │      -001             │
               │  • /check-duplicate   │
               │    → cosine sim via   │
               │      numpy/sklearn    │
               │    (reads vectors from│
               │      PostgreSQL)      │
               └──────────────────────┘
                          │
                          ▼
                 ┌────────────────┐
                 │ Google AI      │
                 │ Studio API     │
                 │ (gemini-2.5-   │
                 │  flash +       │
                 │  embedding-001)│
                 └────────────────┘
```

### 6.2 Two-Backend Architecture Explained

The system uses **two separate backend services**:

| Service | Tech | Port | Responsibility |
|---|---|---|---|
| **Main API** | Node.js + Express + Prisma | 3000 | All CRUD, auth, business logic, SLA, file upload |
| **AI Service** | Python + FastAPI | 8000 | All Gemini API calls, embedding generation, cosine similarity |

The Main API calls the AI Service internally (server-to-server on localhost or same Docker network). Flutter **never calls the AI Service directly**.

```
Flutter → Node.js Main API → Python AI Service → Google AI Studio API
                           ↑                   ↓
                           └─── result back ───┘
```

### 6.3 Google OAuth Authentication Flow

```
1. Flutter: user taps "Sign in with Google"
2. google_sign_in triggers Google's consent screen
   → hd parameter set to "rvce.edu.in" (domain lock)
   → Only @rvce.edu.in Google accounts can proceed
3. Google returns idToken (Google-signed JWT) to Flutter
4. Flutter: POST /api/auth/google  { idToken: "..." }
5. Node.js backend:
   a. Calls Google's tokeninfo API to verify idToken
   b. Checks hd claim === "rvce.edu.in"  (domain enforcement)
   c. If foreign domain → 403 DOMAIN_NOT_ALLOWED
   d. Extracts: sub (Google user ID), email, name, picture
   e. Upserts user in PostgreSQL (create on first login)
   f. Assigns role based on email pattern rules (configurable)
   g. Issues SCMS JWT (access + refresh tokens)
6. Flutter receives SCMS JWT → saved to FlutterSecureStorage
7. All subsequent requests use SCMS JWT as Bearer token
```

### 6.4 Data Flow — Full Complaint Submission (v3)

```
1. User types title + description
2. (800ms debounce) Flutter → Node.js → Python AI: grammar check
   → Gemini 2.5 Flash → corrected text shown
3. (800ms debounce) Flutter → Node.js → Python AI: categorize
   → Gemini 2.5 Flash (JSON mode) → category, severity, confidence
4. User selects tags, captures GPS-locked media (watermarked)
5. Pre-submit: Flutter → Node.js → Python AI: check-duplicate
   → Python fetches embeddings from pgvector
   → numpy cosine similarity → returns match results
6. User submits → multipart POST /api/complaints
7. Node.js:
   a. Saves complaint to PostgreSQL
   b. Calls Python AI: embed(description) → stores vector in pgvector
   c. Saves media to Firebase Storage / Cloudinary
   d. Sets status = PENDING_SR_REVIEW
   e. Finds active SR for that zone → sends FCM via Firebase Admin SDK
8. SR reviews → approves → Node.js: status = OPEN
9. Python AI auto-categorizes → department assigned
10. SLA timer starts (node-cron)
11. Staff FCM sent
```

---

## 7. Tech Stack & Tooling

### 7.1 Flutter App

| Package | Version | Purpose |
|---|---|---|
| Flutter SDK | 3.22.x (stable) | Cross-platform mobile framework |
| Dart | 3.4.x | Programming language |
| `dio` | ^5.4.3 | HTTP client with interceptors |
| `flutter_bloc` | ^8.1.5 | State management (BLoC pattern) |
| `provider` | ^6.1.2 | Lightweight state for simpler features |
| `go_router` | ^13.2.0 | Declarative routing |
| `flutter_secure_storage` | ^9.0.0 | Secure JWT token storage |
| `google_sign_in` | ^6.2.1 | Google OAuth 2.0 sign-in |
| `camera` | ^0.11.0 | In-app camera (GPS-locked evidence capture) |
| `geolocator` | ^12.0.0 | GPS coordinates |
| `geocoding` | ^3.0.0 | Reverse geocode GPS → place name string |
| `image` | ^4.1.3 | Image manipulation for watermark overlay |
| `video_player` | ^2.8.6 | In-app video preview |
| `video_compress` | ^3.1.2 | Compress video before upload |
| `firebase_core` | ^2.30.0 | Firebase SDK initialization |
| `firebase_messaging` | ^14.9.1 | FCM push notifications |
| `flutter_local_notifications` | ^17.1.2 | Local notification display |
| `cached_network_image` | ^3.3.1 | Image caching |
| `fl_chart` | ^0.68.0 | Analytics charts (bar, pie, line) |
| `lottie` | ^3.1.0 | Animated Lottie illustrations |
| `flutter_dotenv` | ^5.1.0 | Environment variable loading |
| `hive` + `hive_flutter` | ^2.2.3 | Local offline draft storage |
| `connectivity_plus` | ^6.0.3 | Network connectivity detection |
| `intl` | ^0.19.0 | Date/time formatting |
| `permission_handler` | ^11.3.1 | Runtime permissions (camera, location) |
| `shimmer` | ^3.0.0 | Loading skeleton UI |
| `fluttertoast` | ^8.2.6 | Toast messages |
| `diff_match_patch` | ^0.4.1 | Diff highlight for grammar corrections |
| `path_provider` | ^2.1.3 | Temp file storage for watermarked media |

### 7.2 Main Backend — Node.js + Express

| Tool | Version | Purpose |
|---|---|---|
| **Node.js** | 20 LTS | JavaScript runtime |
| **Express.js** | ^4.19.x | HTTP framework / routing |
| **Prisma ORM** | ^5.14.x | Type-safe PostgreSQL ORM + migrations |
| **@prisma/client** | ^5.14.x | Auto-generated DB client |
| **jsonwebtoken** | ^9.0.2 | Issue + verify SCMS JWTs |
| **google-auth-library** | ^9.11.0 | Verify Google ID tokens server-side |
| **multer** | ^1.4.5 | Multipart file upload handling |
| **node-cron** | ^3.0.4 | SLA deadline scheduler (cron jobs) |
| **firebase-admin** | ^12.2.0 | Send FCM push notifications |
| **axios** | ^1.7.2 | Internal HTTP calls to Python AI service |
| **zod** | ^3.23.8 | Request body validation schemas |
| **bcryptjs** | ^2.4.3 | Password hashing (for any local accounts) |
| **cors** | ^2.8.5 | CORS middleware |
| **helmet** | ^7.1.0 | Security headers |
| **morgan** | ^1.10.0 | HTTP request logging |
| **dotenv** | ^16.4.5 | Environment variables |
| **uuid** | ^10.0.0 | UUID generation |

### 7.3 Python AI Microservice

| Tool | Version | Purpose |
|---|---|---|
| **Python** | 3.11+ | Runtime |
| **FastAPI** | ^0.111.0 | REST API framework |
| **Uvicorn** | ^0.30.0 | ASGI server |
| **google-generativeai** | ^0.7.0 | Official Gemini Python SDK |
| **numpy** | ^1.26.4 | Cosine similarity computation |
| **scikit-learn** | ^1.5.0 | Cosine similarity utilities |
| **psycopg2-binary** | ^2.9.9 | PostgreSQL connection (read embeddings) |
| **pydantic** | ^2.7.0 | Request/response models |
| **python-dotenv** | ^1.0.1 | Environment variables |

### 7.4 Authentication — Google OAuth 2.0

| Component | Tool / Service | Details |
|---|---|---|
| **Flutter sign-in** | `google_sign_in` package | Triggers Google consent screen |
| **Domain restriction (Flutter)** | `serverClientId` + `hostedDomain: "rvce.edu.in"` | Only shows @rvce.edu.in accounts in the picker |
| **Token verification (backend)** | `google-auth-library` | Verifies Google-signed `idToken` |
| **Domain enforcement (backend)** | Check `hd` claim in verified token | Hard reject if `hd !== "rvce.edu.in"` |
| **Session token** | `jsonwebtoken` | Issues SCMS JWT after successful Google verification |
| **Configurable allowed domains** | `allowed_domains` table in PostgreSQL | Admin can add more allowed domains (e.g. `@rvce.ac.in`) |

**Domain Restriction Logic (two-layer):**

```
Layer 1 — Flutter UI:
  google_sign_in configured with hostedDomain = "rvce.edu.in"
  → Google's picker only shows accounts from that domain
  → UX: foreign accounts are greyed out in the picker

Layer 2 — Backend hard enforcement:
  Even if Layer 1 is bypassed (e.g. API call directly):
  → Backend verifies idToken with Google
  → Checks payload.hd === "rvce.edu.in"
  → If mismatch: 403 { error: "DOMAIN_NOT_ALLOWED",
      message: "Only @rvce.edu.in accounts are permitted." }
```

### 7.5 Database — PostgreSQL + pgvector

| Component | Details |
|---|---|
| **PostgreSQL** | Version 16 |
| **pgvector extension** | Stores complaint description embeddings as `vector(768)` columns |
| **Prisma Migrations** | Schema versioned via `prisma/migrations/` folder |
| **Connection pooling** | PgBouncer or Prisma connection limit config |

**Why pgvector:** Stores Gemini embeddings (768-dimension vectors) directly in PostgreSQL alongside complaint records. The Python service runs cosine similarity queries using pgvector's `<=>` operator OR pulls raw vectors into numpy for batch comparison.

### 7.6 AI / NLP — Google AI Studio (Gemini)

| Function | Model | Mode | Called From |
|---|---|---|---|
| **Grammar Check** | `gemini-2.5-flash` | Text generation — structured prompt | Python AI Service |
| **Complaint Categorization** | `gemini-2.5-flash` | JSON output mode (controlled generation) | Python AI Service |
| **Text Embedding** | `gemini-embedding-001` | Embedding generation (768-dim) | Python AI Service |
| **Duplicate Detection** | numpy + scikit-learn | Cosine similarity against pgvector | Python AI Service (local computation) |

**Gemini API Key:** Stored in Python AI service `.env` as `GEMINI_API_KEY`. Never exposed to Flutter or Node.js directly.

### 7.7 Push Notifications

| Component | Tool |
|---|---|
| **Service** | Firebase Cloud Messaging (FCM) |
| **Backend SDK** | `firebase-admin` (Node.js) |
| **Flutter SDK** | `firebase_messaging` + `flutter_local_notifications` |

### 7.8 Media Storage

| Option | Tool | Notes |
|---|---|---|
| **Primary** | Firebase Storage | Free tier sufficient for academic project |
| **Alternative** | Cloudinary | Built-in video watermarking transforms |

### 7.9 Development Tools

| Tool | Purpose |
|---|---|
| VS Code | IDE (Flutter + Node.js + Python) |
| Postman / Thunder Client | API testing |
| Firebase Console | FCM, Storage |
| Google Cloud Console | OAuth 2.0 client credentials, allowed domains |
| Docker Compose | Run Node.js + Python + PostgreSQL together locally |
| Prisma Studio | Visual PostgreSQL data browser |
| Flutter DevTools | Widget and performance profiling |
| Git + GitHub | Version control |

---

## 8. Project Directory Structure

The following is the **exact** directory structure the AI agent must scaffold. Do not deviate.

```
scms_flutter/
├── android/
├── ios/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── app.dart                         # MaterialApp + GoRouter setup
│   ├── firebase_options.dart            # Firebase config (auto-generated)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart       # Base URL, endpoint paths
│   │   │   ├── app_constants.dart       # App-wide constants
│   │   │   └── route_constants.dart     # Named route strings
│   │   ├── theme/
│   │   │   ├── app_theme.dart           # ThemeData light + dark
│   │   │   ├── app_colors.dart          # Color palette
│   │   │   └── app_text_styles.dart     # Typography
│   │   ├── utils/
│   │   │   ├── date_formatter.dart
│   │   │   ├── validators.dart
│   │   │   ├── extensions.dart          # Dart extension methods
│   │   │   └── logger.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   └── network/
│   │       ├── dio_client.dart          # Dio instance + interceptors
│   │       └── network_info.dart        # Connectivity checker
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── complaint_model.dart
│   │   │   ├── complaint_update_model.dart
│   │   │   ├── department_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── rating_model.dart
│   │   │   └── analytics_model.dart
│   │   ├── repositories/
│   │   │   ├── auth_repository.dart
│   │   │   ├── complaint_repository.dart
│   │   │   └── analytics_repository.dart
│   │   └── datasources/
│   │       ├── remote/
│   │       │   ├── auth_remote_datasource.dart
│   │       │   └── complaint_remote_datasource.dart
│   │       └── local/
│   │           ├── auth_local_datasource.dart   # JWT storage
│   │           └── complaint_local_datasource.dart # Hive offline drafts
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user_entity.dart
│   │   │   └── complaint_entity.dart
│   │   └── usecases/
│   │       ├── login_usecase.dart
│   │       ├── submit_complaint_usecase.dart
│   │       ├── get_my_complaints_usecase.dart
│   │       ├── update_complaint_status_usecase.dart
│   │       └── get_analytics_usecase.dart
│   │
│   ├── presentation/
│   │   ├── bloc/
│   │   │   ├── auth/
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_event.dart
│   │   │   │   └── auth_state.dart
│   │   │   ├── complaint/
│   │   │   │   ├── complaint_bloc.dart
│   │   │   │   ├── complaint_event.dart
│   │   │   │   └── complaint_state.dart
│   │   │   ├── submit_complaint/
│   │   │   │   ├── submit_complaint_cubit.dart
│   │   │   │   └── submit_complaint_state.dart
│   │   │   └── analytics/
│   │   │       ├── analytics_cubit.dart
│   │   │       └── analytics_state.dart
│   │   │
│   │   ├── pages/
│   │   │   ├── splash/
│   │   │   │   └── splash_page.dart
│   │   │   ├── onboarding/
│   │   │   │   └── onboarding_page.dart
│   │   │   ├── auth/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── register_page.dart
│   │   │   ├── home/
│   │   │   │   └── home_page.dart           # Role-aware shell
│   │   │   ├── complaint/
│   │   │   │   ├── my_complaints_page.dart
│   │   │   │   ├── complaint_detail_page.dart
│   │   │   │   ├── submit_complaint_page.dart
│   │   │   │   └── rating_page.dart
│   │   │   ├── staff/
│   │   │   │   ├── staff_dashboard_page.dart
│   │   │   │   └── staff_complaint_detail_page.dart
│   │   │   ├── admin/
│   │   │   │   ├── admin_dashboard_page.dart
│   │   │   │   └── admin_complaints_list_page.dart
│   │   │   └── settings/
│   │   │       └── settings_page.dart
│   │   │
│   │   └── widgets/
│   │       ├── common/
│   │       │   ├── scms_button.dart
│   │       │   ├── scms_text_field.dart
│   │       │   ├── scms_chip.dart
│   │       │   ├── loading_overlay.dart
│   │       │   ├── error_widget.dart
│   │       │   └── empty_state_widget.dart
│   │       ├── complaint/
│   │       │   ├── complaint_card.dart
│   │       │   ├── status_badge.dart
│   │       │   ├── sla_timer_widget.dart
│   │       │   ├── photo_picker_widget.dart
│   │       │   └── category_selector_widget.dart
│   │       ├── analytics/
│   │       │   ├── stats_card.dart
│   │       │   └── complaints_chart.dart
│   │       └── notification/
│   │           └── notification_badge.dart
│   │
│   └── services/
│       ├── notification_service.dart    # FCM + local notifications
│       ├── storage_service.dart         # Hive initialization
│       └── analytics_service.dart      # Crash reporting
│
├── test/
│   ├── unit/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── blocs/
│   └── widget/
│       ├── complaint_card_test.dart
│       └── login_page_test.dart
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   └── onboarding/
│   ├── animations/
│   │   └── success.json              # Lottie animation
│   └── icons/
│
├── .env                               # Environment variables (gitignored)
├── .env.example                       # Template for .env
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 9. Feature Catalog

### 9.1 Feature List with Priority

| ID | Feature | Priority | Role | Module |
|---|---|---|---|---|
| F01 | User Registration | P0 | All | Auth |
| F02 | User Login (JWT) | P0 | All | Auth |
| F03 | Token Refresh | P0 | All | Auth |
| F04 | Logout | P0 | All | Auth |
| F05 | Submit Complaint (Text + Photo) | P0 | User | Complaint |
| F06 | AI Auto-categorization Preview | P0 | User | Complaint |
| F07 | View My Complaints List | P0 | User | Complaint |
| F08 | Complaint Detail + Timeline | P0 | User | Complaint |
| F09 | Real-time Status Updates (FCM) | P0 | User | Notification |
| F10 | SLA Timer Display | P1 | User | Complaint |
| F11 | Rate & Review Resolution | P1 | User | Feedback |
| F12 | Staff Task Dashboard | P0 | Staff | Staff |
| F13 | Update Complaint Status | P0 | Staff | Staff |
| F14 | Add Work Notes | P1 | Staff | Staff |
| F15 | Admin Analytics Dashboard | P0 | Admin | Analytics |
| F16 | Admin — View All Complaints | P0 | Admin | Admin |
| F17 | Admin — Reassign Complaint | P1 | Admin | Admin |
| F18 | Escalation Alerts | P1 | Admin | Notification |
| F19 | Offline Draft Saving | P1 | User | Offline |
| F20 | Notification History | P2 | All | Notification |
| F21 | Profile Management | P2 | All | Settings |
| F22 | Department Filter | P2 | Admin | Admin |

**Priority Key:** P0 = Must Have (MVP), P1 = Should Have, P2 = Nice to Have

---

## 10. Detailed Screen Specifications

### 10.1 Splash Screen (`splash_page.dart`)

**Purpose:** App initialization — checks auth status, routes accordingly.

**UI Elements:**
- Full-screen background: `AppColors.primary` gradient.
- Centered SCMS logo (PNG from assets, 120×120 px).
- App name "SCMS" in `AppTextStyles.displayLarge` (white).
- Tagline "Smart Campus. Faster Resolutions." in body2 (white 70% opacity).
- Lottie loading animation below tagline (subtle pulse, 1s loop).

**Logic:**
1. On `initState`, wait 2 seconds (minimum display time).
2. Check `flutter_secure_storage` for `access_token`.
3. If token exists → validate with backend (`GET /api/auth/me`).
4. If valid → decode JWT role → navigate to role-appropriate home page.
5. If invalid / expired → navigate to Login page.
6. If no token → navigate to Onboarding (first time) or Login.

**State:** Stateless widget; navigation handled by GoRouter redirect.

---

### 10.2 Onboarding Screen (`onboarding_page.dart`)

**Purpose:** Show app value proposition to first-time users.

**UI Elements:**
- `PageView` with 3 slides (swipeable):
  - **Slide 1:** Illustration (campus building), Title: "Report Instantly", Body: "Snap a photo and submit your complaint in under 60 seconds."
  - **Slide 2:** Illustration (checklist/tracking), Title: "Track in Real-Time", Body: "Know exactly where your complaint stands. No more guessing."
  - **Slide 3:** Illustration (star/rating), Title: "Hold Us Accountable", Body: "Rate the resolution. Your feedback drives improvement."
- Dot indicators (custom, animated).
- "Next" button → moves to next slide.
- On last slide, button changes to "Get Started" → routes to Login.
- "Skip" text button (top right) → routes directly to Login.

**State:** `StatefulWidget` with `PageController`.

---

### 10.3 Login Screen (`login_page.dart`)

**Purpose:** Authenticate returning users.

**UI Elements:**
- `SafeArea` with `SingleChildScrollView`.
- App logo (60×60 px) + "Welcome Back" heading.
- `ScmsTextField` for email (keyboardType: emailAddress).
- `ScmsTextField` for password (obscured, with visibility toggle icon).
- "Forgot Password?" text button (right-aligned, routes to a placeholder screen).
- Primary `ScmsButton` labeled "Login".
- Divider row: "──── or ────".
- Secondary text: "Don't have an account? **Register**" (tappable).
- `BlocConsumer` → shows `LoadingOverlay` on `AuthLoading`, error `SnackBar` on `AuthFailure`.

**Validation Rules (real-time, on unfocus):**
- Email: non-empty + valid email format.
- Password: non-empty, minimum 6 characters.

**BLoC Event:** `LoginSubmitted(email, password)`.
**On Success:** GoRouter navigates based on role decoded from JWT.

---

### 10.4 Registration Screen (`register_page.dart`)

**Purpose:** New user account creation.

**UI Elements:**
- Full name field.
- Email field.
- Phone number field (optional, numeric keyboard).
- Role selector: `DropdownButtonFormField` with options [Student, Faculty, Staff].
- Department selector (shown only if role = Staff/Faculty): fetched from `GET /api/departments`.
- Password field + Confirm Password field.
- "Create Account" primary button.
- "Already have an account? Login" link.

**Validation Rules:**
- Full name: non-empty, min 3 chars.
- Email: valid email + uniqueness validated on-blur (`POST /api/auth/check-email`).
- Phone: 10 digits, optional.
- Password: min 8 chars, at least one uppercase, one number.
- Confirm password: matches password field.

---

### 10.5 Home Page — Student View (`home_page.dart` with `ROLE_USER`)

**Purpose:** Main hub for the student role.

**Layout:** `Scaffold` with `BottomNavigationBar` (3 tabs):

1. **"My Complaints" tab** → `MyComplaintsPage`.
2. **"Submit" tab** → `SubmitComplaintPage` (opens as full-screen modal).
3. **"Notifications" tab** → `NotificationHistoryPage`.

**AppBar:**
- Greeting: "Good morning, Arjun 👋" (dynamic based on time).
- Notification bell icon with `NotificationBadge` overlay showing unread count.
- Avatar icon → navigates to `SettingsPage`.

**Quick Stats Row (top of My Complaints tab):**
- Row of 3 small cards: "Open: N", "In Progress: N", "Resolved: N".
- Tapping each card filters the list below.

---

### 10.6 My Complaints Page (`my_complaints_page.dart`)

**Purpose:** List all complaints submitted by the current user.

**UI Elements:**
- `RefreshIndicator` wrapping a `ListView.builder`.
- Each list item → `ComplaintCard` widget.
- Filter chips at top: All | Open | In Progress | Resolved | Closed.
- Empty state widget when no complaints.
- Shimmer loading skeletons while BLoC is in loading state.

**`ComplaintCard` Spec:**
- Left border colored by severity (Red = High, Orange = Medium, Yellow = Low).
- Title: complaint subject (max 2 lines, ellipsis overflow).
- Subtitle: Department badge + Location.
- `StatusBadge` (pill-shaped chip).
- Date/time (relative: "2 hours ago").
- `SlaTimerWidget` — if Open or In Progress, shows countdown.
- Arrow icon → taps to `ComplaintDetailPage`.

---

### 10.7 Submit Complaint Page (`submit_complaint_page.dart`)

**Purpose:** Multi-step complaint submission form.

**Design Pattern:** Stepper-based (3 steps), or scrollable single form. Use scrollable single form for simplicity.

**Form Sections:**

**Section A — Describe the Issue:**
- `ScmsTextField` (multiline, max 5 lines): "Describe your complaint…" (hint).
- Character counter (min 20, max 500).
- **AI Suggestion Banner** (appears after user types ≥ 30 chars and pauses for 800ms debounce):
  - Calls `POST /api/complaints/ai-preview` with the text.
  - Shows a card: "🤖 We think this is an **Electrical** issue, severity **Medium**. Is that correct?" with [Yes, change it] options.
  - If user confirms → auto-fills Category and Severity dropdowns.

**Section B — Location & Category:**
- `ScmsTextField` for Location (building name, room number). Example hint: "e.g., Hostel Block C, Room 204".
- `CategorySelectorWidget`: horizontally scrollable chips for categories [Electrical, Plumbing, IT/Network, Housekeeping, Furniture, AC/HVAC, Other].
- Severity selector: three large tappable cards [🔴 High — "Unsafe/Urgent", 🟡 Medium — "Functional Issue", 🟢 Low — "Minor Inconvenience"].

**Section C — Evidence:**
- `PhotoPickerWidget`: Shows a dashed-border upload zone.
  - Tapping opens bottom sheet with [Camera, Gallery, Cancel].
  - Supports up to 3 photos.
  - Shows thumbnail previews with "X" delete button.
  - File size limit: 5 MB per photo.

**Submit Button:**
- Full-width `ScmsButton` labeled "Submit Complaint".
- On tap → validates all fields → dispatches `SubmitComplaintRequested` BLoC event.
- On success → shows Lottie success animation → navigates back to My Complaints.
- On failure → shows error SnackBar with retry option.

**Offline Behavior:**
- If no internet detected → show a `SnackBar` warning "You are offline. Your complaint will be saved as a draft."
- Save to Hive as draft. Show draft indicator on form.
- When connectivity restored → prompt user to submit draft.

---

### 10.8 Complaint Detail Page (`complaint_detail_page.dart`)

**Purpose:** Full view of a single complaint with timeline.

**Layout:**

**Header Card:**
- Status badge (large).
- Complaint ID: "#SCM-2024-0042".
- Title/subject.
- Category chip + Department chip.
- Severity indicator bar.

**SLA Section:**
- SLA deadline datetime.
- Progress bar: time elapsed vs total SLA window.
- Color: green → yellow → red as deadline approaches.
- If breached: shows "⚠️ SLA Breached — Escalated to Administration".

**Details Card:**
- Full description text.
- Location.
- Submitted on date.

**Photos Section:**
- Horizontal `ListView` of uploaded photos.
- Tapping any photo opens full-screen image viewer (`Hero` animation).

**Timeline Section:**
- Vertical `ListView` of `ComplaintUpdate` records:
  - Each row: avatar icon (role indicator) + timestamp + update text.
  - E.g., "🤖 AI Categorized → Electrical | Medium | [timestamp]".
  - "👤 Complaint assigned to Suresh Kumar (Electrician) | [timestamp]".
  - "🔧 Staff marked as In Progress | [timestamp]".
  - "✅ Resolved by Staff | [timestamp]".

**Rating Section (shown only when status = Resolved and no rating yet):**
- Star rating widget (1–5).
- Optional comment field.
- "Submit Feedback" button.

---

### 10.9 Staff Dashboard (`staff_dashboard_page.dart`)

**Purpose:** Task management view for ground staff.

**UI Elements:**
- AppBar: "My Tasks" + role badge "STAFF".
- Filter tabs: All | Assigned | In Progress | Resolved (today).
- `ListView` of `ComplaintCard` (staff variant):
  - Shows: Complaint ID, Description snippet, Location, Severity, SLA countdown.
  - Primary action button: "Start Working" (changes status to In Progress).
- Stats row: "Assigned: 4 | In Progress: 2 | Completed Today: 6".

---

### 10.10 Staff Complaint Detail Page (`staff_complaint_detail_page.dart`)

**Purpose:** Staff view of complaint with action buttons.

**Additional Sections vs User Detail Page:**

**Action Panel (bottom sheet or sticky bottom bar):**
- Current status selector: dropdown or button group.
  - Status options: Assigned → In Progress → Resolved.
- Work notes text field: "Add a note for this update…".
- "Update Status" button → dispatches `UpdateComplaintStatus` event.

**Status Transition Rules (enforced on frontend):**
- Staff can only move forward: Assigned → In Progress → Resolved.
- Staff cannot move to Closed (Admin only) or revert to Open.

---

### 10.11 Admin Dashboard (`admin_dashboard_page.dart`)

**Purpose:** Analytical overview for administrators.

**Layout:**
- `CustomScrollView` with `SliverAppBar` (collapsible).

**Sections:**

**KPI Cards Row (horizontal scroll):**
- Total Active Complaints.
- SLA Breaches (past 7 days).
- Average Resolution Time (hours).
- Resolution Rate (%).

**Complaints by Department Bar Chart** (`fl_chart`):
- Horizontal bar chart.
- X-axis: number of complaints.
- Y-axis: department names.
- Color-coded by status.

**Complaints by Category Pie Chart** (`fl_chart`):
- Donut chart.
- Legend below.

**Recent SLA Breaches List:**
- Last 5 breached complaints.
- Each item: Complaint ID, Department, Hours Overdue, Escalate Button.

**Recent Activity Feed:**
- Last 10 status change events across all complaints.

---

### 10.12 Admin Complaints List (`admin_complaints_list_page.dart`)

**Purpose:** Searchable, filterable master list of all complaints.

**UI Elements:**
- `SearchBar` widget (real-time search, 500ms debounce).
- Filter row: Department | Category | Status | Severity | Date Range.
- `ListView` with `ComplaintCard` (admin variant showing assigned staff).
- Long-press or swipe to reveal [Reassign, Escalate, Close] actions.
- Pagination with "Load More" button at bottom.

---

### 10.13 Settings Page (`settings_page.dart`)

**Purpose:** Profile management and app preferences.

**Sections:**
- Profile card: Avatar (initials-based), Name, Email, Role badge.
- Edit Profile option.
- Notification Preferences toggle (enable/disable push).
- App theme: Light / Dark / System.
- About: App version, Build number.
- Logout button (with confirmation dialog).

---

## 11. Data Models

All Dart model classes must implement `fromJson` / `toJson` for serialization. Use `freezed` + `json_serializable` or manual serialization (manual preferred for simplicity in academic context).

### 11.1 `UserModel`

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;          // nullable
  final String role;           // ROLE_USER | ROLE_STAFF | ROLE_DEPT_HEAD | ROLE_ADMIN
  final String? departmentId;
  final String? departmentName;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### 11.2 `ComplaintModel`

```dart
class ComplaintModel {
  final String id;                         // UUID
  final String complaintNumber;            // "SCM-2024-0042"
  final String subject;
  final String description;
  final String location;
  final String categoryId;
  final String categoryName;
  final String departmentId;
  final String departmentName;
  final String severity;                   // HIGH | MEDIUM | LOW
  final String status;                     // OPEN | ASSIGNED | IN_PROGRESS | RESOLVED | CLOSED
  final String submittedById;
  final String submittedByName;
  final String? assignedToId;
  final String? assignedToName;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? slaDeadline;
  final bool isSlaBreached;
  final bool isAiCategorized;
  final double? aiConfidenceScore;
  final double? rating;
  final String? ratingComment;
  final List<ComplaintUpdateModel> updates;

  const ComplaintModel({ ... });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### 11.3 `ComplaintUpdateModel`

```dart
class ComplaintUpdateModel {
  final String id;
  final String complaintId;
  final String updatedById;
  final String updatedByName;
  final String updatedByRole;
  final String previousStatus;
  final String newStatus;
  final String? notes;
  final DateTime timestamp;

  const ComplaintUpdateModel({ ... });
  factory ComplaintUpdateModel.fromJson(Map<String, dynamic> json) { ... }
}
```

### 11.4 `DepartmentModel`

```dart
class DepartmentModel {
  final String id;
  final String name;
  final String code;            // "ELEC", "PLUMB", "IT", etc.
  final String headName;
  final int activeComplaintsCount;

  const DepartmentModel({ ... });
  factory DepartmentModel.fromJson(Map<String, dynamic> json) { ... }
}
```

### 11.5 `CategoryModel`

```dart
class CategoryModel {
  final String id;
  final String name;
  final String iconName;         // Maps to IconData
  final String defaultDepartmentId;

  const CategoryModel({ ... });
  factory CategoryModel.fromJson(Map<String, dynamic> json) { ... }
}
```

### 11.6 `AiPreviewResponse`

```dart
class AiPreviewResponse {
  final String suggestedCategoryId;
  final String suggestedCategoryName;
  final String suggestedDepartmentId;
  final String suggestedSeverity;
  final double confidenceScore;        // 0.0 to 1.0

  const AiPreviewResponse({ ... });
  factory AiPreviewResponse.fromJson(Map<String, dynamic> json) { ... }
}
```

### 11.7 `AnalyticsModel`

```dart
class AnalyticsModel {
  final int totalActiveComplaints;
  final int slaBreachesLast7Days;
  final double avgResolutionTimeHours;
  final double resolutionRatePercent;
  final List<DepartmentStat> byDepartment;
  final List<CategoryStat> byCategory;
  final List<ComplaintModel> recentSlaBreaches;

  const AnalyticsModel({ ... });
  factory AnalyticsModel.fromJson(Map<String, dynamic> json) { ... }
}

class DepartmentStat {
  final String departmentName;
  final int openCount;
  final int inProgressCount;
  final int resolvedCount;
}

class CategoryStat {
  final String categoryName;
  final int count;
}
```

### 11.8 `ComplaintDraft` (Hive Local Model)

```dart
@HiveType(typeId: 0)
class ComplaintDraft extends HiveObject {
  @HiveField(0) String subject;
  @HiveField(1) String description;
  @HiveField(2) String location;
  @HiveField(3) String? categoryId;
  @HiveField(4) String? severity;
  @HiveField(5) List<String> localPhotoPaths;  // Local file paths
  @HiveField(6) DateTime savedAt;
}
```

---

## 12. API Contract

**Base URL:** `{{API_BASE_URL}}/api` (loaded from `.env`)
**Authentication:** Bearer JWT token in `Authorization` header.
**Content-Type:** `application/json` (except for multipart form endpoints).

### 12.1 Auth Endpoints

> There is **no username/password registration or login**. All authentication goes through Google OAuth 2.0. The only credential is a Google ID Token issued after the user signs in with their @rvce.edu.in Google account.

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| POST | `/auth/google` | No | Exchange Google ID token for SCMS JWT |
| POST | `/auth/refresh` | Refresh token | Refresh access token |
| GET | `/auth/me` | Yes | Get current user profile |
| POST | `/auth/logout` | Yes | Invalidate refresh token |
| GET | `/auth/allowed-domains` | Yes (Admin) | List allowed email domains |
| POST | `/auth/allowed-domains` | Yes (Admin) | Add a new allowed domain |
| DELETE | `/auth/allowed-domains/:domain` | Yes (Admin) | Remove an allowed domain |

---

**POST `/auth/google` — Main Login Endpoint**

Flutter sends the raw Google ID Token it received from `google_sign_in`.

**Request:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "fcmToken": "fGzP7_abc123..."
}
```
- `idToken`: The Google-signed JWT returned by `google_sign_in.authentication.idToken`.
- `fcmToken`: Device FCM token, saved for push notifications.

**Backend Processing:**
```
1. Verify idToken with Google:
   GET https://oauth2.googleapis.com/tokeninfo?id_token={idToken}
   OR use google-auth-library OAuth2Client.verifyIdToken()

2. Extract payload:
   { sub, email, name, picture, hd, email_verified }

3. Validate:
   a. email_verified === true
   b. hd === "rvce.edu.in"  (check against allowed_domains table)
   c. If fail → 403 DOMAIN_NOT_ALLOWED

4. Upsert user in PostgreSQL:
   - Find by googleId (sub) OR email
   - If new user: create with role = "ROLE_USER" (default)
   - If existing: update name, picture, lastLogin
   - Save fcmToken to user record

5. Role auto-assignment rules (configurable in DB):
   - Email prefix matches pattern "hod.*" → ROLE_DEPT_HEAD
   - Email in staff_emails table → ROLE_STAFF
   - Email in sr_emails table → ROLE_SR
   - Admin manually upgrades roles via admin panel
   - All others → ROLE_USER

6. Issue SCMS tokens:
   accessToken: JWT signed with APP_SECRET, expires 1h
   refreshToken: opaque random token, stored in DB, expires 30d
```

**Response (200):**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "scms_rt_abc123...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "isNewUser": false,
  "user": {
    "id": "uuid-string",
    "name": "Arjun Kumar",
    "email": "arjun.kumar@rvce.edu.in",
    "picture": "https://lh3.googleusercontent.com/...",
    "role": "ROLE_USER",
    "zoneId": null,
    "departmentId": null
  }
}
```

**Error — Domain Not Allowed (403):**
```json
{
  "error": "DOMAIN_NOT_ALLOWED",
  "message": "Only @rvce.edu.in accounts are permitted to use this app.",
  "allowedDomains": ["rvce.edu.in"]
}
```

**Error — Unverified Email (403):**
```json
{
  "error": "EMAIL_NOT_VERIFIED",
  "message": "Your Google account email is not verified."
}
```

---

**Flutter Implementation — `google_sign_in` Configuration:**

```dart
// In auth_remote_datasource.dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: Env.googleServerClientId,  // OAuth 2.0 Web Client ID
  hostedDomain: "rvce.edu.in",               // Layer 1: domain restriction in picker
  scopes: ['email', 'profile'],
);

Future<String> getGoogleIdToken() async {
  final account = await _googleSignIn.signIn();
  if (account == null) throw AuthException("Sign-in cancelled");
  final auth = await account.authentication;
  return auth.idToken!;
}
```

**`.env` entry required:**
```
GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
```
This is the **Web Client ID** from Google Cloud Console OAuth credentials (not the Android client ID). The Web Client ID is used for server-side token verification.

---

**POST `/auth/refresh` Request:**
```json
{ "refreshToken": "scms_rt_abc123..." }
```
**Response (200):**
```json
{ "accessToken": "eyJ...", "expiresIn": 3600 }
```

---

**Managing Allowed Domains (Admin):**

An admin can extend the system to allow additional domains (e.g., `@rvce.ac.in` for a different TLD, or `@faculty.rvce.edu.in` for a faculty-specific subdomain).

**POST `/auth/allowed-domains` Request:**
```json
{ "domain": "rvce.ac.in", "description": "Alternative RVCE domain" }
```
The backend's domain check reads from the `allowed_domains` table, making it dynamic without code changes.
```

### 12.2 Complaint Endpoints

| Method | Endpoint | Auth Required | Description |
|---|---|---|---|
| GET | `/complaints/my` | Yes | Get current user's complaints |
| GET | `/complaints/{id}` | Yes | Get complaint by ID |
| POST | `/complaints` | Yes | Submit new complaint (multipart) |
| PATCH | `/complaints/{id}/status` | Yes (Staff/Admin) | Update status |
| POST | `/complaints/{id}/rating` | Yes (User) | Submit rating |
| POST | `/complaints/ai-preview` | Yes | Get AI classification preview |
| GET | `/complaints` | Yes (Admin) | Get all complaints with filters |
| PATCH | `/complaints/{id}/assign` | Yes (Admin) | Reassign complaint |

**POST `/complaints` Request (multipart/form-data):**
```
subject: "Water leaking from bathroom ceiling"
description: "There is a persistent water leak from the ceiling of the bathroom in my room..."
location: "Hostel Block C, Room 204"
categoryId: "cat-plumbing-001"
severity: "HIGH"
photos: [file1.jpg, file2.jpg]   (binary, max 3 files, 5MB each)
```

**POST `/complaints` Response (201):**
```json
{
  "id": "comp-uuid-001",
  "complaintNumber": "SCM-2024-0042",
  "status": "OPEN",
  "slaDeadline": "2024-06-16T10:30:00Z",
  "aiCategorized": true,
  "aiConfidenceScore": 0.91,
  "message": "Complaint submitted successfully. Assigned to Plumbing Department."
}
```

**GET `/complaints/my` Query Parameters:**
```
status: OPEN | ASSIGNED | IN_PROGRESS | RESOLVED | CLOSED | (omit for all)
page: 0
size: 10
```

**PATCH `/complaints/{id}/status` Request:**
```json
{
  "newStatus": "IN_PROGRESS",
  "notes": "Inspection done. Pipe replacement in progress."
}
```

**POST `/complaints/ai-preview` Request:**
```json
{
  "text": "The tube light in my room has been flickering for 3 days and sometimes goes off completely."
}
```

**POST `/complaints/ai-preview` Response:**
```json
{
  "suggestedCategoryId": "cat-electrical-001",
  "suggestedCategoryName": "Electrical",
  "suggestedDepartmentId": "dept-elec-001",
  "suggestedSeverity": "MEDIUM",
  "confidenceScore": 0.87
}
```

### 12.3 Department & Category Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/departments` | List all departments |
| GET | `/categories` | List all complaint categories |

### 12.4 Analytics Endpoints (Admin Only)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/analytics/summary` | KPI summary cards data |
| GET | `/analytics/by-department` | Complaint counts by department |
| GET | `/analytics/by-category` | Complaint counts by category |
| GET | `/analytics/sla-breaches` | Recent SLA breach list |

### 12.5 HTTP Error Codes Handled by App

| Code | Meaning | App Behavior |
|---|---|---|
| 400 | Bad Request | Show field-level validation errors from response body |
| 401 | Unauthorized | Attempt token refresh; if fails, redirect to Login |
| 403 | Forbidden | Show "Access denied" error widget |
| 404 | Not Found | Show "Not found" empty state |
| 422 | Validation Error | Show error messages from response |
| 500 | Server Error | Show "Something went wrong. Try again." with retry |
| Network timeout | — | Show "No internet connection" state |

---

## 13. State Management Architecture

### 13.1 Pattern: BLoC (Business Logic Component)

The app uses `flutter_bloc` for all major features. Each feature has its own BLoC or Cubit.

**Rule:** Cubits are used for simpler, one-directional flows (form submission, analytics loading). BLoCs are used for complex, event-driven features (auth, complaint list with filters).

### 13.2 AuthBloc

**Events:**
```dart
abstract class AuthEvent {}
class AppStarted extends AuthEvent {}
class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
}
class RegisterSubmitted extends AuthEvent { ... }
class LogoutRequested extends AuthEvent {}
class TokenRefreshRequested extends AuthEvent {}
```

**States:**
```dart
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final UserModel user;
}
class AuthUnauthenticated extends AuthState {}
class AuthFailure extends AuthState {
  final String message;
}
```

### 13.3 ComplaintBloc

**Events:**
```dart
class LoadMyComplaints extends ComplaintEvent {
  final String? statusFilter;
}
class LoadComplaintDetail extends ComplaintEvent {
  final String complaintId;
}
class FilterComplaints extends ComplaintEvent {
  final String? status;
}
class RefreshComplaints extends ComplaintEvent {}
```

**States:**
```dart
class ComplaintInitial extends ComplaintState {}
class ComplaintLoading extends ComplaintState {}
class MyComplaintsLoaded extends ComplaintState {
  final List<ComplaintModel> complaints;
  final String? activeFilter;
}
class ComplaintDetailLoaded extends ComplaintState {
  final ComplaintModel complaint;
}
class ComplaintError extends ComplaintState {
  final String message;
}
```

### 13.4 SubmitComplaintCubit

**States:**
```dart
class SubmitComplaintState {
  final bool isLoading;
  final String? subject;
  final String? description;
  final String? location;
  final String? categoryId;
  final String? severity;
  final List<File> photos;
  final AiPreviewResponse? aiPreview;
  final bool aiPreviewAccepted;
  final bool isSuccess;
  final String? errorMessage;
  final bool isDraft;
}
```

### 13.5 Dio Client Configuration (`dio_client.dart`)

```dart
class DioClient {
  late final Dio _dio;

  DioClient(String baseUrl, FlutterSecureStorage secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage, _dio),    // Adds Bearer token
      LoggingInterceptor(),                    // Dev-only logging
      RetryInterceptor(_dio),                  // Auto-retry on 401 with refresh
    ]);
  }
}
```

**AuthInterceptor behavior:**
1. On each request: read `access_token` from `FlutterSecureStorage`, add to `Authorization: Bearer` header.
2. On 401 response: attempt token refresh via `POST /auth/refresh`.
3. If refresh succeeds: save new tokens, retry original request.
4. If refresh fails: clear tokens, dispatch `LogoutRequested` event, redirect to Login.

---

## 14. Navigation Architecture

### 14.1 Router Setup (`go_router`)

The app uses `GoRouter` with a redirect guard based on auth state.

```dart
final goRouter = GoRouter(
  initialLocation: Routes.splash,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isOnAuthPage = state.matchedLocation == Routes.login ||
                         state.matchedLocation == Routes.register ||
                         state.matchedLocation == Routes.splash ||
                         state.matchedLocation == Routes.onboarding;

    if (!isLoggedIn && !isOnAuthPage) return Routes.login;
    if (isLoggedIn && isOnAuthPage) return _getRoleHome(authState.user.role);
    return null;
  },
  routes: [ ... ]
);
```

### 14.2 Route Constants (`route_constants.dart`)

```dart
class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const userHome = '/home/user';
  static const staffHome = '/home/staff';
  static const adminHome = '/home/admin';
  static const submitComplaint = '/complaint/submit';
  static const complaintDetail = '/complaint/:id';
  static const ratingPage = '/complaint/:id/rate';
  static const settings = '/settings';
  static const notificationHistory = '/notifications';
}
```

### 14.3 Role-Based Home Routing

```dart
String _getRoleHome(String role) {
  switch (role) {
    case 'ROLE_ADMIN':
    case 'ROLE_DEPT_HEAD':
      return Routes.adminHome;
    case 'ROLE_STAFF':
      return Routes.staffHome;
    default:
      return Routes.userHome;
  }
}
```

---

## 15. UI/UX Design System

### 15.1 Color Palette (`app_colors.dart`)

```dart
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1A56DB);       // Deep Blue
  static const Color primaryLight = Color(0xFF4D7FE0);
  static const Color primaryDark = Color(0xFF1240B0);

  // Accent
  static const Color accent = Color(0xFF00C896);        // Teal Green

  // Status Colors
  static const Color statusOpen = Color(0xFF6B7280);    // Gray
  static const Color statusAssigned = Color(0xFF3B82F6); // Blue
  static const Color statusInProgress = Color(0xFFF59E0B); // Amber
  static const Color statusResolved = Color(0xFF10B981); // Green
  static const Color statusClosed = Color(0xFF374151);  // Dark Gray

  // Severity Colors
  static const Color severityHigh = Color(0xFFEF4444);  // Red
  static const Color severityMedium = Color(0xFFF97316); // Orange
  static const Color severityLow = Color(0xFFEAB308);   // Yellow

  // Neutrals
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Dark Theme equivalents
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
}
```

### 15.2 Typography (`app_text_styles.dart`)

```dart
class AppTextStyles {
  static const String _fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32, fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24, fontWeight: FontWeight.w700,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18, fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16, fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16, fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14, fontWeight: FontWeight.w400,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
```

**Font Setup:** Add `Inter` font to `pubspec.yaml` from Google Fonts or bundle in `assets/fonts/`. Use `google_fonts` package as an alternative.

### 15.3 Component Specs

**`ScmsButton`:**
- Primary: filled, `AppColors.primary` background, white text, `BorderRadius.circular(12)`, height: 52px, full-width by default.
- Secondary: outlined, primary color border, primary color text.
- Destructive: filled, `AppColors.severityHigh` background.
- Loading state: shows `CircularProgressIndicator` (white, size 20px) in place of label.
- Disabled state: opacity 0.5.

**`ScmsTextField`:**
- Border: `OutlineInputBorder`, radius 12, color `AppColors.border`.
- Focused border: `AppColors.primary`, width 2.
- Error border: `AppColors.severityHigh`.
- Label floats on focus.
- Height: auto (expands with content for multiline).
- Padding: 16 horizontal, 14 vertical.

**`StatusBadge`:**
- Pill-shaped `Container` with rounded corners (circular).
- Background: status color at 15% opacity.
- Text: status color at 100% opacity, `AppTextStyles.labelMedium`.
- Status → Label mapping:
  - OPEN → "Open"
  - ASSIGNED → "Assigned"
  - IN_PROGRESS → "In Progress"
  - RESOLVED → "Resolved ✓"
  - CLOSED → "Closed"

**`SlaTimerWidget`:**
- Displays: "SLA: 14h 32m remaining" in `labelMedium`.
- Color: Green if > 50% time remaining, Orange if 20–50%, Red if < 20% or breached.
- Uses `Timer.periodic` to count down in real-time.
- If breached: shows "⚠️ SLA Breached" in red bold.

**`ComplaintCard`:**
- `Card` widget, elevation: 2, borderRadius: 16.
- Left accent border: 4px wide, color = severity color.
- Padding: 16 all sides.
- Content: complaint number (caption), subject (titleMedium, max 2 lines), location row (icon + text), bottom row (status badge + SLA timer + date).
- Tap ripple effect on entire card.

### 15.4 Spacing & Layout

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

- Standard screen padding: 16px horizontal.
- Card internal padding: 16px all.
- List item spacing: 12px between cards.
- Section header spacing: 24px top, 12px bottom.

---

## 16. AI/NLP Integration

### 16.1 Overview

All AI operations are handled by the **Python FastAPI AI microservice**. Node.js never calls Google AI Studio directly — it proxies through the Python service. Flutter never calls the AI service directly — it only talks to Node.js.

```
Flutter (debounce) → Node.js /api/ai/* → Python FastAPI → Google AI Studio
```

| Feature | Model | Python Endpoint | Trigger |
|---|---|---|---|
| Grammar Check | `gemini-2.5-flash` | `POST /grammar-check` | 800ms after typing stops (≥20 chars) |
| Categorization | `gemini-2.5-flash` (JSON mode) | `POST /categorize` | After grammar step |
| Embedding | `gemini-embedding-001` | `POST /embed` | After complaint saved to DB |
| Duplicate Detection | numpy cosine similarity | `POST /check-duplicate` | Pre-submission check |

---

### 16.2 Python AI Service — Full Specification

**Service location:** `scms_ai_service/` (separate repo or `/backend/ai-service/` folder)

**Directory structure:**
```
scms_ai_service/
├── main.py                  # FastAPI app entry point
├── routers/
│   ├── grammar.py           # /grammar-check endpoint
│   ├── categorize.py        # /categorize endpoint
│   ├── embed.py             # /embed endpoint
│   └── duplicate.py         # /check-duplicate endpoint
├── services/
│   ├── gemini_client.py     # Gemini SDK singleton setup
│   └── db_client.py         # Read embeddings from PostgreSQL
├── models/
│   └── schemas.py           # Pydantic request/response models
├── .env
└── requirements.txt
```

**`.env` for AI service:**
```
GEMINI_API_KEY=AIzaSy...
DATABASE_URL=postgresql://user:pass@localhost:5432/scms_db
SIMILARITY_THRESHOLD=0.75
```

---

### 16.3 Grammar Check — Gemini 2.5 Flash

**Python endpoint:** `POST /grammar-check`

**Prompt design (system + user):**
```python
GRAMMAR_SYSTEM_PROMPT = """
You are a grammar correction assistant for a campus complaint management system.
Users may be non-native English speakers. Your job is to:
1. Fix grammatical errors, spelling mistakes, and punctuation.
2. Improve sentence clarity without changing the meaning.
3. Keep the tone informal and natural — do not make it sound formal or corporate.
4. Return ONLY a JSON object with this exact structure:
{
  "hasCorrections": true/false,
  "correctedText": "...",
  "diffs": [
    { "type": "EQUAL" | "DELETE" | "INSERT", "text": "..." }
  ]
}
Do not add any explanation outside the JSON.
"""

user_prompt = f'Correct this complaint text: "{input_text}"'
```

**Gemini call:**
```python
import google.generativeai as genai

genai.configure(api_key=os.environ["GEMINI_API_KEY"])
model = genai.GenerativeModel(
    model_name="gemini-2.5-flash",
    generation_config=genai.GenerationConfig(
        response_mime_type="application/json",
        temperature=0.1,   # Low temperature for consistent grammar fix
    ),
    system_instruction=GRAMMAR_SYSTEM_PROMPT,
)

response = model.generate_content(user_prompt)
result = json.loads(response.text)
```

**Node.js proxy route:** `POST /api/ai/grammar-check` → forwards to Python → returns to Flutter.

**Flutter handling:**
- If `hasCorrections == true`: show `GrammarCorrectionBanner` with diff.
- If `hasCorrections == false`: no banner, proceed silently.
- If AI service times out or errors: silent fail — form remains usable.

---

### 16.4 Complaint Categorization — Gemini 2.5 Flash (JSON Mode)

**Python endpoint:** `POST /categorize`

**Prompt design:**
```python
CATEGORIZE_SYSTEM_PROMPT = """
You are a complaint categorization assistant for a college campus.
Given a complaint description, return a JSON object with this exact structure:
{
  "categoryName": one of ["Electrical", "Plumbing", "IT/Network",
                           "Housekeeping", "Furniture", "AC/HVAC", "Other"],
  "severity": one of ["HIGH", "MEDIUM", "LOW"],
  "reasoning": "one sentence explaining the categorization",
  "confidenceScore": a float between 0.0 and 1.0
}

Severity rules:
- HIGH: safety risk, complete failure, affects many people (e.g. power outage, flooding)
- MEDIUM: functional issue, partial failure (e.g. flickering light, slow wifi)
- LOW: cosmetic or minor inconvenience (e.g. broken chair leg, dirty window)

Return ONLY the JSON object, no other text.
"""

user_prompt = f"Categorize this complaint: \"{description}\""
```

**Gemini call:**
```python
model = genai.GenerativeModel(
    model_name="gemini-2.5-flash",
    generation_config=genai.GenerationConfig(
        response_mime_type="application/json",
        temperature=0.0,   # Deterministic output for classification
    ),
    system_instruction=CATEGORIZE_SYSTEM_PROMPT,
)
response = model.generate_content(user_prompt)
result = json.loads(response.text)
# result: { categoryName, severity, reasoning, confidenceScore }
```

**Category → Department mapping** is done in Node.js (not Gemini) using the `category_department_mapping` table in PostgreSQL.

**Flutter AI Suggestion Banner:**
```
┌────────────────────────────────────────────────┐
│  🤖  AI Suggestion  (confidence: 87%)          │
│  Category: Electrical  │  Severity: Medium     │
│  "Flickering light indicates an electrical     │
│   fault, medium severity"                      │
│  [✓ Looks right]       [✏ Change it]           │
└────────────────────────────────────────────────┘
```
- Confidence pill: green (≥80%), amber (60–79%), red (<60%).
- `reasoning` text shown as sub-label inside the banner.

---

### 16.5 Embedding Generation — gemini-embedding-001

**Python endpoint:** `POST /embed`

**Called by Node.js after a complaint is saved to PostgreSQL** (not during user interaction — this is an async background step).

```python
EMBED_SYSTEM = "Represent this campus complaint for semantic search:"

async def embed_text(text: str) -> list[float]:
    model = "models/gemini-embedding-001"
    result = genai.embed_content(
        model=model,
        content=text,
        task_type="RETRIEVAL_DOCUMENT",
        title=EMBED_SYSTEM,
    )
    return result["embedding"]   # 768-dimensional float list
```

**PostgreSQL storage (Prisma schema):**
```prisma
model Complaint {
  id          String   @id @default(uuid())
  // ... other fields ...
  embedding   Unsupported("vector(768)")?   // pgvector column

  @@map("complaints")
}
```

**Raw SQL for storing (via Prisma $executeRaw):**
```sql
UPDATE complaints
SET embedding = $1::vector
WHERE id = $2;
```

---

### 16.6 Duplicate Detection — numpy Cosine Similarity

**Python endpoint:** `POST /check-duplicate`

**Called before submission** when user taps Submit (not debounced — once only).

**Algorithm:**
```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import psycopg2

async def check_duplicate(new_text: str, zone_id: str, tags: list[str]):
    # Step 1: Embed the new complaint
    new_embedding = await embed_text(new_text)

    # Step 2: Fetch existing open/active complaint embeddings
    # from PostgreSQL for the same zone
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT id, complaint_number, title, status, embedding::text
        FROM complaints
        WHERE zone_id = %s
          AND status NOT IN ('CLOSED', 'REJECTED')
          AND embedding IS NOT NULL
    """, (zone_id,))
    rows = cursor.fetchall()

    if not rows:
        return { "isDuplicate": False, "similarCount": 0 }

    # Step 3: Compute cosine similarity
    existing_embeddings = np.array([
        list(map(float, row[4].strip("[]").split(",")))
        for row in rows
    ])
    new_vec = np.array(new_embedding).reshape(1, -1)
    scores = cosine_similarity(new_vec, existing_embeddings)[0]

    # Step 4: Find matches above threshold
    threshold = float(os.environ.get("SIMILARITY_THRESHOLD", 0.75))
    matches = [
        { "id": rows[i][0], "complaintNumber": rows[i][1],
          "title": rows[i][2], "status": rows[i][3],
          "score": float(scores[i]) }
        for i in range(len(rows))
        if scores[i] >= threshold
    ]
    matches.sort(key=lambda x: x["score"], reverse=True)

    return {
        "isDuplicate": len(matches) > 0,
        "similarCount": len(matches),
        "topMatch": matches[0] if matches else None,
        "allMatches": matches[:5],   # Max 5 shown to user
        "groupId": matches[0].get("groupId") if matches else None,
    }
```

**Threshold:** 0.75 by default (configurable via env var). Scores ≥ 0.75 are treated as duplicates.

---

### 16.7 Node.js Proxy Routes to Python AI Service

Node.js exposes these routes to Flutter — all internally forwarded to Python:

| Node.js Route | Python Service Route | Purpose |
|---|---|---|
| `POST /api/ai/grammar-check` | `POST :8000/grammar-check` | Grammar correction |
| `POST /api/ai/categorize` | `POST :8000/categorize` | Complaint categorization |
| `POST /api/ai/check-duplicate` | `POST :8000/check-duplicate` | Pre-submission duplicate check |
| (internal) `POST :8000/embed` | Called after complaint saved | Embedding generation (not Flutter-facing) |

**Node.js proxy implementation:**
```javascript
const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8000";

router.post("/grammar-check", authenticate, async (req, res) => {
  try {
    const { data } = await axios.post(
      `${AI_SERVICE_URL}/grammar-check`,
      { text: req.body.text },
      { timeout: 5000 }   // 5s timeout — fail silently
    );
    res.json(data);
  } catch (err) {
    // AI service failure: return "no corrections" so form stays usable
    res.json({ hasCorrections: false, correctedText: req.body.text, diffs: [] });
  }
});
```

**Golden rule:** If the Python AI service is down, Node.js **never propagates the error to Flutter**. It returns a safe default response so the form remains fully functional.

---

### 16.8 Grammar Diff Rendering in Flutter

Use `diff_match_patch` package to render word-level diffs returned from the grammar check API:

```dart
List<InlineSpan> buildDiffSpans(List<GrammarDiff> diffs) {
  return diffs.map((diff) {
    switch (diff.type) {
      case 'DELETE':
        return TextSpan(
          text: diff.text,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: AppColors.severityHigh,   // Red
          ),
        );
      case 'INSERT':
        return TextSpan(
          text: diff.text,
          style: TextStyle(
            color: AppColors.accent,          // Teal green
            fontWeight: FontWeight.w600,
            backgroundColor: Color(0x1A00C896),
          ),
        );
      default:
        return TextSpan(text: diff.text);
    }
  }).toList();
}
```

---

## 17. Notifications & Real-time Updates

### 17.1 Firebase Cloud Messaging (FCM) Setup

**Step 1:** Create a Firebase project. Add Android app. Download `google-services.json` to `android/app/`.

**Step 2:** Initialize in `main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await NotificationService.initialize();
```

**Step 3:** Request permission and get FCM token:
```dart
// In NotificationService
Future<void> initialize() async {
  await _messaging.requestPermission(...);
  final token = await _messaging.getToken();
  // Send token to backend: PATCH /api/users/fcm-token
}
```

**Step 4:** Register background message handler:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.showLocalNotification(message);
}
```

### 17.2 Notification Payload Schema

The Node.js backend sends FCM notifications via `firebase-admin` with this structure:

```json
{
  "notification": {
    "title": "Complaint #SCM-2024-0042 Updated",
    "body": "Your complaint has been assigned to Suresh Kumar."
  },
  "data": {
    "type": "COMPLAINT_STATUS_UPDATE",
    "complaintId": "comp-uuid-001",
    "complaintNumber": "SCM-2024-0042",
    "newStatus": "ASSIGNED",
    "timestamp": "2024-06-15T10:30:00Z"
  }
}
```

**Notification Types:**

| Type | Sent To | Trigger |
|---|---|---|
| `COMPLAINT_STATUS_UPDATE` | Submitter | Any status change |
| `COMPLAINT_ASSIGNED` | Staff member | New complaint assigned |
| `SLA_WARNING` | Staff + Admin | SLA < 2 hours remaining |
| `SLA_BREACHED` | Dept Head + Admin | SLA deadline passed |
| `ESCALATION_ALERT` | Admin | Complaint escalated |
| `RESOLUTION_FEEDBACK_REQUEST` | Submitter | Complaint marked Resolved |

### 17.3 Notification Tap Handling

```dart
// In NotificationService — handle tap when app is in background/terminated
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final complaintId = message.data['complaintId'];
  if (complaintId != null) {
    navigatorKey.currentContext?.push(Routes.complaintDetail.replaceAll(':id', complaintId));
  }
});
```

### 17.4 In-App Notification Display

When app is in foreground and FCM arrives:
- Show a custom top banner (not system notification).
- Banner: complaint number + message + tap to view.
- Auto-dismiss after 4 seconds.
- If user is currently viewing the same complaint detail → silently refresh the complaint data.

---

## 18. Error Handling & Offline Strategy

### 18.1 Error Hierarchy

```dart
// exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
}

class NetworkException implements Exception {
  final String message;
}

class CacheException implements Exception {
  final String message;
}

class AuthException implements Exception {
  final String message;  // Token expired, unauthorized, etc.
}
```

### 18.2 Error Display Strategy

| Error Type | Display Method |
|---|---|
| Form validation errors | Inline red text below field |
| API errors on page load | Full-screen `ErrorWidget` with retry button |
| API errors on action (submit, update) | `SnackBar` at bottom with error message + retry |
| Network offline on page load | `EmptyStateWidget` with offline icon + "Check connection" message |
| Network offline on action | `SnackBar`: "You're offline. Changes will sync when connected." |
| Auth expired | Automatic redirect to Login with `SnackBar`: "Session expired. Please log in again." |

### 18.3 Offline Draft Strategy

**Flow:**
1. User opens Submit Complaint form (no internet).
2. App detects offline via `ConnectivityPlus`.
3. User fills form → taps Submit.
4. App saves form data to Hive as `ComplaintDraft`.
5. Shows success-like animation with message: "Saved as Draft. Submit when you're online."
6. On returning online → `ConnectivityPlus` fires event → check Hive for pending drafts.
7. Show banner: "You have 1 pending draft. Tap to submit."

**Hive Setup:**
```dart
// In StorageService.initialize()
await Hive.initFlutter();
Hive.registerAdapter(ComplaintDraftAdapter());
await Hive.openBox<ComplaintDraft>('drafts');
```

### 18.4 Loading States

Every list and detail screen must handle 4 states:
1. **Loading** → Show shimmer skeleton.
2. **Loaded** → Show content.
3. **Empty** → Show `EmptyStateWidget` with relevant illustration and message.
4. **Error** → Show `ErrorWidget` with retry button.

---

## 19. Security Requirements

### 19.1 Token Storage

- SCMS JWT access token and refresh token stored in `flutter_secure_storage` (Android Keystore / iOS Keychain).
- **Never** store tokens in `SharedPreferences` or plain local files.
- The Google `idToken` is **never persisted** — it is used once to call `POST /api/auth/google` and then discarded.
- There are no passwords in this system. Never store or transmit a password.

### 19.2 Google OAuth Domain Restriction — Two Layers

**Layer 1 — Flutter (UX gate):**
```dart
GoogleSignIn(
  hostedDomain: "rvce.edu.in",  // Only @rvce.edu.in shown in picker
  serverClientId: Env.googleServerClientId,
)
```

**Layer 2 — Node.js Backend (hard enforcement):**
```javascript
const ticket = await oAuth2Client.verifyIdToken({ idToken, audience: CLIENT_ID });
const payload = ticket.getPayload();

// Hard reject — cannot be bypassed by modifying Flutter code
if (payload.hd !== "rvce.edu.in" && !isAllowedDomain(payload.email)) {
  return res.status(403).json({ error: "DOMAIN_NOT_ALLOWED" });
}
if (!payload.email_verified) {
  return res.status(403).json({ error: "EMAIL_NOT_VERIFIED" });
}
```

**Rule:** Layer 1 is for UX convenience. Layer 2 is the real security gate. Both must be in place.

### 19.3 API Security

- All endpoints except `POST /auth/google` require `Authorization: Bearer <SCMS JWT>` header.
- Token refresh happens automatically via `AuthInterceptor` in Dio.
- Node.js verifies SCMS JWT signature on every protected request using `APP_JWT_SECRET` from `.env`.
- On logout: call `POST /auth/logout` (invalidates refresh token in DB), then clear tokens from `flutter_secure_storage` and clear Hive drafts.

### 19.4 AI Service Security

- The Gemini API Key (`GEMINI_API_KEY`) lives **only** in the Python AI service `.env`. It is never in the Node.js `.env`, never in Flutter, and never in version control.
- The Python AI service is **not publicly accessible** — it listens on `localhost:8000` or within a private Docker network. Only Node.js can call it.
- All Gemini API calls are made server-side. The API key is never exposed to clients.

### 19.5 Media Upload Security

- Accept only `.jpg`, `.jpeg`, `.png`, `.mp4` — validated on Flutter before upload and on Node.js with `multer` file filter.
- Size limits: 5 MB per photo, 30 MB per video — enforced on Flutter and Node.js middleware.
- All media served via HTTPS signed URLs only.
- Original unwatermarked photos are discarded client-side after watermark baking.

### 19.6 Input Sanitization

- All text inputs trimmed before API submission.
- Node.js uses `zod` schemas to validate every request body — invalid input returns 422.
- No HTML rendering of user content in Flutter (`Text` widgets only, no `WebView`).
- PostgreSQL queries use Prisma parameterized queries — no raw SQL injection possible in main API.

### 19.7 Role Enforcement

- Flutter UI guards are convenience — not security. Backend enforces roles on every request.
- If a non-admin user somehow reaches an admin route → show "Access Denied" screen.
- Node.js middleware: `requireRole(["ROLE_ADMIN"])` on admin endpoints — returns 403 if insufficient.
- SR can only access complaints from their assigned zone — `zoneId` check on every SR endpoint.

### 19.8 pgvector Embeddings Privacy

- Embeddings stored in PostgreSQL contain no raw personal information — they are semantic vectors of the complaint text only.
- The complaint text itself is stored separately with standard access controls.

---

## 20. Testing Strategy

### 20.1 Unit Tests

**Location:** `test/unit/`

**What to test:**

| Subject | Tests |
|---|---|
| `ComplaintModel.fromJson` | Correct parsing of all fields; null safety for optional fields |
| `AuthBloc` | All state transitions for login events |
| `SubmitComplaintCubit` | AI preview fetch; form validation; draft save |
| `Validators` | Email format, password strength, min length |
| `DateFormatter` | Relative time formatting ("2 hours ago", "Yesterday") |

**Example unit test (BLoC):**
```dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthAuthenticated] when login succeeds',
  build: () {
    when(() => mockAuthRepo.login(any(), any()))
        .thenAnswer((_) async => Right(mockUser));
    return AuthBloc(authRepo: mockAuthRepo);
  },
  act: (bloc) => bloc.add(LoginSubmitted(email: 'a@b.com', password: 'pass123')),
  expect: () => [isA<AuthLoading>(), isA<AuthAuthenticated>()],
);
```

### 20.2 Widget Tests

**Location:** `test/widget/`

**What to test:**

| Widget | Tests |
|---|---|
| `LoginPage` | Renders all fields; Submit button disabled when fields empty; Shows error SnackBar on failure |
| `ComplaintCard` | Renders subject, status badge, SLA timer; Tap navigates correctly |
| `StatusBadge` | Correct label and color for each status value |
| `ScmsButton` | Shows loading spinner when `isLoading: true`; Disabled when `isEnabled: false` |

**Example widget test:**
```dart
testWidgets('ComplaintCard shows correct status badge', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: ComplaintCard(complaint: mockComplaintOpen)),
  );
  expect(find.text('Open'), findsOneWidget);
  expect(find.byType(StatusBadge), findsOneWidget);
});
```

### 20.3 Integration Tests (Optional — P2)

- End-to-end login flow using `integration_test` package.
- Submit complaint flow with mocked API.

### 20.4 Code Coverage Target

- Unit tests: > 70% line coverage on BLoC and repository classes.
- Widget tests: all P0 widgets covered.

---

## 21. Build & Deployment

### 21.1 Environment Files

There are **three separate `.env` files** — one per service. All are gitignored. `.env.example` files are committed.

---

**Flutter app — `scms_flutter/.env`:**
```
# Node.js main API base URL
API_BASE_URL=http://192.168.1.100:3000

# Google OAuth — Web Client ID from Google Cloud Console
GOOGLE_SERVER_CLIENT_ID=xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com

# Firebase
FIREBASE_PROJECT_ID=scms-campus-app
```

---

**Node.js main API — `scms_backend/.env`:**
```
# Server
PORT=3000
NODE_ENV=development

# PostgreSQL (Prisma)
DATABASE_URL=postgresql://scms_user:scms_pass@localhost:5432/scms_db

# JWT
APP_JWT_SECRET=your_super_secret_jwt_key_here
JWT_ACCESS_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=30d

# Google OAuth
GOOGLE_CLIENT_ID=xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
ALLOWED_DOMAINS=rvce.edu.in   # comma-separated if multiple

# Firebase Admin (FCM)
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# Python AI service
AI_SERVICE_URL=http://localhost:8000

# Media storage (Firebase Storage bucket or Cloudinary)
FIREBASE_STORAGE_BUCKET=scms-campus-app.appspot.com
```

---

**Python AI service — `scms_ai_service/.env`:**
```
# Google AI Studio
GEMINI_API_KEY=AIzaSy...

# PostgreSQL (read embeddings)
DATABASE_URL=postgresql://scms_user:scms_pass@localhost:5432/scms_db

# Duplicate detection
SIMILARITY_THRESHOLD=0.75

# Server
PORT=8000
```

### 21.2 Flavor Configuration (Optional but Recommended)

```
Dev flavor: API_BASE_URL = local server
Staging flavor: API_BASE_URL = staging server
Production flavor: API_BASE_URL = production server
```

Configure via `flutter_flavorizr` or manual `main_dev.dart`, `main_prod.dart` entry points.

### 21.3 Android Build

**Minimum SDK:** 21 (Android 5.0)
**Target SDK:** 34 (Android 14)
**Build command (debug):** `flutter run`
**Build command (release APK):** `flutter build apk --release`
**Build command (release AAB):** `flutter build appbundle --release`

**Required permissions in `AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### 21.4 pubspec.yaml Template

```yaml
name: scms_flutter
description: Smart Complaint Management System
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.3
  flutter_bloc: ^8.1.5
  go_router: ^13.2.0
  flutter_secure_storage: ^9.0.0
  image_picker: ^1.1.2
  firebase_core: ^2.30.0
  firebase_messaging: ^14.9.1
  flutter_local_notifications: ^17.1.2
  cached_network_image: ^3.3.1
  fl_chart: ^0.68.0
  lottie: ^3.1.0
  flutter_dotenv: ^5.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^6.0.3
  intl: ^0.19.0
  permission_handler: ^11.3.1
  shimmer: ^3.0.0
  fluttertoast: ^8.2.6
  provider: ^6.1.2
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  hive_generator: ^2.0.1
  build_runner: ^2.4.9

flutter:
  uses-material-design: true
  assets:
    - .env
    - assets/images/
    - assets/animations/
    - assets/icons/
```

---

## 22. Step-by-Step Implementation Plan for AI Agent

> **Instructions for AI Agent:** Execute each step in exact order. Do not begin the next step until the current step is fully complete and verified. After completing each step, run `flutter analyze` and fix all warnings before proceeding.

---

### Phase 0: Project Setup (All Three Services)

**Step 0.1 — Monorepo structure:**
```bash
mkdir scms_project && cd scms_project
git init
# Three sub-projects:
# scms_flutter/     → Flutter mobile app
# scms_backend/     → Node.js + Express API
# scms_ai_service/  → Python FastAPI AI service
```

**Step 0.2 — Flutter project:**
```bash
flutter create scms_flutter --org com.scms --platforms android
cd scms_flutter
```
- Copy `pubspec.yaml` from Section 21.4 exactly. Run `flutter pub get`.
- Scaffold full directory structure from Section 8.
- Create `.env` and add to `.gitignore`.
- Load in `main.dart`: `await dotenv.load(fileName: ".env");`

**Step 0.3 — Node.js backend:**
```bash
mkdir scms_backend && cd scms_backend
npm init -y
npm install express prisma @prisma/client jsonwebtoken google-auth-library \
  multer node-cron firebase-admin axios zod bcryptjs cors helmet morgan dotenv uuid
npm install --save-dev nodemon typescript @types/node @types/express ts-node
npx prisma init   # Creates prisma/schema.prisma + .env
```
- Create `.env` with all vars from Section 21.1 (Node.js block).
- Create folder structure: `src/routes/`, `src/middleware/`, `src/services/`, `src/jobs/`.

**Step 0.4 — Prisma schema setup:**

Key models in `prisma/schema.prisma`:
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id           String    @id @default(uuid())
  googleId     String    @unique
  name         String
  email        String    @unique
  picture      String?
  role         String    @default("ROLE_USER")
  zoneId       String?
  departmentId String?
  fcmToken     String?
  isApproved   Boolean   @default(true)
  createdAt    DateTime  @default(now())
  lastLogin    DateTime?
  complaints   Complaint[]
}

model Complaint {
  id               String    @id @default(uuid())
  complaintNumber  String    @unique
  title            String
  description      String
  location         String
  gpsLatitude      Float?
  gpsLongitude     Float?
  gpsPlaceName     String?
  categoryId       String
  departmentId     String
  severity         String
  status           String    @default("PENDING_SR_REVIEW")
  tags             String[]
  submittedById    String
  assignedToId     String?
  reviewedBySrId   String?
  srRejectionCause String?
  isGrammarCorrected Boolean @default(false)
  isAiCategorized  Boolean  @default(false)
  aiConfidenceScore Float?
  duplicateGroupId  String?
  slaDeadline      DateTime?
  isSlaBreached    Boolean  @default(false)
  rating           Float?
  ratingComment    String?
  // embedding stored via raw SQL with pgvector — not a Prisma field
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt
  submittedBy      User     @relation(fields: [submittedById], references: [id])
  mediaItems       MediaItem[]
  updates          ComplaintUpdate[]
}

model MediaItem {
  id           String    @id @default(uuid())
  complaintId  String
  url          String
  mediaType    String
  thumbnailUrl String?
  gpsLatitude  Float
  gpsLongitude Float
  gpsPlaceName String
  capturedAt   DateTime
  isWatermarked Boolean @default(false)
  fileSizeBytes Int
  complaint    Complaint @relation(fields: [complaintId], references: [id])
}

model ComplaintUpdate {
  id             String    @id @default(uuid())
  complaintId    String
  updatedById    String
  updatedByName  String
  updatedByRole  String
  previousStatus String
  newStatus      String
  notes          String?
  timestamp      DateTime  @default(now())
  complaint      Complaint @relation(fields: [complaintId], references: [id])
}

model AllowedDomain {
  id          String   @id @default(uuid())
  domain      String   @unique
  description String?
  createdAt   DateTime @default(now())
}

model RefreshToken {
  id        String   @id @default(uuid())
  token     String   @unique
  userId    String
  expiresAt DateTime
  createdAt DateTime @default(now())
}
```

```bash
# Enable pgvector then run migration
npx prisma migrate dev --name init
# After migration, run manually:
# psql -U scms_user -d scms_db -c "CREATE EXTENSION IF NOT EXISTS vector;"
# ALTER TABLE complaints ADD COLUMN embedding vector(768);
```

**Step 0.5 — Python AI service:**
```bash
mkdir scms_ai_service && cd scms_ai_service
python3 -m venv venv && source venv/bin/activate
pip install fastapi uvicorn google-generativeai numpy scikit-learn \
  psycopg2-binary pydantic python-dotenv
```
- Create `.env` with Gemini key, DB URL, threshold (Section 21.1 Python block).
- Create folder structure: `routers/`, `services/`, `models/`.

**Step 0.6 — Docker Compose (optional but recommended for local dev):**
```yaml
# docker-compose.yml at project root
version: '3.8'
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: scms_user
      POSTGRES_PASSWORD: scms_pass
      POSTGRES_DB: scms_db
    ports: ["5432:5432"]

  backend:
    build: ./scms_backend
    ports: ["3000:3000"]
    depends_on: [postgres]
    env_file: ./scms_backend/.env

  ai_service:
    build: ./scms_ai_service
    ports: ["8000:8000"]
    depends_on: [postgres]
    env_file: ./scms_ai_service/.env
```
Using `pgvector/pgvector:pg16` Docker image gives PostgreSQL 16 with pgvector already installed.

**Step 0.7 — Firebase Setup:**
- Create `firebase_options.dart` in Flutter (auto-generated by FlutterFire CLI).
- Download `google-services.json` → `android/app/`.
- Download Firebase Admin SDK service account JSON → `scms_backend/firebase-service-account.json` (gitignored).
- Call `Firebase.initializeApp()` in Flutter `main.dart`.

**Step 0.8 — Google Cloud Console setup (document for team):**
1. Create project at console.cloud.google.com.
2. Enable "Google Sign-In" API.
3. Create OAuth 2.0 credentials:
   - **Web Client** → copy Client ID → paste as `GOOGLE_CLIENT_ID` in Node.js `.env` and `GOOGLE_SERVER_CLIENT_ID` in Flutter `.env`.
   - **Android Client** → use SHA-1 fingerprint of your debug keystore → needed for `google_sign_in` on device.
4. Add authorized domains: `rvce.edu.in`.

---

### Phase 1: Foundation

**Step 1.1 — Design System**
- Implement `app_colors.dart` (Section 15.1) completely.
- Implement `app_text_styles.dart` (Section 15.2) completely.
- Implement `app_theme.dart`: create `ThemeData.light()` and `ThemeData.dark()` using the colors and text styles above. Set `colorScheme`, `textTheme`, `inputDecorationTheme`, `elevatedButtonTheme`, `cardTheme`.

**Step 1.2 — Constants**
- Implement `api_constants.dart`: `baseUrl` from dotenv, all endpoint path strings.
- Implement `route_constants.dart`: all `Routes` class constants (Section 14.2).
- Implement `app_constants.dart`: SLA threshold percentages, max photo count, max description length, etc.

**Step 1.3 — Data Models**
- Implement all 7 model classes from Section 11 completely.
- Write `fromJson` and `toJson` for every model.
- Write `Hive TypeAdapter` for `ComplaintDraft`.
- Run `flutter analyze` — zero warnings.

**Step 1.4 — Utilities**
- Implement `date_formatter.dart`: `formatRelative(DateTime)`, `formatFull(DateTime)`, `formatSla(DateTime)`.
- Implement `validators.dart`: `validateEmail()`, `validatePassword()`, `validateNotEmpty()`, `validateMinLength()`.
- Implement `extensions.dart`: `String.capitalize()`, `String.toStatusColor()`, `DateTime.timeAgoString()`.
- Implement `logger.dart`: wrapper over `debugPrint` that is a no-op in release mode.

---

### Phase 2: Core Services + Network Layer

**Step 2.1 — Network Info**
- Implement `network_info.dart` using `connectivity_plus`.
- Expose: `Future<bool> get isConnected`.

**Step 2.2 — Dio Client**
- Implement `dio_client.dart` with `AuthInterceptor`, `LoggingInterceptor` (Section 13.5).
- `AuthInterceptor`: reads SCMS JWT from `FlutterSecureStorage`, adds `Authorization: Bearer` header, handles 401 by calling `POST /api/auth/refresh`.
- `LoggingInterceptor`: print request URL + response status in debug mode only.

**Step 2.3 — Remote Data Sources (updated for Google OAuth):**
- Implement `auth_remote_datasource.dart`:
  - `googleSignIn()` → calls `google_sign_in`, gets Google idToken, calls `POST /api/auth/google`.
  - `refreshToken(refreshToken)` → `POST /api/auth/refresh`.
  - `getMe()` → `GET /api/auth/me`.
  - `logout()` → `POST /api/auth/logout`.
  - **No** `login()`, `register()`, `checkEmail()` methods — these do not exist in v3.
- Implement `complaint_remote_datasource.dart`: all complaint methods (same as before, including new duplicate check + AI endpoints).

**Step 2.4 — Local Data Sources**
- Implement `auth_local_datasource.dart`: save/get/delete SCMS JWT + refresh token from `FlutterSecureStorage`. Also save/get `UserModel` as JSON string.
- Implement `complaint_local_datasource.dart`: Hive draft CRUD.

**Step 2.5 — Repositories**
- Implement `auth_repository.dart`.
- Implement `complaint_repository.dart`.
- Implement `sr_review_repository.dart`.

---

### Phase 3: State Management

**Step 3.1 — AuthBloc**
- Implement `auth_event.dart`, `auth_state.dart`, `auth_bloc.dart` (Section 13.2).
- Handle: `AppStarted`, `LoginSubmitted`, `RegisterSubmitted`, `LogoutRequested`, `TokenRefreshRequested`.
- `AppStarted` reads token from storage and validates with backend.

**Step 3.2 — ComplaintBloc**
- Implement `complaint_event.dart`, `complaint_state.dart`, `complaint_bloc.dart` (Section 13.3).

**Step 3.3 — SubmitComplaintCubit**
- Implement `submit_complaint_cubit.dart` + `submit_complaint_state.dart` (Section 13.4).
- Include debounced AI preview fetch logic.

**Step 3.4 — AnalyticsCubit**
- Implement `analytics_cubit.dart`: loads analytics data from `analytics_repository`.
- State: loading, loaded (with `AnalyticsModel`), error.

---

### Phase 4: Navigation & App Shell

**Step 4.1 — GoRouter Setup**
- Implement full GoRouter in `app.dart` with all routes from `route_constants.dart`.
- Implement redirect guard (Section 14.1).
- Implement `_getRoleHome()` function (Section 14.3).

**Step 4.2 — Main App**
- In `main.dart`: initialize services, set up `MultiBlocProvider` with `AuthBloc`, wrap `MaterialApp.router` with theme.
- App must handle light/dark theme based on system settings.

**Step 4.3 — Global Providers**
- Wrap the entire app with `MultiBlocProvider` providing: `AuthBloc`, `ComplaintBloc`, `SubmitComplaintCubit`, `AnalyticsCubit`.

---

### Phase 5: Common Widgets

**Step 5.1 — `ScmsButton`**
- Implement with all variants: primary, secondary, destructive.
- `isLoading` parameter replaces label with spinner.
- `isEnabled` parameter controls disabled state.
- Enforce 52px minimum height, 12px border radius.

**Step 5.2 — `ScmsTextField`**
- Implement with: label, hint, error text, suffix/prefix icon, obscure text toggle, keyboard type, max lines, max length.
- Uses `AppTextStyles` and `AppColors` consistently.

**Step 5.3 — `StatusBadge`**
- Maps status strings to label + color pair.
- Pill shape, 6px horizontal padding, 3px vertical padding.

**Step 5.4 — `SlaTimerWidget`**
- Takes `DateTime slaDeadline` parameter.
- Uses `Timer.periodic(Duration(seconds: 1), ...)` to recalculate remaining time.
- Disposes timer on widget disposal.
- Shows breached state clearly.

**Step 5.5 — `LoadingOverlay`**
- `Stack` with semi-transparent black overlay + `CircularProgressIndicator` centered.
- Controlled by `isLoading` boolean parameter.

**Step 5.6 — `ErrorWidget` (custom name: `ScmsErrorWidget`)**
- Takes `message` and `onRetry` callback.
- Shows an error illustration, message text, and "Try Again" button.

**Step 5.7 — `EmptyStateWidget`**
- Takes `message` and optional `actionLabel` + `onAction`.
- Shows illustration + message + optional action button.

**Step 5.8 — `ComplaintCard`**
- Implement as per Section 15.3, using all sub-widgets.

**Step 5.9 — `PhotoPickerWidget`**
- Shows dashed border zone. Tapping opens `showModalBottomSheet` with Camera/Gallery options.
- After picking: shows thumbnail grid with delete buttons.
- Enforces max 3 photos and 5 MB per file.

**Step 5.10 — `CategorySelectorWidget`**
- Horizontal scroll view of tappable chips.
- Selected chip: `AppColors.primary` background, white text.
- Unselected chip: outline style, `AppColors.primary` text.

---

### Phase 6: Screens — Auth Flow

**Step 6.1 — SplashPage**
- Implement as per Section 10.1.
- Auth check: read SCMS JWT from `FlutterSecureStorage` → call `GET /api/auth/me`.
- On success: dispatch `AppStarted` → `AuthAuthenticated` → route by role.
- On failure (expired/missing): → `AuthUnauthenticated` → `LoginPage`.

**Step 6.2 — OnboardingPage**
- Implement 4-slide `PageView` as per Section 10.2.

**Step 6.3 — LoginPage (Google Sign-In — no email/password)**

The login page is minimal. Its only interactive element is a Google Sign-In button.

**UI:**
- Full-screen background: `AppColors.primary` gradient (same as splash).
- SCMS logo centered (120px).
- App name + tagline.
- Spacer.
- **"Sign in with Google"** button:
  - White background, Google "G" logo on left (use `google_fonts` or bundled asset), "Sign in with Google" label in dark text.
  - Standard Google Sign-In button appearance (follow Google's brand guidelines).
  - Height: 52px, width: 280px, border radius: 8px, border: 1px `AppColors.border`.
- Below button: small text "Only @rvce.edu.in accounts are permitted."
- `BlocConsumer<AuthBloc, AuthState>`:
  - `AuthLoading` → show `LoadingOverlay`.
  - `AuthAuthenticated` → `GoRouter.go(_getRoleHome(user.role))`.
  - `AuthFailure` → show SnackBar with error message.
  - Special error `DOMAIN_NOT_ALLOWED` → show bottom sheet: "This app is only available to RVCE students and staff. Please sign in with your @rvce.edu.in Google account."

**No Register page exists.** Users are registered automatically on first Google sign-in. No email/password fields anywhere in the app.

**BLoC event on button tap:** `GoogleSignInRequested()`

**`AuthBloc` handling `GoogleSignInRequested`:**
```dart
on<GoogleSignInRequested>((event, emit) async {
  emit(AuthLoading());
  try {
    final idToken = await authRepo.getGoogleIdToken();
    final fcmToken = await notificationService.getToken();
    final result = await authRepo.signInWithGoogle(idToken, fcmToken);
    await authLocalDataSource.saveTokens(result.accessToken, result.refreshToken);
    await authLocalDataSource.saveUser(result.user);
    emit(AuthAuthenticated(user: result.user));
  } on DomainNotAllowedException {
    emit(AuthFailure(message: "DOMAIN_NOT_ALLOWED"));
  } on AuthException catch (e) {
    emit(AuthFailure(message: e.message));
  }
});
```

---

### Phase 7: Screens — Student/User Flow

**Step 7.1 — HomePage (User)**
- Implement with 3-tab `BottomNavigationBar`.
- Dynamic greeting based on time of day.
- Notification badge on bell icon.

**Step 7.2 — MyComplaintsPage**
- Implement with filter chips, shimmer loading, `RefreshIndicator`, empty state.

**Step 7.3 — SubmitComplaintPage**
- Implement full form as per Section 10.7.
- AI preview integration (debounced, banner widget).
- Offline draft saving.
- Photo picker.

**Step 7.4 — ComplaintDetailPage**
- Implement full detail view as per Section 10.8.
- Timeline list with all update types.
- Hero animation on photo tap.
- Rating section shown conditionally.

**Step 7.5 — RatingPage**
- Star rating widget (1–5 stars, tappable).
- Optional comment field.
- Submit button calls `POST /api/complaints/{id}/rating`.

---

### Phase 8: Screens — Staff Flow

**Step 8.1 — StaffDashboardPage**
- Implement as per Section 10.9.
- Load assigned complaints on init.
- Filter tabs work correctly.

**Step 8.2 — StaffComplaintDetailPage**
- Extends detail page with action panel.
- Status update dispatches `UpdateComplaintStatus` event.
- Status transition rules enforced (Section 10.10).

---

### Phase 9: Screens — Admin Flow

**Step 9.1 — AdminDashboardPage**
- Implement `CustomScrollView` + `SliverAppBar`.
- KPI cards loaded from `AnalyticsCubit`.
- Bar chart using `fl_chart` for department data.
- Donut chart for category breakdown.
- Recent SLA breaches list.

**Step 9.2 — AdminComplaintsListPage**
- Implement searchable, filterable list.
- Pagination support.
- Long-press context menu with [Reassign, Escalate, Close] actions.

---

### Phase 10: Services & Notifications

**Step 10.1 — NotificationService**
- FCM initialization, permission request, token retrieval.
- After Google sign-in succeeds: call `PATCH /api/users/fcm-token` with the device FCM token.
- Handle foreground (custom in-app banner), background, and terminated states.
- Tap navigates to complaint detail using `complaintId` from FCM `data` payload.

**Step 10.2 — StorageService**
- Hive initialization with all registered adapters.
- Expose methods to manage draft storage.

**Step 10.3 — Offline Sync**
- `ConnectivityPlus` stream listener at app level.
- On reconnect: check for pending drafts → show prompt to submit.

---

### Phase 10B: Node.js Backend Implementation (Reference for Backend Developer)

> This phase is for the backend developer on the team. AI agents building only the Flutter app can skip to Phase 11.

**Step 10B.1 — Auth routes (`src/routes/auth.js`):**
```javascript
// POST /api/auth/google
router.post('/google', async (req, res) => {
  const { idToken, fcmToken } = req.body;
  // 1. Verify with Google oauth2 library
  // 2. Check hd claim against allowed_domains table
  // 3. Upsert user
  // 4. Issue SCMS JWT
  // 5. Return tokens + user
});
```

**Step 10B.2 — Domain check middleware:**
```javascript
async function checkAllowedDomain(email, hd) {
  const domains = await prisma.allowedDomain.findMany();
  const allowed = domains.map(d => d.domain);
  return allowed.includes(hd) || allowed.some(d => email.endsWith(`@${d}`));
}
```

**Step 10B.3 — SLA scheduler (`src/jobs/sla.js`):**
```javascript
const cron = require('node-cron');
// Run every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  const breached = await prisma.complaint.findMany({
    where: {
      slaDeadline: { lte: new Date() },
      isSlaBreached: false,
      status: { notIn: ['RESOLVED', 'CLOSED', 'REJECTED'] }
    }
  });
  for (const c of breached) {
    await prisma.complaint.update({
      where: { id: c.id },
      data: { isSlaBreached: true }
    });
    // Send FCM SLA_BREACHED to dept head + admin
  }
});
```

**Step 10B.4 — Async embedding job:**
After a complaint is saved, call the Python AI service in the background (don't await in the request handler):
```javascript
// Fire-and-forget
setImmediate(async () => {
  try {
    const { data } = await axios.post(`${AI_SERVICE_URL}/embed`,
      { text: complaint.description });
    await prisma.$executeRaw`
      UPDATE complaints SET embedding = ${data.embedding}::vector WHERE id = ${complaint.id}
    `;
  } catch (e) {
    logger.warn('Embedding failed for complaint', complaint.id);
  }
});
```

**Step 10B.5 — FCM sending (`src/services/fcm.js`):**
```javascript
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function sendToUser(userId, { title, body, data }) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.fcmToken) return;
  await admin.messaging().send({
    token: user.fcmToken,
    notification: { title, body },
    data,
  });
}
```

---

### Phase 10C: Python AI Service Implementation (Reference for AI Developer)

> This phase is for the AI/ML developer on the team.

**Step 10C.1 — `main.py`:**
```python
from fastapi import FastAPI
from routers import grammar, categorize, embed, duplicate

app = FastAPI(title="SCMS AI Service")
app.include_router(grammar.router)
app.include_router(categorize.router)
app.include_router(embed.router)
app.include_router(duplicate.router)
```

**Step 10C.2 — `services/gemini_client.py`:**
```python
import google.generativeai as genai
import os

genai.configure(api_key=os.environ["GEMINI_API_KEY"])

def get_flash_model(system_prompt: str):
    return genai.GenerativeModel(
        model_name="gemini-2.5-flash",
        generation_config=genai.GenerationConfig(
            response_mime_type="application/json",
            temperature=0.1,
        ),
        system_instruction=system_prompt,
    )

def get_embedding_model():
    return "models/gemini-embedding-001"
```

**Step 10C.3 — Implement all 4 routers** per Section 16 specs:
- `routers/grammar.py` → grammar-check endpoint (Section 16.3).
- `routers/categorize.py` → categorize endpoint (Section 16.4).
- `routers/embed.py` → embed endpoint (Section 16.5).
- `routers/duplicate.py` → check-duplicate endpoint (Section 16.6).

**Step 10C.4 — Run:**
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

### Phase 11: Settings Screen

**Step 11.1 — SettingsPage**
- Profile card: user's Google profile picture (`CachedNetworkImage`), name, email, role badge.
- **No "Change Password" option** — authentication is fully managed by Google.
- Notification preferences toggle.
- Theme selector (Light / Dark / System).
- About section: app version + "Authentication powered by Google".
- Logout button → confirm dialog → `LogoutRequested` → `google_sign_in.signOut()` + clear SCMS tokens from `FlutterSecureStorage` + navigate to LoginPage.

---

### Phase 12: Polish & Error Handling

**Step 12.1 — Global Error Handling**
- Wrap root widget with `ErrorBoundary` or use `FlutterError.onError` to catch and log unexpected errors.
- Implement `AnalyticsService` (Firebase Crashlytics stub or print-based logger).

**Step 12.2 — Accessibility**
- Add `Semantics` labels to all icon buttons.
- Ensure minimum tap target size 48×48 px for all interactive elements.
- Use `Tooltip` on icon-only buttons.

**Step 12.3 — Performance**
- All lists use `ListView.builder` (not `ListView` with children).
- Images use `CachedNetworkImage` with `memCacheWidth` limits.
- BLoC states are `equatable` (implement `Equatable` or `@override == and hashCode`).
- Use `const` constructors wherever possible.

---

### Phase 13: Testing

**Step 13.1 — Unit Tests**
- Write unit tests for all models' `fromJson` methods.
- Write unit tests for `AuthBloc` state transitions.
- Write unit tests for `Validators`.
- Write unit tests for `DateFormatter`.

**Step 13.2 — Widget Tests**
- Write widget tests for `LoginPage` (renders, validation, error).
- Write widget tests for `ComplaintCard` (status badge, SLA timer).
- Write widget tests for `ScmsButton` (loading state, disabled state).

**Step 13.3 — Run All Tests**
```bash
flutter test
flutter analyze
```
Fix all failures before considering the project complete.

---

### Phase 14: Final Build

**Step 14.1 — Release Build**
```bash
flutter build apk --release
```
Verify APK builds without errors.

**Step 14.2 — README**
Write a comprehensive `README.md` including:
- Project overview.
- Setup instructions (Flutter version, Firebase setup steps, backend URL config).
- How to run in dev mode.
- How to build release APK.
- Architecture diagram reference.
- Screenshots (placeholder).

---

## 23. Acceptance Criteria & Definition of Done

A feature is considered **done** when all of the following are true:

| # | Criterion |
|---|---|
| 1 | Feature works end-to-end with a live backend API call |
| 2 | All 4 UI states (loading, loaded, empty, error) are handled |
| 3 | `flutter analyze` returns zero issues for files in that feature |
| 4 | No hardcoded strings — all UI text uses constants or is parameterized |
| 5 | Role-based access is enforced — wrong roles cannot access feature |
| 6 | Form validations prevent invalid data from reaching the API |
| 7 | Offline behavior is handled gracefully (no crashes, informative messages) |
| 8 | Relevant unit or widget test exists and passes |
| 9 | PR/commit is titled with the feature ID (e.g., "[F05] Submit Complaint") |
| 10 | No `print()` statements in production code (use `logger.dart`) |

---

## 24. Appendix

### 24.1 Complaint Status State Machine

```
         submit
  ┌─────────────────┐
  │                 ▼
  │             [OPEN]
  │                 │ AI categorizes + assigns dept
  │                 ▼
  │          [ASSIGNED] ←─── Admin reassigns
  │                 │ Staff taps "Start Working"
  │                 ▼
  │        [IN_PROGRESS]
  │                 │ Staff marks resolved
  │                 ▼
  │           [RESOLVED]
  │                 │ Admin reviews / SLA satisfied
  │                 ▼
  │            [CLOSED]
  │                 │
  └─────────────────┘ (Admin can reopen → OPEN)
```

### 24.2 SLA Policy (Default)

| Severity | Response Time | Resolution Time |
|---|---|---|
| HIGH | 2 hours | 8 hours |
| MEDIUM | 8 hours | 48 hours |
| LOW | 24 hours | 7 days |

These are defaults; configurable by Admin in future version.

### 24.3 Category → Department Mapping

| Category | Default Department |
|---|---|
| Electrical | Electrical & Maintenance Dept. |
| Plumbing | Civil & Plumbing Dept. |
| IT/Network | IT Infrastructure Dept. |
| Housekeeping | Housekeeping & Sanitation |
| Furniture | Civil & Maintenance |
| AC/HVAC | Electrical & Maintenance Dept. |
| Other | Administration (manual triage) |

### 24.4 API Error Response Schema (Standard)

```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable message for display.",
  "details": {
    "field": "error detail"    // Optional, for validation errors
  },
  "timestamp": "2024-06-15T10:30:00Z",
  "path": "/api/complaints"
}
```

The Flutter app must parse `message` for SnackBar display and `details` for field-level error display.

### 24.5 Glossary

| Term | Definition |
|---|---|
| SLA | Service Level Agreement — the maximum time committed for resolving a complaint |
| FCM | Firebase Cloud Messaging — Google's push notification service |
| JWT | JSON Web Token — the authentication token format used by this system |
| Google idToken | A short-lived Google-signed JWT issued after Google Sign-In — sent once to the backend to get a SCMS JWT |
| SCMS JWT | The app's own JWT issued after verifying the Google idToken — used for all subsequent API calls |
| BLoC | Business Logic Component — the state management pattern used in this app |
| Triage | The process of categorizing and assigning complaints to the right department |
| NLP | Natural Language Processing — the AI technique used to analyze complaint text |
| Escalation | Automatic promotion of a complaint to a higher authority when SLA is breached |
| pgvector | PostgreSQL extension for storing and querying high-dimensional vectors (embeddings) |
| Embedding | A 768-dimensional numerical representation of complaint text, generated by gemini-embedding-001, used for semantic similarity |
| Cosine Similarity | A measure of similarity between two vectors — used to detect duplicate complaints (score 0 = unrelated, 1 = identical) |
| hostedDomain | A `google_sign_in` parameter that restricts the Google account picker to show only accounts from a specific domain (e.g., rvce.edu.in) |
| hd claim | The "hosted domain" field in a Google ID Token payload — used by the backend to verify the user's Google Workspace domain |
| Prisma | A Node.js ORM that generates type-safe database clients and manages PostgreSQL schema migrations |
| FastAPI | A Python web framework for building the AI microservice — high-performance, async, OpenAPI auto-documented |
| SR | Student Representative — elected student responsible for reviewing complaints in their assigned zone |
| Zone | A geographic campus area (e.g., Hostel Block C) assigned to an SR |
| Watermark | Date + time + GPS place name text overlay baked permanently into captured photos |

---

*End of PRD — Smart Complaint Management System (SCMS) v3.0.0*

*Prepared for: MCA Mobile Application Development Subject*
*Flutter | Node.js + Express + Prisma | Python FastAPI | PostgreSQL + pgvector | Google OAuth 2.0 | Gemini 2.5 Flash*
*Academic Institution: RV College of Engineering*

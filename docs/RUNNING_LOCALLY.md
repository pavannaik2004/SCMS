# Running SCMS Locally

How to start every piece of the stack (backend, AI service, Flutter app) and
test on a real Android phone. Written for Windows + PowerShell, which is how
this project is normally run.

> Testing with someone else's phone too (not just your own dev device)?
> See [`docs/TESTING_WITH_FRIENDS.md`](TESTING_WITH_FRIENDS.md) — covers
> sharing a release APK and the in-app "Server URL" override so they don't
> need USB debugging or a rebuild.

```
scms_flutter/       (Flutter app)
      │  HTTPS/HTTP, JWT Bearer
      ▼
scms_backend/       (Node.js/Express, :3000)  ──Prisma──▶ PostgreSQL
      │  internal HTTP only
      ▼
scms_ai_service/    (Python FastAPI, :8000)  ──────────▶ Google Gemini
```

---

## 1. Prerequisites (one-time setup)

- **PostgreSQL** running on `localhost:5432`, matching `scms_backend/.env`'s
  `DATABASE_URL`. On this machine that's the native `postgresql-x64-18`
  Windows service (Docker is not required if you already have Postgres
  installed natively).
- **`scms_backend/.env`** — copy from `.env.example` and fill in
  `DATABASE_URL`, `GOOGLE_CLIENT_ID`, `FIREBASE_SERVICE_ACCOUNT_PATH`, etc.
- **`scms_ai_service/.env`** — copy from `.env.example` and set a real
  `GEMINI_API_KEY` (get one from Google AI Studio). Without it, AI features
  (grammar check, auto-categorize, duplicate detection) fail safe and the app
  still works — you just won't see AI suggestions.
- **`scms_flutter/.env`** — copy from `.env.example`. Leave
  `API_BASE_URL=http://localhost:3000` for the emulator/USB-tunnel workflow
  below (see §4 for the alternatives).
- Dependencies installed once:
  ```powershell
  cd scms_backend; npm install
  cd ../scms_ai_service; python -m venv venv; .\venv\Scripts\pip.exe install -r requirements.txt
  cd ../scms_flutter; flutter pub get
  ```

---

## 2. Quick start (recommended): the orchestrator script

From the repo root in PowerShell:

```powershell
# First time on a fresh DB (applies migrations + seeds reference data + demo data):
./scripts/start-dev.ps1 -SeedDb

# Every time after that:
./scripts/start-dev.ps1
```

This opens two new PowerShell windows — one running the backend
(`npm run dev`, port 3000), one running the AI service (`uvicorn`, port 8000) — and leaves them running with logs visible. Close a window (or
Ctrl+C inside it) to stop that service, or run:

```powershell
./scripts/stop-dev.ps1
```

to stop both cleanly (it only touches the two processes it started —
tracked in `scripts/.dev-pids.json` — nothing else on your machine).

### Useful flags

| Flag       | What it does                                                                                                 |
| ---------- | ------------------------------------------------------------------------------------------------------------ |
| `-Install` | Runs`npm install` and `pip install -r requirements.txt` first                                                |
| `-SeedDb`  | Applies Prisma migrations + runs both seed scripts (fresh DB)                                                |
| `-Phone`   | Sets up`adb reverse` so a USB-connected Android phone can reach `localhost:3000`/`:8000` on this PC (see §4) |
| `-RunApp`  | Also launches`flutter run` in a new window                                                                   |

Combine as needed, e.g. a from-scratch run that also launches the app on a
plugged-in phone:

```powershell
./scripts/start-dev.ps1 -Install -SeedDb -Phone -RunApp
```

---

## 3. Manual step-by-step (if you don't want the script)

**Backend:**

```powershell
cd scms_backend
npx prisma migrate deploy   # only if the DB schema isn't applied yet
npx prisma generate
node prisma/seed.js               # only on a fresh DB (departments/categories/zones/tags)
node prisma/seed_sample_data.js   # only on a fresh DB (demo users + complaints)
npm run dev                 # nodemon, http://localhost:3000
```

**AI service** (separate terminal):

```powershell
cd scms_ai_service
.\venv\Scripts\Activate.ps1
uvicorn main:app --reload --port 8000
```

Interactive docs at `http://localhost:8000/docs`.

**Flutter app** (separate terminal):

```powershell
cd scms_flutter
flutter run
```

---

## 4. Testing on a real Android phone

The Flutter debug build reads `API_BASE_URL` from `scms_flutter/.env` at
**build time** (it's bundled as an asset). `localhost` means something
different depending on how the phone reaches your PC:

| Setup                           | `API_BASE_URL`                                                                               | Extra step                                                                                                                                                                                                                                                                                       |
| ------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **USB debugging (recommended)** | `http://localhost:3000`                                                                      | `adb reverse tcp:3000 tcp:3000` (and `tcp:8000` if testing AI features directly) — tunnels the phone's `localhost` to your PC over the USB cable. No firewall changes needed.                                                                                                                    |
| **Wi-Fi, same LAN**             | `http://<this-PC's-LAN-IP>:3000` (e.g. `http://192.168.1.104:3000`, find it with `ipconfig`) | Requires an**inbound firewall rule** for port 3000 (`New-NetFirewallRule -DisplayName "SCMS Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow`) — this needs an **elevated (Admin) PowerShell**, since Windows Firewall changes aren't allowed from a normal user session. |

`start-dev.ps1 -Phone` automates the USB path (adb reverse for both ports on
whichever device `adb devices` reports).

**No more rebuilding for IP changes.** `.env`'s `API_BASE_URL` is only the
*default* — the app has an in-app override: **Profile → All Settings →
Developer → Server URL**. Type an IP there (with or without `http://`) and
it takes effect immediately, no rebuild or restart needed. This is the
better option for the Wi-Fi path above, and for letting someone else's phone
connect to your backend — see
[`docs/TESTING_WITH_FRIENDS.md`](TESTING_WITH_FRIENDS.md) for the full
walkthrough.

**Cleartext HTTP:** Android blocks plaintext HTTP by default. This repo's
main manifest sets `android:usesCleartextTraffic="true"`, so **both debug
and release builds** can reach a plain `http://` backend (fine for local
dev/testing; reconsider before shipping to a public app store).

### Quick manual USB recipe

```powershell
adb devices                       # confirm exactly one device shows "device"
adb reverse tcp:3000 tcp:3000
adb reverse tcp:8000 tcp:8000      # only needed if hitting :8000 directly
cd scms_flutter
flutter run                       # or: flutter build apk --debug && adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

The mock-login role chips on the login screen (Student/SR/Staff/Admin) work
without any network call, but every real data screen (dashboard counts, All
Complaints, submit, etc.) needs the backend reachable — that's what the
tunnel/firewall step is for.

---

## 5. Troubleshooting

| Symptom                                                        | Likely cause                                                                                                                                                  | Fix                                                                                                                                                                                                   |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Failed to fetch complaints" / errors on every list screen     | App can't reach the backend                                                                                                                                   | Confirm backend is running (`npm run dev` window has no errors) and the phone can reach it — USB: re-run `adb reverse`; Wi-Fi: check the firewall rule and the Server URL saved in Profile → All Settings → Developer |
| Was working, now every request fails after switching networks  | Stale IP saved in **Settings → Developer → Server URL** (your PC got a new IP, or you're back on USB but an old Wi-Fi IP is still saved)                      | Re-check `ipconfig`, update the Server URL field (or tap "Reset to default" to fall back to `.env`'s value / USB tunnel)                                                                              |
| "No categories available" on the submit form                   | Database not seeded                                                                                                                                           | `node prisma/seed.js` (from `scms_backend/`)                                                                                                                                                          |
| Mock login "succeeds" but everything else fails                | Expected — mock sign-in (`signInWithMock` in `auth_repository.dart`) is 100% client-side and never calls the network, so it works even with no backend at all | Not a bug; just confirms auth UI, not connectivity                                                                                                                                                    |
| "AI service offline" banner when submitting                    | Python AI service isn't running, or`GEMINI_API_KEY` isn't set                                                                                                 | Start it per §3, confirm`.env` has a real key. The app is designed to **fail safe** here — complaints still submit without AI suggestions                                                             |
| `relation "users" already exists` from `prisma migrate deploy` | Schema was applied previously but migration history is out of sync                                                                                            | `npx prisma migrate resolve --applied 20260605083336_init`, then re-run `migrate deploy`                                                                                                              |
| `adb devices` shows nothing / "unauthorized"                   | USB debugging not enabled, or the phone hasn't accepted the RSA key prompt                                                                                    | Enable USB debugging in Developer Options, reconnect, tap "Allow" on the phone's prompt                                                                                                               |

---

## 6. Stopping everything

- If started via `start-dev.ps1`: run `./scripts/stop-dev.ps1`.
- If started manually: Ctrl+C in each terminal window.
- `adb reverse --remove-all` clears any USB port tunnels (optional — they
  don't hurt anything left in place).

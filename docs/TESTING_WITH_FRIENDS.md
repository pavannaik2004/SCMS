# Testing SCMS with Friends (No Dev Setup on Their Phone)

A guide for sharing a build of the app with friends so they can try it against
your locally-running backend — no Android Developer Options, no cable, no
rebuild every time your PC's IP changes.

**The one hard requirement: everyone testing must be on the same Wi-Fi
network as your PC.** Your backend isn't hosted anywhere public — it only
exists on your machine, reachable on your local network. If a friend is on
mobile data or a different Wi-Fi, this won't work (see §6).

---

## 1. Overview — who does what

| Step | Who | What |
|---|---|---|
| 1 | **You** | Start the backend (+ AI service, optional) |
| 2 | **You** | Find your PC's current LAN IP |
| 3 | **You** | Build the release APK and send it to your friend |
| 4 | **Friend** | Install the APK (allow "install unknown apps" once) |
| 5 | **Friend** | Open the app → Settings → type your PC's IP |
| 6 | **Both** | Confirm it's working |

Repeat steps 2 and 5 only — whenever your PC reconnects to Wi-Fi and gets a
new IP, you just tell your friend the new one; they retype it in Settings.
No reinstall, no rebuild.

---

## 2. You: start the backend

From the repo root:

```powershell
./scripts/start-dev.ps1
```

(add `-SeedDb` the first time on a fresh database — see
`docs/RUNNING_LOCALLY.md` for full details). Leave the backend window open
for the whole testing session — if it closes, your friend's app stops
getting data.

The Windows Firewall rules that let another device on your Wi-Fi reach your
PC (`SCMS Backend 3000`, `SCMS AI Service 8000`) should already be in place.
To check:

```powershell
Get-NetFirewallRule -DisplayName "SCMS*" | Select-Object DisplayName, Enabled
```

If they're missing, run this **once**, in an **Admin PowerShell window**:

```powershell
New-NetFirewallRule -DisplayName "SCMS Backend 3000" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Profile Any
```

---

## 3. You: find your PC's current LAN IP

```powershell
ipconfig
```

Look for the **IPv4 Address** under your Wi-Fi adapter (e.g.
`192.168.1.104`). This is what you'll give your friend — write it down or
keep the terminal open, you'll need it again in step 5.

---

## 4. You: build and share the release APK

```powershell
cd scms_flutter
flutter build apk --release
```

The APK is at `scms_flutter\build\app\outputs\flutter-apk\app-release.apk`.
Send that file to your friend however's convenient — WhatsApp, Google
Drive, email, a USB cable, doesn't matter.

You only need to rebuild this when the **app itself** changes. Switching
networks or IPs does **not** require a rebuild — that's what step 5 is for.

---

## 5. Friend: install the APK and connect it to your PC

**Install:**
1. Open the APK file (from WhatsApp/Drive/wherever it landed)
2. Android will prompt to allow installing from this source — allow it (one
   time only)
3. Install, then open the app

**Point it at your backend:**
1. Sign in (Google sign-in, or one of the "Development Bypass" role chips
   on the login screen if you're just testing UI flows)
2. Go to **Profile → All Settings**
3. Scroll to the **Developer** section → **Server URL**
4. Type the IP you were given, with the port, e.g.:
   ```
   192.168.1.104:3000
   ```
   (the `http://` scheme is added automatically if you leave it out)
5. Tap **Save**

That's it — no restart needed. The app immediately starts sending requests
to that address.

---

## 6. Confirming it's working

- **Dashboard shows real numbers** (not stuck at 0 with a spinner) → connected
- **"Failed to fetch complaints" / red error banners everywhere** → not
  connected — see troubleshooting below
- Submitting a complaint on the friend's phone should show up when **you**
  browse "All Complaints" on your own device, and vice versa — that's the
  clearest end-to-end confirmation both devices are hitting the same backend

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Failed to fetch complaints" on the friend's phone | Not on the same Wi-Fi, wrong IP typed, or backend not running | Confirm both devices show the same Wi-Fi network name; re-check the IP with `ipconfig`; confirm the backend window has no errors |
| Worked earlier today, broken now | Your PC reconnected to Wi-Fi and got a new IP (common after sleep/reboot) | Run `ipconfig` again, give your friend the new IP, they update Settings → Developer → Server URL |
| "No categories available" on the submit form | Database isn't seeded | Run `node prisma/seed.js` from `scms_backend/` (see `docs/RUNNING_LOCALLY.md`) |
| Friend can't even install the APK | Their phone is blocking the install source | They need to tap through the "Install unknown apps" / "Allow from this source" prompt Android shows — it's not related to Developer Options |
| Works on your phone but not your friend's, same Wi-Fi | Router client isolation (some Wi-Fi networks, especially "Guest" networks, block devices from talking to each other) | Try a different Wi-Fi network, or your phone's mobile hotspot instead of a public/guest router |

---

## 8. Limits of this approach

- **Same Wi-Fi only.** This is local-network testing, not real hosting. A
  friend on a different network can't reach your PC at all — that needs
  actual hosting (Railway/Render/Fly.io etc.) or a tunnel service, which is
  a separate, bigger step.
- **Your PC must stay on and the backend running** for the whole session —
  closing the terminal window or sleeping the PC drops everyone.
- The **AI features** (grammar check, auto-categorize, duplicate detection)
  also need the Python AI service running (`scripts/start-dev.ps1` starts
  both); without it the app still works, it just skips AI suggestions.

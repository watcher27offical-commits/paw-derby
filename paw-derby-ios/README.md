# Paw Derby — iOS app

This is the iPhone/iPad app for Paw Derby. It's a thin app shell (Capacitor) that opens the live game at
**https://ediso.fly.dev**, so every `fly deploy` updates the app instantly — you only rebuild the app to
change its icon, name or version.

You're on Windows, and iOS apps can only be built on a Mac, so a free GitHub-hosted Mac builds it for you
and sends it straight to **TestFlight** (Apple's app for installing test builds on your phone).

---

## Quickest test (free, 1 minute, no Apple account)

After deploying the updated game (`fly deploy` in the paw-derby folder):

1. On your iPhone, open **Safari** and go to https://ediso.fly.dev
2. Tap **Share** → **Add to Home Screen** → **Add**.

You get a Paw Derby icon that opens full-screen with no browser bars — almost identical to the real app.

---

## Real app for free (Windows + free Apple ID, no $99)

The app is signed with your normal Apple ID instead of a paid account. Limits: it only installs on **your own**
devices, needs a USB cable, and **stops opening after 7 days** — just reinstall it (your game progress is safe on the server).

1. Put this folder on GitHub (step 3 below — skip the Apple steps and secrets).
2. Repo → **Actions** → **Build test app (free, for Sideloadly)** → **Run workflow**. After ~10 min open the finished run
   and download **PawDerby-unsigned-ipa** at the bottom (unzip it to get `PawDerby-unsigned.ipa`).
3. On Windows install **iTunes from apple.com** (not the Microsoft Store version) and **Sideloadly** from https://sideloadly.io
4. Plug in your iPhone, tap **Trust** on the phone. In Sideloadly drag in the `.ipa`, enter your Apple ID, press **Start**.
5. On the iPhone: Settings → Privacy & Security → **Developer Mode** → On (phone restarts), then
   Settings → General → **VPN & Device Management** → your Apple ID → **Trust**. Open Paw Derby.

---

## Real app through TestFlight (paid, $99/year)

### What you need
- An **Apple Developer Program** membership ($99 USD/year): https://developer.apple.com/programs/enroll/
- A free **GitHub** account: https://github.com

### 1. Register the app with Apple (one time, in a browser)
1. https://developer.apple.com/account/resources/identifiers → **+** → **App IDs** → **App** → Continue.
   - Description: `Paw Derby`
   - Bundle ID (Explicit): `ca.ediso.pawderby`
     (if Apple says it's taken, pick another like `ca.edi.pawderby` and put the same text in `capacitor.config.json` → `appId`)
   - Continue → Register.
2. https://appstoreconnect.apple.com/apps → **+** → **New App**
   - Platform iOS, Name `Paw Derby` (must be unique on the App Store; add a word if taken), language English,
     Bundle ID = the one above, SKU `pawderby`, Full Access → Create.

### 2. Make an App Store Connect API key (lets the GitHub Mac sign and upload for you)
1. https://appstoreconnect.apple.com/access/integrations/api → **Team Keys** → **+** (request access first if asked).
2. Name `GitHub`, Access **Admin** → Generate. (Admin is needed so Apple can sign the app in the cloud.)
3. Note the **Issuer ID** (top of the page) and the **Key ID**, then **Download** the `.p8` file (only downloadable once).
4. Your **Team ID**: https://developer.apple.com/account → Membership details → Team ID (10 characters).

### 3. Put this folder on GitHub
1. https://github.com/new → name `paw-derby-ios` → **Private** → Create repository.
2. On the new repo page click **uploading an existing file**, drag in **everything inside this folder**
   (including the hidden `.github` folder — in File Explorer turn on View → Show → Hidden items), then **Commit changes**.
   - Check the repo shows `.github/workflows/testflight.yml`. If the upload skipped it, use **Add file → Create new file**,
     type `.github/workflows/testflight.yml` as the name and paste that file's contents.

### 4. Add your Apple details as secrets
Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**, four times:

| Name | Value |
|---|---|
| `APPLE_TEAM_ID` | your Team ID |
| `ASC_KEY_ID` | the Key ID |
| `ASC_ISSUER_ID` | the Issuer ID |
| `ASC_KEY_P8` | open the `.p8` file in Notepad and paste **all** of it, including the BEGIN/END lines |

### 5. Build
Repo → **Actions** → **Build iOS app → TestFlight** → **Run workflow** → Run.
It takes about 10–15 minutes. A green tick means the build was uploaded.

### 6. Install on your iPhone
1. App Store Connect → your app → **TestFlight**. The build shows up after Apple finishes "Processing" (5–30 min).
2. Under **Internal Testing** click **+**, create a group, and add yourself (your Apple ID email must be a user on the team).
3. On your iPhone install **TestFlight** from the App Store, open the invite email, and install Paw Derby.

To let friends test without adding them to your team, use **External Testing** (Apple does a quick beta review
of the first build, usually under a day) and share the public link.

### Updating
- **Game changes:** just `fly deploy` the game — the app loads the live site, nothing to rebuild.
- **New app build** (icon, name, Apple's yearly SDK requirements): Actions → Run workflow again. Build numbers go up automatically.

---

## If the build fails
Open the failed run → **build-logs** download at the bottom, or click the red step to read the error.
- *"No profiles for ... were found" / "No Accounts"* — the API key isn't **Admin**, or a secret is mistyped.
- *"Cannot determine the Apple ID from Bundle ID"* — step 1.2 (New App in App Store Connect) wasn't done, or the bundle IDs differ.
- *"The bundle version must be higher"* — just run the workflow again.

## Files
- `capacitor.config.json` — app ID, name, and the game address (`server.url`)
- `assets/` — app icon (1024×1024) and launch screen
- `www/offline.html` — shown if the phone can't reach the game
- `scripts/ci-build.sh` — signs and uploads (used by the workflow)
- `.github/workflows/testflight.yml` — the GitHub Mac build

## On a Mac instead
    npm install
    npx cap add ios && npm run ios:assets && npx cap sync ios
    npx cap open ios      # then pick your team under Signing & Capabilities and press Run

## About App Store release
TestFlight is fine for you and testers. If you later submit to the public App Store, Apple sometimes rejects apps
that are "just a website" (guideline 4.2) — native touches like push notifications or offline play help with that.

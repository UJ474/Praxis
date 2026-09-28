# 3-2-1 Desktop

A macOS 14+ menubar app that renders an interactive, editorial-style desktop edition and persists its data through a Railway-hosted Express API and MongoDB Atlas.

## Behaviour deliberately chosen

- The desktop window uses `.desktopIcon + 1`: it is above the Finder wallpaper/icons while remaining below ordinary application windows.
- `.canJoinAllSpaces`, `.stationary`, `.ignoresCycle`, and `.transient` keep it present across Spaces and out of Cmd-Tab/Mission Control. `LSUIElement` removes its Dock presence.
- It is a real key-capable `NSWindow`, so scroll views, buttons, and AppKit rich-text input remain interactive.
- The app is set to request launch-at-login registration through `SMAppService`.

## Open the Mac app

Open [Package.swift](Package.swift) in Xcode (File → Open), set the run destination to **My Mac**, and run. For an archiveable, signed `.app`, create a native **macOS App** target in Xcode, then add every Swift file under `App`, `Core`, `Models`, and `Views`; set [Info.plist](Resources/Info.plist) and [NewsletterDesktop.entitlements](Resources/NewsletterDesktop.entitlements) as its build settings. This small package is intentionally single-target: there is no WidgetKit extension or App Group.

Before running, duplicate `Core/Config.example.swift` as `Core/Config.swift`, replace the API URL and token, and exclude the example from the target to prevent a duplicate `AppConfiguration` definition.

## Google OAuth setup

1. In [Google Cloud Console](https://console.cloud.google.com/), create/select a project and enable **Gmail API**.
2. Configure the OAuth consent screen as **External**, add yourself as a test user while the app remains in testing, and request only `gmail.readonly`.
3. Create an OAuth Client ID of type **Web application**. Add `https://YOUR-RAILWAY-DOMAIN/auth/google/callback` as its exact authorized redirect URI.
4. Put its client ID, secret, redirect URI, a random API token, and a base64 32-byte encryption key in Railway variables, following [Backend/.env.example](Backend/.env.example).
5. In the installed app choose **Connect Gmail** from the menu bar. Approve Google’s consent screen; the backend encrypts and stores the refresh token in MongoDB. Then choose **Refresh**. It only searches `from:jamesclear.com subject:"3-2-1"`.

The backend, not the Mac app, owns Gmail credentials. The Mac app only holds the API bearer token; use a different high-entropy token for every deployment.

## Deploy the API

1. Create a MongoDB Atlas database and Railway project from the `Backend` folder.
2. Set Railway’s start command to `npm start`; add all variables from `.env.example`.
3. Deploy. Verify `GET /health`, then place Railway’s URL and `API_TOKEN` in `Config.swift`.

`POST /api/newsletter/sync` retrieves and parses the newest newsletter. `GET /api/newsletter/latest` and task CRUD are bearer-protected. The Monday UTC job copies incomplete tasks forward once and archives the prior-week originals.

## Parser contract

`Backend/services/emailParser.js` uses the stable `3 Ideas From Me`, `2 Quotes From Others`, and `1 Question For You` headings; it stops at “Want to share this issue.” It rejects malformed issues rather than silently saving an incomplete edition.

# Budget Buddy — Flutter

A Flutter rewrite of the Budget Buddy React app (mobile + web). It talks to the
**same Express/Lambda backend** as the original, so no backend changes are
required — endpoint paths and payloads are unchanged.

## What's here

| Area | React original | Flutter equivalent |
| --- | --- | --- |
| State | React Context | `provider` (`ChangeNotifier`) |
| Routing / guards | react-router | `go_router` with a redirect guard |
| Charts | recharts | `fl_chart` |
| Local storage | `localStorage` | `shared_preferences` |
| i18n (en/es) | i18next | `lib/l10n/app_strings.dart` |
| Bank linking | react-plaid-link | `plaid_flutter` |
| Social login | @react-oauth/google + FB SDK | `google_sign_in` + `flutter_facebook_auth` |
| 2FA | `/api/send-2fa-code` etc. | same endpoints via `ApiClient` |

The responsive shell mirrors the React breakpoint: a **sidebar at ≥768px**
(desktop/web) and a **bottom nav** on phones.

## Project layout

```
lib/
  main.dart              # bootstrap + provider wiring
  app.dart               # MaterialApp.router + routes/guard + responsive shell
  config.dart            # build-time config (API URL, OAuth client IDs)
  theme/                 # colors + light/dark ThemeData (ported from global.css)
  l10n/                  # en/es strings
  models/                # transaction, budget, bill, category, user, plaid
  services/              # api_client, prefs, social_auth
  providers/             # theme, locale, auth, data, plaid
  widgets/               # shell (sidebar/bottom nav/top bar) + shared UI
  pages/                 # auth, dashboard, transactions, budget, bills,
                         # reports, settings, linked_accounts, legal
```

## Setup

```bash
flutter pub get
```

Then create the platform folders if they don't exist yet (this repo ships only
`lib/` + `pubspec.yaml`):

```bash
flutter create .
```

## Configuration (build-time)

Config is injected with `--dart-define`, mirroring the React `VITE_*` variables:

```bash
flutter run \
  --dart-define=API_URL=https://your-backend.example.com \
  --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com \
  --dart-define=FACEBOOK_APP_ID=1234567890
```

- `API_URL` — base URL of the existing backend. Leave empty for same-origin web.
- `GOOGLE_CLIENT_ID` / `FACEBOOK_APP_ID` — only needed for social login.

For web, also add to `web/index.html`:

```html
<script src="https://cdn.plaid.com/link/v2/stable/link-initialize.js"></script>
```

## Native integration notes

- **Plaid** (`plaid_flutter`): register your Android package name and iOS
  redirect URI in the Plaid dashboard. Android `minSdk >= 21`, iOS `>= 14`.
- **Google** (`google_sign_in`): configure the OAuth client per platform
  (Android `google-services.json` / iOS URL scheme / web client ID).
- **Facebook** (`flutter_facebook_auth`): add the app ID + client token to
  `AndroidManifest.xml` and `Info.plist` per the package docs.

## Backend compatibility

The `ApiClient` calls exactly the routes the backend already exposes:

```
POST /auth/login            POST /auth/login/mfa     POST /auth/register
POST /auth/social           POST /auth/logout
POST /api/send-2fa-code     POST /api/verify-2fa-code
POST /plaid/link-token      POST /plaid/exchange
GET  /plaid/items           GET  /plaid/transactions
POST /plaid/transactions/sync   DELETE /plaid/items/:itemId
```

## Run

```bash
flutter run                 # mobile (attached device/emulator)
flutter run -d chrome       # web
flutter build apk           # Android
flutter build web           # web bundle
```

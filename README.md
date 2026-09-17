# smart_mart_mobile

A new Flutter project.

## Google/Facebook Login + CAPTCHA setup

Social login and CAPTCHA only appear on the Login/Signup screens once
enabled in the ERP (Settings > Social Login & Security) — nothing to
configure here for that part, it's fetched at runtime from
`GET /mobile/website-settings`.

**Google Sign-In** needs no build-time secret — its client_id comes from the
ERP at runtime. You only need to register this app's SHA-1 signing
fingerprint (Android) / bundle ID (iOS) as an Android/iOS OAuth client under
that same Google Cloud project, in Google Cloud Console > Credentials.

**Facebook Login** is different: the native SDK reads its App ID at app
startup, so it must be baked into this build. Before shipping a build with
Facebook Login enabled, get the App ID + Client Token from
developers.facebook.com > your app > Settings > Basic, then replace:
- `android/app/src/main/res/values/strings.xml` — `facebook_app_id`,
  `fb_login_protocol_scheme` (must stay `fb` + the App ID),
  `facebook_client_token`
- `ios/Runner/Info.plist` — `FacebookAppID`, `FacebookClientToken`, and the
  `fbREPLACE_WITH_FACEBOOK_APP_ID` URL scheme entry. Also replace
  `REPLACE_WITH_REVERSED_GOOGLE_CLIENT_ID` there with the Google OAuth
  client ID reversed (e.g. `1234-abc.apps.googleusercontent.com`
  → `com.googleusercontent.apps.1234-abc`) — iOS's Google Sign-In redirect
  needs this URL scheme registered at build time too.

CAPTCHA (reCAPTCHA v2) needs no native setup — it's shown in an in-app
WebView using the public site key from the same settings call.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

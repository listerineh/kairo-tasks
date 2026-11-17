# Launch checklist: TestFlight, App Store and Google Play

Steps that need your accounts, in order. Texts and answers for the consoles are in [store-listing.md](store-listing.md); the iOS portal steps in detail are in [ios-release.md](ios-release.md).

## 1. Backend

- [ ] **Custom SMTP in Supabase.** The built-in sender rejects many addresses and allows only a few emails an hour, so sign-ups and password resets fail. Create an account with an email provider (for example Resend), verify a sending domain (for example `listerineh.dev`), then Supabase → kairo-db → Authentication → Emails → SMTP Settings: host, port, user, password and sender `Kairo <no-reply@listerineh.dev>`. Raise the email rate limit under Authentication → Rate Limits.
- [ ] **Demo account password.** In the SQL editor (the password is yours, never in git):

  ```sql
  update auth.users
  set encrypted_password = crypt('<password>', gen_salt('bf'))
  where email = 'kairo.review@example.com';
  ```

## 2. Apple (TestFlight, then App Store)

Follow [ios-release.md](ios-release.md) § One-time setup:

- [ ] App ID `com.kairotasks.kairotasks` with Push Notifications and Sign in with Apple.
- [ ] The app in App Store Connect (name `Kairo: tareas con calma`, primary language Spanish (Mexico) or Spanish (Latin America), SKU `kairo`).
- [ ] App Store Connect API key (Admin) and the GitHub secrets `ASC_KEY_P8_BASE64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `IOS_TEAM_ID`.
- [ ] APNs key uploaded to Firebase (Cloud Messaging → Apple app configuration).
- [ ] Sign in with Apple enabled in Supabase (Authentication → Providers → Apple, with the bundle ID as client ID).

## 3. Google Play

- [ ] **Developer account** at play.google.com/console (one-time fee, identity verification can take a few days).
- [ ] **Upload key.** Create it on your Mac and keep the file and passwords somewhere safe (a password manager); losing it means asking Google to reset it:

  ```bash
  keytool -genkey -v -keystore ~/kairo-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```

- [ ] **GitHub secrets** for the Android workflow:

  ```bash
  base64 -i ~/kairo-upload-keystore.jks | gh secret set KEYSTORE_BASE64 --repo listerineh/kairo-tasks
  ```

  ```bash
  gh secret set KEYSTORE_PASSWORD --repo listerineh/kairo-tasks
  ```

  ```bash
  gh secret set KEY_ALIAS --repo listerineh/kairo-tasks --body upload
  ```

  ```bash
  gh secret set KEY_PASSWORD --repo listerineh/kairo-tasks
  ```

- [ ] **Create the app** in the Play Console (name `Kairo: tareas con calma`, app, free), fill the store listing, data safety, content rating and app content from [store-listing.md](store-listing.md).
- [ ] **Google sign-in on release builds.** Play re-signs the app with its own key, so its SHA-1 must be allowed: Play Console → Test and release → App integrity → App signing → copy the **App signing key** SHA-1 and the **Upload key** SHA-1, then Google Cloud Console → APIs & Services → Credentials → create an **Android** OAuth client for `com.kairotasks.kairotasks` with each SHA-1. Without it, "Continuar con Google" fails only in the Play build.
- [ ] **Firebase**: add the same SHA-1 fingerprints to the Android app in Firebase project settings.

## 4. Build

- [ ] Merge the open PRs into `main`, then tag the release from `main`:

  ```bash
  git tag v2.1.0+118 && git push origin v2.1.0+118
  ```

- [ ] **Release iOS to TestFlight** uploads the build; it shows up in TestFlight after Apple processes it (10 to 30 minutes).
- [ ] **Release Android (APK and AAB)** attaches `Kairo-2.1.0+118-release.aab` to the GitHub release.

## 5. Test

- [ ] TestFlight on your iPhone: sign in with Apple, Google and email; share a task with a friend and receive the push; delete a throwaway account.
- [ ] Play internal testing: upload the `.aab` by hand the first time (Test and release → Internal testing → Create release), install from the Play link and repeat the same checks, Google sign-in included.

## 6. Submit

- [ ] Run `supabase/seed/demo_account.sql` so the demo account has today's tasks.
- [ ] **App Store**: screenshots (6.9" iPhone), texts, privacy answers, review notes and demo account → Add for Review → Submit.
- [ ] **Google Play**: personal developer accounts need a **closed test with at least 12 testers for 14 days** before production. Promote the internal build to closed testing, invite 12 or more testers, wait 14 days, apply for production access, then roll out to production.

# iOS release: TestFlight, push and Sign in with Apple

How Kairo gets from a `v*` tag to TestFlight, and the one-time setup it needs in the Apple Developer account (paid program, account holder). Steps marked **(portal)** happen in Apple's or Firebase's web consoles and need your account; everything else is already in the repository.

## How a release works

1. Push a tag `vX.Y.Z+N` (the build number `N` must be new for every upload).
2. `.github/workflows/release_ios.yml` builds the app with Flutter 3.47.1, archives it with Xcode and uploads it to App Store Connect.
3. Signing is automatic: an App Store Connect API key lets Xcode use cloud-managed certificates and profiles, so no `.p12` or `.mobileprovision` lives in the secrets.
4. After Apple processes the build (usually 10–30 minutes), it appears in TestFlight on your iPhone. TestFlight builds last 90 days.

Android keeps building the APK for the GitHub Release (`release.yml`).

## One-time setup

### 1. Team ID in the project

The paid program creates a new team, different from the "(Personal Team)". Find its Team ID in **developer.apple.com/account → Membership details** and set `DEVELOPMENT_TEAM` to it in `ios/Runner.xcodeproj/project.pbxproj` (three build configurations). In Xcode → Settings → Accounts, the new team should appear next to the personal one.

### 2. App ID capabilities (portal)

developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → `com.kairotasks.kairotasks`:

- **Push Notifications**: on.
- **Sign in with Apple**: on, as a primary App ID.

Building once with Xcode's automatic signing usually turns these on for you, because the project's `Runner.entitlements` asks for them.

### 3. The app in App Store Connect (portal)

appstoreconnect.apple.com → Apps → **+ New App**: platform iOS, name Kairo (or the closest available), primary language Spanish, bundle ID `com.kairotasks.kairotasks`, SKU `kairo`. TestFlight only needs this record; no screenshots or review yet.

### 4. App Store Connect API key (portal)

App Store Connect → Users and Access → **Integrations → App Store Connect API** → Team Keys → **+**:

- Name: `GitHub Actions`
- Access: **Admin** (cloud-managed distribution signing needs it).

Download `AuthKey_<KEY_ID>.p8` (Apple lets you download it **once**). Note the **Key ID** and the **Issuer ID** shown above the list.

### 5. GitHub secrets

From the folder where the `.p8` is:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | gh secret set ASC_KEY_P8_BASE64 --repo listerineh/kairo-tasks
gh secret set ASC_KEY_ID --repo listerineh/kairo-tasks --body XXXXXXXXXX
gh secret set ASC_ISSUER_ID --repo listerineh/kairo-tasks --body xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
gh secret set IOS_TEAM_ID --repo listerineh/kairo-tasks --body YOURTEAMID
```

Keep the `.p8` somewhere safe (a password manager) and out of the repository.

The old secrets `IOS_P12_CERTIFICATE`, `IOS_P12_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64` and `IOS_PROVISIONING_NAME` are no longer used.

### 6. Push notifications: APNs key in Firebase (portal)

1. developer.apple.com → Keys → **+** → name `Kairo APNs`, check **Apple Push Notifications service (APNs)** → download `AuthKey_<KEY_ID>.p8` (once).
2. Firebase console → project `kairotasks` → Project settings → **Cloud Messaging** → Apple app configuration → **APNs Authentication Key** → upload the `.p8` with its Key ID and your Team ID.

Firebase then delivers the pushes that the `fcm` Edge Function sends to iOS devices.

### 7. Sign in with Apple in Supabase (portal)

Supabase → kairo-db → Authentication → Sign In / Providers → **Apple** → enable, and set **Client IDs** to `com.kairotasks.kairotasks`. The app uses the native flow (an ID token from the device), so the secret key and Services ID are not needed for iOS.

## Check it works

1. Push a tag (`vX.Y.Z+N`) and watch **Actions → Release iOS to TestFlight**.
2. In App Store Connect → TestFlight, the build appears as "Processing", then "Ready to Test". Answer the export compliance question (the app only uses standard HTTPS: "None of the algorithms mentioned above").
3. Install **TestFlight** on the iPhone and accept the invitation (internal testers: add yourself under App Store Connect → Users).
4. In the app: sign in with Apple, and share a task with a friend to receive a push.

## Troubleshooting

- **"No Account for Team" / "No signing certificate"** in the workflow: the API key is not Admin, or `IOS_TEAM_ID` is the personal team.
- **"Personal development teams do not support the Push Notifications capability"** locally: `DEVELOPMENT_TEAM` still points to the personal team (step 1).
- **"The bundle version must be higher"** on upload: the tag reused a build number; bump `N` in `pubspec.yaml` and tag again.

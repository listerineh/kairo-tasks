# Supabase setup (new project)

How to stand up Kairo's backend on a fresh Supabase project. Everything the database needs is in `supabase/migrations/`; this guide covers the parts that live outside the repo (secrets, auth providers, function deploys) and the app config that points at the project.

You need the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) logged in (`supabase login`). Never commit any of the keys below.

---

## 1. Create the project

1. In the Supabase dashboard, create a project (any region; Free tier is enough).
2. Note from **Project Settings → API**:
   - Project **ref** (the `<ref>` in `https://<ref>.supabase.co`)
   - **Project URL**
   - **anon** public key
   - Keep the **service_role** key private (the Edge Functions receive it automatically; you should not need to copy it).

## 2. Apply the schema

```bash
supabase link --project-ref <ref>
supabase db push
```

`db push` applies every migration in `supabase/migrations/`, in order. It creates:

| Area | What |
| --- | --- |
| Tables | `profiles`, `tasks`, `shared_tasks`, `friendships`, `logs` (with RLS) |
| Functions | `handle_new_user` (profile on sign-up), `update_updated_at`, `tasks_set_completed_at`, `get_public_friend_tasks` (friend calendars), `fcm_*` push triggers |
| Storage | Public `avatars` bucket (2 MB, JPEG/PNG/WebP) and its policies |
| Realtime | `tasks`, `shared_tasks`, `friendships`, `profiles` in `supabase_realtime` |
| Extensions | `pg_net`, `supabase_vault` |

> The migration that locks down `public.logs` (`20261020000001_logs_table_rls.sql`) is in PR #10. Merge it before pushing, or run `supabase db push` again after it lands.

## 3. Vault secrets (push notifications)

The push triggers read two secrets from the vault. Run this once in **SQL Editor**, with a long random value for the key (for example `openssl rand -hex 32`):

```sql
select vault.create_secret('https://<ref>.supabase.co', 'project_url');
select vault.create_secret('<random-internal-key>', 'fcm_internal_key');
```

Without them, task and friend changes still save; pushes are just skipped.

To change one later: `select vault.update_secret((select id from vault.secrets where name = 'project_url'), 'https://<new-ref>.supabase.co');`

## 4. Edge Functions

```bash
supabase functions deploy fcm
supabase functions deploy logs
```

`fcm` is deployed with JWT verification off (see `supabase/config.toml`): the database calls it without a user token and the function checks the `x-fcm-internal-key` header instead. `logs` keeps JWT verification on; the app calls it with its anon session and the `x-logs-key` header.

Set the function secrets (`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected by Supabase):

```bash
supabase secrets set \
  FCM_INTERNAL_KEY=<same value as the vault fcm_internal_key> \
  LOGS_API_KEY=<random UUID, same as the app's LOGS_API_KEY> \
  FCM_SERVICE_ACCOUNT="$(cat path/to/firebase-service-account.json)"
```

The Firebase service account comes from **Firebase console → Project settings → Service accounts → Generate new private key**.

## 5. Authentication

In **Authentication → Providers**:

- **Email**: on (the default).
- **Google**: on. The app signs in natively with an ID token, so add both OAuth client IDs (web and iOS, from Google Cloud Console) to **Authorized Client IDs**, and set the web client ID and secret.
- **Apple**: on, with the Services ID, Team ID, Key ID and private key from the Apple Developer account.

In **Authentication → URL Configuration**, add the app's redirect URL:

```
com.kairotasks.kairotasks://login-callback
```

## 6. Point the app at the new project

1. In `.env` (copy of `.env.example`), set `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `LOGS_API_KEY`. The Google client IDs only change if you created new ones.
2. For CI releases, regenerate the `ENV_FILE_BASE64` repository secret: `base64 -i .env | pbcopy`.

## 7. Check it works

1. `flutter run --dart-define-from-file=.env`, sign up, and confirm a row appears in `profiles`.
2. Create a task: it appears in the task list without a refresh (realtime).
3. Upload an avatar from the profile screen.
4. From a second account, send a friend request and share a task: the first device gets a push. If not, check **Edge Functions → fcm → Logs** and that both vault secrets exist (`select name from vault.secrets;`).
5. The `flutter run` console stops printing `LoggerService flush failed`.

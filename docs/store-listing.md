# Store listing: App Store and Google Play

Everything to paste into App Store Connect and the Play Console for Kairo 2.1. Spanish (Latin America) is the primary language; English is the second localization. Character limits are noted next to each field; every text below fits.

## Shared facts

| Field | Value |
| --- | --- |
| Bundle ID / package | `com.kairotasks.kairotasks` |
| Category | Productivity (secondary on iOS: Lifestyle) |
| Price | Free, no in-app purchases, no ads |
| Privacy policy URL | https://listerineh.dev/kairo/privacy |
| Account deletion URL (Play) | https://listerineh.dev/kairo/delete-account |
| Support URL | https://listerineh.dev/contact |
| Marketing URL (optional) | https://listerineh.dev/projects/kairo |
| Copyright (iOS) | `2026` followed by your legal name (as in the developer account) |
| Devices | iPhone (portrait). Android phones. No iPad build. |

## App Store Connect

### Español (América Latina)

- **Nombre** (30): `Kairo: tareas con calma`
- **Subtítulo** (30): `Un momento a la vez`
- **Palabras clave** (100): `tareas,pendientes,agenda,calendario,foco,pomodoro,hábitos,racha,TDAH,amigos,compartir,organizar`
- **Texto promocional** (170): `Kairo te muestra qué toca ahora y te acompaña hasta terminarlo. Foco con descansos, calendario y tareas compartidas con amigos, sin ruido ni anuncios.`
- **Descripción** (4000):

```
Kairo es una forma tranquila de organizar tu día. En lugar de una lista interminable, te muestra qué toca ahora y deja lo demás para su turno.

UN MOMENTO A LA VEZ
• Hoy reúne lo pendiente y lo vencido, y destaca la tarea del momento con un botón para enfocarte.
• Tu racha y el progreso del día, sin culpas: si te atrasas, Kairo te sugiere la tarea más corta.

ENFÓCATE DE VERDAD
• Rondas de foco con descansos, un anillo que avanza y +5 minutos cuando los necesitas.
• El temporizador sigue aunque salgas de la app.

PLANEA TU TIEMPO
• Calendario por día, semana y mes. Toca para crear, arrastra para mover.
• «Algún día» para lo que aún no tiene fecha.

MEJOR, JUNTOS
• Agrega amigos, comparte tareas y calendarios, y mira cómo avanzan.
• Dense un empujón cuando alguien lo necesite.

KAIRO, TU COMPAÑERO
Kairo es un gato calicó que vive en la app. Respira, parpadea, se estira y te da sugerencias útiles. Se alegra cuando terminas algo y duerme cuando es hora de descansar.

PENSADA PARA TODOS
• Diseño tranquilo, apto para TDAH y autismo: una cosa a la vez, sin alertas rojas.
• Reducir movimiento, vibración y tamaño de texto hasta 200 %.
• Funciona sin conexión y se sincroniza al volver.

Sin anuncios, sin rastreo y de código abierto. Puedes eliminar tu cuenta y todos tus datos desde la app en cualquier momento.
```

- **Novedades de esta versión** (4000): `Primera versión en el App Store: icono nuevo, un recorrido de bienvenida y un inicio de sesión más simple con Apple, Google o correo.`

### English (U.S.)

- **Name** (30): `Kairo: Calm Tasks`
- **Subtitle** (30): `One moment at a time`
- **Keywords** (100): `tasks,to-do,planner,calendar,focus,pomodoro,habits,streak,ADHD,friends,share,organize,routine`
- **Promotional text** (170): `Kairo shows you what's next and stays with you until it's done. Focus rounds, a calendar and tasks shared with friends, with no noise and no ads.`
- **Description** (4000):

```
Kairo is a calm way to organize your day. Instead of an endless list, it shows you what's up now and lets everything else wait its turn.

ONE MOMENT AT A TIME
• Today gathers what's pending and overdue, and highlights the task for now with a button to focus on it.
• Your streak and the day's progress, without guilt: if you fall behind, Kairo suggests the shortest task.

FOCUS FOR REAL
• Focus rounds with breaks, a ring that fills up, and +5 minutes when you need them.
• The timer keeps going even if you leave the app.

PLAN YOUR TIME
• Day, week and month calendar. Tap to create, drag to move.
• "Someday" for things without a date yet.

BETTER TOGETHER
• Add friends, share tasks and calendars, and see how they're doing.
• Give each other a nudge when someone needs it.

KAIRO, YOUR COMPANION
Kairo is a calico cat who lives in the app. He breathes, blinks, stretches and gives you useful suggestions. He's happy when you finish something and sleeps when it's time to rest.

MADE FOR EVERYONE
• A calm design that works for ADHD and autism: one thing at a time, no red alerts.
• Reduce motion, haptics and text size up to 200%.
• Works offline and syncs when you're back.

No ads, no tracking, and open source. You can delete your account and all your data from the app at any time.
```

- **What's New** (4000): `Kairo's first App Store release: a new icon, a welcome tour and a simpler sign-in with Apple, Google or email.`

### App Privacy (nutrition label)

Answer **"Yes, we collect data"**. For every type below: **Linked to the user: Yes**, **Used for tracking: No**, purpose **App Functionality** only.

| Category | Type | Why |
| --- | --- | --- |
| Contact Info | Name | Display name on the profile |
| Contact Info | Email Address | Account sign-in |
| User Content | Photos or Videos | Optional profile photo |
| User Content | Other User Content | Tasks, shared tasks, nudges |
| Identifiers | User ID | Account identifier |
| Diagnostics | Crash Data | Error logs |
| Diagnostics | Other Diagnostic Data | Error logs with device model and app version |

Not collected: location, contacts, browsing history, financial info, health, purchases, usage data for analytics, advertising data. This matches `ios/Runner/PrivacyInfo.xcprivacy`.

### Age rating

Answer **None** to every content question. "Unrestricted web access": No. "User-generated content shared with other users": Yes, limited to accepted friends (tasks and nudges). Expected rating: **4+**.

### App Review information

- **Sign-in required:** Yes. Demo account: see "Demo account" below.
- **Notes** (paste as is):

```
Kairo is a task manager with a focus timer and a social layer limited to accepted friends.

Demo account (email and password in the fields above) has sample tasks, a friend and a shared task so every screen has content.

Sign in options: Sign in with Apple, Google, or email. Account deletion: Yo (Me) tab → Delete account; it removes the account and all its data immediately. Privacy policy: Yo → Privacy policy, and on the sign-in screen.

Social features: users only see content from friends whose request they accepted. A friend can be removed at any time from the Juntos (Together) tab, which stops all sharing with them.

Push notifications are used for friend requests, shared tasks, nudges and optional reminders. Permission is asked after sign-in.
```

### Export compliance

"Does your app use encryption?" is answered by `ITSAppUsesNonExemptEncryption = false` in `Info.plist` (only standard HTTPS), so App Store Connect does not ask on each build.

## Google Play Console

### Store listing

**Español (Latinoamérica), es-419**
- **Nombre de la app** (30): `Kairo: tareas con calma`
- **Descripción breve** (80): `Tareas, foco y calendario con calma. Un momento a la vez, solo o con amigos.`
- **Descripción completa** (4000): the App Store description above.

**English (United States), en-US**
- **App name** (30): `Kairo: Calm Tasks`
- **Short description** (80): `Tasks, focus and a calendar, calmly. One moment at a time, alone or with friends.`
- **Full description** (4000): the App Store description above.

### Data safety

- Does your app collect or share any of the required user data types? **Yes**.
- Is all of the user data collected by your app encrypted in transit? **Yes**.
- Do you provide a way for users to request that their data be deleted? **Yes** (in the app, and at the account deletion URL).
- Data **shared** with third parties: **None** (Supabase and Firebase act as service providers).

| Data type | Collected | Optional | Purpose |
| --- | --- | --- | --- |
| Personal info → Name | Yes | No | App functionality, Account management |
| Personal info → Email address | Yes | No | App functionality, Account management |
| Personal info → User IDs | Yes | No | App functionality, Account management |
| Photos and videos → Photos | Yes | Yes | App functionality |
| App activity → Other user-generated content | Yes | No | App functionality |
| App info and performance → Crash logs | Yes | No | App functionality |
| App info and performance → Diagnostics | Yes | No | App functionality |
| Device or other IDs | Yes | No | App functionality (push notification token) |

None of it is processed ephemerally only, and none is used for ads or analytics.

### Content rating (IARC questionnaire)

Category **Utility, Productivity, Communication or Other**. Violence, sexuality, language, controlled substances, gambling: **No**. Users can interact or exchange content: **Yes** (friends only, no public content). Shares user location: **No**. Expected rating: **Everyone / PEGI 3**.

### App content declarations

- **Ads:** No ads.
- **Target audience:** 13 and over (not designed for children).
- **News app:** No. **COVID-19 app:** No. **Government app:** No. **Financial features:** None. **Health:** None.
- **Account deletion:** in the app (Yo → Eliminar cuenta) and https://listerineh.dev/kairo/delete-account.
- **App access:** "All or some functionality is restricted": give the demo account.

### Release path

New personal Play developer accounts must run a **closed test with at least 12 testers for 14 days** before they can apply for production. Plan: internal testing (yourself) → closed testing (12+ testers) for 14 days → apply for production access → production.

## Demo account

| Field | Value |
| --- | --- |
| Email | `kairo.review@example.com` (Alex Rivera) |
| Password | Set by you in the SQL editor; never committed |
| Friend | `ana.demo@example.com` (Ana Morales, never signs in) |
| Content | Tasks for today (one done, one shared run), one overdue, the next days, two without a date, and a shared move |

`supabase/seed/demo_account.sql` creates both accounts if missing and rebuilds their tasks around today's date. Run it in the SQL editor right before each submission, so the reviewer sees a full "Hoy". It does not touch the password.

## Screenshots

| Store | Required | Size |
| --- | --- | --- |
| App Store | iPhone 6.9" (iPhone 17 Pro Max) | 1320 × 2868, 3 to 10 |
| Google Play | Phone | 1080 × 1920 to 1080 × 2400 (ratio up to 2:1), 2 to 8 |
| Google Play | Feature graphic | 1024 × 500 |
| Google Play | App icon | 512 × 512 (`assets/icons/app_icon_1024.png` scaled) |

Suggested set, with the demo account: Hoy, Foco, Planear (semana), Juntos, Crear tarea, Kairo.

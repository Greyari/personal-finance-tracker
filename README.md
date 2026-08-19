# Personal Finance App — Phase 1

**Scope of this phase:** Flutter project setup, Firebase (Auth + Firestore)
wiring, and full email/password authentication (login, register, logout,
forgot password) with a Firestore-backed user profile.

Not in this phase (coming later, per the phased plan): transactions,
categories, budgets, dashboard, savings, investments, recurring
transactions, reports, projections. The `HomePlaceholderScreen` you see
after logging in is a stand-in so the auth flow can be verified end to end.

## Folder structure

```
lib/
├── core/
│   ├── constants/app_constants.dart   Firestore collection names
│   ├── theme/app_theme.dart           colors, input/button styling
│   └── utils/validators.dart          shared form validation
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/app_user_model.dart
│   │   │   ├── repositories/auth_repository.dart      (FirebaseAuth)
│   │   │   ├── repositories/user_repository.dart       (Firestore profile)
│   │   │   └── exceptions/auth_exception.dart
│   │   └── presentation/
│   │       ├── providers/auth_providers.dart           (Riverpod)
│   │       └── screens/ login_screen.dart, register_screen.dart,
│   │                    forgot_password_screen.dart
│   └── dashboard/presentation/screens/home_placeholder_screen.dart
│
├── shared/widgets/ app_text_field.dart, app_button.dart
├── firebase_options.dart   placeholder — regenerate with FlutterFire CLI
└── main.dart
```

**Architecture notes**

- **State management: Riverpod**, used consistently everywhere per your
  instruction not to mix frameworks. It's a good fit here because most of
  this app's data (profile, later: transactions, budgets) is naturally a
  Firestore *stream*, and Riverpod's `StreamProvider` maps to that
  directly without extra boilerplate.
- **Data flow:** UI → Riverpod provider/controller → Repository →
  Firebase SDK. Screens never call `FirebaseAuth` or `FirebaseFirestore`
  directly — only repositories do. This keeps Firebase swappable/mockable
  and keeps business logic out of widgets.
- **Auth vs. Profile are separate:** FirebaseAuth owns identity (uid,
  email, password). Firestore (`users/{userId}/profile/data`) owns
  app-specific profile data. On register, we create both — the auth
  account, then the profile document — so they can't silently drift out
  of sync.

## Setup

1. **Install Flutter** (3.24+) if you haven't: https://docs.flutter.dev/get-started/install

2. **Create the project shell.** This bundle contains `lib/`, `pubspec.yaml`,
   `analysis_options.yaml`, and `firestore.rules` — the files that
   actually differ from a fresh Flutter project. Generate the rest with:
   ```bash
   flutter create --org com.yourcompany --project-name personal_finance_app temp_app
   ```
   then copy `temp_app/android`, `temp_app/ios`, etc. (the platform
   folders) into this project directory, and delete `temp_app`.

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Create a Firebase project** at https://console.firebase.google.com,
   then enable:
   - **Authentication → Sign-in method → Email/Password**
   - **Firestore Database** (start in production mode; the rules below
     replace the defaults)

5. **Connect Firebase to the app:**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Select your Firebase project and target platforms. This overwrites
   `lib/firebase_options.dart` with real values and registers the
   Android/iOS/web apps in your Firebase project.

6. **Deploy the security rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```
   (requires `firebase-tools`: `npm install -g firebase-tools`, then
   `firebase login` and `firebase init firestore` once to link this
   folder to your project, if not already linked.)

## Running

```bash
flutter run
```

## Testing the flow

1. Launch the app → you land on **Login** (no session yet).
2. Tap **Daftar** → fill in name/email/password → **Daftar**.
   - Check Firebase Console → Authentication: new user appears.
   - Check Firestore: `users/{uid}/profile/data` document appears with
     `displayName`, `email`, `createdAt`, `updatedAt`.
   - App navigates to the placeholder Home screen automatically.
3. Tap the logout icon → back to Login.
4. Log back in with the same credentials → Home screen loads the profile
   from Firestore (not just from memory) and shows your name.
5. On Login, tap **Lupa password?** → enter your email → check that a
   password-reset email arrives.
6. Try invalid inputs (bad email format, short password, mismatched
   confirm-password, wrong password on login) → confirm inline/snackbar
   validation messages appear in Indonesian and no request is sent to
   Firebase for client-side validation failures.

## Next phase

**Phase 2** will add: transaction model, income/expense entry, and
default + custom categories — replacing `HomePlaceholderScreen` content
incrementally rather than rebuilding it from scratch.

# Alveo App

Alveo is a Flutter mobile application designed to help users stay consistent with their medication routines, understand their treatment journey, and build healthier habits over time.

The app is built for people who need a simple but motivating way to:

- track prescribed medications
- receive timely reminders
- log whether doses were taken
- monitor progress over time
- stay engaged with a streak and XP-based wellness routine

## Why this project exists

Medication adherence is often difficult because schedules are easy to forget, especially when a person is managing multiple prescriptions or a long-term treatment plan. Alveo aims to reduce that friction by combining medication tracking, reminder notifications, and progress insights in one mobile experience.

The project focuses on making treatment management practical, encouraging, and easy to maintain day by day.

## Key features

### Medication management
- Add and manage prescribed medicines
- Set dosage, frequency, notes, and intake instructions
- Organize medications into treatment plans
- Track medication logs and completion status

### Reminder system
- Schedule notifications for medication times
- Trigger reminders before doses are due
- Use local notification handling and reminder scheduling logic in the app

### Progress and motivation
- Display key health and treatment stats
- Track streaks and XP-based engagement
- Reward medication consistency with milestone-oriented progress tracking

### User account flow
- Splash screen and startup gate
- Sign-up, login, password reset flow
- Profile access and personalized app experience via Supabase

### Dashboard experience
- Main navigation with home, medication, and statistics screens
- Quick overview of medication-related activity and app state
- Consistent UI built with Flutter Material 3 styling

## Tech stack

- Flutter
- Dart
- Supabase for authentication and backend data storage
- Flutter local notifications for reminder delivery
- Material Design UI
- SQLite-like structured data modeling through Supabase tables and app-side models

## Repository structure

```text
.
├── lib/
│   ├── core/                 # Shared utilities, theme, navigation, config
│   ├── features/
│   │   ├── auth/             # Login, register, password reset flow
│   │   ├── home/             # Home/dashboard screen
│   │   ├── medication/       # Medicines, treatment plans, logs
│   │   ├── notifications/    # Reminder and notification features
│   │   ├── profile/           # User profile screens
│   │   ├── splash/            # Startup and loading screens
│   │   ├── stats/             # Statistics and progress tracking
│   │   └── widgets/          # Shared UI components
│   ├── main.dart             # App bootstrap and route setup
│   └── main_navigation_page.dart
├── assets/                   # App assets and branding resources
├── android/                  # Android project files
├── ios/                      # iOS project files
├── linux/                    # Linux target files
├── macos/                    # macOS target files
├── windows/                  # Windows target files
├── web/                      # Web project files
├── sql/                      # Database migration and SQL helpers
├── alveo_database.sql        # Database schema context for the app
├── pubspec.yaml              # Flutter package metadata and dependencies
├── analysis_options.yaml     # Analyzer rules
├── README.md                 # Project documentation
└── replace.bat               # Utility script
```

## Data model overview

The application is designed around a medication tracking workflow that stores:

- medicines
- treatment plans
- medication schedules
- medication logs
- notifications
- user profile information
- XP and progress events

This structure is reflected in the SQL schema in `alveo_database.sql`, which includes tables such as:

- `medicines`
- `treatment_plans`
- `user_medications`
- `medication_schedules`
- `medication_logs`
- `notifications`
- `user_profile`
- `xp_events`
- `xp_levels`

The app uses this relational structure to support real-world medication routines while also tracking motivation and habit consistency.

## App flow

The app initializes on startup using `StartupGate`:

1. Flutter is initialized and the app boots.
2. Supabase is initialized.
3. Notification services are configured.
4. If the user is logged in, the app opens the main navigation dashboard.
5. Otherwise, the user is sent to the splash/login flow.

The main navigation screen then provides the user with access to:

- home dashboard
- medication management
- statistics and progress overview

## Getting started

### Prerequisites

- Flutter SDK installed
- Android/iOS emulator or physical device
- Supabase project configured

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Supabase setup

This project is configured to use Supabase for authentication and app data. The current backend configuration is defined in:

- `lib/core/supabase_config.dart`

If you are using your own Supabase instance, replace the project URL and anonymous key with your own values before running the app.

## Database notes

The project includes SQL schema context and reminder-related database logic to support scheduling and notification automation.

A reminder system is set up around:

- medication schedules
- notification generation
- scheduled reminders for active medications
- client-side handling of reminder delivery and acknowledgements

## Contributing

Contributions are welcome. If you want to improve the app, consider focusing on areas such as:

- better UX and onboarding
- medication reminder reliability
- analytics and health insights
- accessibility improvements
- testing and bug fixes

## License

This project does not currently declare a specific license in the repository. If you plan to reuse or redistribute it, confirm the intended licensing before publishing or distributing the code.

## Summary

Alveo is a medication adherence and wellness companion app that helps users stay consistent with treatment plans, remember scheduled doses, and build positive health routines over time. It blends mobile-first usability, reminder automation, and progress tracking into a cohesive Flutter application.

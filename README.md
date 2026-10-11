# 💊 Alveo App

Alveo is a Flutter mobile application designed to help users stay consistent with their medication routines, understand their treatment journey, and build healthier habits over time. 🌱

The app provides a simple and motivating way to:

- 💊 Track prescribed medications
- ⏰ Receive timely medication reminders
- ✅ Log whether doses were taken
- 📊 Monitor treatment progress
- 🔥 Build medication-taking streaks
- ⭐ Earn XP through consistent adherence

## 🎯 Why this project exists

Medication adherence can be difficult, especially when someone is managing multiple prescriptions or following a long-term treatment plan. Schedules are easy to forget, and it can be hard to see progress over time.

Alveo aims to make treatment management more practical, encouraging, and easy to maintain day by day. The app combines medication tracking, reminder notifications, progress insights, and motivational features in one mobile experience. 🤝

## ✨ Key features

### 💊 Medication management

- Add and manage prescribed medicines
- Set dosage, frequency, notes, and intake instructions
- Organize medications into treatment plans
- Track medication schedules and logs
- Record dose completion status

### ⏰ Reminder system

- Schedule notifications for medication times
- Receive reminders before doses are due
- View upcoming medication reminders
- Use local notification handling and reminder scheduling logic

### 📈 Progress and motivation

- View treatment and medication statistics
- Track current and longest streaks 🔥
- Earn XP for medication consistency ⭐
- Monitor total medication doses taken
- Use progress information to stay motivated

### 🔐 User account flow

- Startup and splash screen experience
- User registration and login
- Password reset support
- Personalized account data through Supabase
- Profile management

### 🏠 Dashboard experience

- Home dashboard with a quick overview of medication activity
- Dedicated medication management screen
- Statistics and progress screen
- In-app medication reminder bar
- Smooth navigation between major app areas
- Consistent UI built with Flutter Material 3 styling

## 🛠️ Tech stack

- **Flutter** — Cross-platform application framework
- **Dart** — Application programming language
- **Supabase** — Authentication and backend data storage
- **Flutter Local Notifications** — Local medication reminders
- **Timezone packages** — Timezone-aware reminder scheduling
- **Material 3** — Modern Flutter UI components
- **Poppins** — Application typography

## 🗂️ Repository structure

```text
.
├── lib/
│   ├── core/                 # Shared utilities, theme, navigation, and config
│   ├── features/
│   │   ├── auth/             # Login, registration, and password reset flow
│   │   ├── home/             # Home and dashboard screens
│   │   ├── medication/       # Medicines, treatment plans, schedules, and logs
│   │   ├── notifications/    # Reminder and notification features
│   │   ├── profile/          # User profile screens
│   │   ├── splash/           # Startup and loading screens
│   │   ├── stats/            # Statistics and progress tracking
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
├── sql/                      # Database migrations and SQL helpers
├── alveo_database.sql        # Database schema reference
├── pubspec.yaml              # Flutter dependencies and project metadata
├── analysis_options.yaml     # Dart analyzer rules
├── README.md                 # Project documentation
└── replace.bat               # Utility script
```

## 🧩 Data model overview

Alveo is built around a medication tracking workflow that stores:

- 💊 Medicines
- 📋 Treatment plans
- 🗓️ Medication schedules
- 📝 Medication logs
- 🔔 Notifications
- 👤 User profile information
- ⭐ XP events and levels

The database schema in `alveo_database.sql` includes tables such as:

- `medicines`
- `treatment_plans`
- `user_medications`
- `medication_schedules`
- `medication_logs`
- `notifications`
- `user_profile`
- `xp_events`
- `xp_levels`

This relational structure supports real-world medication routines while also tracking motivation and habit consistency. 📚

## 🔄 App flow

The application initializes through `StartupGate`:

1. 🚀 Flutter is initialized and the app starts.
2. ☁️ Supabase is initialized.
3. 🔔 Notification services are configured.
4. 🔐 The current authentication state is checked.
5. 🏠 Authenticated users are taken to the main dashboard.
6. 👋 New or signed-out users are taken to the splash and login flow.

The main navigation screen provides access to:

- 🏠 Home dashboard
- 💊 Medication management
- 📊 Statistics and progress overview

## 🚀 Getting started

### ✅ Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed
- Dart SDK compatible with the version specified in `pubspec.yaml`
- An Android or iOS emulator, simulator, or physical device
- A configured Supabase project

### 📦 Install dependencies

```bash
flutter pub get
```

### ▶️ Run the app

```bash
flutter run
```

### 🧪 Run tests

```bash
flutter test
```

### ☁️ Supabase setup

This project uses Supabase for authentication and application data. The backend configuration is defined in:

```text
lib/core/supabase_config.dart
```

If you are using your own Supabase instance, replace the project URL and anonymous key with your own values before running the app.

> 🔒 Never commit private service-role keys or other sensitive credentials. The mobile application should only use a properly restricted public/anonymous key.

## 🗄️ Database setup

The repository includes the database schema and reminder-related SQL logic needed to support medication scheduling and notification automation.

The reminder system is built around:

- 🗓️ Medication schedules
- 🔔 Notification generation
- ⏱️ Scheduled reminders for active medications
- 📱 Client-side reminder display and handling
- 🔐 User-specific access control through Supabase policies

Refer to `alveo_database.sql` and the SQL files in the `sql/` directory when setting up the backend.

## 🤝 Contributing

Contributions and ideas are welcome! You can help improve Alveo by working on:

- 🎨 User experience and onboarding
- ⏰ Medication reminder reliability
- 📊 Health insights and analytics
- ♿ Accessibility improvements
- 🧪 Automated tests
- 🐛 Bug fixes and performance improvements

A typical contribution workflow is:

1. Fork the repository.
2. Create a feature branch.
3. Make and test your changes.
4. Open a pull request with a clear description.

## 📄 License

This project does not currently declare a specific license in the repository. If you plan to reuse or redistribute it, confirm the intended licensing before publishing or distributing the code.

## 💚 Summary

Alveo is a medication adherence and wellness companion designed to help users remember scheduled doses, stay consistent with treatment plans, and build positive health routines over time. By combining reminders, medication logs, progress statistics, streaks, and XP, Alveo makes medication management more organized and motivating. 🌟

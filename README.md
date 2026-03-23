# HydroGate (Automated Floodgate and Monitoring System)

This is the Flutter-based mobile and web application for the Automated Floodgate and Monitoring System.

## Project Structure
- `lib/`: Contains the Dart source code for the app.
- `assets/`: Contains images and other assets.
- `android/`, `ios/`, `web/`, `windows/`: Platform-specific configuration and code.

## Getting Started

### Prerequisites
- Flutter SDK installed
- Firebase CLI installed (if configuring Firebase)

### Setup
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure Firebase (Mandatory for teammates):
   Since sensitive Firebase configuration files are ignored by Git (see `.gitignore`), each team member must regenerate them locally:
   ```powershell
   flutterfire configure --project=afwms-d3141
   ```
   *This will regenerate `lib/firebase_options.dart` and other platform-specific secrets.*
4. Keep all app, admin, and CLI work on the same Firebase project: `afwms-d3141`.

### Running the App
- **Chrome (Web):** `flutter run -d chrome`
- **Windows (Desktop):** `flutter run -d windows`

## Firebase Features
- Authentication (Email/Password)
- Real-time Monitoring (Coming Soon)

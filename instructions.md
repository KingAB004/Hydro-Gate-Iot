# HydroGate AFWMS — Setup Guide 🌊

Complete step-by-step guide for teammates to clone and run this project on their machine. Follow **every step in order** — don't skip anything.

---

## 📝 Prerequisites (Install BEFORE Starting)

Make sure you have ALL of these installed first:

| Tool | Version | Download Link |
|------|---------|---------------|
| **Git** | Any recent version | [git-scm.com/download/win](https://git-scm.com/download/win) |
| **Flutter SDK** | v3.10.4 or higher | [flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| **Android Studio** | Latest (for Android emulator + SDK) | [developer.android.com/studio](https://developer.android.com/studio) |
| **VS Code** | Latest (recommended editor) | [code.visualstudio.com](https://code.visualstudio.com) |
| **Node.js + npm** | LTS version (needed for Firebase CLI) | [nodejs.org](https://nodejs.org) |
| **Chrome** | Latest (for web testing) | Already installed probably 😄 |

### ✅ Quick Verification
After installing, open a **new** terminal (PowerShell or CMD) and verify everything:
```bash
git --version
flutter --version
node --version
npm --version
```
All four should print version numbers. If any fails, the tool is not in your `PATH` — reinstall it.

### ⚠️ Windows Developer Mode (REQUIRED)
Flutter plugins need symlink support. Enable Developer Mode:
```bash
start ms-settings:developers
```
Then toggle **Developer Mode** to ON.

### ⚠️ Flutter Doctor
Run this to check if your Flutter setup is complete:
```bash
flutter doctor
```
Fix any ❌ items before proceeding. Common fixes:
- **Android toolchain**: Open Android Studio → Settings → SDK Manager → install SDK + command-line tools
- **Accept Android licenses**: `flutter doctor --android-licenses`

---

## 🚀 Setup Instructions

### Step 1: Clone the Repository
```bash
git clone <insert-your-repo-url-here>
cd AFWMS
```

### Step 2: Install Flutter Dependencies
This downloads all the packages listed in `pubspec.yaml`:
```bash
flutter pub get
```
> **If this fails**, make sure `flutter` is in your PATH and you are inside the `AFWMS/` folder.

### Step 3: Firebase CLI Setup
We use Firebase Authentication, Firestore, and Realtime Database. The config files are NOT in GitHub (they are gitignored), so you need to generate them locally.

**a. Install Firebase CLI via npm:**
```bash
npm install -g firebase-tools
```

**b. Verify it works:**
```bash
firebase --version
```
> **If `firebase` is not recognized**, close and reopen your terminal, then try again.

**c. Login to Firebase:**
```bash
firebase login
```
This opens a browser window. Log in with the **same Google account** that has access to the Firebase project. Ask your team lead to add you if needed.

### Step 4: FlutterFire CLI Setup
FlutterFire generates the `firebase_options.dart` config file that the app needs.

**a. Install FlutterFire CLI:**
```bash
dart pub global activate flutterfire_cli
```

**b. Add Pub Cache to your PATH (Windows):**
The CLI is installed to a folder that may not be in your PATH. Add this folder:
```
C:\Users\<your-username>\AppData\Local\Pub\Cache\bin
```
**How to add to PATH:**
1. Press `Win + S`, search for **"Environment Variables"**
2. Click **"Edit the system environment variables"**
3. Click **"Environment Variables..."** button
4. Under **User variables**, find `Path`, click **Edit**
5. Click **New**, paste: `C:\Users\<your-username>\AppData\Local\Pub\Cache\bin`
6. Click OK on all windows
7. **Close and reopen** your terminal / VS Code

**c. Verify it works:**
```bash
flutterfire --version
```

### Step 5: Generate Firebase Config Files
This is the most important step. It generates `lib/firebase_options.dart` and `android/app/google-services.json`:
```bash
flutterfire configure --project=afwms-d3141
```

When prompted:
- **Select platforms**: Use arrow keys + spacebar to select **Android, Web, and Windows** (or whichever you need)
- Press Enter to confirm

> **IMPORTANT**: After running this, open `lib/firebase_options.dart` and check if `databaseURL` is present. If it's missing, you need to manually add this line to the Web, Android, and Windows configurations inside that file:
> ```dart
> databaseURL: 'https://afwms-d3141-default-rtdb.firebaseio.com',
> ```

### Step 6: Environment Variables (API Keys)
The app uses a `.env` file for API keys. This file is gitignored so your keys stay private.

**a. Create your `.env` file from the template:**

PowerShell:
```powershell
Copy-Item .env.example .env
```

CMD:
```cmd
copy .env.example .env
```

Git Bash / macOS / Linux:
```bash
cp .env.example .env
```

**b. Get your OpenWeatherMap API Key:**
1. Go to [openweathermap.org](https://openweathermap.org/api) and create a **free** account
2. Verify your email (check inbox + spam)
3. Go to [API Keys page](https://home.openweathermap.org/api_keys)
4. Copy your Default key (or generate a new one)
5. ⏳ **Wait 10 minutes to 2 hours** for the key to activate (this is normal!)

**c. Get your Gemini AI API Key:**
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key

**d. Fill in your `.env` file:**
Open the `.env` file and replace the placeholder values:
```dotenv
OPENWEATHER_API_KEY=paste_your_openweather_key_here
OPENWEATHER_BASE_URL=https://api.openweathermap.org/data/2.5
GEMINI_API_KEY=paste_your_gemini_key_here
```

**e. Test your OpenWeatherMap key:**
Open this URL in your browser (replace `YOUR_KEY`):
```
https://api.openweathermap.org/data/2.5/weather?q=Manila&appid=YOUR_KEY&units=metric
```
If you see JSON weather data, your key is working ✅

### Step 7: Run the App! 🎉
Check available devices:
```bash
flutter devices
```

Run on your preferred platform:
```bash
# Chrome (Web)
flutter run -d chrome

# Android Emulator (make sure emulator is running first)
flutter run -d emulator-5554

# Windows Desktop
flutter run -d windows

# Or just let Flutter pick a device
flutter run
```

---

## 📱 Building the APK (Android)

To generate a debug APK for testing on a physical phone:
```bash
flutter build apk --debug
```
The APK will be in: `build/app/outputs/flutter-apk/app-debug.apk`

For release APK (needs signing key — ask the team lead):
```bash
flutter build apk --release
```

---

## 🛠 Troubleshooting

### ❌ "Undefined name 'DefaultFirebaseOptions'" or firebase_options.dart error
**Cause**: Firebase config file hasn't been generated yet.
**Fix**: Run `flutterfire configure --project=afwms-d3141` (Step 5).

### ❌ Firebase Realtime Database not working (reads/writes fail)
**Cause**: `databaseURL` missing from `firebase_options.dart`.
**Fix**: Open `lib/firebase_options.dart` and add this line to each platform config:
```dart
databaseURL: 'https://afwms-d3141-default-rtdb.firebaseio.com',
```

### ❌ "Building with plugins requires symlink support" (Windows)
**Cause**: Developer Mode is not enabled.
**Fix**: Run `start ms-settings:developers` and turn on Developer Mode.

### ❌ `git` / `flutter` / `firebase` / `flutterfire` not recognized
**Cause**: The tool is not in your system PATH.
**Fix**: 
- `git` → Reinstall Git and make sure "Add to PATH" is checked
- `flutter` → Add `<flutter-sdk-path>/bin` to your PATH
- `firebase` → Run `npm install -g firebase-tools` and restart terminal
- `flutterfire` → Add `C:\Users\<you>\AppData\Local\Pub\Cache\bin` to PATH and restart terminal

### ❌ "Invalid API key" on Weather screen
**Cause**: OpenWeatherMap key is wrong, not activated yet, or `.env` file is missing.
**Fix**:
1. Make sure `.env` file exists in the project root
2. Double-check your API key is copied correctly (no extra spaces)
3. If new account, wait 1-2 hours for activation
4. Test using the URL in Step 6e

### ❌ Gemini chatbot not responding
**Cause**: `GEMINI_API_KEY` is missing or invalid in `.env`.
**Fix**: Get a new key from [Google AI Studio](https://aistudio.google.com/app/apikey) and update your `.env`.

### ❌ `flutter pub get` fails with version errors
**Fix**: Try upgrading:
```bash
flutter pub upgrade
```
If it still fails, check you're on Flutter 3.10.4+:
```bash
flutter --version
```

### ❌ Android build fails / Gradle errors
**Fix**: Make sure you have:
1. Android SDK installed (via Android Studio → SDK Manager)
2. Java 17+ (bundled with Android Studio)
3. Accepted licenses: `flutter doctor --android-licenses`
4. Try cleaning: `flutter clean && flutter pub get`

---

## 📁 Project Structure (Key Files)

```
AFWMS/
├── lib/
│   ├── main.dart                 # App entry point & auth routing
│   ├── firebase_options.dart     # (GENERATED - gitignored) Firebase config
│   ├── screens/                  # All app screens
│   │   ├── dashboard_screen.dart # Operator dashboard (water level + gate control)
│   │   ├── lgu_home_screen.dart  # LGU/Admin dashboard
│   │   ├── alerts_screen.dart    # Announcements & notifications
│   │   ├── weather_screen.dart   # Weather forecast
│   │   └── ...
│   ├── services/                 # Backend services (auth, audit logs, weather)
│   ├── widgets/                  # Reusable UI components
│   ├── models/                   # Data models
│   └── utils/                    # Utility functions
├── android/                      # Android-specific config
│   └── app/google-services.json  # (GENERATED - gitignored) Firebase Android config
├── web/                          # Web-specific config
├── assets/                       # Images & logos
├── .env                          # (YOUR COPY - gitignored) API keys
├── .env.example                  # Template for .env
├── pubspec.yaml                  # Project dependencies
└── instructions.md               # This file!
```

---

## 🔑 Roles in the App

| Role | Dashboard | Features |
|------|-----------|----------|
| **Admin / LGU** | `LGUDashboardScreen` | Monitor water level, broadcast announcements, view audit logs, close/open gates |
| **Homeowner / Operator** | `MainHomeScreen` → `DashboardScreen` | View water level, control assigned gate, view alerts, weather |

---

## 💬 Need Help?
If you're stuck, send a screenshot of your error in the group chat. Most issues are PATH or Firebase config related — usually fixable in < 5 minutes.



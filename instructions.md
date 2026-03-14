# AFWMS (Flutter Project) Setup Guide

This is the step-by-step guide to set up and run the project smoothly after cloning. Follow the steps below so we don't miss any dependencies.

## 📝 Prerequisites
Before we start, make sure you have the following installed on your machine:
- **Git** (for cloning, and it must be available in your system `PATH`)
- **Flutter SDK** (v3.10.4 or higher) - [Download here](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (Included when you install Flutter)
- **Code Editor** (VS Code, Android Studio, or IntelliJ)
- **Firebase Account** (for backend/auth features)
- **OpenWeatherMap Account** (for weather functionality) - [Sign up here](https://openweathermap.org/api)

---

## 🚀 Setup Instructions

### 1. Clone the Repository
First, clone the repo to your local machine:
```bash
git clone <insert-repo-url-here>
cd AFWMS
```

### 2. Install Dependencies
We need to download the packages used in the project (like firebase, cupertino icons, etc.):
```bash
flutter pub get
```

### 3. Firebase Setup (Important!)
Since we use Firebase authentication and Firestore, we need to connect the app to the Firebase project. The Firebase configuration files are not included in the GitHub repo (they are in `.gitignore`), so each teammate needs to generate them locally.

**a. Install FlutterFire CLI**
If you don't have FlutterFire CLI installed globally yet, run:
```bash
dart pub global activate flutterfire_cli
```
*(Note: On Windows, add `C:\Users\<your-username>\AppData\Local\Pub\Cache\bin` to your `PATH` environment variable if `flutterfire` is not recognized after installation.)*

**b. Install Firebase CLI**
The `firebase login` command requires the Firebase CLI. Install it first:

Option 1: With Node.js and npm installed
```bash
npm install -g firebase-tools
```

Option 2: Download the standalone Firebase CLI from the official docs
- [Firebase CLI setup guide](https://firebase.google.com/docs/cli)

**c. Login to Firebase**
Before configuring, you must be logged into your Firebase account:
```bash
firebase login
```

**d. Configure Firebase**
To generate the missing `firebase_options.dart` file (where errors often occur when missing):
```bash
flutterfire configure --project=afwms-d3141
```
This will connect to Firebase using the specific project id used in the app. After this, the `lib/firebase_options.dart` file will be generated automatically.

### 4. Environment Variables Setup (API Keys)
The app uses environment variables to securely store API keys. This prevents sensitive information from being pushed to GitHub.

**a. Copy the environment template**
Copy the `.env.example` file to create your own `.env` file:
```bash
cp .env.example .env
```
*(On Windows Command Prompt, use: `copy .env.example .env`)*

**b. Get OpenWeatherMap API Key**
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Create a free account
3. Verify your email address (check your inbox!)
4. Go to [API Keys](https://home.openweathermap.org/api_keys)
5. Generate a new API key
6. Wait 10-120 minutes for activation (this is normal)

**c. Configure your `.env` file**
Open your `.env` file and replace `your_api_key_here` with your actual API key:
```dotenv
OPENWEATHER_API_KEY=your_actual_api_key_here
```

**d. Test your API key**
You can test if your API key works by visiting this URL in your browser:
```
https://api.openweathermap.org/data/2.5/weather?q=Manila&appid=YOUR_API_KEY&units=metric
```
*(Replace `YOUR_API_KEY` with your actual key)*

### 5. Run the App
Once the dependencies and Firebase configuration are okay, we can test the app!

If you want to see the list of available devices:
```bash
flutter devices
```

To run the app:
- **Chrome (Web):** `flutter run -d chrome`
- **Windows (Desktop):** `flutter run -d windows`

---

## 🛠 Troubleshooting Common Errors

### Firebase Errors
**"Undefined name 'DefaultFirebaseOptions'" or "Error when reading 'lib/firebase_options.dart'"**
- This means your Firebase configuration hasn't been generated locally yet. Just go back to **Step 3.c** (`flutterfire configure --project=afwms-d3141`) and make sure you are in the root directory of the project (`AFWMS/`).

**Firebase Realtime Database not saving or reading data**
- Sometimes `flutterfire configure` forgets to add the Realtime Database URL. Open your generated `lib/firebase_options.dart` and make sure `databaseURL: 'https://afwms-d3141-default-rtdb.firebaseio.com'` is added to your Web, Android, and Windows configurations.

### Weather API Errors
**"Invalid API key" error in Weather screen**
- Check if you copied your API key correctly in the `.env` file
- Make sure your email is verified with OpenWeatherMap
- Wait 1-2 hours for the API key to activate (this is normal for new accounts)
- Test your key using the URL provided in Step 4.d

**Weather screen shows error or won't load**
- Make sure your `.env` file exists and has the correct API key
- Check that your OpenWeatherMap API key is valid and activated
- Verify your internet connection

### System Errors
**"Building with plugins requires symlink support" (Windows)**
- You need to enable **Developer Mode** in your Windows Settings. You can type in the terminal:
  ```bash
  start ms-settings:developers
  ```
  Then turn on Developer Mode.

**"git : The term 'git' is not recognized..." when running Flutter or Dart commands**
- Install **Git for Windows** from [git-scm.com](https://git-scm.com/download/win)
- During installation, keep the option that adds Git to your command line tools / `PATH`
- After installation, fully close and reopen your terminal or VS Code
- Verify it works with:
  ```bash
  git --version
  ```
- Then retry the original command, for example:
  ```bash
  dart pub global activate flutterfire_cli
  ```

**"flutterfire : The term 'flutterfire' is not recognized..."**
- Add `C:\Users\<your-username>\AppData\Local\Pub\Cache\bin` to your `PATH`
- Fully close and reopen your terminal or VS Code
- Verify it works with:
  ```bash
  flutterfire --version
  ```

**"firebase : The term 'firebase' is not recognized..."**
- Install the Firebase CLI by following Step 3.b
- If you installed it with npm, make sure Node.js and npm are installed and available in your `PATH`
- Fully close and reopen your terminal or VS Code
- Verify it works with:
  ```bash
  firebase --version
  ```

### Package Version Errors
**"1 package has newer versions incompatible with dependency constraints"**
- This is sometimes normal when there are version mismatches. If you want to update to the latest compatible versions, run:
  ```bash
  flutter pub upgrade
  ```

---

## 📁 Project Structure Notes

- **`.env`** - Your local environment variables (never commit this!)
- **`.env.example`** - Template for environment variables (safe to commit)  
- **`lib/firebase_options.dart`** - Auto-generated Firebase config (in .gitignore)
- **Weather integration** - Uses OpenWeatherMap API for real-time weather data

---
Happy coding! 💻 🌤️

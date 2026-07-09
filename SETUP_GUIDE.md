# Catalyst Setup & Cloning Guide 🔋

Welcome to **Catalyst**—a high-performance, mobile fitness and fuel tracker constructed in a sleek, neo-technical brutalist aesthetic. This project is built with **Expo (React Native)** and utilizes **native Firebase services** (Auth, Firestore, and Cloud Messaging) and **Google Gemini AI**.

This guide is designed for developers who have cloned this repository and want to run, configure, and compile it locally on **Windows**, **macOS**, or **Linux**.

---

## 🚀 Quick Automated Setup (Recommended)

We have created automated setup scripts that check your installed versions of Node.js, Java JDK, and Android SDK. If they are missing or outdated, they will attempt to install them (using `winget` on Windows, `brew` on macOS, or `apt` on Linux) and then set up the project dependencies and files automatically.

### On macOS and Linux (Ubuntu):
Open your terminal in the root of the project and run:
```bash
./setup.sh
```

### On Windows:
Open PowerShell as Administrator in the root of the project and run:
```powershell
.\setup.ps1
```

---

## 📋 Table of Contents
1. [Prerequisites (All Operating Systems)](#1-prerequisites-all-operating-systems)
2. [Operating System Setup Guides](#2-operating-system-setup-guides)
   - [Windows Setup](#windows-setup)
   - [macOS Setup](#macos-setup)
   - [Linux Setup](#linux-setup)
3. [Connecting Your Own Database & Services](#3-connecting-your-own-database--services)
   - [Firebase Configuration (Firestore & Auth)](#firebase-configuration-firestore--auth)
   - [Gemini AI Configuration](#gemini-ai-configuration)
4. [Generating Native Folders (`android` / `ios`)](#4-generating-native-folders-android--ios)
5. [Running in Development Mode](#5-running-in-development-mode)
6. [Building a Standalone Production APK](#6-building-a-standalone-production-apk)

---

## 1. Prerequisites (All Operating Systems)

Before installing OS-specific tools, make sure you have the following installed:
* **Node.js**: Recommended version **v20.x (LTS)**.
* **Java Development Kit (JDK)**: Recommended version **JDK 17**. *(Note: Android Gradle Plugin inside this project version does not support JDK 25 by default; stick to JDK 17 or JDK 21)*.
* **Android Studio & Android SDK**: Required to build and run the Android app locally.
* **Git**: To clone the repository.

---

## 2. Operating System Setup Guides

### Windows Setup

#### Step A: Install Node.js & Git
1. Download and install **Node.js LTS (v20)** from the [official Node.js website](https://nodejs.org/).
2. Download and install **Git for Windows** from [git-scm.com](https://git-scm.com/). Ensure **Git Bash** is installed as part of the package.

#### Step B: Install JDK 17
1. Download and install **Microsoft Build of OpenJDK 17** or **Eclipse Temurin JDK 17** (LTS).
2. Add the JDK installation path to your system's Environment Variables:
   * Set `JAVA_HOME` to `C:\Program Files\Eclipse Foundation\jdk-17.x.x-hotspot\` (or your specific JDK 17 path).
   * Add `%JAVA_HOME%\bin` to your system `PATH` variable.

#### Step C: Install & Configure Android Studio
1. Download and install [Android Studio](https://developer.android.com/studio).
2. During the setup wizard, select the standard options to install the **Android SDK**, **Android SDK Command-line Tools**, and **Android Virtual Device (Emulator)**.
3. Open Android Studio -> Tools -> SDK Manager -> SDK Tools tab. Ensure the following are checked and installed:
   * **Android SDK Build-Tools**
   * **Android SDK Command-line Tools (latest)**
   * **Android Emulator**
4. Configure Environment Variables for Android SDK:
   * Create a new User variable named `ANDROID_HOME` pointing to your Android SDK folder:
     `C:\Users\<Your-Username>\AppData\Local\Android\Sdk`
   * Add the following paths to your system/user `PATH` environment variable:
     * `%ANDROID_HOME%\platform-tools`
     * `%ANDROID_HOME%\emulator`
     * `%ANDROID_HOME%\tools`
     * `%ANDROID_HOME%\tools\bin`

---

### macOS Setup

#### Step A: Install Homebrew, Node.js, and Git
Open your Terminal and run:
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js LTS and Git
brew install node@20 git
brew link node@20
```

#### Step B: Install JDK 17
Install the OpenJDK 17 distribution via Homebrew:
```bash
brew install openjdk@17
```
Add the JDK path to your Shell profile (`~/.zshrc` or `~/.bash_profile`):
```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"
```
Apply the changes: `source ~/.zshrc`

#### Step C: Install Android Studio & configure environment variables
1. Download and install **Android Studio** (make sure to choose the Apple Silicon version if using an M1/M2/M3 Mac).
2. Open Android Studio and install the Android SDK and Command-line Tools.
3. Configure the environment variables in your Shell profile (`~/.zshrc` or `~/.bash_profile`):
```bash
export ANDROID_HOME=$HOME/Library/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```
Apply the changes: `source ~/.zshrc`

#### Step D: Install Xcode (Optional — for iOS Development)
1. Download and install **Xcode** from the Mac App Store.
2. Open Xcode, go to settings -> Locations, and ensure the **Command Line Tools** are selected.
3. Install CocoaPods:
```bash
brew install cocoapods
```

---

### Linux Setup

#### Step A: Install Node.js, Git, and JDK 17
On Debian/Ubuntu-based distributions, run:
```bash
# Update packages
sudo apt update

# Install Git and build dependencies
sudo apt install -y git build-essential curl

# Install Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install OpenJDK 17
sudo apt install -y openjdk-17-jdk
```

#### Step B: Set up Android SDK
1. Download the Android Command Line Tools from the Android Developer portal, or install Android Studio for Linux.
2. Extract the SDK to a folder (e.g., `/usr/lib/android-sdk` or `$HOME/Android/Sdk`).
3. Add the following to your `~/.bashrc` or `~/.zshrc`:
```bash
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64" # Check your specific path
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"
export PATH="$JAVA_HOME/bin:$PATH"
```
4. Run `source ~/.bashrc` to reload.

---

## 3. Connecting Your Own Database & Services

If you want to configure your own backend and AI services rather than the template credentials, update these two files:

### Firebase Configuration (Firestore & Auth)
Catalyst uses native Firebase for its users, logs, and configurations.
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. In the Firebase Project settings, add an **Android application**.
   * **Package Name**: Use `com.catalyst.app` (defined in your `app.json`). If you want to rename your package, update the `android.package` property in `app.json`.
3. Download the **`google-services.json`** file.
4. Replace the existing `google-services.json` in the root of the project with your downloaded file.
5. In the Firebase console, make sure to enable:
   * **Authentication** (specifically Email/Password sign-in).
   * **Cloud Firestore** (start in test mode or define your own access rules).

*(Optional for iOS)*: If building for iOS, add an iOS app to your Firebase project, download `GoogleService-Info.plist`, and place it in the project root. Make sure it is referenced in `app.json` under `ios.googleServicesFile`.

### Gemini AI Configuration
This app uses Gemini for food scanning and fitness coaching.
1. Obtain an API key from the [Google AI Studio](https://aistudio.google.com/).
2. Create a file named `.env` in the root of your project.
3. Write your key in the file:
```env
EXPO_PUBLIC_GEMINI_API_KEY=your_actual_gemini_api_key_here
```

---

## 4. Generating Native Folders (`android` / `ios`)

Since Expo builds use native wrappers (`@react-native-firebase`, `@notifee`, and biometric modules), you must generate the native directories. **Do not modify the `android/` or `ios/` folders directly unless you know what you are doing.** They can be completely regenerated at any time using:

```bash
# 1. Install JS dependencies
npm install

# 2. Run Expo prebuild to generate/sync native folders
npx expo prebuild --clean
```
This command reads your `app.json` (specifically the plugins list and settings like `googleServicesFile`) and compiles a brand-new native configuration inside the `android` and `ios` folders.

---

## 5. Running in Development Mode

To start coding and testing on a device/emulator:

### Step 1: Start the Metro Bundler
This starts the bundler server that compiles JavaScript on the fly:
```bash
npm start
```

### Step 2: Run on Emulator or Connected Device
Open a second terminal window and boot the application:
* **For Android**:
  ```bash
  npm run android
  ```
* **For iOS** (macOS only):
  ```bash
  npm run ios
  ```

*Make sure your emulator is running or a physical device is plugged in with USB Debugging enabled.*

---

## 6. Building a Standalone Production APK

If you want to build a local, standalone, offline-installable APK (`.apk`) that you can transfer directly to any phone:

### On Linux & macOS:
We have created an automated, styled build script `build.sh` in the root directory. You can simply run:
```bash
bash build.sh
```
This script will validate your environment keys, verify Node/Java installations, run `expo prebuild`, clear the Gradle asset cache, and compile your release APK.

### On Windows:
You can build the production package directly using the Gradle wrapper:
1. Open PowerShell or Command Prompt.
2. Generate native folders if you haven't already:
   ```bash
   npx expo prebuild --clean
   ```
3. Navigate into the native Android folder:
   ```bash
   cd android
   ```
4. Run the Gradle clean and assemble release tasks:
   ```powershell
   # Clean previous build artifacts
   .\gradlew clean
   # Assemble the production APK
   .\gradlew assembleRelease
   ```

### Locating the Built APK (All Platforms):
Once the Gradle process successfully completes, find your offline installer APK at:
```
android/app/build/outputs/apk/release/app-release.apk
```
Copy this file onto your phone, bypass the untrusted app warning, install it, and you're ready!

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  setup.sh  —  Catalyst Environment Setup Script
#
#  Usage:
#    bash setup.sh
# ═══════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "  ╔════════════════════════════════════════════════════════╗"
echo "  ║                                                        ║"
echo "  ║     ⚡  C A T A L Y S T   E N V   S E T U P  ⚡          ║"
echo "  ║                                                        ║"
echo "  ╚════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Linux*)     OS="Linux";;
    Darwin*)    OS="macOS";;
    *)          OS="Unknown";;
esac

echo -e "   Detected OS: ${BOLD}${MAGENTA}$OS${RESET}"

# Helper: check command exists
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper: Prompt user to press enter to continue
prompt_install() {
    local service="$1"
    local command="$2"
    echo -e "   ${YELLOW}⚠  $service is missing or has incorrect version.${RESET}"
    read -p "   Do you want this script to attempt installing it via package manager? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        eval "$command"
    else
        echo -e "   ${RED}Skipping automatic installation. Please install $service manually before continuing.${RESET}"
    fi
}

# ── 1. Check Node.js ──────────────────────────────────────────
echo -e "\n   ${BOLD}${BLUE}Checking Node.js...${RESET}"
NODE_OK=false
if cmd_exists node; then
    NODE_VER=$(node -v | tr -d 'v')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    echo -e "   Found Node.js version ${GREEN}$NODE_VER${RESET}"
    if [ "$NODE_MAJOR" -ge 18 ]; then
        NODE_OK=true
    else
        echo -e "   ${YELLOW}Node.js version is too old (needs v18+).${RESET}"
    fi
else
    echo -e "   Node.js is ${RED}not installed${RESET}."
fi

if [ "$NODE_OK" = false ]; then
    if [ "$OS" = "macOS" ]; then
        if cmd_exists brew; then
            prompt_install "Node.js v20" "brew install node@20 && brew link node@20"
        else
            echo -e "   ${RED}Homebrew is not installed. Please install Homebrew or install Node.js from https://nodejs.org/${RESET}"
        fi
    elif [ "$OS" = "Linux" ]; then
        if cmd_exists apt-get; then
            prompt_install "Node.js v20" "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
        else
            echo -e "   ${RED}apt-get not found. Please install Node.js manually via your package manager.${RESET}"
        fi
    else
        echo -e "   ${RED}Please install Node.js v18+ manually from https://nodejs.org/${RESET}"
    fi
fi

# Re-check Node.js after install attempt
if ! cmd_exists node; then
    echo -e "   ${RED}Node.js setup failed or skipped. Cannot proceed without Node.js.${RESET}"
    exit 1
fi

# ── 2. Check Java JDK (needs 17 or 21) ───────────────────────
echo -e "\n   ${BOLD}${BLUE}Checking Java JDK (needs JDK 17 or 21)...${RESET}"
JDK_OK=false
if cmd_exists java; then
    JAVA_VER_STR=$(java -version 2>&1 | head -n 1)
    echo -e "   Found Java: ${GREEN}$JAVA_VER_STR${RESET}"
    if [[ "$JAVA_VER_STR" == *"17."* ]] || [[ "$JAVA_VER_STR" == *"21."* ]]; then
        JDK_OK=true
    elif [[ "$JAVA_VER_STR" == *"25."* ]]; then
        echo -e "   ${YELLOW}Warning: JDK 25 is installed. Gradle builds may fail to parse Kotlin files with JDK 25.${RESET}"
        # We will check if we have JDK 17/21 installed elsewhere or prompt
    else
        echo -e "   ${YELLOW}Java version is not JDK 17 or 21.${RESET}"
    fi
else
    echo -e "   Java is ${RED}not installed${RESET}."
fi

if [ "$JDK_OK" = false ]; then
    if [ "$OS" = "macOS" ]; then
        if cmd_exists brew; then
            prompt_install "OpenJDK 17" "brew install openjdk@17 && sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
        else
            echo -e "   ${RED}Homebrew is not found. Please install JDK 17 from Adoptium or Oracle.${RESET}"
        fi
    elif [ "$OS" = "Linux" ]; then
        if cmd_exists apt-get; then
            prompt_install "OpenJDK 17" "sudo apt-get update && sudo apt-get install -y openjdk-17-jdk"
        else
            echo -e "   ${RED}apt-get not found. Please install JDK 17 manually.${RESET}"
        fi
    else
        echo -e "   ${RED}Please download and install JDK 17 manually.${RESET}"
    fi
fi

# ── 3. Check Android SDK ──────────────────────────────────────
echo -e "\n   ${BOLD}${BLUE}Checking Android SDK & Environment...${RESET}"
SDK_FOUND=false
SDK_PATH=""

# Check env variables first
if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ]; then
    SDK_PATH="$ANDROID_HOME"
    SDK_FOUND=true
elif [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
    SDK_PATH="$ANDROID_SDK_ROOT"
    SDK_FOUND=true
fi

# If not found in env, check common install locations
if [ "$SDK_FOUND" = false ]; then
    COMMON_PATHS=(
        "$HOME/Library/Android/Sdk"
        "$HOME/Android/Sdk"
        "/usr/lib/android-sdk"
        "/Library/Android/sdk"
    )
    for path in "${COMMON_PATHS[@]}"; do
        if [ -d "$path" ]; then
            SDK_PATH="$path"
            SDK_FOUND=true
            # Export temporarily
            export ANDROID_HOME="$path"
            break
        fi
    done
fi

if [ "$SDK_FOUND" = true ]; then
    echo -e "   Android SDK found at: ${GREEN}$SDK_PATH${RESET}"
    
    # Check if we need to write/update android/local.properties
    mkdir -p android
    echo "sdk.dir=$SDK_PATH" > android/local.properties
    echo -e "   Updated ${CYAN}android/local.properties${RESET} with SDK path."
else
    echo -e "   ${YELLOW}⚠ Android SDK was not detected in standard paths.${RESET}"
    echo -e "   Please ensure Android Studio is installed and SDK is configured."
    echo -e "   See https://reactnative.dev/docs/set-up-your-environment for guidance."
    read -p "   Do you want to proceed anyway? (y/n): " sdk_confirm
    if [[ ! "$sdk_confirm" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ── 4. Verify Config Files ───────────────────────────────────
echo -e "\n   ${BOLD}${BLUE}Verifying Config Files...${RESET}"
if [ ! -f "google-services.json" ]; then
    echo -e "   ${YELLOW}⚠ google-services.json is missing in the root directory.${RESET}"
    echo -e "     Please download it from your Firebase console to connect your own database."
fi

if [ ! -f ".env" ]; then
    echo -e "   ${YELLOW}⚠ .env file is missing in the root directory.${RESET}"
    echo -e "     Creating a template .env file..."
    echo "EXPO_PUBLIC_GEMINI_API_KEY=your_gemini_key_here" > .env
    echo -e "     Created template ${CYAN}.env${RESET}."
fi

# ── 5. Install JS Dependencies ──────────────────────────────
echo -e "\n   ${BOLD}${BLUE}Installing JS dependencies (npm install)...${RESET}"
npm install

# ── 6. Run Expo Prebuild ─────────────────────────────────────
echo -e "\n   ${BOLD}${BLUE}Generating native folders (npx expo prebuild)...${RESET}"
if [ -f "google-services.json" ]; then
    npx expo prebuild --clean
    echo -e "\n   ${GREEN}✔ Setup complete! Native android/ and ios/ folders successfully generated.${RESET}"
    echo -e "   You can now start the development server:"
    echo -e "     ${BOLD}npm start${RESET}"
    echo -e "   Or compile a local release APK:"
    echo -e "     ${BOLD}bash build.sh${RESET}"
else
    echo -e "\n   ${YELLOW}⚠ Prebuild skipped because google-services.json is missing.${RESET}"
    echo -e "     Please add google-services.json and run ${BOLD}npx expo prebuild --clean${RESET} manually."
fi

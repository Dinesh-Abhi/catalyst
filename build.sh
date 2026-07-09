#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  build.sh  —  Catalyst Production APK Builder (Dashboard Edition)
#
#  Usage:
#    bash build.sh
# ═══════════════════════════════════════════════════════════════

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
APK_OUT="$PROJECT_ROOT/android/app/build/outputs/apk/release/app-release.apk"

# ── Colours & styles ─────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Global State ─────────────────────────────────────────────
SCRIPT_START=$(date +%s)
TOTAL_STEPS=6
CURRENT_STEP=0
CURRENT_TASK_NAME="Initializing..."
LOGS=()

SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# ── Helpers: time formatting ───────────────────────────────
fmt_elapsed() {
  local secs=$1
  local m=$((secs / 60))
  local s=$((secs % 60))
  if [ "$m" -gt 0 ]; then
    printf "%dm %ds" "$m" "$s"
  else
    printf "%ds" "$s"
  fi
}

# ── Helpers: progress bar ────────────────────────────────────
progress_bar() {
  local step=$1
  local total=$2
  local width=40
  
  if [ "$total" -eq 0 ]; then total=1; fi
  if [ "$step" -gt "$total" ]; then step=$total; fi
  
  local filled=$(( step * width / total ))
  local empty=$(( width - filled ))
  local bar=""
  
  local k
  for ((k=0; k<filled; k++)); do bar+="█"; done
  for ((k=0; k<empty; k++)); do bar+="░"; done
  local pct=$(( step * 100 / total ))
  
  printf "${DIM}[${RESET}${MAGENTA}%s${RESET}${DIM}]${RESET} ${BOLD}%3d%%${RESET}" "$bar" "$pct"
}

# ── Dashboard Renderer ───────────────────────────────────────
render_dashboard() {
  local frame="$1"
  local elapsed="$2"
  local status_text="$3"
  local detail_text="$4"
  
  # Move cursor to top-left (0,0)
  printf "\033[H"
  
  echo -e "${BOLD}${CYAN}"
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  echo "  ║                                                              ║"
  echo "  ║      ⚡  C A T A L Y S T   B U I L D   S Y S T E M  ⚡       ║"
  echo "  ║                                                              ║"
  echo "  ╚══════════════════════════════════════════════════════════════╝\033[K"
  echo -e "${RESET}\033[K"
  
  echo -e "   ${BOLD}OVERALL PROGRESS${RESET}\033[K"
  echo -e "   $(progress_bar $CURRENT_STEP $TOTAL_STEPS)   (Step $CURRENT_STEP/$TOTAL_STEPS)\033[K"
  echo -e "\033[K"
  
  echo -e "   ${BOLD}CURRENT TASK${RESET}\033[K"
  echo -e "   ${CYAN}▶${RESET} $CURRENT_TASK_NAME\033[K"
  echo -e "\033[K"
  
  echo -e "   ${BOLD}STATUS${RESET}\033[K"
  if [ -n "$status_text" ]; then
    printf "   ${CYAN}%s${RESET}  %-20s  ${DIM}[%s]${RESET} %-40s\033[K\n" "$frame" "$status_text" "$elapsed" "${detail_text:0:40}"
  else
    echo -e "   ${GREEN}✔${RESET}  Idle\033[K"
  fi
  echo -e "\033[K"
  
  echo -e "   ${BOLD}LATEST LOGS${RESET}\033[K"
  echo -e "   ──────────────────────────────────────────────────────────────\033[K"
  # Print the last 8 logs
  for log in "${LOGS[@]}"; do
    echo -e "   $log\033[K"
  done
  
  # Clear anything below our dashboard to prevent ghost lines
  printf "\033[J"
}

add_log() {
  LOGS+=("$1")
  if [ ${#LOGS[@]} -gt 8 ]; then
    LOGS=("${LOGS[@]:1}")
  fi
}

ok()   { add_log "${GREEN}✔${RESET} $1"; render_dashboard "✔" "" "" ""; }
warn() { add_log "${YELLOW}⚠${RESET} $1"; render_dashboard "⚠" "" "" ""; }
info() { add_log "${BLUE}ℹ${RESET} $1"; render_dashboard "ℹ" "" "" ""; }

fail() {
  render_dashboard "✘" "" "FAILED" ""
  echo ""
  echo -e "${RED}${BOLD}  ╔══════════════════════════════════════╗${RESET}"
  echo -e "${RED}${BOLD}  ║          BUILD ABORTED  ✘             ║${RESET}"
  echo -e "${RED}${BOLD}  ╚══════════════════════════════════════╝${RESET}"
  echo -e "   ${RED}Error: $1${RESET}"
  tput cnorm 2>/dev/null || true
  exit 1
}

# ── Helpers: spinner ────────────────────────────────────────
run_with_spinner() {
  local label="$1"; shift
  CURRENT_TASK_NAME="$label"
  local logfile
  logfile="$(mktemp)"
  local start=$(date +%s)

  ("$@") >"$logfile" 2>&1 &
  local pid=$!

  local i=0
  tput civis 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    local frame="${SPINNER_FRAMES[$((i % ${#SPINNER_FRAMES[@]}))]}"
    local now=$(date +%s)
    local elapsed=$(fmt_elapsed $((now - start)))
    
    render_dashboard "$frame" "$elapsed" "Running..." ""
    
    i=$((i + 1))
    sleep 0.08
  done
  
  wait "$pid"
  local exit_code=$?
  local now=$(date +%s)
  local elapsed=$(fmt_elapsed $((now - start)))

  if [ $exit_code -eq 0 ]; then
    ok "$label [${elapsed}]"
  else
    add_log "${RED}✘${RESET} $label failed! [${elapsed}]"
    render_dashboard "✘" "$elapsed" "FAILED" ""
    echo ""
    echo -e "   ${RED}${BOLD}— Error Output —${RESET}"
    sed 's/^/   /' "$logfile" | tail -30
    rm -f "$logfile"
    tput cnorm 2>/dev/null || true
    exit 1
  fi

  LAST_LOG="$logfile"
  return 0
}

# ── SETUP & INIT ────────────────────────────────────────────
# Clear screen once at the beginning
tput smcup 2>/dev/null || clear
tput civis 2>/dev/null || true

cd "$PROJECT_ROOT"

# ── 1. Check tools ───────────────────────────────────────────
CURRENT_STEP=1
CURRENT_TASK_NAME="Checking Environment"
render_dashboard "⠋" "0s" "Validating..." ""

command -v node   >/dev/null 2>&1 || fail "node is not installed"
command -v npm    >/dev/null 2>&1 || fail "npm is not installed"
command -v java   >/dev/null 2>&1 || fail "java is not installed (need JDK 17+)"
command -v npx    >/dev/null 2>&1 || fail "npx is not installed"

DEFAULT_JAVA_VER=$(java -version 2>&1 | head -1)
if [ -z "$JAVA_HOME" ] || [[ "$DEFAULT_JAVA_VER" == *"25."* ]]; then
  for jdk_path in "/usr/lib/jvm/java-1.21.0-openjdk-amd64" "/usr/lib/jvm/java-21-openjdk-amd64" "/usr/lib/jvm/java-1.17.0-openjdk-amd64" "/usr/lib/jvm/java-17-openjdk-amd64"; do
    if [ -d "$jdk_path" ]; then
      export JAVA_HOME="$jdk_path"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
fi

if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
  for sdk_path in "/usr/lib/android-sdk" "$HOME/Android/Sdk" "$HOME/android-sdk"; do
    if [ -d "$sdk_path" ]; then
      export ANDROID_HOME="$sdk_path"
      export ANDROID_SDK_ROOT="$sdk_path"
      break
    fi
  done
fi

ok "Node  $(node --version)"
ok "NPM   $(npm --version)"
ok "Java  $(java -version 2>&1 | head -1 | awk -F '"' '{print $2}')"
[ -n "$ANDROID_HOME" ] && ok "Android SDK Found" || warn "ANDROID_HOME missing"

# ── 2. Validate .env ─────────────────────────────────────────
CURRENT_STEP=2
CURRENT_TASK_NAME="Checking API Keys"
render_dashboard "⠋" "0s" "Validating..." ""

if [ ! -f ".env" ]; then fail ".env file not found."; fi

if grep -q "EXPO_PUBLIC_GEMINI_API_KEY=" .env; then
  KEY_VAL=$(grep "EXPO_PUBLIC_GEMINI_API_KEY=" .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
  if [ -z "$KEY_VAL" ] || [ "$KEY_VAL" = "your_key_here" ]; then fail "EXPO_PUBLIC_GEMINI_API_KEY is empty"; fi
  ok "API Key Validated"
else
  fail "EXPO_PUBLIC_GEMINI_API_KEY missing"
fi

# ── 3. Install JS dependencies ────────────────────────────────
CURRENT_STEP=3
run_with_spinner "Installing NPM Dependencies" npm install --silent

# ── 4. Expo prebuild ─────────────────────────────────────────
CURRENT_STEP=4
run_with_spinner "Generating Native Android Source" npx expo prebuild --platform android --clean
if [ -f "$LAST_LOG" ]; then rm -f "$LAST_LOG"; fi

# ── 5. Clear asset cache ─────────────────────────────────────
CURRENT_STEP=5
CURRENT_TASK_NAME="Clearing Stale Cache"
render_dashboard "⠋" "0s" "Cleaning..." ""

STALE_RES="$PROJECT_ROOT/android/app/build/generated/res/createBundleReleaseJsAndAssets"
STALE_ASSETS="$PROJECT_ROOT/android/app/build/generated/assets/createBundleReleaseJsAndAssets"
[ -d "$STALE_RES" ] && rm -rf "$STALE_RES" && info "Cleared res cache"
[ -d "$STALE_ASSETS" ] && rm -rf "$STALE_ASSETS" && info "Cleared assets cache"
ok "Cache Clear Complete"

# ── 6. Gradle release build ───────────────────────────────────
CURRENT_STEP=6
CURRENT_TASK_NAME="Building Release APK (Gradle)"

cd "$PROJECT_ROOT/android"
GRADLE_LOG="$(mktemp)"

(
  ./gradlew assembleRelease --no-daemon --console=plain
) >"$GRADLE_LOG" 2>&1 &
GRADLE_PID=$!

i=0
GRADLE_START=$(date +%s)
LAST_TASK=""

while kill -0 "$GRADLE_PID" 2>/dev/null; do
  frame="${SPINNER_FRAMES[$((i % ${#SPINNER_FRAMES[@]}))]}"
  now=$(date +%s)
  elapsed=$(fmt_elapsed $((now - GRADLE_START)))
  
  CUR_TASK=$(grep -E "^> Task" "$GRADLE_LOG" 2>/dev/null | tail -1 | sed 's/> Task //')
  if [ -n "$CUR_TASK" ]; then LAST_TASK="$CUR_TASK"; fi
  
  render_dashboard "$frame" "$elapsed" "Gradle Building..." "${LAST_TASK}"
  
  i=$((i + 1))
  sleep 0.08
done

wait "$GRADLE_PID"
GRADLE_EXIT=$?
now=$(date +%s)
elapsed=$(fmt_elapsed $((now - GRADLE_START)))

if [ $GRADLE_EXIT -eq 0 ]; then
  ok "Gradle Build Success [${elapsed}]"
else
  add_log "${RED}✘${RESET} Gradle Build Failed [${elapsed}]"
  render_dashboard "✘" "$elapsed" "FAILED" ""
  echo ""
  echo -e "   ${RED}${BOLD}— Gradle Output (Errors) —${RESET}"
  grep -E "^(>|BUILD|FAILURE|Task|Deprecated|w:|e:)" "$GRADLE_LOG" | grep -v "^w: file://" | sed 's/^/   /' | head -40
  rm -f "$GRADLE_LOG"
  tput cnorm 2>/dev/null || true
  exit 1
fi
rm -f "$GRADLE_LOG"

# ── 7. Verify output ─────────────────────────────────────────
CURRENT_STEP=6
CURRENT_TASK_NAME="Finalizing"

TOTAL_NOW=$(date +%s)
TOTAL_ELAPSED=$(fmt_elapsed $((TOTAL_NOW - SCRIPT_START)))

if [ -f "$APK_OUT" ]; then
  SIZE=$(du -sh "$APK_OUT" | cut -f1)
  
  # Final render
  render_dashboard "✔" "$TOTAL_ELAPSED" "COMPLETED" "$SIZE"
  
  echo ""
  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════════════════╗"
  echo "  ║                                                              ║"
  echo "  ║                 BUILD SUCCESSFUL  ✅                         ║"
  echo "  ║                                                              ║"
  echo "  ╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "   ${BOLD}Output Path:${RESET} $APK_OUT"
  echo -e "   ${BOLD}File Size:${RESET}   ${MAGENTA}$SIZE${RESET}"
  echo -e "   ${BOLD}Total Time:${RESET}  ${MAGENTA}$TOTAL_ELAPSED${RESET}"
  echo ""
  echo -e "   ${CYAN}To install on a connected device:${RESET}"
  echo "   adb install -r \"$APK_OUT\""
  echo ""
else
  fail "APK file not found after build!"
fi

tput cnorm 2>/dev/null || true
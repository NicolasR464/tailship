#!/bin/bash
set -e

if [[ "$1" == "--version" ]]; then
  echo "tailship v0.1.0"
  exit 0
fi

RESET=$'\033[0m'
BOLD=$'\033[1m'
CYAN=$'\033[38;5;51m'
WHITE=$'\033[38;5;15m'
PURPLE=$'\033[38;5;141m'
ORANGE=$'\033[38;5;208m'
YELLOW=$'\033[38;5;226m'
RED=$'\033[38;5;196m'
GRAY=$'\033[38;5;245m'
GREEN=$'\033[38;5;46m'

print_intro() {
  clear

  WIDTH=42

  center_color() {
    local color="$1"
    local text="$2"
    local pad=$(( (WIDTH - ${#text}) / 2 ))
    printf "%*s%s%s%s\n" "$pad" "" "$color" "$text" "$RESET"
  }

  echo
  center_color "$CYAN$BOLD" "   /\   "
  center_color "$CYAN$BOLD" "  /  \  "
  center_color "$WHITE"     " /____\ "
  center_color "$CYAN"      " | TS | "
  center_color "$CYAN"      " |    | "
  center_color "$WHITE"     " /| || |\ "
  center_color "$YELLOW"    "  /||\  "
  center_color "$ORANGE"    " / || \ "
  center_color "$RED"       "   ||   "
  center_color "$GRAY"      "   ..   "

  center_color "$PURPLE$BOLD" "╔═══════════════════════════════╗"
  center_color "$WHITE$BOLD"  "      TAILSHIP      "
  center_color "$GRAY"        "   Remote deploy over tailnet     "
  center_color "$PURPLE$BOLD" "╚═══════════════════════════════╝"
  echo
  echo
}

fail() {
  echo -e "${RED}❌ $1${RESET}"
}

success() {
  echo -e "${GREEN}✅ $1${RESET}"
}

info() {
  echo -e "${CYAN}$1${RESET}"
}

print_intro

# GET CONFIG FILE VALUES #
CONFIG_FILE="./tailship.config"

if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "Missing config file: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

required_vars=(
  HEADSCALE_URL
  REMOTE_USER
  SSH_KEY
  REMOTE_FRONT_DIR
  REMOTE_BACK_DIR
  REMOTE_BASH
  LOCAL_ENV_DIR
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    fail "Missing required config value: $var"
    exit 1
  fi
done

# CHECK TAILNET CONNECTION #
info "Checking the tailnet connectivity..."

if ! command -v tailscale >/dev/null 2>&1; then
  fail "Tailscale is not installed."
  exit 1
fi
    
if ! curl -fsS "$HEADSCALE_URL/health" >/dev/null 2>&1; then
  fail "Headscale server is not reachable at $HEADSCALE_URL."
  echo -e "${GRAY}Check that the Headscale server is running and reachable from this machine.${RESET}"
  echo -e "${GRAY}Diagnostics you can run:${RESET}"
  echo -e "${CYAN}  1) Check Headscale API:${RESET} curl -v $HEADSCALE_URL/health"
  echo -e "${CYAN}  2) Check Tailscale client:${RESET} tailscale status"
  echo -e "${CYAN}  3) On the remote Headscale server:${RESET} docker ps | grep headscale"
  exit 1
fi

if ! tailscale status >/tmp/remote_launcher_tailscale_status 2>/tmp/remote_launcher_tailscale_error; then
  fail "Local Tailscale client is not available."
  echo -e "${RED}$(cat /tmp/remote_launcher_tailscale_error)${RESET}"
  echo -e "${GRAY}Start the local Tailscale daemon, then run this script again.${RESET}"
  exit 1
fi

success "Tailscale is running."
echo ""

echo "Fetching tailnet machines..."

nodes=()
names=()
i=1

while read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line" | grep -q "offline" && continue

  ip=$(echo "$line" | awk '{print $1}')
  name=$(echo "$line" | awk '{print $2}')

  [[ -z "$ip" || -z "$name" ]] && continue

  nodes+=("$ip")
  names+=("$name")

  echo "$i) $name ($ip)"
  ((i++))
done < /tmp/remote_launcher_tailscale_status

if [[ ${#nodes[@]} -eq 0 ]]; then
  fail "No online tailnet machines found."
  exit 1
fi

echo ""
read -p "Select target machine: " choice

index=$((choice - 1))
REMOTE_HOST="${nodes[$index]}"
REMOTE_NAME="${names[$index]}"

if [[ -z "$REMOTE_HOST" ]]; then
  fail "Invalid selection."
  exit 1
fi

success "Selected: $REMOTE_NAME ($REMOTE_HOST)"
echo ""
echo "$GREEN" "🚀 Ready to launch deployments!"

section "3. Environment files"

echo "1) Copy local env files when available"
echo "2) Keep remote env files"
read -p "Choice [2]: " env_choice
env_choice=${env_choice:-2}

if [[ "$env_choice" == "1" ]]; then
  info "Looking in: $LOCAL_ENV_DIR"

  FRONT_ENV="$LOCAL_ENV_DIR/.env.local"
  BACK_ENV="$LOCAL_ENV_DIR/.env"

  if [[ -f "$FRONT_ENV" ]]; then
    info "Copying frontend env: $FRONT_ENV"
    scp -i "$SSH_KEY" -o IdentitiesOnly=yes \
      "$FRONT_ENV" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_FRONT_DIR/.env.local"
  else
    warn "Frontend .env.local not found. Keeping remote frontend env."
  fi

  if [[ -f "$BACK_ENV" ]]; then
    info "Copying backend env: $BACK_ENV"
    scp -i "$SSH_KEY" -o IdentitiesOnly=yes \
      "$BACK_ENV" \
      "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BACK_DIR/.env"
  else
    warn "Backend .env not found. Keeping remote backend env."
  fi
else
  info "Keeping all remote environment files."
fi

section "4. Deployment scope"

echo "1) Frontend + backend"
echo "2) Frontend only"
echo "3) Backend only"
read -p "Choice [1]: " scope_choice
scope_choice=${scope_choice:-1}

DEPLOY_FRONT=false
DEPLOY_BACK=false

case "$scope_choice" in
  "1")
    DEPLOY_FRONT=true
    DEPLOY_BACK=true
    ;;
  "2")
    DEPLOY_FRONT=true
    ;;
  "3")
    DEPLOY_BACK=true
    ;;
  *)
    fail "Invalid deployment scope."
    exit 1
    ;;
esac

section "5. Branch selection"

select_branch() {
  local label="$1"
  local default_branch="$2"

  echo "Select $label branch:"
  echo "1) $default_branch (default)"
  echo "2) qualif"
  echo "3) other"

  read -p "Choice [1]: " branch_choice

  case "$branch_choice" in
    ""|"1") echo "$default_branch" ;;
    "2") echo "qualif" ;;
    "3")
      read -p "Enter branch name: " custom_branch
      echo "$custom_branch"
      ;;
    *)
      echo "$default_branch"
      ;;
  esac
}

FRONT_BRANCH=""
BACK_BRANCH=""

if [[ "$DEPLOY_FRONT" == true ]]; then
  echo
  FRONT_BRANCH=$(select_branch "frontend" "main")
else
  warn "Skipping frontend."
fi

if [[ "$DEPLOY_BACK" == true ]]; then
  echo
  BACK_BRANCH=$(select_branch "backend" "main")
else
  warn "Skipping backend."
fi

section "6. Deployment summary"

echo "Target machine : $REMOTE_NAME ($REMOTE_HOST)"
echo "Scope          : $(
  if [[ "$DEPLOY_FRONT" == true && "$DEPLOY_BACK" == true ]]; then
    echo "frontend + backend"
  elif [[ "$DEPLOY_FRONT" == true ]]; then
    echo "frontend only"
  else
    echo "backend only"
  fi
)"
echo "Frontend branch: $([[ "$DEPLOY_FRONT" == true ]] && echo "$FRONT_BRANCH" || echo "skipped")"
echo "Backend branch : $([[ "$DEPLOY_BACK" == true ]] && echo "$BACK_BRANCH" || echo "skipped")"
echo "Env strategy   : $([[ "$env_choice" == "1" ]] && echo "copy local when available" || echo "keep remote")"
echo

read -p "Continue deployment? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  warn "Deployment cancelled."
  exit 0
fi

section "7. Remote deployment"

ssh -i "$SSH_KEY" -o IdentitiesOnly=yes "$REMOTE_USER@$REMOTE_HOST" \
"DEPLOY_FRONT='$DEPLOY_FRONT' DEPLOY_BACK='$DEPLOY_BACK' FRONT_BRANCH='$FRONT_BRANCH' BACK_BRANCH='$BACK_BRANCH' REMOTE_FRONT_DIR='$REMOTE_FRONT_DIR' REMOTE_BACK_DIR='$REMOTE_BACK_DIR' REMOTE_KIOSK_BAT='$REMOTE_KIOSK_BAT' \"$REMOTE_BASH\" -lc '
set -e

safe_update_repo() {
  local repo_dir=\"\$1\"
  local branch=\"\$2\"
  local label=\"\$3\"

  echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"
  echo \"Updating \$label repository...\"
  echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"

  cd \"\$repo_dir\"

  PREV_COMMIT=\$(git rev-parse HEAD)
  STASHED=0

  if [[ -n \"\$(git status --porcelain)\" ]]; then
    echo \"Local changes detected. Stashing...\"
    git stash push -m \"auto-stash before remote launcher deploy \$(date +%s)\"
    STASHED=1
  fi

  git fetch --all
  git checkout \"\$branch\"
  git pull --ff-only

  if [[ \"\$STASHED\" -eq 1 ]]; then
    echo \"Re-applying stashed changes...\"
    if ! git stash pop; then
      echo \"Stash conflict detected. Rolling back to previous commit...\"
      git reset --hard \"\$PREV_COMMIT\"
      exit 1
    fi
  fi
}

if [[ \"\$DEPLOY_FRONT\" == \"true\" ]]; then
  safe_update_repo \"\$REMOTE_FRONT_DIR\" \"\$FRONT_BRANCH\" \"frontend\"

  echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"
  echo \"Building frontend...\"
  echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"

  cd \"\$REMOTE_FRONT_DIR\"
  pnpm install
  pnpm build
else
  echo \"Skipping frontend update and build.\"
fi

if [[ \"\$DEPLOY_BACK\" == \"true\" ]]; then
  safe_update_repo \"\$REMOTE_BACK_DIR\" \"\$BACK_BRANCH\" \"backend\"
else
  echo \"Skipping backend update.\"
fi

echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"
echo \"Restarting PM2...\"
echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"

pm2 restart all

sleep 3

if [[ -n "$REMOTE_KIOSK_BAT" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Launching kiosk Chrome..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cmd.exe /c "$REMOTE_KIOSK_BAT"
else
  echo "Skipping kiosk launch (not configured)."
fi

cmd.exe /c \"\$REMOTE_KIOSK_BAT\"

echo \"Deployment complete.\"
'"

section "8. Done"
success "Deployment completed successfully."

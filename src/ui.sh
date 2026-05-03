
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

# VISUAL INTRO #
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

# HELPER FUNCTIONS #
section() {
  echo
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${WHITE}${BOLD}$1${RESET}"
  echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
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
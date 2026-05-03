# GIT BRANCH SELECTION #
section "Branch selection"

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

section "Deployment summary"

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

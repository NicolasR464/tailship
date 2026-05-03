# ENVIRONMENT FILES SELECTION #
section "Environment files"

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

section "Deployment scope"

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
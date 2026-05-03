# REMOTE DEPLOYMENT #
section "Remote deployment"

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

section "Done"
success "Deployment completed successfully."

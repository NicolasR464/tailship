VERSION_FILE="$SCRIPT_DIR/version"

get_version() {
  if [[ -f "$VERSION_FILE" ]]; then
    cat "$VERSION_FILE"
  else
    echo "0.0.0-dev"
  fi
}

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  echo "tailship v$(get_version)"
  exit 0
fi
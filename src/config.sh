CONFIG_DIR="$SCRIPT_DIR/CONFIGS"

is_example_config() {
  local file_name
  file_name="$(basename "$1")"

  [[ "$file_name" == "example.config" || "$file_name" == *.example.config ]]
}

select_config_file() {
  local configs=()
  local names=()
  local i=1

  if [[ ! -d "$CONFIG_DIR" ]]; then
    fail "Config directory not found: $CONFIG_DIR"
    exit 1
  fi

  while IFS= read -r file; do
    if is_example_config "$file"; then
      continue
    fi

    configs+=("$file")
    names+=("$(basename "$file" .config)")
  done < <(find "$CONFIG_DIR" -maxdepth 1 -type f -name "*.config" | sort)

  if [[ ${#configs[@]} -eq 0 ]]; then
    fail "No usable config files found in $CONFIG_DIR"
    echo -e "${GRAY}Example configs like example.config are ignored.${RESET}"
    exit 1
  fi

  section "Select your config"

  for name in "${names[@]}"; do
    echo "$i) $name"
    ((i++))
  done

  echo
  read -p "Select config: " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    fail "Invalid selection. Pick a number."
    exit 1
  fi

  local index=$((choice - 1))
  CONFIG_FILE="${configs[$index]}"

  if [[ -z "$CONFIG_FILE" ]]; then
    fail "Invalid selection. Pick a number in the select range."
    exit 1
  fi

  success "Using config: $(basename "$CONFIG_FILE" .config)"
}

if [[ -n "$1" ]]; then
  if [[ "$1" == *.config ]]; then
    CONFIG_FILE="$CONFIG_DIR/$1"
  else
    CONFIG_FILE="$CONFIG_DIR/$1.config"
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    fail "Config not found: $CONFIG_FILE"
    exit 1
  fi

  if is_example_config "$CONFIG_FILE"; then
    fail "$(basename "$CONFIG_FILE") is an example config and cannot be used."
    exit 1
  fi

  success "Using config: $(basename "$CONFIG_FILE" .config)"
else
  select_config_file
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

# GET TAILSCALE CLIENT STATUS #
info "Checking Tailscale client status..."
if ! tailscale status 2>/dev/null | grep -qE '^100\.'; then
  fail "Not connected to tailnet."
  exit 1
fi

success "Connected to tailnet."

nodes=()
names=()
i=1

# GET TAILNET MACHINES #
info "Fetching tailnet machines..."

nodes=()
names=()
i=1

if ! TS_STATUS="$(tailscale status 2>&1)"; then
  fail "Local Tailscale client is not available."
  echo -e "${RED}$TS_STATUS${RESET}"
  exit 1
fi

if echo "$TS_STATUS" | grep -qi "logged out"; then
  fail "Local Tailscale client is logged out."
  echo -e "${GRAY}Connect to your Headscale tailnet, then run Tailship again.${RESET}"
  exit 1
fi

LOCAL_TS_IP="$(tailscale ip -4 2>/dev/null | head -n 1)"

while read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line" | grep -qi "offline" && continue

  ip=$(echo "$line" | awk '{print $1}')
  name=$(echo "$line" | awk '{print $2}')

  [[ "$ip" =~ ^100\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
  [[ "$ip" == "$LOCAL_TS_IP" ]] && continue

  nodes+=("$ip")
  names+=("$name")

  echo "$i) $name ($ip)"
  ((i++))
done <<< "$TS_STATUS"

if [[ ${#nodes[@]} -eq 0 ]]; then
  fail "No online remote tailnet machines found."
  echo -e "${GRAY}Make sure at least one other machine is online in your tailnet.${RESET}"
  exit 1
fi

echo ""

# MACHINE SELECTION #
section "Select target machine"

read -p "Machines in tailnet: " choice

index=$((choice - 1))
REMOTE_HOST="${nodes[$index]}"
REMOTE_NAME="${names[$index]}"

if [[ -z "$REMOTE_HOST" ]]; then
  fail "Invalid selection."
  exit 1
fi

success "Selected: $REMOTE_NAME ($REMOTE_HOST)"
echo ""
echo -e "${GREEN}🚀 Ready to launch deployments!${RESET}"
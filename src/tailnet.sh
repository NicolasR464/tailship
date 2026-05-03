# GET TAILNET MACHINES #
echo "Fetching tailnet machines..."

if grep -qi "logged out" /tmp/remote_launcher_tailscale_status; then
  fail "Local Tailscale client is logged out."
  echo -e "${GRAY}Connect to your Headscale tailnet, then run Tailship again.${RESET}"
  exit 1
fi

nodes=()
names=()
i=1

while read -r line; do
  [[ -z "$line" ]] && continue
  echo "$line" | grep -q "offline" && continue

  ip=$(echo "$line" | awk '{print $1}')
  name=$(echo "$line" | awk '{print $2}')

  # Only accept real tailnet IP lines
  if ! [[ "$ip" =~ ^100\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    continue
  fi

  [[ -z "$name" ]] && continue

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
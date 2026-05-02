
# 🚀 TAILSHIP

Tailship is a lightweight CLI tool to deploy applications to remote machines over a Headscale/Tailscale network.

It lets you:

* select a target node
* choose what to deploy (frontend / backend)
* inject environment files
* update code (git)
* build and restart services

---

## ✨ Features

* 🌐 Works over Headscale / Tailscale
* 🎯 Interactive CLI (machine + branch selection)
* 📦 Optional env file injection
* 🔄 Safe git workflow (stash + fast-forward pull)
* 🧠 Partial deploy (frontend / backend / both)
* ⚡ No dependencies (pure Bash)

---

## 📁 Project structure

.
├── tailship.sh
├── tailship.config
└── ENVIRONMENTS_VARIABLES/
    ├── .env         # backend
    └── .env.local   # frontend

---

## ⚙️ Configuration

Edit tailship.config:

HEADSCALE_URL="http://192....:8080"
REMOTE_USER="user"
SSH_KEY="$HOME/.ssh/your_ssh_key"
REMOTE_FRONT_DIR="/c/Users/.../front"
REMOTE_BACK_DIR="/c/Users/.../back"
REMOTE_BASH="/c/Program Files/Git/bin/bash.exe"
REMOTE_KIOSK_BAT=""
LOCAL_ENV_DIR="./ENVIRONMENTS_VARIABLES"

---

## 🚀 Usage

```sh
chmod +x tailship.sh
./tailship.sh
```
---

## 🧭 Workflow

1. Check Headscale connectivity
2. Select target machine
3. Choose env strategy:
    * inject local env files
    * keep remote env
4. Choose deploy scope:
    * frontend / backend / both
5. Select branches
6. Confirm
7. Deploy

---

## 🔐 Requirements

* Tailscale client running locally
* Access to Headscale server
* SSH access to remote machines
* Git + Node + PM2 installed remotely

---

## 🧪 Troubleshooting

Headscale unreachable
```bash
curl -v http://<HEADSCALE_URL>/health
```
Tailscale not running
```bash
tailscale status
```
Remote issues
```bash
docker ps
```

---

## 📌 Roadmap (optional)

* rollback support
* deploy logs
* multi-config profiles
* better branch discovery
* multi-machine deploy
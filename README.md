# 🚀 TAILSHIP

Tailship is a lightweight CLI tool to deploy applications to remote machines over a Headscale/Tailscale network.

It lets you:

- select a target node
- choose what to deploy (frontend / backend)
- inject environment files
- update code (git)
- build and restart services

***

## ✨ Features

- 🌐 Works over Headscale / Tailscale
- 🎯 Interactive CLI (machine + branch selection)
- 📦 Optional env file injection
- 🔄 Safe git workflow (stash + fast-forward pull)
- 🧠 Partial deploy (frontend / backend / both)
- ⚡ No dependencies (pure Bash)

***

## 📁 Project structure

```
.
├── tailship                  # entrypoint
├── CONFIGS/
│   └── example.config
│   └── frigo.config
├── ENVIRONMENTS_VARIABLES/
│   ├── .env
│   └── .env.local
└── src/
    ├── ui.sh                 # colors, intro, section, fail/success helpers
    ├── config.sh             # config selection + validation
    ├── tailnet.sh            # tailscale/headscale checks + node selection
    ├── env.sh                # env file copy logic
    ├── branches.sh           # branch/scope selection
    └── deploy.sh             # ssh remote deploy logic
```

***

## ⚙️ Configuration

Edit `your_file.config` (in ./CONFIGS):

```
HEADSCALE_URL="<http://192....:8080>"
REMOTE_USER="user"
SSH_KEY="$HOME/.ssh/your\_ssh\_key"
REMOTE_FRONT_DIR="/c/Users/.../front"
REMOTE_BACK_DIR="/c/Users/.../back"
REMOTE_BASH="/c/Program Files/Git/bin/bash.exe"
REMOTE_KIOSK_BAT=""
LOCAL_ENV_DIR="./ENVIRONMENTS_VARIABLES"
```

***

## 🚀 Usage

- Add execution rights:
```sh
chmod +x ./tailship
```
- Run script: 
```sh
./tailship
```

***

## 🧭 Workflow

1. Check Headscale connectivity
2. Select target machine
3. Choose env strategy:
   - inject local env files
   - keep remote env
4. Choose deploy scope:
   - frontend / backend / both
5. Select branches
6. Confirm
7. Deploy

***

## 🔐 Requirements

- Tailscale client running locally
- Access to Headscale server
- SSH access to remote machines
- Git + Node + PM2 installed remotely

***

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

***

## 📌 Roadmap (optional)

- rollback support
- deploy logs
- multi-config profiles
- better branch discovery
- multi-machine deploy


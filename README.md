# Letta Mobile

Self-hosted Letta + Ollama on Android (Samsung S20 Ultra) with memfs sync.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│              Master memfs Repo (GitHub/GitLab)               │
│           "Source of Sanity" for all agents                  │
└────────────────────────┬─────────────────────────────────────┘
                         │ git sync
       ┌─────────────────┼─────────────────┐
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   S20 Ultra  │  │   Desktop    │  │ Letta Cloud  │
│   (Phone)    │  │   (Home)     │  │   (Backup)   │
│              │  │              │  │              │
│ Termux:      │  │ Docker/pip:  │  │ 3 agents max │
│ ├── ollama   │  │ ├── Letta    │  │              │
│ ├── letta    │  │ ├── Ollama   │  │              │
│ └── lettabot │  │ └── LettaBot │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Setup (Termux on Android)

### Prerequisites

1. Install Termux from **F-Droid** (not Google Play - F-Droid version works better)
2. Install Termux:API from F-Droid (optional, for system integration)

### Installation

```bash
# Clone the repo
git clone https://github.com/seriouslovewiz/letta-mobile.git
cd letta-mobile

# Set your memory remote (optional but recommended)
export MEMFS_REMOTE=https://github.com/YOUR_USERNAME/letta-memory.git

# Run setup
chmod +x setup-termux.sh
./setup-termux.sh
```

### Running

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Start Letta server
source ~/.letta/.env && letta server

# Terminal 3: Prevent Android from killing processes
termux-wake-lock
```

## Memory Sync

### Setup Remote

```bash
cd ~/letta-memfs-shared
git remote add origin https://github.com/YOUR_USERNAME/letta-memory.git
git push -u origin main
```

### Sync Commands

```bash
# Pull latest from remote (before starting work)
~/letta-memfs-shared/sync.sh <agent-id> pull

# Push to remote (after finishing work)
~/letta-memfs-shared/sync.sh <agent-id> push

# Pull then push (full sync)
~/letta-memfs-shared/sync.sh <agent-id> both
```

### Memory Block Format

Every `.md` file needs valid frontmatter:

```markdown
---
description: What this block contains
limit: 20000
---

Content here.
```

## Models

Recommended for S20 Ultra (12-16GB RAM):

| Model | RAM | Speed | Quality |
|-------|-----|-------|---------|
| llama3.2:1b | 2GB | ⚡⚡⚡ | Good |
| llama3.2:3b | 4GB | ⚡⚡ | Better |
| phi3:mini | 5GB | ⚡⚡ | Excellent |
| gemma2:2b | 3GB | ⚡⚡⚡ | Good |

## Frontend

Using Telegram via LettaBot (simplest option). Your phone agent communicates through LettaBot's Telegram channel, same as your desktop agents.

## Files

- `setup-termux.sh` - Main setup script for Android
- `~/letta-memfs-shared/sync.sh` - Memory sync script (generated)
- `~/letta-memfs-shared/templates/memory-block.md` - Memory block template

## Troubleshooting

**Android killing processes:**
```bash
termux-wake-lock
```

**Git authentication issues:**
```bash
git config --global credential.helper store
# Then push once and enter credentials
```

**Ollama not starting:**
```bash
pkill ollama
ollama serve &
```

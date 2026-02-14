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
│ └── git      │  │ └── LettaBot │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Setup (Termux on Android)

1. Install Termux from F-Droid (not Google Play)
2. Copy `setup-termux.sh` to your phone
3. Run it:

```bash
chmod +x setup-termux.sh
./setup-termux.sh
```

## Running

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Start Letta server
source ~/.letta/.env && letta server

# Terminal 3: Prevent Android from killing processes
termux-wake-lock
```

## Memory Sync

```bash
# Sync agent memory with master repo
~/letta-memfs-shared/sync.sh <agent-id>
```

## Models

Recommended for S20 Ultra (12-16GB RAM):

| Model | RAM | Speed | Quality |
|-------|-----|-------|---------|
| llama3.2:1b | 2GB | ⚡⚡⚡ | Good |
| llama3.2:3b | 4GB | ⚡⚡ | Better |
| phi3:mini | 5GB | ⚡⚡ | Excellent |
| gemma2:2b | 3GB | ⚡⚡⚡ | Good |

## Frontend Options

1. **Telegram** - Use LettaBot's Telegram channel
2. **Open WebUI** - Run alongside Letta server
3. **Custom web frontend** - Build something lightweight

## Files

- `setup-termux.sh` - Main setup script for Android
- `sync.sh` - Memory sync script (generated in ~/letta-memfs-shared/)

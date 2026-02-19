#!/usr/bin/env bash
# ========================================
# Termux Setup Script for Samsung S20 Ultra
# Letta + Ollama + memfs sync
# ========================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MEMFS_REMOTE="${MEMFS_REMOTE:-}"  # Set this to your shared memory repo URL
GIT_USER_EMAIL="${GIT_USER_EMAIL:-seri@users.noreply.github.com}"
GIT_USER_NAME="${GIT_USER_NAME:-seri}"

echo -e "${CYAN}=== Letta Mobile Setup ===${NC}"
echo ""

# 1. Update packages
echo -e "${GREEN}[1/7] Updating packages...${NC}"
pkg update -y && pkg upgrade -y

# 2. Install dependencies
echo -e "${GREEN}[2/7] Installing dependencies...${NC}"
pkg install -y git python nodejs ollama

# 3. Setup Ollama
echo -e "${GREEN}[3/7] Starting Ollama server...${NC}"
ollama serve &
sleep 3

echo -e "${YELLOW}Pulling model (llama3.2:3b)...${NC}"
ollama pull llama3.2:3b
ollama pull nomic-embed-text

#3.5 pre-install local utils 
pkg install -y cmake patchelf binutils make

# 4. Install Letta
echo -e "${GREEN}[4/7] Installing Letta server...${NC}"
pip install letta

# 5. Configure environment
echo -e "${GREEN}[5/7] Creating configuration...${NC}"
mkdir -p ~/.letta

cat > ~/.letta/.env << 'EOF'
# Ollama (local LLM)
OLLAMA_BASE_URL=http://localhost:11434/v1

# Letta server
LETTA_BASE_URL=http://localhost:8283

# Models
LETTA_LLM_MODEL=llama3.2:3b
LETTA_EMBEDDING_MODEL=nomic-embed-text
EOF

# 6. Configure git
echo -e "${GREEN}[6/7] Configuring git...${NC}"
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

# 7. Setup memfs sync
echo -e "${GREEN}[7/7] Setting up memfs sync...${NC}"
mkdir -p ~/letta-memfs-shared
cd ~/letta-memfs-shared

# Initialize git repo if not already
if [ ! -d .git ]; then
    git init
    git branch -m main
fi

# Add remote if provided
if [ -n "$MEMFS_REMOTE" ]; then
    git remote add origin "$MEMFS_REMOTE" 2>/dev/null || \
    git remote set-url origin "$MEMFS_REMOTE"
    echo -e "${GREEN}Remote configured: $MEMFS_REMOTE${NC}"
else
    echo -e "${YELLOW}No MEMFS_REMOTE set. Set it later with:${NC}"
    echo -e "  ${CYAN}git remote add origin <your-repo-url>${NC}"
fi

# Create pre-commit hook for frontmatter validation
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Validate frontmatter in .md files

for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.md$'); do
    if [ -f "$file" ]; then
        # Check for frontmatter
        if ! head -1 "$file" | grep -q '^---$'; then
            echo "ERROR: $file missing frontmatter (must start with ---)"
            exit 1
        fi
        
        # Check for required fields
        if ! grep -q '^description:' "$file"; then
            echo "ERROR: $file missing 'description' in frontmatter"
            exit 1
        fi
        
        if ! grep -q '^limit:' "$file"; then
            echo "ERROR: $file missing 'limit' in frontmatter"
            exit 1
        fi
    fi
done
exit 0
HOOK
chmod +x .git/hooks/pre-commit

# Create sync script
cat > ~/letta-memfs-shared/sync.sh << 'EOF'
#!/usr/bin/env bash
# Sync agent memory with master repo
# Usage: ./sync.sh <agent-id> [pull|push|both]

set -e

AGENT_ID="${1:-}"
MODE="${2:-both}"
MEMFS_DIR="$HOME/.letta/agents/$AGENT_ID/memory"
SHARED_DIR="$HOME/letta-memfs-shared"
AGENT_SHARED="$SHARED_DIR/agents/$AGENT_ID"

if [ -z "$AGENT_ID" ]; then
    echo "Usage: ./sync.sh <agent-id> [pull|push|both]"
    echo ""
    echo "Modes:"
    echo "  pull  - Pull from remote, copy to agent memory"
    echo "  push  - Copy from agent memory, push to remote"
    echo "  both  - Pull first, then push (default)"
    exit 1
fi

if [ ! -d "$MEMFS_DIR" ]; then
    echo "Agent memory not found: $MEMFS_DIR"
    echo "Create an agent first with: letta create-agent"
    exit 1
fi

cd "$SHARED_DIR"

# Pull mode
if [ "$MODE" = "pull" ] || [ "$MODE" = "both" ]; then
    echo ">>> Pulling from remote..."
    git pull --rebase || echo "Pull failed or no remote configured"
    
    # Copy shared -> agent
    if [ -d "$AGENT_SHARED" ]; then
        echo ">>> Copying to agent memory..."
        mkdir -p "$MEMFS_DIR"
        cp -r "$AGENT_SHARED"/* "$MEMFS_DIR/" 2>/dev/null || true
    fi
fi

# Push mode
if [ "$MODE" = "push" ] || [ "$MODE" = "both" ]; then
    echo ">>> Copying from agent memory..."
    mkdir -p "$AGENT_SHARED"
    cp -r "$MEMFS_DIR"/* "$AGENT_SHARED/" 2>/dev/null || true
    
    echo ">>> Committing and pushing..."
    git add .
    git commit -m "sync from phone ($AGENT_ID) - $(date -Iseconds)" || echo "No changes to commit"
    git push || echo "Push failed or no remote configured"
fi

echo ">>> Done!"
EOF
chmod +x ~/letta-memfs-shared/sync.sh

# Create template memory block
mkdir -p ~/letta-memfs-shared/templates
cat > ~/letta-memfs-shared/templates/memory-block.md << 'EOF'
---
description: Description of this memory block
limit: 20000
---

# Memory Block Title

Content goes here.
EOF

# Print summary
echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo -e "Services:"
echo -e "  ${CYAN}Ollama:${NC}     http://localhost:11434"
echo -e "  ${CYAN}Letta API:${NC}  http://localhost:8283/v1"
echo ""
echo -e "To start Letta server:"
echo -e "  ${YELLOW}source ~/.letta/.env && letta server${NC}"
echo ""
echo -e "To prevent Android from killing processes:"
echo -e "  ${YELLOW}termux-wake-lock${NC}"
echo ""
echo -e "To set up remote memory repo:"
echo -e "  ${YELLOW}cd ~/letta-memfs-shared && git remote add origin <repo-url>${NC}"
echo ""
echo -e "To sync memory:"
echo -e "  ${YELLOW}~/letta-memfs-shared/sync.sh <agent-id> pull${NC}   # Get latest from remote"
echo -e "  ${YELLOW}~/letta-memfs-shared/sync.sh <agent-id> push${NC}   # Send to remote"
echo -e "  ${YELLOW}~/letta-memfs-shared/sync.sh <agent-id> both${NC}   # Pull then push"
echo ""
echo -e "Memory block template: ${CYAN}~/letta-memfs-shared/templates/memory-block.md${NC}"
echo ""

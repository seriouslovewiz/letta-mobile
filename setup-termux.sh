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

echo -e "${CYAN}=== Letta Mobile Setup ===${NC}"
echo ""

# 1. Update packages
echo -e "${GREEN}[1/6] Updating packages...${NC}"
pkg update -y && pkg upgrade -y

# 2. Install dependencies
echo -e "${GREEN}[2/6] Installing dependencies...${NC}"
pkg install -y git python nodejs ollama

# 3. Setup Ollama
echo -e "${GREEN}[3/6] Starting Ollama server...${NC}"
ollama serve &
sleep 3

echo -e "${YELLOW}Pulling model (llama3.2:3b)...${NC}"
ollama pull llama3.2:3b
ollama pull nomic-embed-text

# 4. Install Letta
echo -e "${GREEN}[4/6] Installing Letta server...${NC}"
pip install letta

# 5. Configure environment
echo -e "${GREEN}[5/6] Creating configuration...${NC}"
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

# 6. Setup memfs sync directory
echo -e "${GREEN}[6/6] Setting up memfs sync...${NC}"
mkdir -p ~/letta-memfs-shared

cat > ~/letta-memfs-shared/sync.sh << 'EOF'
#!/usr/bin/env bash
# Sync agent memory with master repo

AGENT_ID="${1:-}"
MEMFS_DIR="$HOME/.letta/agents/$AGENT_ID/memory"
SHARED_DIR="$HOME/letta-memfs-shared"

if [ -z "$AGENT_ID" ]; then
    echo "Usage: ./sync.sh <agent-id>"
    exit 1
fi

if [ ! -d "$MEMFS_DIR" ]; then
    echo "Agent memory not found: $MEMFS_DIR"
    exit 1
fi

# Pull latest from remote
cd "$SHARED_DIR"
git pull --rebase

# Copy agent memory to shared (with agent prefix)
mkdir -p "$SHARED_DIR/agents/$AGENT_ID"
cp -r "$MEMFS_DIR"/* "$SHARED_DIR/agents/$AGENT_ID/" 2>/dev/null || true

# Commit and push
git add .
git commit -m "sync from phone ($AGENT_ID) - $(date -Iseconds)" || echo "No changes"
git push
EOF
chmod +x ~/letta-memfs-shared/sync.sh

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
echo -e "To sync memory with master repo:"
echo -e "  ${YELLOW}~/letta-memfs-shared/sync.sh <agent-id>${NC}"
echo ""

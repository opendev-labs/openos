#!/bin/bash
# Fast AI Terminal Install - Using Ollama (easier than llama.cpp)

set -e

echo "🚀 Quick AI Terminal Install with Ollama..."

# 1. Install Ollama (one-line install)
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✓ Ollama already installed"
fi

# 2. Pull NanoPi model
echo "Downloading NanoPi 1.5B model..."
ollama pull qwen2.5:1.5b

# 3. Create NanoPi model
echo "Creating opendev-labs/nanopi model..."
cat > /tmp/nanopi-modelfile << 'MODELFILE'
FROM qwen2.5:1.5b
SYSTEM You are NanoPi, a helpful AI assistant integrated into MoltOS. You provide concise, accurate answers to help users with their Linux and development tasks.
MODELFILE

ollama create opendev-labs/nanopi -f /tmp/nanopi-modelfile

# 4. Start Ollama service
sudo systemctl enable ollama
sudo systemctl start ollama

# 5. Create nanopi command
sudo tee /usr/local/bin/nanopi > /dev/null <<'EOF'
#!/bin/bash
# MoltOS NanoPi - Photonic Intelligence
if [ -z "$*" ]; then
    echo "Usage: nanopi '<your question>'"
    exit 1
fi

ollama run opendev-labs/nanopi "$*"
EOF

sudo chmod +x /usr/local/bin/nanopi

echo ""
echo "✅ Done! Try it:"
echo "   nanopi 'how do I check disk space?'"

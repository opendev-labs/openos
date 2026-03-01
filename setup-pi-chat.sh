#!/bin/bash
# Setup script for pi-chat - Configure your API key

API_KEY="$1"
CONFIG_DIR="$HOME/.config/pi-chat"
API_KEY_FILE="$CONFIG_DIR/api_key"

if [ -z "$API_KEY" ]; then
    echo "Usage: setup-pi-chat <your-api-key>"
    echo ""
    echo "Example:"
    echo "  setup-pi-chat sk-K8_he...lvvt"
    echo ""
    echo "Get your API key from OpenWebUI:"
    echo "  Settings → Account → API Keys"
    exit 1
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Save API key
echo "$API_KEY" > "$API_KEY_FILE"
chmod 600 "$API_KEY_FILE"

echo "✅ API key configured successfully!"
echo ""
echo "Now you can use:"
echo "  pi-chat              - Start interactive chat"
echo "  pi-chat \"message\"    - Send a single message"
echo ""
echo "Try it: pi-chat \"how are you?\""

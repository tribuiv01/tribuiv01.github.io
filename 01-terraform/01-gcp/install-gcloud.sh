#!/bin/bash
# Script to install Google Cloud SDK (gcloud)

# Default version - leave empty for latest version
GCLOUD_VERSION=${1:-""}

echo "Installing Google Cloud SDK..."

# Create temporary directory for installation
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || { echo "Failed to create temporary directory"; exit 1; }

# Determine system architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Determine OS
OS="linux"
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="darwin"
    echo "This script is optimized for Linux. For macOS, consider using the official installer."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        exit 0
    fi
fi

# Download the appropriate package
if [[ -n "$GCLOUD_VERSION" ]]; then
    echo "Downloading Google Cloud SDK version $GCLOUD_VERSION for $OS-$ARCH..."
    DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-${OS}-${ARCH}.tar.gz"
else
    echo "Downloading latest Google Cloud SDK for $OS-$ARCH..."
    DOWNLOAD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${OS}-${ARCH}.tar.gz"
fi

echo "Download URL: $DOWNLOAD_URL"

# Download the package
curl -L -o gcloud.tar.gz "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Failed to download Google Cloud SDK. Please check the version and try again."
    exit 1
fi

# Extract the archive
echo "Extracting the archive..."
tar -xzf gcloud.tar.gz
if [ $? -ne 0 ]; then
    echo "Failed to extract the archive."
    exit 1
fi

# Verify extraction
if [ ! -d "google-cloud-sdk" ]; then
    echo "Failed to find the google-cloud-sdk directory after extraction."
    echo "Contents of current directory:"
    ls -la
    exit 1
fi

# Install the SDK
echo "Running the installer..."
./google-cloud-sdk/install.sh --quiet --usage-reporting=false --command-completion=true --path-update=true

# Verify installation
if [ ! -f "./google-cloud-sdk/bin/gcloud" ]; then
    echo "Installation seems to have failed. gcloud binary not found."
    exit 1
fi

# Initialize gcloud (optional)
echo "Do you want to initialize gcloud now? (y/n)"
read -r init_response
if [[ "$init_response" == "y" ]]; then
    # Use absolute path to ensure we find the binary
    GCLOUD_PATH="$TMP_DIR/google-cloud-sdk/bin/gcloud"
    echo "Running: $GCLOUD_PATH init"
    "$GCLOUD_PATH" init
fi

# Move to home directory
echo "Moving Google Cloud SDK to your home directory..."
if [ -d "$HOME/google-cloud-sdk" ]; then
    echo "Existing installation found in $HOME/google-cloud-sdk. Backing up..."
    mv "$HOME/google-cloud-sdk" "$HOME/google-cloud-sdk.backup-$(date +%Y%m%d%H%M%S)"
fi

mv "$TMP_DIR/google-cloud-sdk" "$HOME/"

# Clean up
cd - > /dev/null || true
rm -rf "$TMP_DIR"

# Add to PATH if not already done
if ! grep -q "google-cloud-sdk/bin" "$HOME/.bashrc"; then
    echo "Adding gcloud to your PATH..."
    echo "export PATH=\$PATH:\$HOME/google-cloud-sdk/bin" >> "$HOME/.bashrc"
    echo "Please restart your shell or run 'source ~/.bashrc' to use gcloud."
fi

echo "Google Cloud SDK installation completed!"
echo "Verify installation with: $HOME/google-cloud-sdk/bin/gcloud version"
echo "After sourcing your .bashrc, you can simply use: gcloud version"

# Show components that can be installed
echo "You can install additional components using: gcloud components install COMPONENT"
echo "Available components: app-engine-python, kubectl, docker-credential-gcr, etc."

export PATH=$PATH:/home/codespace/google-cloud-sdk/bin

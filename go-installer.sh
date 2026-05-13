#!/bin/sh
# Go Installer Script
# Securely downloads and installs Go on Linux
# Usage: ./install-go.sh [version]

set -e

VERSION="$1"

echo ">> Checking dependencies..."

for cmd in curl tar sha256sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: $cmd is required but not installed."
        exit 1
    fi
done

if [ -z "$VERSION" ]; then
    echo ">> Fetching latest Go version..."
    VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1 | sed 's/go//')
fi

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        GOARCH="amd64"
        ;;
    aarch64|arm64)
        GOARCH="arm64"
        ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

GO_TARBALL="go${VERSION}.linux-${GOARCH}.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${GO_TARBALL}"
CHECKSUM_URL="https://go.dev/dl/${GO_TARBALL}.sha256"

echo ">> Downloading Go ${VERSION}..."
curl -LO "$DOWNLOAD_URL"

echo ">> Downloading checksum..."
EXPECTED_CHECKSUM=$(curl -s "$CHECKSUM_URL")

echo ">> Verifying checksum..."
ACTUAL_CHECKSUM=$(sha256sum "$GO_TARBALL" | awk '{print $1}')

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo "ERROR: Checksum verification failed!"
    rm -f "$GO_TARBALL"
    exit 1
fi

echo ">> Removing old Go installation..."
sudo rm -rf /usr/local/go

echo ">> Extracting Go ${VERSION}..."
sudo tar -C /usr/local -xzf "$GO_TARBALL"

echo ">> Cleaning up..."
rm -f "$GO_TARBALL"

add_path() {
    FILE="$1"

    if [ -f "$FILE" ] && ! grep -q '/usr/local/go/bin' "$FILE"; then
        echo ">> Adding Go PATH to $FILE"
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$FILE"
    fi
}

add_path "$HOME/.profile"
add_path "$HOME/.bashrc"
add_path "$HOME/.zshrc"

export PATH=$PATH:/usr/local/go/bin

echo ">> Verifying installation..."
go version

echo ">> Installation complete."
echo ">> Restart your terminal or run:"
echo "source ~/.profile"

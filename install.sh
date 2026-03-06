#!/bin/bash
set -euo pipefail

VERSION="${KXN_VERSION:-latest}"

# Use GITHUB_TOKEN if available (avoids API rate limits)
AUTH_HEADER=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)  TARGET_OS="unknown-linux-gnu" ;;
  darwin) TARGET_OS="apple-darwin" ;;
  *)      echo "::error::Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) TARGET_ARCH="x86_64" ;;
  aarch64|arm64) TARGET_ARCH="aarch64" ;;
  *)             echo "::error::Unsupported arch: $ARCH"; exit 1 ;;
esac

TARGET="${TARGET_ARCH}-${TARGET_OS}"

# Resolve latest version from homebrew-tap releases (public)
if [ "$VERSION" = "latest" ]; then
  RELEASE_JSON=$(curl -sSL ${AUTH_HEADER:+-H "$AUTH_HEADER"} "https://api.github.com/repos/kexa-io/homebrew-tap/releases/latest" || true)
  VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/' || true)
  if [ -z "$VERSION" ]; then
    echo "::error::Failed to resolve latest kxn version. API response:"
    echo "$RELEASE_JSON" | head -5
    exit 1
  fi
fi

ASSET="kxn-${TARGET}.tar.gz"
DOWNLOAD_URL="https://github.com/kexa-io/homebrew-tap/releases/download/${VERSION}/${ASSET}"

echo "Installing kxn ${VERSION} for ${TARGET}..."

curl -sSL "$DOWNLOAD_URL" -o "/tmp/${ASSET}" || {
  echo "::error::Failed to download ${DOWNLOAD_URL}"
  exit 1
}

tar xzf "/tmp/${ASSET}" -C /tmp/
chmod +x /tmp/kxn

# Install to PATH
sudo mv /tmp/kxn /usr/local/bin/kxn || mv /tmp/kxn "${HOME}/.local/bin/kxn"

echo "kxn $(kxn --version) installed successfully"

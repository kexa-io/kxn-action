#!/bin/bash
set -euo pipefail

VERSION="${KXN_VERSION:-latest}"
TOKEN="${GH_TOKEN:-}"

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

AUTH_HEADER=""
if [ -n "$TOKEN" ]; then
  AUTH_HEADER="Authorization: token $TOKEN"
fi

# Resolve latest version via GitHub API
if [ "$VERSION" = "latest" ]; then
  LATEST_URL="https://api.github.com/repos/kexa-io/kxn/releases/latest"
  if [ -n "$AUTH_HEADER" ]; then
    VERSION=$(curl -sSL -H "$AUTH_HEADER" "$LATEST_URL" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
  else
    VERSION=$(curl -sSL "$LATEST_URL" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
  fi
  if [ -z "$VERSION" ]; then
    echo "::error::Failed to resolve latest kxn version. Is the token valid for kexa-io/kxn?"
    exit 1
  fi
fi

ASSET="kxn-${TARGET}.tar.gz"
DOWNLOAD_URL="https://github.com/kexa-io/kxn/releases/download/${VERSION}/${ASSET}"

echo "Installing kxn ${VERSION} for ${TARGET}..."

# Download asset (use GitHub API for private repos)
ASSET_API_URL="https://api.github.com/repos/kexa-io/kxn/releases/tags/${VERSION}"
if [ -n "$AUTH_HEADER" ]; then
  ASSET_ID=$(curl -sSL -H "$AUTH_HEADER" "$ASSET_API_URL" | grep -B 3 "\"name\": \"${ASSET}\"" | grep '"id"' | head -1 | sed 's/.*"id": *\([0-9]*\).*/\1/')
  if [ -n "$ASSET_ID" ]; then
    # Private repo: download via API
    curl -sSL -H "$AUTH_HEADER" -H "Accept: application/octet-stream" \
      "https://api.github.com/repos/kexa-io/kxn/releases/assets/${ASSET_ID}" \
      -o "/tmp/${ASSET}" || {
      echo "::error::Failed to download asset via API"
      exit 1
    }
  else
    # Fallback to direct URL (public repo)
    curl -sSL "$DOWNLOAD_URL" -o "/tmp/${ASSET}" || {
      echo "::error::Failed to download ${DOWNLOAD_URL}"
      exit 1
    }
  fi
else
  curl -sSL "$DOWNLOAD_URL" -o "/tmp/${ASSET}" || {
    echo "::error::Failed to download ${DOWNLOAD_URL}"
    exit 1
  }
fi

tar xzf "/tmp/${ASSET}" -C /tmp/
chmod +x /tmp/kxn

# Install to PATH
sudo mv /tmp/kxn /usr/local/bin/kxn || mv /tmp/kxn "${HOME}/.local/bin/kxn"

echo "kxn $(kxn --version) installed successfully"

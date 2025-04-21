#!/bin/bash

# Usage: ./check-release.sh <version>
# Example: ./check-release.sh 7.6.3

if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./check-release.sh <version>"
    exit 1
fi

VERSION=$1
TAG_NAME="angular_${VERSION}"
REPO_URL="$(git config --get remote.origin.url | sed 's/\.git$//')"
REPO_PATH="${REPO_URL#*github.com/}"

# Check if release exists
response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/${REPO_PATH}/releases/tags/${TAG_NAME}")

if [ "$response" = "200" ]; then
    echo "Error: A release for version ${VERSION} already exists!"
    exit 1
elif [ "$response" = "404" ]; then
    echo "No existing release found for version ${VERSION}, proceeding..."
    exit 0
else
    echo "Error: Failed to check release status (HTTP ${response})"
    exit 2
fi
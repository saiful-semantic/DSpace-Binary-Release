#!/bin/bash

# Usage: ./build-dspace-backend.sh <version>
# Example: ./build-dspace-backend.sh 7.6.3 or 9.0-rc1

if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./build-dspace-backend.sh <version>"
    exit 1
fi

VERSION=$1
SOURCE_DIR="source"
DSPACE_DIR="DSpace-dspace-${VERSION}"
MAJOR_VERSION="${VERSION%%.*}"

# Determine Java version based on DSpace version
if [ "$MAJOR_VERSION" = "7" ]; then
    JAVA_VERSION="11"
elif [ "$MAJOR_VERSION" = "8" ] || [ "$MAJOR_VERSION" = "9" ]; then
    JAVA_VERSION="17"
else
    echo "Error: Unsupported DSpace version $VERSION"
    exit 1
fi

# Check if release already exists
TAG_NAME="backend_${VERSION}"
REPO_URL="$(git config --get remote.origin.url | sed 's/\.git$//')"
REPO_PATH="${REPO_URL#*github.com/}"

response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/${REPO_PATH}/releases/tags/${TAG_NAME}")

if [ "$response" = "200" ]; then
    echo "Error: A release for version ${VERSION} already exists!"
    exit 1
elif [ "$response" != "404" ]; then
    echo "Error: Failed to check release status (HTTP ${response})"
    exit 2
fi

# Create source directory if it doesn't exist
mkdir -p ${SOURCE_DIR}

# Download source from tag (both regular releases and RCs are tagged)
echo "Downloading DSpace ${VERSION}..."
curl -L -o source.zip "https://github.com/DSpace/DSpace/archive/refs/tags/dspace-${VERSION}.zip"
unzip -o source.zip -d ./${SOURCE_DIR}

# Build with Maven
cd "${SOURCE_DIR}/${DSPACE_DIR}"
mvn --no-transfer-progress clean package

# Create installer zip
cd dspace/target
zip -r "../../../dspace${VERSION//./_}-installer.zip" dspace-installer

echo "Build completed successfully!"
cd ../../..
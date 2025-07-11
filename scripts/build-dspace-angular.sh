#!/bin/bash

# Usage: ./build-dspace-angular.sh <version>
# Example: ./build-dspace-angular.sh 7.6.3 or 9.0-rc1

if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./build-dspace-angular.sh <version>"
    exit 1
fi

VERSION=$1
MAJOR_VERSION="${VERSION%%.*}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if release already exists
"${SCRIPT_DIR}/check-release.sh" "$VERSION" "angular"
if [ $? -ne 0 ]; then
    exit 1
fi

SOURCE_DIR="source"
ANGULAR_DIR="dspace-angular-dspace-${VERSION}"

# Create source directory if it doesn't exist
mkdir -p ${SOURCE_DIR}

# Download source from tag (both regular releases and RCs are tagged)
echo "Downloading DSpace Angular ${VERSION}..."
curl -L -o source.zip "https://github.com/DSpace/dspace-angular/archive/refs/tags/dspace-${VERSION}.zip"
unzip -o source.zip -d ./${SOURCE_DIR}

# Install dependencies and build
cd "${SOURCE_DIR}/${ANGULAR_DIR}"
echo "Installing dependencies..."
if [ "$MAJOR_VERSION" = "9" ]; then
    echo "Using npm for DSpace Angular 9.0+"
    npm ci
    echo "Building project..."
    npm run build:prod
else
    echo "Using yarn for DSpace Angular < 9.0"
    yarn install
    echo "Building project..."
    yarn build:prod
fi

# Create distribution zip
echo "Creating distribution package..."
SAFE_VERSION=$(echo "$VERSION" | sed 's/[^a-zA-Z0-9]/_/g')
zip -r "../angular${SAFE_VERSION}-dist.zip" ./dist

echo "Created ZIP at: $(realpath "../angular${SAFE_VERSION}-dist.zip")"

echo "Build completed successfully!"

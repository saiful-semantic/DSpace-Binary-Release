#!/bin/bash

# Usage: ./build-dspace-angular.sh <version>
# Example: ./build-dspace-angular.sh 7.6.3 or 9.0-rc1

if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./build-dspace-angular.sh <version>"
    exit 1
fi

VERSION=$1

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
yarn install

echo "Building project..."
yarn build:prod

# Create distribution zip
echo "Creating distribution package..."
cd dist
zip -r "../../angular${VERSION//./_}-dist.zip" .

echo "Build completed successfully!"
cd ../../..
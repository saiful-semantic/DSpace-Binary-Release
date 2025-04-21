#!/bin/bash

# Usage: ./build-dspace-angular.sh <version>
# Example: ./build-dspace-angular.sh 7.6.3 or 9.0-rc1

if [ -z "$1" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./build-dspace-angular.sh <version>"
    exit 1
fi

VERSION=$1

# Check if release already exists
./check-release.sh "$VERSION"
if [ $? -ne 0 ]; then
    exit 1
fi

SOURCE_DIR="source"
ANGULAR_DIR="dspace-angular-dspace-${VERSION}"

# Create source directory if it doesn't exist
mkdir -p ${SOURCE_DIR}

# Check if this is an RC version
if [[ $VERSION == *"-rc"* ]]; then
    echo "Downloading DSpace Angular ${VERSION} from branch..."
    curl -L -o source.zip "https://github.com/DSpace/dspace-angular/archive/refs/heads/dspace-${VERSION}.zip"
else
    echo "Downloading DSpace Angular ${VERSION} from tag..."
    curl -L -o source.zip "https://github.com/DSpace/dspace-angular/archive/refs/tags/dspace-${VERSION}.zip"
fi

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
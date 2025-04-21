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

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if release already exists
"${SCRIPT_DIR}/check-release.sh" "$VERSION" "backend"
if [ $? -ne 0 ]; then
    exit 1
fi

# Determine Java version based on DSpace version
if [ "$MAJOR_VERSION" = "7" ]; then
    JAVA_VERSION="11"
elif [ "$MAJOR_VERSION" = "8" ] || [ "$MAJOR_VERSION" = "9" ]; then
    JAVA_VERSION="17"
else
    echo "Error: Unsupported DSpace version $VERSION"
    exit 1
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

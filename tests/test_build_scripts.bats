#!/usr/bin/env bats

setup() {
    # Create mock functions
    export -f curl
    export -f unzip
    export -f mvn
    export -f yarn
    export -f zip
    export -f mkdir
    export -f cd

    # Create test directories
    TEST_DIR="$(mktemp -d)"
    mkdir -p "${TEST_DIR}/source"
    export TEST_DIR
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# Mock functions
curl() { echo "Downloading..."; }
unzip() { echo "Extracting..."; }
mvn() { echo "Building with Maven..."; }
yarn() { echo "Running yarn $1..."; }
zip() { echo "Creating zip..."; }
mkdir() { echo "Creating directory $1"; }
cd() { echo "Changing to $1"; }

@test "build-backend-script fails when no version provided" {
    run ./scripts/build-dspace-backend.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Error: Version number is required" ]
}

@test "build-backend-script validates Java version for DSpace 7" {
    run ./scripts/build-dspace-backend.sh 7.6.3
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Downloading DSpace 7.6.3" ]]
}

@test "build-backend-script validates Java version for DSpace 8" {
    run ./scripts/build-dspace-backend.sh 8.1
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Downloading DSpace 8.1" ]]
}

@test "build-backend-script validates Java version for DSpace 9" {
    run ./scripts/build-dspace-backend.sh 9.0-rc1
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Downloading DSpace 9.0-rc1" ]]
}

@test "build-backend-script fails for unsupported version" {
    run ./scripts/build-dspace-backend.sh 10.0.0
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "Error: Unsupported DSpace version" ]]
}

@test "build-angular-script fails when no version provided" {
    run ./scripts/build-dspace-angular.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Error: Version number is required" ]
}

@test "build-angular-script handles normal version" {
    run ./scripts/build-dspace-angular.sh 7.6.3
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Downloading DSpace Angular 7.6.3" ]]
}

@test "build-angular-script handles RC version" {
    run ./scripts/build-dspace-angular.sh 9.0-rc1
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "Downloading DSpace Angular 9.0-rc1" ]]
}
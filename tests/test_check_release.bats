#!/usr/bin/env bats

setup() {
    # Create a mock curl function
    export -f curl
}

# Mock curl function for testing
curl() {
    if [[ "$*" == *"success_tag"* ]]; then
        echo "200"
    elif [[ "$*" == *"nonexistent_tag"* ]]; then
        echo "404"
    else
        echo "500"
    fi
}

@test "check-release fails when no version provided" {
    run ./scripts/check-release.sh
    [ "$status" -eq 1 ]
    [ "${lines[0]}" = "Error: Version number is required" ]
}

@test "check-release succeeds for non-existent release" {
    run ./scripts/check-release.sh nonexistent_tag
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ "No existing release found for version nonexistent_tag" ]]
}

@test "check-release fails for existing release" {
    run ./scripts/check-release.sh success_tag
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ "Error: A release for version success_tag already exists!" ]]
}

@test "check-release handles API errors" {
    run ./scripts/check-release.sh error_tag
    [ "$status" -eq 2 ]
    [[ "${lines[0]}" =~ "Error: Failed to check release status" ]]
}
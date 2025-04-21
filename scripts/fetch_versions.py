#!/usr/bin/env python3
import json
import sys
import requests

def get_dspace_versions():
    # First get releases
    releases_url = "https://api.github.com/repos/DSpace/dspace-angular/releases"
    releases_response = requests.get(releases_url)
    
    if releases_response.status_code != 200:
        print(f"Error fetching releases: {releases_response.status_code}", file=sys.stderr)
        sys.exit(1)
    
    versions = []
    
    # Get regular releases
    releases = releases_response.json()
    for release in releases:
        # Remove 'dspace-' prefix from tag name if it exists
        version = release['tag_name'].replace('dspace-', '')
        versions.append(version)
    
    # Get RC versions from branches
    branches_url = "https://api.github.com/repos/DSpace/dspace-angular/branches"
    branches_response = requests.get(branches_url)
    
    if branches_response.status_code == 200:
        branches = branches_response.json()
        for branch in branches:
            branch_name = branch['name']
            # Check for RC branches following pattern dspace-X.Y-rcZ
            if branch_name.startswith('dspace-') and '-rc' in branch_name.lower():
                version = branch_name.replace('dspace-', '')
                versions.append(version)
    
    # Sort versions
    def version_key(v):
        # Split version into parts
        parts = v.lower().replace('-rc', '.rc').split('.')
        # Convert numbers to ints for proper sorting
        return [int(x) if x.isdigit() else x for x in parts]
    
    versions.sort(key=version_key)
    
    # Group versions by major version
    version_groups = {}
    for version in versions:
        major = version.split('.')[0]
        if major not in version_groups:
            version_groups[major] = []
        version_groups[major].append(version)
    
    # Print JSON output that GitHub Actions can parse
    print(json.dumps(version_groups))
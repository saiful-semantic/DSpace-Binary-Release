#!/usr/bin/env python3
import json
import sys
import requests
import argparse

def get_dspace_versions(component):
    """Fetch DSpace versions for the specified component.
    
    Args:
        component: Either 'angular' or 'backend' to specify which component's versions to fetch
    """
    # Determine repository based on component
    repo = "dspace-angular" if component == "angular" else "DSpace"
    releases_url = f"https://api.github.com/repos/DSpace/{repo}/releases"
    
    response = requests.get(releases_url)
    if response.status_code != 200:
        print(f"Error fetching releases: {response.status_code}", file=sys.stderr)
        sys.exit(1)
    
    versions = []
    releases = response.json()
    
    for release in releases:
        # Remove 'dspace-' prefix from tag name if it exists
        version = release['tag_name'].replace('dspace-', '')
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

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Fetch DSpace component versions')
    parser.add_argument('component', choices=['angular', 'backend'],
                      help='Which component versions to fetch (angular or backend)')
    
    args = parser.parse_args()
    get_dspace_versions(args.component)
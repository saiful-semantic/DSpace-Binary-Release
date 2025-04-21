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
        # Split version into parts and normalize pre-release identifiers
        v = v.lower().replace('-beta', '.0.beta.').replace('-rc', '.0.rc.').replace('-preview-', '.0.preview.')
        parts = v.split('.')
        
        result = []
        for part in parts:
            if part.startswith(('beta', 'rc', 'preview')):
                # Pre-release versions sort before final releases
                # Use negative numbers to ensure they sort before release versions
                prefix = part[:-1] if part[-1].isdigit() else part
                num = int(part[len(prefix):]) if part[len(prefix):].isdigit() else 0
                if prefix == 'beta':
                    result.append((-3, num))
                elif prefix == 'preview':
                    result.append((-2, num))
                elif prefix == 'rc':
                    result.append((-1, num))
            else:
                try:
                    result.append((0, int(part)))
                except ValueError:
                    # Skip any non-numeric parts
                    continue
        return result

    # Sort versions using the new key function
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
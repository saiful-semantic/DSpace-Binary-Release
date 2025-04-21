# DSpace Binary Releases

[DSpace Documentation](https://wiki.lyrasis.org/display/DSDOC/) |
[DSpace Releases](https://github.com/DSpace/DSpace/releases) |
[DSpace Wiki](https://wiki.lyrasis.org/display/DSPACE/Home) |
[Support](https://wiki.lyrasis.org/display/DSPACE/Support)

## Overview

DSpace open source software is a turnkey repository application used by more than
2,000 organizations and institutions worldwide to provide durable access to digital resources.
For more information, visit http://www.dspace.org/

DSpace consists of both a Java-based backend and an Angular-based frontend.

* Backend (this codebase) provides a REST API, along with other machine-based interfaces (e.g. OAI-PMH, SWORD, etc)
    * The REST Contract is at https://github.com/DSpace/RestContract
* Frontend (https://github.com/DSpace/dspace-angular/) is the User Interface built on the REST API

## Build Requirements

### Backend
- Java requirements:
  - DSpace 7.x: Java 11
  - DSpace 8.x and 9.x: Java 17
- Maven 3.3+

### Frontend (Angular UI)
- Node.js requirements:
  - DSpace 7.x: Node.js 18.x
  - DSpace 8.x: Node.js 20.x
  - DSpace 9.x: Node.js 22.x
- Yarn package manager

## Automated Builds

This repository contains GitHub Actions workflows to automatically build both DSpace Backend and Frontend (Angular UI) components. The workflows can be triggered manually and support all current DSpace versions including release candidates.

### Available Workflows

1. **Backend Build**
   - Builds the DSpace Backend (REST API) component
   - Creates an installer package containing all backend components
   - Packages are named: `dspace[VERSION]-installer.zip`

2. **Frontend Build**
   - Builds the DSpace Angular UI
   - Creates a production-ready distribution package
   - Packages are named: `angular[VERSION]-dist.zip`

### How to Use

1. Go to the Actions tab in GitHub
2. Select either the Backend or Frontend build workflow
3. Click "Run workflow"
4. Enter the required information:
   - Major version (7, 8, or 9)
   - Specific version (e.g., 7.6.3, 8.1, 9.0-rc1)
   - Node.js version (for Frontend builds)

The workflow will:
- Validate the requested version exists
- Ensure correct Java/Node.js version is used
- Build and package the component
- Create a GitHub release with the built package

## Automated Dependency Validation

The build workflows automatically validate that the correct versions of dependencies are used:

- Backend builds verify Java version compatibility (Java 11 for 7.x, Java 17 for 8.x/9.x)
- Frontend builds enforce Node.js version requirements (18.x for 7.x, 20.x for 8.x, 22.x for 9.x)
- Release candidate versions are properly marked as pre-releases
- Version availability is checked against official DSpace releases
- Duplicate builds are prevented by checking existing releases

For more details about DSpace's version compatibility, see the 
[DSpace Release Notes](https://wiki.lyrasis.org/display/DSDOC7x/Release+Notes)

## Repository Structure

- `.github/workflows/` - GitHub Actions workflow definitions
- `scripts/` - Build and helper scripts
  - `build-dspace-angular.sh` - Frontend build script
  - `build-dspace-backend.sh` - Backend build script
  - `check-release.sh` - Release existence checker
  - `fetch_dspace_versions.py` - Version availability validator


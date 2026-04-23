# WJ-BIM Revit Deployment - Custom Icon Solution

Complete solution for deploying custom Revit shortcut icons across your organization.

## Quick Links

- **Quick Start:** See `DOCUMENTATION/README-HYBRID-QUICKSTART.md`
- **Icon Naming:** `DOCUMENTATION/NAMING-CONVENTION.md` (RVTYY.ico format)
- **GitHub Setup:** `DOCUMENTATION/GITHUB-SETUP.md`
- **External References:**
  - https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
  - https://www.bimpure.com/blog/revit-icons

## Contents

### ICONS/

Custom icons for Revit versions (2023-2027+)

- Format: RVTYY.ico (RVT23.ico, RVT24.ico, etc.)
- Located: `ICONS/`

### SCRIPTS/

Deployment scripts for local machines and Group Policy

- **LOCAL:** `SCRIPTS/LOCAL/` - Single machine deployment
- **GPO:** `SCRIPTS/GPO/` - Company-wide via Active Directory
- **LEGACY:** `SCRIPTS/LEGACY/` - Original versions (reference)

### DOCUMENTATION/

Guides, references, and troubleshooting

- Quick start guide
- GitHub setup instructions
- Detailed deployment guide
- Icon naming convention reference
- External resources

## Features

✅ Dynamic Revit version detection (2014-2034+)
✅ GitHub-hosted icon repository
✅ Start Menu + Desktop shortcuts
✅ Taskbar management
✅ Anti-reversion protections
✅ Company-wide GPO deployment
✅ Automatic icon updates (no script changes)

## Getting Started

1. **Local Testing:**
   
   - Run: `SCRIPTS/LOCAL/Deploy-RevitShortcuts-HYBRID-RVT.ps1`
   - Verify icons appear and persist

2. **Company-Wide:**
   
   - Create Group Policy
   - Add: `SCRIPTS/GPO/Deploy-RevitShortcuts-GPO-HYBRID-RVT.ps1`
   - Deploy to target OU

See `DOCUMENTATION/README-HYBRID-QUICKSTART.md` for detailed steps.

## Icon Naming Convention

**Format:** RVTYY.ico

- RVT23.ico = Revit 2023
- RVT24.ico = Revit 2024
- RVT25.ico = Revit 2025
- RVT26.ico = Revit 2026
- RVT27.ico = Revit 2027
- RVT28.ico = Revit 2028 (future - just add this file)

**Future-Proof:** When new Revit versions release, upload the icon to `ICONS/` and scripts automatically deploy it.

## References

- https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
- https://www.bimpure.com/blog/revit-icons

## License

MIT License - See LICENSE file

## Support

For detailed information, see documentation in `DOCUMENTATION/` folder.

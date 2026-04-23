# Group Policy Deployment Script

## Deploy-RevitShortcuts-GPO-HYBRID-RVT.ps1

Deploy to all domain machines via Group Policy.

### Setup Steps

1. Create GPO: "Revit Custom Shortcuts"
2. Add to: Computer Configuration > Scripts > Startup
3. Configure: PowerShell execution policy via Admin Templates
4. Link to: Target OU (Revit Users)
5. Deploy: gpupdate /force /boot

See GITHUB-SETUP.md for detailed steps.

### References

- https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
- https://www.bimpure.com/blog/revit-icons

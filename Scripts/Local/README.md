# Local Deployment Scripts

## Deploy-RevitShortcuts-HYBRID-RVT.ps1

Deploy custom Revit shortcuts on your local machine.

### Usage

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\Deploy-RevitShortcuts-HYBRID-RVT.ps1"
```

### What It Does

- Detects installed Revit versions (2014-2034+)
- Downloads icons from GitHub (RVTYY.ico)
- Creates Start Menu shortcuts
- Creates Desktop shortcuts
- Manages taskbar pins/unpins
- Clears icon cache
- Hardens registry
- Makes shortcuts read-only

### Output

[2023] INSTALLED

[2024] INSTALLED

[2025] INSTALLED

[NOT INSTALLED if Revit not installed]

Log: `C:\ProgramData\RevitDeploymentLog.txt`

## Fix-RevitIconReversion-ADVANCED.ps1

Fix icons reverting to defaults when Revit opens.

### Usage

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& ".\Fix-RevitIconReversion-ADVANCED.ps1"
```

Then restart your computer.

### References

- https://kam-jam.com/docs/Software%20Deployment/Revit%20Icons
- https://www.bimpure.com/blog/revit-icons

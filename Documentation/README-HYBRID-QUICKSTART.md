# REVIT CUSTOM ICON DEPLOYMENT - HYBRID GITHUB VERSION
## Quick Start Guide (Enhanced)

---

## What's New in This Version ✨

| Feature | Improvement |
|---------|-------------|
| **Dynamic Version Detection** | No hardcoding - automatically detects Revit 2014-2034+ |
| **GitHub Integration** | Icons stored in WJ-BIM/revit-icons, downloaded on deployment |
| **Both Start Menu + Desktop** | Shortcuts created in both locations |
| **Taskbar Management** | Automatically pins/unpins taskbar shortcuts |
| **Anti-Reversion** | Icon cache clearing, registry hardening, read-only protection |
| **One Status Line Per Year** | Perfect for automation/Action1 reporting |

---

## PHASE 1: GitHub Setup (Do This First!)

### Step 1: Create GitHub Repository

1. Go to https://github.com/WJ-BIM (your account)
2. Click **New** → **Create repository**
   - Name: `revit-icons`
   - Visibility: Public OR Private (your choice)
3. Click **Create**

### Step 2: Upload Your Icon Files

1. In the repo, click **Add file** → **Upload files**
2. Drag & drop your .ico files:
   ```
   r2023.ico
   r2024.ico
   r2025.ico
   r2026.ico
   r2027.ico
   r2028.ico  (add as new versions release)
   ```
3. Commit: "Add Revit version icons"

### Step 3: Get Your GitHub Token (If Private Repo)

**Only if you made the repo PRIVATE:**

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token → Check `repo` scope
3. Copy token (save somewhere safe)

**If PUBLIC repo:** Skip this, token not needed

### Verify GitHub Setup

```powershell
# Test in PowerShell
$TestUrl = "https://raw.githubusercontent.com/WJ-BIM/revit-icons/main/r2024.ico"
Invoke-WebRequest -Uri $TestUrl -OutFile C:\Temp\test.ico
# Should download successfully
```

---

## PHASE 2: Local Testing (Your Machine)

### Step 1: Download and Customize Script

Edit `Deploy-RevitShortcuts-HYBRID.ps1`:

```powershell
# At the top of the script, update if using PRIVATE repo:
param(
    [string]$GitHubToken = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # Your PAT
)

# If PUBLIC repo, leave empty:
param(
    [string]$GitHubToken = ""  # Public repo - no token needed
)
```

### Step 2: Run Local Deployment

```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Run the script (adjust path as needed)
& "C:\Scripts\Deploy-RevitShortcuts-HYBRID.ps1"
```

### Step 3: Verify on Your Machine

**Check Start Menu:**
```
Start Menu → Autodesk → Revit 2023
            → Revit 2024
            → Revit 2025
            → etc.
```

**Check Desktop:**
- Should see `Revit 2023.lnk`, `Revit 2024.lnk`, etc.
- Icons should show your custom colors

**Critical Test:**
```
1. Open Revit 2025 from shortcut
2. Wait for fully loaded
3. Minimize Revit
4. Check Desktop shortcut icon
5. Should still show custom icon (not revert to default)
```

**If icons revert after opening Revit:**

```powershell
# Run the fix script
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\Scripts\Fix-RevitIconReversion-ADVANCED.ps1"

# Then restart computer
Restart-Computer
```

---

## PHASE 3: Company-Wide Deployment via GPO

### Step 1: Prepare GPO Script

Edit `Deploy-RevitShortcuts-GPO-HYBRID.ps1`:

```powershell
# At the top, set GitHub token if private repo
param(
    [string]$GitHubToken = ""  # Public repo
    # OR
    # [string]$GitHubToken = "ghp_xxx"  # Private repo with PAT
)
```

### Step 2: Create Group Policy

**On your Domain Controller:**

1. Open **Group Policy Management** (gpmc.msc)
2. Create new GPO: **Revit Custom Shortcuts - Hybrid**
3. Edit the GPO
4. Navigate: **Computer Configuration > Windows Settings > Scripts (Startup/Shutdown)**
5. Right-click **Startup** → **Properties**
6. Click **Scripts** → **Add...**
7. Browse to: `Deploy-RevitShortcuts-GPO-HYBRID.ps1`

### Step 3: Configure PowerShell Execution

**In same GPO:**

1. Navigate: **Computer Configuration > Admin Templates > Windows Components > Windows PowerShell**
2. Find: **Turn on Script Execution**
3. Set to: **Enabled**
4. Select: **Allow local scripts and remote signed scripts**
5. Click OK

### Step 4: Link to Target Organizational Unit

1. **In Group Policy Management:**
   - Right-click your **Target OU** (e.g., "Revit Users")
   - Select **Link an Existing GPO**
   - Choose: **Revit Custom Shortcuts - Hybrid**

### Step 5: Test and Deploy

**On a test machine:**

```powershell
# Force immediate group policy update
gpupdate /force /boot
# Computer will restart
```

**After restart, verify:**
- Start Menu shortcuts exist
- Desktop shortcuts exist
- Custom icons display
- Check log: `C:\ProgramData\RevitDeploymentLog.txt`

**Status lines should show:**
```
[2023] INSTALLED
[2024] INSTALLED
[2025] INSTALLED
[NOT INSTALLED versions skipped]
```

**If successful, expand to all machines:**
- GPO automatically deploys to all linked users at next startup

---

## UPDATING ICONS IN THE FUTURE

### When Revit 2028 is Released

1. **Create icon and convert to .ico format**
2. **In GitHub repo:**
   - Click **Add file** → **Upload files**
   - Upload: `r2028.ico`
   - Commit: "Add Revit 2028 icon"
3. **On next GPO deployment run:**
   - Scripts automatically detect new version
   - Download new icon
   - Create shortcuts
   - **Zero script changes needed**

### Update Existing Icon (e.g., Change Colors)

1. **In GitHub repo:**
   - Click the icon file (e.g., `r2025.ico`)
   - Delete it
   - Upload new version
   - Commit: "Update Revit 2025 icon"
2. **Force update on clients:**
   ```powershell
   gpupdate /force
   ```
   Icons updated on next script run

---

## Troubleshooting

### Icons Don't Appear on Desktop/Start Menu

```powershell
# Check Revit installations
Test-Path "C:\Program Files\Autodesk\Revit 2023\Revit.exe"

# Check deployment log
Get-Content C:\ProgramData\RevitDeploymentLog.txt

# Verify GitHub access
$TestUrl = "https://raw.githubusercontent.com/WJ-BIM/revit-icons/main/r2024.ico"
Invoke-WebRequest -Uri $TestUrl -OutFile C:\Temp\test.ico
```

### Icons Revert After Opening Revit

```powershell
# Run anti-reversion script
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "C:\Scripts\Fix-RevitIconReversion-ADVANCED.ps1"

# Restart computer
Restart-Computer
```

### Private Repo - 401 Unauthorized Error

- **Issue:** GitHub token expired or invalid
- **Solution:** Generate new PAT at GitHub → Settings → Developer settings → Tokens
- **Update:** Edit script with new token
- **Deploy:** `gpupdate /force /boot`

### GitHub Not Accessible (Network/Firewall)

```powershell
# Test connectivity
Test-NetConnection raw.githubusercontent.com -Port 443

# If blocked, work with IT to allow:
# - raw.githubusercontent.com:443 (HTTPS)
```

### Script Errors in Event Viewer

- Check: `C:\ProgramData\RevitDeploymentLog.txt` for detailed errors
- Check: Event Viewer → Windows Logs → System for PowerShell errors
- Verify: PowerShell execution policy set in GPO

---

## How It Works (Technical Overview)

### Local Script (HYBRID version)

1. **Detects installed Revit versions** → Checks `C:\Program Files\Autodesk\Revit YYYY\Revit.exe`
2. **Downloads icons from GitHub** → `https://raw.githubusercontent.com/WJ-BIM/revit-icons/main/rYYYY.ico`
3. **Creates Start Menu shortcuts** → `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Autodesk\Revit YYYY\`
4. **Creates Desktop shortcuts** → `%USERPROFILE%\Desktop\Revit YYYY.lnk`
5. **Manages taskbar** → Unpins old, re-pins new with custom icons
6. **Protects icons** → Read-only + Icon cache clearing + Registry hardening

### GPO Script (HYBRID version)

Same as above, but:
- Runs at **system startup** (before user login)
- Applies to **all users** on the machine
- Creates shortcuts in **each user's Desktop**
- Logs to: `C:\ProgramData\RevitDeploymentLog.txt`

### Icon Naming Convention

```
rYYYY.ico = Revit YYYY

r2023.ico = Revit 2023
r2024.ico = Revit 2024
r2025.ico = Revit 2025
r2028.ico = Revit 2028 (future)
r2034.ico = Revit 2034 (future)
```

---

## File Reference

| File | Purpose | Location |
|------|---------|----------|
| `Deploy-RevitShortcuts-HYBRID.ps1` | Local deployment | `C:\Scripts\` |
| `Deploy-RevitShortcuts-GPO-HYBRID.ps1` | Company-wide deployment | `\\DC\SYSVOL\YourDomain\Policies\{GUID}\Machine\Scripts\Startup\` |
| `Fix-RevitIconReversion-ADVANCED.ps1` | Fix reversion issues | `C:\Scripts\` |
| GitHub icons | Icon repository | `https://github.com/WJ-BIM/revit-icons` |
| Deployment log | Status/errors | `C:\ProgramData\RevitDeploymentLog.txt` |

---

## Status Output Format

Each script outputs exactly one line per year for automation:

```
[2023] INSTALLED       ← Revit 2023 found, shortcuts created, icon applied
[2024] INSTALLED
[2025] INSTALLED
[2026] NOT INSTALLED   ← Revit not installed (skipped)
[2027] NOT INSTALLED
[2028] DOWNLOAD FAILED ← Icon file not found on GitHub
```

Perfect for Action1, automation logs, or monitoring systems.

---

## Quick Checklist

### Phase 1: GitHub Setup
- [ ] Created `WJ-BIM/revit-icons` repository
- [ ] Uploaded all .ico files (r2023.ico, r2024.ico, etc.)
- [ ] Set repo visibility (public or private)
- [ ] Generated PAT (if private repo)
- [ ] Tested download: `Test-NetConnection` works

### Phase 2: Local Testing
- [ ] Downloaded `Deploy-RevitShortcuts-HYBRID.ps1`
- [ ] Updated GitHub token (if needed)
- [ ] Ran script as Administrator
- [ ] Verified Start Menu shortcuts exist
- [ ] Verified Desktop shortcuts exist
- [ ] Opened each Revit version - icons persist ✓

### Phase 3: Company-Wide
- [ ] Downloaded `Deploy-RevitShortcuts-GPO-HYBRID.ps1`
- [ ] Updated GitHub token in script (if needed)
- [ ] Created Group Policy
- [ ] Added script to startup scripts
- [ ] Configured PowerShell execution policy
- [ ] Linked GPO to target OU
- [ ] Tested on 3-5 machines
- [ ] Forced: `gpupdate /force /boot`
- [ ] Verified shortcuts and icons on test machines
- [ ] Expanded to all machines

---

## Key Advantages Over Previous Version

✅ **Zero Maintenance** - New Revit versions auto-detected (no script edits)  
✅ **GitHub Managed** - Icons stored in version control (easy to update)  
✅ **Both Start Menu + Desktop** - Maximum visibility  
✅ **Auto Taskbar** - Shortcuts pinned automatically  
✅ **Clean Output** - One line per year (perfect for automation)  
✅ **Persistent Icons** - Anti-reversion protections included  

---

**Next Step:** Go through Phase 1 (GitHub setup), then Phase 2 (local testing). Phase 3 (GPO) once Phase 2 is working!

Need help? Check `GITHUB-SETUP.md` for detailed GitHub configuration.

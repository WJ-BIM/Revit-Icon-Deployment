# REVIT CUSTOM SHORTCUT ICONS - COMPLETE DEPLOYMENT GUIDE
# For Revit 2023-2027 with 4 custom icon variants

## ============================================================================
## PHASE 1: LOCAL TESTING ON YOUR MACHINE
## ============================================================================

### STEP 1A: Prepare Icon Files

Your icon files should be in .ICO format. If you have .PNG files, convert them:

**OPTION 1: Convert PNG to ICO (PowerShell)**
```powershell
# Run this to convert all PNG files to ICO in a folder
$PngFolder = "C:\Your\PNG\Folder"
$OutputFolder = "C:\RevitIcons"

# Install if needed: Install-Module -Name ImageMagick -Force
Get-ChildItem $PngFolder -Filter "*.png" | ForEach-Object {
    $icoName = $_.BaseName + ".ico"
    $outputPath = Join-Path $OutputFolder $icoName
    & magick convert $_.FullName -define icon:auto-resize=256,128,96,64,48,32,24,16 $outputPath
}
```

**OPTION 2: Online Conversion**
- Use https://convertio.co/png-ico/ or similar (drag & drop)
- Download all 4 .ico files

**Icon File Naming (IMPORTANT):**
- Revit2023.ico
- Revit2024.ico
- Revit2025.ico
- Revit2026.ico
- Revit2027.ico

Store them in: `C:\RevitIcons\`

---

### STEP 1B: Run Local Deployment Script

1. **Save the script:**
   - Download: `Deploy-RevitShortcuts-LOCAL.ps1`
   - Save to: `C:\Scripts\` (create folder if needed)

2. **Run as Administrator:**
   ```powershell
   # Open PowerShell as Admin (Win+X, then A)
   cd C:\Scripts
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   .\Deploy-RevitShortcuts-LOCAL.ps1
   ```

3. **Verify on your machine:**
   - Check Desktop for 4 new Revit shortcuts (2023, 2024, 2025, 2026, 2027)
   - Icons should display with your custom colors
   - **CRITICAL TEST:** Open each Revit version
   - ⚠️ **Issue If Icons Revert After Opening** → See "Icon Reversion Fix" below

---

### STEP 1C: Troubleshoot Icon Reversion (Common Issue)

**If custom icons revert when Revit opens:**

This happens because Revit is setting its own icon. Fix with this advanced method:

```powershell
# Run as Admin - Protect shortcuts from being overridden
$shortcutPaths = @(
    "$env:USERPROFILE\Desktop\Revit 2023.lnk",
    "$env:USERPROFILE\Desktop\Revit 2024.lnk",
    "$env:USERPROFILE\Desktop\Revit 2025.lnk",
    "$env:USERPROFILE\Desktop\Revit 2026.lnk",
    "$env:USERPROFILE\Desktop\Revit 2027.lnk"
)

foreach ($lnk in $shortcutPaths) {
    if (Test-Path $lnk) {
        # Set as read-only to prevent Revit from modifying it
        Set-ItemProperty -Path $lnk -Name IsReadOnly -Value $true
        Write-Host "Protected: $lnk"
    }
}
```

**If that doesn't work, try the Nuclear Option:**
```powershell
# Stop Revit monitoring
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTypeOverlayIcons" /t REG_DWORD /d 0 /f

# Clear icon cache completely
taskkill /f /im explorer.exe
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
start explorer.exe
```

---

## ============================================================================
## PHASE 2: DEPLOY VIA GROUP POLICY (COMPANY-WIDE)
## ============================================================================

### STEP 2A: Set Up Network Icon Share

1. **Create a shared folder on your file server:**
   ```
   \\YourDomain\netlogon\RevitIcons
   (or use another shared location your domain can access)
   ```

2. **Copy your 5 .ico files to this share:**
   - Revit2023.ico
   - Revit2024.ico
   - Revit2025.ico
   - Revit2026.ico
   - Revit2027.ico

3. **Set permissions (Read-only for everyone):**
   - Everyone: Read & Execute
   - Domain Users: Read & Execute
   - Do NOT grant Modify

---

### STEP 2B: Create Group Policy Startup Script

#### On Your Domain Controller / Group Policy Management Machine:

1. **Edit the Group Policy:**
   - Open: **Group Policy Management** (gpmc.msc)
   - Navigate: **Computer Configuration > Windows Settings > Scripts (Startup/Shutdown)**
   - Right-click **Startup** → **Properties**

2. **Add the Script:**
   - Click **Scripts** tab
   - Click **Add...**
   - Browse to: `Deploy-RevitShortcuts-GPO.ps1`
   - *(Upload this to SYSVOL first - see below)*

3. **OR Deploy via SYSVOL (Recommended):**
   
   ```powershell
   # On Domain Controller, copy script to SYSVOL
   $dcPath = "\\YourDC\SYSVOL\YourDomain\Policies\{GUID}\Machine\Scripts\Startup\"
   Copy-Item Deploy-RevitShortcuts-GPO.ps1 $dcPath
   ```

---

### STEP 2C: Configure Group Policy Settings

**In Group Policy Editor (gpedit.msc on DC or Group Policy Management):**

```
Computer Configuration
└── Administrative Templates
    └── Windows Components
        └── Windows PowerShell
            └── Turn on Script Execution
                → Set to: "Allow local scripts and remote signed scripts"
```

**Also set:**
```
Computer Configuration
└── Policies
    └── Windows Settings
        └── Security Settings
            └── Local Policies
                └── User Rights Assignment
                    └── Bypass traverse checking
                        → Add: Everyone, Domain Users
```

---

### STEP 2D: Link to Organizational Unit

1. **In Group Policy Management:**
   - Right-click your **Target OU** (e.g., "Revit Users")
   - Select **Link an Existing GPO**
   - Choose your newly created policy

2. **Force Group Policy Update:**
   ```powershell
   # On each client machine (or all via command):
   gpupdate /force /boot
   
   # This forces immediate policy application and reboots
   ```

---

### STEP 2E: Verify Deployment

**On each client machine after reboot:**

1. Check for shortcuts on Desktop
2. Verify custom icons display
3. Test opening each Revit version
4. Check deployment log:
   ```
   C:\ProgramData\RevitDeploymentLog.txt
   ```

---

## ============================================================================
## PHASE 3: TROUBLESHOOTING & MAINTENANCE
## ============================================================================

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Icons not showing | Icons not in network share | Copy .ico files to `\\domain\netlogon\RevitIcons` |
| Icons revert after opening Revit | Revit overriding icons | Run "Nuclear Option" script in Step 1C |
| GPO not applying | Execution policy blocked | Set PowerShell execution policy via GPO |
| Shortcuts not created | Revit not installed | Verify installation path: `C:\Program Files\Autodesk\Revit XXXX\` |
| Script errors | UNC path not accessible | Test: `Test-Path \\your-domain\netlogon\RevitIcons` |

### Testing Network Connectivity

```powershell
# Test if clients can reach icon share
Test-Path "\\YourDomain\netlogon\RevitIcons"

# If false, check:
# 1. Network share exists and is accessible
# 2. Firewall allows SMB/445
# 3. DNS resolves your domain correctly
```

---

## ============================================================================
## PHASE 4: ROLLBACK/UPDATES
## ============================================================================

### If You Need to Update Icons

1. Replace .ico files in `\\domain\netlogon\RevitIcons`
2. Force update on clients:
   ```powershell
   gpupdate /force
   ```
3. Clear local caches:
   ```powershell
   taskkill /f /im explorer.exe
   Remove-Item "C:\ProgramData\RevitShortcutIcons\*.ico" -Force
   Start-Process explorer.exe
   ```

### Complete Rollback

If you need to revert to default icons:

```powershell
# Remove custom shortcuts
Get-Item "$env:USERPROFILE\Desktop\Revit*.lnk" | Remove-Item -Force

# Clear cache
Remove-Item "C:\ProgramData\RevitShortcutIcons" -Recurse -Force

# Unlink GPO and reboot
# Clients will no longer deploy custom shortcuts
```

---

## ============================================================================
## QUICK REFERENCE - DEPLOYMENT CHECKLIST
## ============================================================================

**Phase 1: Local Testing**
- [ ] Convert PNG icons to ICO format (5 files)
- [ ] Place in C:\RevitIcons\
- [ ] Run Deploy-RevitShortcuts-LOCAL.ps1 as Admin
- [ ] Verify 4 shortcuts on Desktop with custom icons
- [ ] Test opening each Revit version
- [ ] If icons revert, run "Nuclear Option" script
- [ ] Verify icons persist after opening Revit

**Phase 2: Company-Wide Deployment**
- [ ] Create \\domain\netlogon\RevitIcons share
- [ ] Copy 5 .ico files to network share
- [ ] Set share permissions (Read-only)
- [ ] Create GPO in Active Directory
- [ ] Add Deploy-RevitShortcuts-GPO.ps1 to startup scripts
- [ ] Configure PowerShell execution policy in GPO
- [ ] Link GPO to Target OU
- [ ] Force gpupdate /force /boot on test machine
- [ ] Verify shortcuts and icons on test machine

**Phase 3: Rollout**
- [ ] Test on 5-10 machines first
- [ ] Document any issues
- [ ] Expand to department
- [ ] Monitor C:\ProgramData\RevitDeploymentLog.txt on clients
- [ ] Update wiki/help docs for users

---

## SCRIPT FILE LOCATIONS

```
Local Testing Script:
  C:\Scripts\Deploy-RevitShortcuts-LOCAL.ps1

GPO Script (copy to SYSVOL):
  \\YourDC\SYSVOL\YourDomain\Policies\{GUID}\Machine\Scripts\Startup\Deploy-RevitShortcuts-GPO.ps1

Icon Files (Network Share):
  \\YourDomain\netlogon\RevitIcons\
    ├── Revit2023.ico
    ├── Revit2024.ico
    ├── Revit2025.ico
    ├── Revit2026.ico
    └── Revit2027.ico

Deployment Log (on each client):
  C:\ProgramData\RevitDeploymentLog.txt
```

---

**Questions?** Check the troubleshooting section or review logs in C:\ProgramData\

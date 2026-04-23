# REVIT ICONS - GITHUB REPOSITORY SETUP

## Overview

This guide sets up a GitHub repository in your **WJ-BIM** account to store and retrieve Revit icon files. Your deployment scripts will clone icons directly from GitHub, eliminating the need for a network share.

---

## STEP 1: Create GitHub Repository

### 1A: Create New Repository

1. Go to https://github.com/WJ-BIM
2. Click **New** → **Create a new repository**
3. Configure:
   - **Repository name:** `revit-icons`
   - **Description:** "Autodesk Revit custom icons for deployment"
   - **Visibility:** Private (unless you want public)
   - **Initialize with README:** Yes
   - **Add .gitignore:** None needed
   - **License:** MIT (optional)

4. Click **Create repository**

### 1B: Add Your Icon Files

Option A - **Via GitHub Web UI (Easiest):**

1. In your new repo, click **Add file** → **Upload files**
2. Drag & drop your icon files:
   ```
   r2023.ico
   r2024.ico
   r2025.ico
   r2026.ico
   r2027.ico
   r2028.ico  (add future versions here)
   r2029.ico
   ... etc
   ```
3. Commit with message: "Add Revit version icons"

Option B - **Via Git Command Line:**

```bash
cd your-local-folder
git clone https://github.com/WJ-BIM/revit-icons.git
cd revit-icons

# Copy your .ico files here
cp C:\RevitIcons\*.ico .

# Commit and push
git add *.ico
git commit -m "Add Revit version icons"
git push origin main
```

### Final Repository Structure

```
revit-icons/
├── README.md
├── r2023.ico
├── r2024.ico
├── r2025.ico
├── r2026.ico
├── r2027.ico
├── r2028.ico  (add as new versions release)
└── ...
```

---

## STEP 2: Configure GitHub Access for Scripts

### Option A: Public Repository (Simpler, No Auth Needed)

1. **Make repo public** (Settings → Visibility → Change to Public)
2. Scripts can download without authentication
3. **Pro:** No credentials in scripts
4. **Con:** Icons visible to anyone

### Option B: Private Repository (More Secure, Requires PAT)

**You'll need a Personal Access Token (PAT):**

1. Go to GitHub → Settings → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Configure:
   - **Token name:** `revit-icons-deploy`
   - **Expiration:** 90 days (or No expiration if approved by IT)
   - **Scopes:** Check only `repo` (full control of private repos)
4. Click **Generate token**
5. **Copy and save somewhere secure** (you won't see it again)

**Add token to your script:**
```powershell
$GitHubToken = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
$GitHubHeaders = @{
    "Authorization" = "token $GitHubToken"
}
```

---

## STEP 3: Script Configuration

### For Deployment Scripts

Update this section in both local and GPO scripts:

```powershell
# ================================
# GITHUB CONFIGURATION
# ================================

$GitHubRepo     = "WJ-BIM/revit-icons"
$GitHubBranch   = "main"
$GitHubToken    = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # Only if PRIVATE repo
$IconRoot       = "C:\ProgramData\RevitIcons"

# Construct GitHub Raw URL
$IconBaseUrl    = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch"

# If private repo, add auth header
if ($GitHubToken) {
    $GitHubHeaders = @{
        "Authorization" = "token $GitHubToken"
    }
} else {
    $GitHubHeaders = @{}
}
```

### Icon Naming Convention

Icons must follow this pattern:
```
r2023.ico  (Revit 2023)
r2024.ico  (Revit 2024)
r2025.ico  (Revit 2025)
rYYYY.ico  (any year)
```

Scripts will automatically:
- Detect installed Revit versions
- Download matching icons from GitHub
- Update shortcuts for each version
- Skip if no matching icon

---

## STEP 4: Update Icons in the Future

### When Revit 2028 is Released

1. **Convert icon to .ico format** (if PNG)
2. **In GitHub repo:**
   - Click **Add file** → **Upload files**
   - Upload `r2028.ico`
   - Commit with message: "Add Revit 2028 icon"
3. **On next deployment run**, scripts automatically detect and deploy it
   - **Zero script changes needed**

### Update Existing Icon

1. In GitHub repo, click the icon file (e.g., `r2025.ico`)
2. Click pencil icon (Edit)
3. Or delete and re-upload with new version
4. Commit changes
5. On next deployment run, new icon is used

---

## STEP 5: Verify GitHub Setup

### Test Icon Download (PowerShell)

```powershell
$GitHubRepo = "WJ-BIM/revit-icons"
$GitHubBranch = "main"
$IconBaseUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch"

# Test downloading r2024.ico
$TestUrl = "$IconBaseUrl/r2024.ico"
$TestPath = "C:\Temp\test-r2024.ico"

try {
    Invoke-WebRequest -Uri $TestUrl -OutFile $TestPath -UseBasicParsing
    Write-Host "✓ Successfully downloaded from GitHub"
    Get-Item $TestPath  # Should show file details
} catch {
    Write-Host "✗ Failed: $_"
}
```

If this works, your GitHub setup is ready for the scripts.

---

## STEP 6: GitHub Access from Domain Machines

### For Company-Wide Deployment:

**Proxy/Firewall Considerations:**
- Ensure machines can reach `raw.githubusercontent.com` (port 443)
- GitHub uses HTTPS only - no special firewall rules needed
- Test from a domain machine:
  ```powershell
  Test-NetConnection raw.githubusercontent.com -Port 443
  ```

**If PAT Expires:**
- Error: `401 Unauthorized`
- Solution: Update `$GitHubToken` in script with new PAT from GitHub
- Redeploy via GPO: `gpupdate /force /boot`

---

## Quick Reference

| Task | How To |
|------|--------|
| **Create repo** | https://github.com/WJ-BIM/new → Name: revit-icons |
| **Add icons** | Repo → Add file → Upload files |
| **Make private** | Settings → Visibility → Private |
| **Create PAT** | Settings → Dev settings → Tokens → Generate |
| **Update future icon** | Just upload new `rYYYY.ico` to GitHub |
| **Verify setup** | Run test script above |

---

## Security Notes

- **PAT in scripts:** Store in secure location only (not in version control)
  - Use: `$GitHubToken = "ghp_xxx"` directly in script (only for internal use)
  - Don't: Commit PAT to GitHub public repos
  - Better: Store PAT in Windows Credential Manager and retrieve it

- **Public repo:** Anyone can see your icons (usually fine)
- **Private repo:** Only WJ-BIM members can download (more secure)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `401 Unauthorized` | PAT expired or invalid - generate new PAT |
| `404 Not Found` | Icon file name doesn't match `rYYYY.ico` format |
| `Network unreachable` | Check firewall, test: `Test-NetConnection github.com -Port 443` |
| Icon not updating | Commit message in GitHub? Check repo visibility (public vs private) |

---

## File References

- **Repository:** https://github.com/WJ-BIM/revit-icons
- **Raw icon URL format:** https://raw.githubusercontent.com/WJ-BIM/revit-icons/main/rYYYY.ico
- **Example:** https://raw.githubusercontent.com/WJ-BIM/revit-icons/main/r2025.ico

---

**Setup is complete when:**
- ✅ GitHub repo created with `revit-icons` name
- ✅ All .ico files uploaded (r2023.ico, r2024.ico, etc.)
- ✅ Repo is Public OR PAT generated (if Private)
- ✅ Test download script succeeds
- ✅ Scripts updated with GitHub URL and PAT (if needed)

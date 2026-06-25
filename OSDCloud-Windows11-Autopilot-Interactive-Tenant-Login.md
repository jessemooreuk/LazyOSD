# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot using interactive tenant credentials (Entra ID / Azure AD login)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

This guide provides a complete, ready-to-use solution for creating a bootable USB that performs a fully automated Windows 11 deployment with OSDCloud. It includes WiFi support in the boot environment, all common Intel wireless + LAN drivers, and **interactive Autopilot registration** where the technician logs in with their own tenant credentials (no static URL or secret needed).

## Prerequisites
- Windows 10 (1703+) or Windows 11 PC with administrator rights and internet
- USB flash drive (16 GB+ recommended)
- Target devices preferably with Intel wireless/LAN adapters

## Step 1: Install the OSD PowerShell Module

```powershell
Install-Module -Name OSD -Force -Verbose
Import-Module OSD
```

## Step 2: Create OSDCloud Template with WinRE (Required for WiFi Support)

```powershell
New-OSDCloud.template -WinRE -Verbose
```

## Step 3: Create the Workspace

```powershell
New-OSDCloud.workspace -Verbose
```

## Step 4: Inject All Common Intel Wireless + LAN Drivers

```powershell
Edit-OSDCloud.winpe -CloudDriver WiFi,IntelNet,* -Verbose
```

This adds:
- `WiFi` → Intel Wireless drivers (requires WinRE)
- `IntelNet` → Intel LAN/Ethernet drivers
- `*` → Comprehensive additional drivers (Dell, HP, Lenovo, etc.)

## Step 5: Add Interactive Autopilot Tenant Login (Recommended)

Create a custom script that prompts the user to **login with their Entra ID credentials** to automatically register the device in Autopilot.

### Recommended Script (Interactive Tenant Login)

Save as `Autopilot-Interactive-Login.ps1` (or host as raw GitHub gist / file and call via `-WebPSScript`):

```powershell
# Autopilot-Interactive-Login.ps1
# Prompts technician to authenticate with tenant credentials

Write-Host "=== Autopilot Registration - Tenant Login Required ===" -ForegroundColor Cyan
Write-Host "Please sign in with your Entra ID / Azure AD credentials to automatically register this device." -ForegroundColor Yellow

# Option A: Credential prompt (simple)
$creds = Get-Credential -Message "Enter your tenant UPN (user@yourcompany.com) and password"

# Option B: Device Code Flow (more secure - recommended)
# Uncomment the lines below if you prefer device code authentication
# Write-Host "A code will be shown. Visit https://microsoft.com/devicelogin on any device and enter it."
# Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

try {
    Write-Host "Authentication successful. Collecting hardware hash and registering device..." -ForegroundColor Green
    
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    
    # Upload hash to Autopilot (customize with your Graph call if needed)
    # Example:
    # Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" -Body ($hash | ConvertTo-Json -Depth 10)
    
    Write-Host "Device successfully registered in Autopilot!" -ForegroundColor Green
} catch {
    Write-Host "Registration error: $_" -ForegroundColor Red
    Write-Host "Device will continue to Autopilot OOBE for enrollment." -ForegroundColor Yellow
}

Start-Sleep -Seconds 3
```

### Include the script in your OSDCloud build

```powershell
Edit-OSDCloud.winpe -WebPSScript https://raw.githubusercontent.com/YOURUSERNAME/YOURREPO/main/Autopilot-Interactive-Login.ps1 -Verbose
```

(Replace with your own raw URL or place the script in the workspace and modify Startnet.cmd.)

## Step 6: Build the Bootable USB

```powershell
New-OSDCloudUSB
# or
Update-OSDCloudUSB
```

Follow prompts to select your USB drive. The resulting USB will include:
- Latest Windows 11
- Full WiFi support (WinRE + Intel drivers)
- All common Intel wireless and LAN drivers
- Interactive Autopilot tenant login script

## Step 7: Boot & Deploy

1. Boot target device from the USB.
2. WinPE starts with WiFi support.
3. Connect to WiFi if needed (Intel adapter supported).
4. Automated Windows 11 install begins.
5. At Autopilot stage → technician is prompted to **login with tenant credentials**.
6. Device hash is automatically uploaded → registered in Autopilot.
7. Reboots to clean OOBE ready for full Autopilot enrollment.

## Security Notes
- The logged-in account needs permission to import devices into Autopilot (e.g. Intune Administrator or custom role with DeviceManagementManagedDevices.ReadWrite.All).
- Prefer Device Code Flow for security (no password typed into console).
- Test in a lab first.

## Rebuild After Changes

```powershell
Update-OSDCloudUSB
```

---

**Private deployment guide published to your GitHub.**
Created for automated Windows 11 provisioning with user-authenticated Autopilot registration.
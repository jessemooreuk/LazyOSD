# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic + Audit Mode)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Recommended Workflow (Local Scripts Version)**

This guide uses **local scripts** (no internet download during deployment). This is more reliable and works offline.

## Stage 1: WinPE – Install Windows + Collect Hash

### 1. Prepare OSDCloud

```powershell
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
```

### 2. Add Scripts Locally (Recommended)

Download these two scripts and copy them into your workspace:

- `Collect-AutopilotHash-WinPE.ps1`
- `AuditMode-AutopilotUpload.ps1`

**Download links:**
- https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Collect-AutopilotHash-WinPE.ps1
- https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/AuditMode-AutopilotUpload.ps1

Then run:

```powershell
$scriptsPath = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $scriptsPath -ItemType Directory -Force

Copy-Item "C:\Path\To\Your\Scripts\Collect-AutopilotHash-WinPE.ps1" -Destination $scriptsPath -Force
Copy-Item "C:\Path\To\Your\Scripts\AuditMode-AutopilotUpload.ps1" -Destination $scriptsPath -Force

# Make scripts available in WinPE
Edit-OSDCloudWinPE -ScriptPath "$scriptsPath\Collect-AutopilotHash-WinPE.ps1" -Verbose
Edit-OSDCloudWinPE -ScriptPath "$scriptsPath\AuditMode-AutopilotUpload.ps1" -Verbose
```

### 3. Configure Audit Mode

```powershell
$unattend = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Reseal>
        <Mode>Audit</Mode>
      </Reseal>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose
```

### 4. Build the USB

```powershell
New-OSDCloudUSB
```

## Stage 2: Audit Mode – Upload Hash

After Windows installs, the device boots into **Audit Mode**.

Run this command in Audit Mode:

```powershell
powershell -NoLogo -File "X:\Scripts\AuditMode-AutopilotUpload.ps1"
```

The script will:
- Prompt you to connect to WiFi
- Use Device Code Flow (works with any tenant)
- Upload the hardware hash
- Automatically run `sysprep /oobe /reboot`

## Files Available in This Repository

All scripts are published locally:

- `Collect-AutopilotHash-WinPE.ps1` – WinPE hash collection
- `AuditMode-AutopilotUpload.ps1` – Audit Mode upload + exit to OOBE

## Summary

- Fully tenant-agnostic
- Scripts run locally from the USB
- Reliable Audit Mode workflow
- WiFi + Intel drivers supported

---

**This is the recommended stable configuration.**
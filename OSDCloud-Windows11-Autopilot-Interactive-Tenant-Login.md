# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic + Audit Mode)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Recommended Workflow (June 2026)**

This guide uses a reliable two-stage approach:

- **Stage 1 (WinPE)**: Install Windows + collect hardware hash
- **Stage 2 (Audit Mode)**: Upload hash to Autopilot, then exit to normal OOBE

This avoids the instability of running Graph authentication inside WinPE.

## Prerequisites
- Windows 10 (1703+) or Windows 11 PC with administrator rights and internet
- USB flash drive (16 GB+ recommended)

## Stage 1: WinPE – Install Windows + Collect Hash

### Step 1: Prepare OSDCloud

```powershell
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
```

### Step 2: Add Hash Collection Script (WinPE)

```powershell
Edit-OSDCloudWinPE -WebPSScript https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Collect-AutopilotHash-WinPE.ps1 -Verbose
```

### Step 3: Configure to Boot into Audit Mode

Create a simple Unattend.xml that forces Audit Mode on first boot, then apply it:

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

### Step 4: Build the USB

```powershell
New-OSDCloudUSB
```

## Stage 2: Audit Mode – Upload Hash & Exit to OOBE

After Windows 11 installs, the device will boot into **Audit Mode**.

### Run the Audit Mode Upload Script

```powershell
powershell -NoLogo -Command "Invoke-WebPSScript 'https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/AuditMode-AutopilotUpload.ps1'"
```

This script will:
- Prompt the technician to connect to WiFi
- Authenticate using Device Code Flow (tenant-agnostic)
- Upload the hardware hash to Autopilot
- Automatically run `sysprep /oobe /reboot` to exit Audit Mode

## Files in This Repository

- `Collect-AutopilotHash-WinPE.ps1` – Runs in WinPE
- `AuditMode-AutopilotUpload.ps1` – Runs in Audit Mode
- `App-Registration-for-Autopilot.md` – Optional App Registration guide

## Summary of Your Universal Deployment

- One USB works with any tenant
- WiFi supported in WinPE
- All common Intel drivers included
- Reliable hash upload in Audit Mode
- Fully automatic exit back to normal OOBE

---

**This is currently the most stable and recommended workflow.**
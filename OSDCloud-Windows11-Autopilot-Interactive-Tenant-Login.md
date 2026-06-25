# LazyOSD

**Automated Enterprise OSD + Intune Enrollment**

## Overview

LazyOSD provides an automated, out-of-the-box method of creating a Windows 11 OSD image for enterprise use, with automatic enrollment into Intune using a user’s M365 account.

## Key Features

- Windows 11 24H2 Enterprise
- Fully automatic installation
- Automatic boot into Audit Mode
- Automatic hardware hash collection + upload to Autopilot/Intune
- Device Code Flow authentication (tenant-agnostic)
- Intel Wireless + LAN drivers included
- WiFi support in WinPE

## How to Build

```powershell
irm https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Build-OSDCloudUSB.ps1 | iex
```

The build will ask for a Project Name and whether you want Progress Bar or Verbose output.

## Deployment Flow

1. Boot from USB/ISO
2. Windows 11 installs automatically
3. Device automatically enters Audit Mode
4. Script runs automatically:
   - Prompts for WiFi (if needed)
   - Collects hardware hash
   - Uploads to Intune/Autopilot using M365 credentials
   - Exits Audit Mode and reboots into normal OOBE

## Files

- `Build-OSDCloudUSB.ps1` – Main build script
- `AuditMode-AutopilotUpload.ps1` – Runs automatically in Audit Mode

---

**LazyOSD** – Making enterprise OSD simple and automated.
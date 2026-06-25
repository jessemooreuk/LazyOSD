# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic + Audit Mode)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Fully Automated Build (Recommended)**

Use the `Build-OSDCloudUSB.ps1` script to automate everything including copying local scripts into the workspace.

## 1. Download the Build Script + Supporting Scripts

Download these three files:

- `Build-OSDCloudUSB.ps1`
- `Collect-AutopilotHash-WinPE.ps1`
- `AuditMode-AutopilotUpload.ps1`

**Links:**
- https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Build-OSDCloudUSB.ps1
- https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Collect-AutopilotHash-WinPE.ps1
- https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/AuditMode-AutopilotUpload.ps1

## 2. Prepare Your Scripts Folder

Create a folder on your build PC, for example:
```powershell
New-Item -Path "C:\OSDCloudScripts" -ItemType Directory -Force
```

Copy the two scripts (`Collect-AutopilotHash-WinPE.ps1` and `AuditMode-AutopilotUpload.ps1`) into `C:\OSDCloudScripts`.

## 3. Run the Automated Build

```powershell
# Run this script (it will do everything automatically)
. C:\Path\To\Build-OSDCloudUSB.ps1
```

The build script will:
- Update the OSD module
- Create Template + Workspace
- Add Intel drivers
- Copy your local scripts into the workspace
- Configure Unattend for Audit Mode
- Build the final USB

## 4. What You Get

Your USB will:
- Install Windows 11
- Collect and save the hardware hash locally
- Boot into Audit Mode automatically
- Run the upload script in Audit Mode (with WiFi prompt)
- Automatically exit to normal OOBE after upload

All scripts run locally from the USB (no internet required during deployment).

---

**This is the most automated and reliable setup.**
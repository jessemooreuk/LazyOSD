# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic + Audit Mode)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Fully Automated Build (Recommended)**

## How to Build

Run this one-liner in PowerShell:

```powershell
irm https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Build-OSDCloudUSB.ps1 | iex
```

### What Happens During the Build

The build script will:

1. Ask you for a **Project Name** (used for Workspace name and ISO filename)
2. Automatically download the two required runtime scripts
3. Create Template + Workspace
4. Add Intel Wireless + LAN drivers
5. Configure automatic execution in WinPE and Audit Mode
6. At the end, ask you whether you want to create:
   - **USB** only
   - **ISO** only (named after your Project)
   - **Both** USB and ISO

You no longer need to manually place any scripts — everything is handled automatically.

## After Building

- If you chose **ISO**, you will get an ISO file named after your Project.
- Boot the ISO/USB on a target machine.
- The deployment will:
  - Automatically collect the hardware hash in WinPE
  - Boot into Audit Mode
  - Automatically run the upload script in Audit Mode (with WiFi prompt)
  - Exit to normal OOBE after registration

## Files in This Repository

- `Build-OSDCloudUSB.ps1` — Main automated build script
- `Collect-AutopilotHash-WinPE.ps1` — Runs in WinPE (auto-executed)
- `AuditMode-AutopilotUpload.ps1` — Runs in Audit Mode (auto-executed)

---

**This is currently the most automated and user-friendly way to build your OSDCloud USB/ISO.**
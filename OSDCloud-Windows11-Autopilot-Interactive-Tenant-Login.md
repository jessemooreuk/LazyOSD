# Automated installation of Windows 11 using OSDCloud

**Booting from a USB Stick**  
**Automatically registering in Autopilot (Tenant-Agnostic)**  
**Includes all common Intel wireless and LAN drivers**  
**OSDCloud supports WiFi Connection**

**Universal / Tenant-Agnostic Version** (June 2026)

This guide creates a **single universal OSDCloud USB** that works with **any Entra ID tenant** without hardcoding Tenant IDs, Client IDs, or Secrets.

> The deployment is fully interactive during Autopilot registration so the same USB can be used across multiple customers or environments.

## Prerequisites
- Windows 10 (1703+) or Windows 11 PC with administrator rights and internet
- USB flash drive (16 GB+ recommended)
- Target devices preferably with Intel wireless/LAN adapters

## Step 1: Install / Update the OSD Module

```powershell
Install-Module OSD -Force -AllowClobber -Verbose
Import-Module OSD -Force
```

## Step 2: Create OSDCloud Template with WinRE (for WiFi Support)

```powershell
New-OSDCloudTemplate -WinRE -Verbose
```

## Step 3: Create the Workspace

```powershell
New-OSDCloudWorkspace -Verbose
```

## Step 4: Add All Common Intel Wireless + LAN Drivers

```powershell
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose
```

## Step 5: Add Tenant-Agnostic Autopilot Registration Script

Use the latest tenant-agnostic script. It uses **Device Code Flow** by default so no tenant details are stored in the USB.

### Latest Tenant-Agnostic Script

**Direct link:** https://github.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/blob/main/Autopilot-Interactive-Login.ps1

### Include it during the build

```powershell
Edit-OSDCloudWinPE -WebPSScript https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main/Autopilot-Interactive-Login.ps1 -Verbose
```

The script will:
- Prompt the technician to authenticate via Device Code Flow to **any target tenant**
- Automatically collect the hardware hash
- Upload the device to Autopilot using the signed-in context

## Step 6: Build the Bootable USB

```powershell
New-OSDCloudUSB
```

## Step 7: Boot & Deploy (Tenant Agnostic Flow)

1. Boot the target device from the USB.
2. WinPE starts with full WiFi support.
3. Connect to WiFi if needed.
4. Windows 11 installs automatically.
5. At the Autopilot step the script runs Device Code authentication.
6. Technician signs in to the **correct tenant** on any device.
7. Device hash is uploaded automatically.
8. Reboots into clean OOBE ready for Autopilot enrollment.

## Making Your Deployment Fully Tenant Agnostic

- Do **not** hardcode any Tenant ID, Client ID, or Client Secret in the script or USB.
- Rely on interactive authentication (Device Code Flow is ideal).
- The same USB works for every customer/environment.
- App Registration is **optional** and should only be created per-tenant if you need app-only automation in specific cases.

## Useful Commands

```powershell
Get-Command -Module OSD | Where-Object Name -like '*OSDCloud*'
Get-OSDCloudTemplate
```

## Security Notes
- Device Code Flow is the most secure interactive method.
- The technician only needs an account with permission to import devices in the target tenant.
- Test thoroughly before production use.

---

**This is now a complete universal OSDCloud solution** for Automated Windows 11 deployment from USB with WiFi, Intel drivers, and tenant-agnostic Autopilot registration.
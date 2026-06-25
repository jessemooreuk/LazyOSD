# Build-OSDCloudUSB.ps1
# Fully automated build script for tenant-agnostic OSDCloud USB
# with Audit Mode + local scripts (no WebPSScript)

Write-Host "=== Building OSDCloud USB (Automated + Local Scripts) ===" -ForegroundColor Cyan

# 1. Update OSD module
Write-Host "Updating OSD module..." -ForegroundColor Yellow
Install-Module OSD -Force -AllowClobber -ErrorAction SilentlyContinue
Import-Module OSD -Force

# 2. Create Template and Workspace
Write-Host "Creating Template and Workspace..." -ForegroundColor Yellow
New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose

# 3. Add Intel drivers
Write-Host "Adding Intel Wireless + LAN drivers..." -ForegroundColor Yellow
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose

# 4. Copy local scripts into workspace (Automation)
Write-Host "Copying local scripts into workspace..." -ForegroundColor Yellow

$workspaceScripts = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $workspaceScripts -ItemType Directory -Force | Out-Null

# Change these paths to where you keep your scripts
$sourceScripts = "C:\OSDCloudScripts"   # <-- Change this to your folder

Copy-Item "$sourceScripts\Collect-AutopilotHash-WinPE.ps1" -Destination $workspaceScripts -Force
Copy-Item "$sourceScripts\AuditMode-AutopilotUpload.ps1" -Destination $workspaceScripts -Force

# 5. Configure Unattend for Audit Mode
Write-Host "Configuring Unattend for Audit Mode..." -ForegroundColor Yellow

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

# 6. Build the USB
Write-Host "Building USB..." -ForegroundColor Yellow
New-OSDCloudUSB

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Your USB now contains local scripts and will boot into Audit Mode." -ForegroundColor Green

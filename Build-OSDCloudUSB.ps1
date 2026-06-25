# Build-OSDCloudUSB.ps1
# Fully automated OSDCloud build with automatic script execution

Write-Host "=== Building Fully Automated OSDCloud USB ===" -ForegroundColor Cyan

# 1. Update module
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

# 2. Create Template + Workspace
New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose

# 3. Add drivers
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose

# 4. Copy scripts to workspace
$workspaceScripts = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $workspaceScripts -ItemType Directory -Force | Out-Null

Copy-Item "C:\OSDCloudScripts\Collect-AutopilotHash-WinPE.ps1" -Destination $workspaceScripts -Force
Copy-Item "C:\OSDCloudScripts\AuditMode-AutopilotUpload.ps1" -Destination $workspaceScripts -Force

# 5. Make hash collection run automatically in WinPE (modify Startnet.cmd)
Write-Host "Configuring automatic hash collection in WinPE..." -ForegroundColor Yellow

$startnet = Get-Content "X:\Windows\System32\Startnet.cmd" -ErrorAction SilentlyContinue
if (-not $startnet) { $startnet = @() }

$startnet += "powershell -NoLogo -File X:\Scripts\Collect-AutopilotHash-WinPE.ps1"
$startnet | Out-File "X:\Windows\System32\Startnet.cmd" -Encoding ASCII -Force

# 6. Configure Unattend with automatic script in Audit Mode
Write-Host "Configuring Unattend for automatic Audit Mode execution..." -ForegroundColor Yellow

$unattend = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Reseal>
        <Mode>Audit</Mode>
      </Reseal>
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
          <Order>1</Order>
          <CommandLine>powershell -NoLogo -File "C:\Scripts\AuditMode-AutopilotUpload.ps1"</CommandLine>
          <Description>Run Autopilot Hash Upload</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose

# 7. Build USB
New-OSDCloudUSB

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Scripts will now run automatically in WinPE and Audit Mode." -ForegroundColor Green

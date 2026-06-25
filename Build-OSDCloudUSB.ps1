# Build-OSDCloudUSB.ps1
# Fully automated build with local scripts + automatic execution

Write-Host "=== Building Automated OSDCloud USB ===" -ForegroundColor Cyan

Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Verbose

Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose

# Copy scripts locally
$workspaceScripts = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $workspaceScripts -ItemType Directory -Force | Out-Null

Copy-Item "C:\OSDCloudScripts\Collect-AutopilotHash-WinPE.ps1" -Destination $workspaceScripts -Force
Copy-Item "C:\OSDCloudScripts\AuditMode-AutopilotUpload.ps1" -Destination $workspaceScripts -Force

# Edit Startnet.cmd inside the template (this runs during build)
Write-Host "Configuring automatic script execution in WinPE..." -ForegroundColor Yellow
$startnetFile = Get-ChildItem -Path "$env:ProgramData\OSDCloud\Template" -Recurse -Filter "Startnet.cmd" | Select-Object -First 1 -ExpandProperty FullName

if ($startnetFile) {
    Add-Content -Path $startnetFile -Value "powershell -NoLogo -File X:\Scripts\Collect-AutopilotHash-WinPE.ps1"
    Write-Host "Startnet.cmd updated in template." -ForegroundColor Green
}

# Unattend with automatic Audit Mode execution
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
          <Description>Run Autopilot Upload Automatically</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattend | Out-File -FilePath "$env:ProgramData\OSDCloud\Unattend.xml" -Encoding utf8 -Force
Edit-OSDCloudWinPE -Unattend "$env:ProgramData\OSDCloud\Unattend.xml" -Verbose

New-OSDCloudUSB

Write-Host "=== Build Complete ===" -ForegroundColor Green

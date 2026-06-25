# Build-OSDCloudUSB.ps1
# Fully automated OSDCloud build script
# Downloads required scripts automatically and prompts for Project name

Write-Host "=== OSDCloud Automated Build ===" -ForegroundColor Cyan

# Ask for Project Name
$ProjectName = Read-Host "Enter Project Name (used for Workspace and USB label)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "OSDCloud-Autopilot" }

Write-Host "Project: $ProjectName" -ForegroundColor Green

# Download the two required scripts automatically
Write-Host "Downloading required scripts..." -ForegroundColor Yellow

$scriptsPath = "$env:ProgramData\OSDCloud\Workspace\Scripts"
New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null

$baseUrl = "https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main"

Invoke-WebRequest -Uri "$baseUrl/Collect-AutopilotHash-WinPE.ps1" -OutFile "$scriptsPath\Collect-AutopilotHash-WinPE.ps1" -UseBasicParsing
Invoke-WebRequest -Uri "$baseUrl/AuditMode-AutopilotUpload.ps1" -OutFile "$scriptsPath\AuditMode-AutopilotUpload.ps1" -UseBasicParsing

Write-Host "Scripts downloaded successfully." -ForegroundColor Green

# Continue with build
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

New-OSDCloudTemplate -WinRE -Verbose
New-OSDCloudWorkspace -Name $ProjectName -Verbose

Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,* -Verbose

# Edit Startnet.cmd in template for automatic execution in WinPE
$startnetFile = Get-ChildItem -Path "$env:ProgramData\OSDCloud\Template" -Recurse -Filter "Startnet.cmd" | Select-Object -First 1 -ExpandProperty FullName
if ($startnetFile) {
    Add-Content -Path $startnetFile -Value "powershell -NoLogo -File X:\Scripts\Collect-AutopilotHash-WinPE.ps1"
}

# Unattend for automatic Audit Mode execution
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
Write-Host "Project Name: $ProjectName" -ForegroundColor Green

# Build-OSDCloudUSB.ps1
# Fully automated OSDCloud build with correct ISO detection

Write-Host "=== OSDCloud Automated Build ===" -ForegroundColor Cyan

# Project Name
$ProjectName = Read-Host "Enter Project Name (used for Workspace and ISO filename)"
if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = "OSDCloud-Autopilot" }
Write-Host "Project: $ProjectName" -ForegroundColor Green

# Progress vs Verbose
$mode = Read-Host "Show simple progress bar or verbose output? (P = Progress bar, V = Verbose)"
$UseProgressBar = ($mode.ToUpper() -eq "P")

if ($UseProgressBar) {
    Write-Host "Progress bar mode enabled (errors will still show)." -ForegroundColor Green
} else {
    Write-Host "Verbose mode enabled." -ForegroundColor Green
}

function Write-BuildStep {
    param([string]$Message, [int]$Percent)
    if ($UseProgressBar) {
        Write-Progress -Activity "Building $ProjectName" -Status $Message -PercentComplete $Percent
    } else {
        Write-Host $Message -ForegroundColor Yellow
    }
}

# Download scripts
Write-BuildStep "Downloading required scripts..." 10

$workspaceRoot = "$env:ProgramData\OSDCloud\Workspace"
New-Item -Path $workspaceRoot -ItemType Directory -Force | Out-Null

$baseUrl = "https://raw.githubusercontent.com/jessemooreuk/osdcloud-windows11-autopilot-interactive-login/main"

try {
    Invoke-WebRequest -Uri "$baseUrl/Collect-AutopilotHash-WinPE.ps1" -OutFile "$workspaceRoot\Collect-AutopilotHash-WinPE.ps1" -UseBasicParsing -ErrorAction Stop
    Invoke-WebRequest -Uri "$baseUrl/AuditMode-AutopilotUpload.ps1" -OutFile "$workspaceRoot\AuditMode-AutopilotUpload.ps1" -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to download scripts. $_" -ForegroundColor Red
    exit
}

# Place Unattend.xml in workspace root
$unattendContent = @'
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
          <CommandLine>powershell -NoLogo -File "X:\AuditMode-AutopilotUpload.ps1"</CommandLine>
          <Description>Run Autopilot Upload Automatically</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@ 

$unattendContent | Out-File -FilePath "$workspaceRoot\Unattend.xml" -Encoding utf8 -Force

# Core build
Write-BuildStep "Updating OSD module..." 20
Install-Module OSD -Force -AllowClobber
Import-Module OSD -Force

Write-BuildStep "Creating Template and Workspace..." 30
New-OSDCloudTemplate -WinRE
New-OSDCloudWorkspace -Name $ProjectName

Write-BuildStep "Adding Intel drivers..." 45
Edit-OSDCloudWinPE -CloudDriver WiFi,IntelNet,*

Write-BuildStep "Finalizing WinPE..." 60
Edit-OSDCloudWinPE

# Output choice
Write-BuildStep "Build complete. Choosing output format..." 80

$choice = Read-Host "Create USB, ISO, or Both? (U = USB, I = ISO, B = Both)"

switch ($choice.ToUpper()) {
    "U" { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB 
    }
    "I" { 
        Write-Host "Creating ISO..." -ForegroundColor Yellow
        New-OSDCloudISO

        # Correctly find the newly created ISO in C:\OSDCloud
        Start-Sleep -Seconds 2
        $latestIso = Get-ChildItem -Path "C:\OSDCloud" -Filter "*.iso" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1

        if ($latestIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $latestIso.FullName -Destination $destination -Force
            Write-Host "ISO renamed and moved to: $destination" -ForegroundColor Green
        } else {
            Write-Host "Warning: Could not find the created ISO to rename." -ForegroundColor Yellow
        }
    }
    "B" { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB
        Write-Host "Creating ISO..." -ForegroundColor Yellow
        New-OSDCloudISO

        Start-Sleep -Seconds 2
        $latestIso = Get-ChildItem -Path "C:\OSDCloud" -Filter "*.iso" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1

        if ($latestIso) {
            $newName = "$ProjectName.iso"
            $destination = Join-Path "$env:USERPROFILE\Downloads" $newName
            Move-Item -Path $latestIso.FullName -Destination $destination -Force
            Write-Host "ISO renamed and moved to: $destination" -ForegroundColor Green
        }
    }
    default { 
        Write-Host "Creating USB..." -ForegroundColor Yellow
        New-OSDCloudUSB 
    }
}

if ($UseProgressBar) { Write-Progress -Activity "Building $ProjectName" -Completed }

Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host "Project: $ProjectName" -ForegroundColor Green

# AuditMode-AutopilotUpload.ps1
# Runs automatically in Audit Mode
# Collects hardware hash + uploads to Autopilot + exits to OOBE
# Tenant-agnostic using Device Code Flow

Write-Host "=== Autopilot Registration - Audit Mode ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Prompt for WiFi if needed
Write-Host "Please connect to WiFi now if you are not on a wired connection." -ForegroundColor Yellow
Write-Host "Press Enter when connected to the internet..." -ForegroundColor Yellow
Read-Host | Out-Null

Write-Host "Proceeding with hardware hash collection and upload..." -ForegroundColor Green
Write-Host ""

# Step 2: Collect hardware hash
try {
    Write-Host "Collecting hardware hash..." -ForegroundColor Yellow
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    Write-Host "Hardware hash collected successfully." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to collect hardware hash. $_" -ForegroundColor Red
    pause
    exit
}

# Step 3: Authenticate with Device Code Flow
Write-Host "Starting Device Code authentication..." -ForegroundColor Yellow
Write-Host "A code will appear. Go to https://microsoft.com/devicelogin on any device and sign in with your tenant credentials."

try {
    Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
    Write-Host "Authentication successful!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Authentication failed. $_" -ForegroundColor Red
    pause
    exit
}

# Step 4: Upload to Autopilot
try {
    Write-Host "Uploading device to Autopilot..." -ForegroundColor Yellow
    
    $body = @{
        serialNumber = $hash.SerialNumber
        productKey   = $hash.ProductKey
        hardwareHash = $hash.HardwareHash
    }
    
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
        -Body ($body | ConvertTo-Json) `
        -ContentType "application/json"
    
    Write-Host "SUCCESS: Device has been registered in Autopilot!" -ForegroundColor Green
    
} catch {
    Write-Host "Upload failed: $_" -ForegroundColor Red
    Write-Host "You can still continue manually if needed." -ForegroundColor Yellow
}

# Step 5: Exit Audit Mode and reboot into OOBE
Write-Host ""
Write-Host "Exiting Audit Mode and rebooting into normal OOBE..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

sysprep /oobe /reboot

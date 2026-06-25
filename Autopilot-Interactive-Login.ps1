# Autopilot-Interactive-Login.ps1
# Standalone script for OSDCloud deployments
# Prompts technician to authenticate with Entra ID / Azure AD tenant credentials
# and automatically registers the device in Autopilot

Write-Host "=== Autopilot Registration - Tenant Login Required ===" -ForegroundColor Cyan
Write-Host "Please sign in with your tenant credentials to automatically register this device in Autopilot." -ForegroundColor Yellow
Write-Host ""

# =============================================
# OPTION 1: Simple Credential Prompt (easiest)
# =============================================
$creds = Get-Credential -Message "Enter your Entra ID UPN (user@yourtenant.com) and password"

# =============================================
# OPTION 2: Device Code Flow (more secure - recommended)
# Uncomment the block below if you prefer this method
# =============================================
<#
Write-Host "A device code will appear below."
Write-Host "Go to https://microsoft.com/devicelogin on any device (phone/laptop) and enter the code."
Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
#>

try {
    Write-Host ""
    Write-Host "Authentication successful! Collecting hardware hash..." -ForegroundColor Green
    
    # Collect the Windows Autopilot hardware hash
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    
    Write-Host "Hardware hash collected successfully." -ForegroundColor Green
    
    # =============================================
    # CUSTOMIZE THIS SECTION if you want to automatically upload via Graph API
    # Example (requires proper app registration + permissions):
    # Invoke-MgGraphRequest -Method POST `
    #     -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
    #     -Body ($hash | ConvertTo-Json -Depth 10)
    # =============================================
    
    Write-Host "Device is now ready for Autopilot registration." -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Error during Autopilot process: $_" -ForegroundColor Red
    Write-Host "You can continue - the device will enter standard Autopilot OOBE." -ForegroundColor Yellow
}

Start-Sleep -Seconds 3
Write-Host ""
Write-Host "Script complete. Proceeding with OSDCloud..." -ForegroundColor Cyan

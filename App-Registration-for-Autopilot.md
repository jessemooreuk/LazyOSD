# App Registration for Automatic Autopilot Enrollment

This guide explains how to create a Microsoft Entra ID (Azure AD) App Registration so the OSDCloud deployment can **automatically upload device hardware hashes** to Autopilot using Microsoft Graph.

This enables the `Autopilot-Interactive-Login.ps1` script (or a fully automated version) to register devices without manual portal uploads.

## Recommended Approach

For technician-driven USB deployments, we recommend **Delegated** permissions + **Device Code Flow**. This is more secure and follows least-privilege principles.

For fully unattended scenarios, use **Application** permissions + Client Secret.

---

## Step 1: Create the App Registration

1. Go to the [Microsoft Entra admin center](https://entra.microsoft.com)
2. Navigate to **Identity** > **Applications** > **App registrations**
3. Click **+ New registration**
4. Fill in:
   - **Name**: `OSDCloud-Autopilot-Registration`
   - **Supported account types**: *Accounts in this organizational directory only (Single tenant)* (recommended)
   - **Redirect URI**: Leave blank (or select *Public client/native* if testing)
5. Click **Register**

## Step 2: Add API Permissions

1. In your new app, go to **API permissions**
2. Click **+ Add a permission**
3. Select **Microsoft Graph**
4. Choose the permission type:
   - **Delegated permissions** (recommended for interactive login)
   - **Application permissions** (for app-only / fully automated)
5. Search for and select:
   - `DeviceManagementManagedDevices.ReadWrite.All`
6. Click **Add permissions**
7. Click **Grant admin consent for [Your Tenant]** (important!)

## Step 3: Create a Client Secret (for Application permissions)

> Skip this step if using only Delegated + Device Code Flow.

1. Go to **Certificates & secrets**
2. Under **Client secrets**, click **+ New client secret**
3. Add a description (e.g., "OSDCloud Autopilot Script")
4. Choose expiration (recommend 6–12 months or custom)
5. Click **Add**
6. **Immediately copy** the **Value** (it will not be shown again!)

You will need:
- Application (client) ID
- Directory (tenant) ID
- Client Secret Value

## Step 4: Note Your IDs

From the **Overview** page of the app, copy:
- **Application (client) ID**
- **Directory (tenant) ID**

## Step 5: Update the Autopilot Script

### For Delegated + Device Code Flow (Recommended)

Use this in your script:

```powershell
Write-Host "Using Device Code Flow for secure authentication..."
Connect-MgGraph -UseDeviceCode -Scopes "DeviceManagementManagedDevices.ReadWrite.All" -NoWelcome
```

### For App-Only (Application Permissions + Secret)

Replace the credential section with:

```powershell
$tenantId = "YOUR-TENANT-ID-HERE"
$clientId = "YOUR-CLIENT-ID-HERE"
$clientSecret = ConvertTo-SecureString "YOUR-CLIENT-SECRET-HERE" -AsPlainText -Force

$secureCred = New-Object System.Management.Automation.PSCredential($clientId, $clientSecret)

Connect-MgGraph -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret
```

### Full Example: Automatic Upload After Authentication

```powershell
try {
    $hash = Get-WindowsAutoPilotInfo -OutputObject
    
    # Upload to Autopilot
    $body = @{
        serialNumber = $hash.SerialNumber
        productKey = $hash.ProductKey
        hardwareHash = $hash.HardwareHash
        # Add other fields as needed
    }
    
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
        -Body ($body | ConvertTo-Json) `
        -ContentType "application/json"
    
    Write-Host "Device successfully registered in Autopilot via Graph!" -ForegroundColor Green
} catch {
    Write-Host "Upload failed: $_" -ForegroundColor Red
}
```

## Security Best Practices

- Use the **shortest possible secret expiration**
- Prefer **Device Code Flow** over storing secrets in scripts
- Restrict the app to only the required permission (`DeviceManagementManagedDevices.ReadWrite.All`)
- Monitor sign-in logs in Entra ID
- Rotate secrets regularly

## Next Steps

1. Update your `Autopilot-Interactive-Login.ps1` with the App Registration details.
2. Rebuild your OSDCloud USB with the updated script.
3. Test on a non-production device.

---

**Published alongside the OSDCloud Windows 11 deployment guide.**
This enables fully automated or semi-automated Autopilot device registration from your USB boot process.
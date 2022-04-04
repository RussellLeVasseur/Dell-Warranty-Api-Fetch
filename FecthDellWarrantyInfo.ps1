$DellApiKey="";
$DellApiSecret="";



$SerialNumber = Read-Host -Prompt "`nEnter a Service Tag number or hit Enter to check the current machine";
Start-Sleep -Seconds 1;
If (!$SerialNumber) {
    Write-Host "`nNo Service Tag number entered. Fetching current device serial number...";
    Start-Sleep -Seconds 1;
    $Win32_BIOS = Get-WMIObject -Class Win32_BIOS;
    $SerialNumber = $Win32_BIOS.SerialNumber;
    Write-Host "`nCurrent Device Service Tag is: $SerialNumber";
} Else {
    Write-Host "`nYou Entered Service Tag: $SerialNumber";
}
Start-Sleep -Seconds 1;
Write-Host "`nChecking Dell API for Warranty information...";
Start-Sleep -Seconds 1;

$AuthURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
$OAuth = "$DellApiKey`:$DellApiSecret";
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($OAuth);
$EncodedOAuth = [Convert]::ToBase64String($Bytes);
$DellTokenHeaders = @{};
$DellTokenHeaders.Add("authorization", "Basic $EncodedOAuth");
$Authbody = 'grant_type=client_credentials';
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$AuthResult = Invoke-RESTMethod -Method Post -Uri $AuthURI -Body $AuthBody -Headers $DellTokenHeaders;
$Token = $AuthResult.access_token;
$DellApiHeaders = @{"Accept" = "application/json" };
$DellApiHeaders.Add("Authorization", "Bearer $Token");
$DellApiParams = @{};
$DellApiParams = @{servicetags = $SerialNumber; Method = "GET" };
$DellApiResponse = Invoke-RestMethod -Uri "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements" -Headers $DellApiHeaders -Body $DellApiParams -Method Get -ContentType "application/json" -ea 0
$DellApiResponse | ConvertTo-Json | ConvertFrom-Json;
$DellApiResponse = $DellApiResponse | ConvertTo-Json | ConvertFrom-Json;

$SaveToFile = Read-Host -Prompt "`nWould you like to save this information to a file? yes|no";
Start-Sleep -Seconds 1;
Switch ($SaveToFile.ToLower()) {
    { @("y","ye","yes","yess")  -contains $_ } {
        $FileType = Read-Host -Prompt "`nWhat file type would you like to output it to? csv/|json|txt";
        Switch ($FileType.ToLower()) {
            { @("c","cs","csv","csvv") -contains $_ } {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.csv" -Value ($DellApiResponse | ConvertTo-Csv) -Force;
                Write-Host "`nSaved to file $PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.csv";
            }
            { @("t","tx","txt","txtt") -contains $_ } {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.txt" -Value ($DellApiResponse | Out-String) -Force;
                Write-Host "`nSaved to file $PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.txt";
            }
            { @("j","js","jso","json","jsonn") -contains $_ } {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.json" -Value ($DellApiResponse | ConvertTo-Json) -Force;
                Write-Host "`nSaved to file $PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.json";
            }
            default {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$($SerialNumber)_DellWarrantyInfo.txt" -Value ($DellApiResponse | Out-String) -Force;
                Write-Host "`nSaved to file $($SerialNumber)_DellWarrantyInfo.txt";
            }
        }
    }
    { @("n", "no") -contains $_ } { exit 0; }
    "default" { exit 0; }
}
Start-Sleep -Seconds 1;


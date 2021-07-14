#
# 1. Powershell to deploy Column Master Keys (CMK) and column encryption keys (CEK)
# See https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/configure-always-encrypted-keys-using-powershell?view=sql-server-ver15#azure-key-vault-without-role-separation-example
# 
#
# Create a column master key in Azure Key Vault.
$akvKeyName = "CMKAuto1"
#New-AzResourceGroup -Name $resourceGroup -Location $azureLocation # Creates a new resource group - skip, if your desired group already exists.

Set-AzKeyVaultAccessPolicy -VaultName $env:AKV -ResourceGroupName $env:RG -PermissionsToKeys get, create, delete, list, wrapKey,unwrapKey, sign, verify -ServicePrincipalName $env:clientId
$akvKey = Get-AzKeyVaultKey -VaultName $env:AKV -Name $akvKeyName
if ($akvKey) {
    Write-Host "keys were already created, exit"
    exit 0
}

$akvKey = Add-AzKeyVaultKey -VaultName $env:AKV -Name $akvKeyName -Destination "Software"

$userPassword = Get-AzKeyVaultSecret -VaultName $env:AKV -Name 'SQLPassword' -AsPlainText
$connStr = "Server = " + $env:SQLSERVER + ".database.windows.net; Database = " + $env:SQLDATABASE + "; User ID=" + $env:SQLLOGIN + ";Password='" + $userPassword + "';"
$databaseInstance = Get-SqlDatabase -ConnectionString $connStr

#$databaseInstance = Get-AzSqlDatabase -ResourceGroupName $env:RG -ServerName $env:SQLSERVER -DatabaseName $env:SQLDATABASE -ErrorAction SilentlyContinue
# Create a SqlColumnMasterKeySettings object for your column master key. 
$cmkSettings = New-SqlAzureKeyVaultColumnMasterKeySettings -KeyURL $akvKey.Key.Kid

# Create column master key metadata in the database.
$cmkName = "CMK_Auto1"
New-SqlColumnMasterKey -Name $cmkName -InputObject $databaseInstance -ColumnMasterKeySettings $cmkSettings

# Authenticate to Azure
Add-SqlAzureAuthenticationContext -ClientID $env:clientId -Secret $env:clientSecret -Tenant $env:tenantId

# Generate a column encryption key, encrypt it with the column master key and create column encryption key metadata in the database. 
$cekName = "CEK_Auto1"
New-SqlColumnEncryptionKey -Name $cekName -InputObject $databaseInstance -ColumnMasterKey $cmkName
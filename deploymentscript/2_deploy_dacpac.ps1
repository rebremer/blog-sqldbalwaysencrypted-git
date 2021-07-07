#
# 2. Powershell to deploy dacpac to SQLDB
# 
# 
# Todo: Create service principal and grant Service principal access to key vault where CMK is stored
# See here how to create service principal: https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-6.2.0
# Modify policy below to grant service principal access to key vault to get CMK (see also script 1_create_cmk_cek_akv.ps1)
#Set-AzKeyVaultAccessPolicy -VaultName $akvName -ResourceGroupName $resourceGroup -PermissionsToKeys get, create, delete, list, wrapKey,unwrapKey, sign, verify -UserPrincipalName $azureCtx.Account
$clientId = "<<your client id of SPN>>"
$clientSecret= "<<your client secret>>"
$subscriptionId = "<<your subscription id>>"
$tenantId = "<<your tenant id>>"
$serverName = "<<your sql server name>>.database.windows.net"
$databaseName = "test-dacpac-sql"
az login --service-principal --username $clientId --password $clientSecret --tenant $tenantId
$token = az account get-access-token --resource=https://database.windows.net/ --subscription $subscriptionId --query accessToken --output tsv
./sqlpackage.exe /sf:"data\test-dacpac-sql.dacpac" /AccessToken:$token /a:Publish /tcs:"Server = $serverName; Database = $databaseName; Column Encryption Setting=enabled;" /p:BlockOnPossibleDataLoss=false /AzureKeyVaultAuthMethod:ClientIdSecret /ClientId:$clientId /Secret:$clientSecret /p:ExcludeObjectType="ColumnEncryptionKeys" /p:ExcludeObjectType="ColumnMasterKeys"
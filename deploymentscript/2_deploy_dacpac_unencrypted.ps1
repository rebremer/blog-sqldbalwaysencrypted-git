#
# 2. Powershell to deploy dacpac to SQLDB
# 
# 
# Todo: Create service principal and grant Service principal access to key vault where CMK is stored
# See here how to create service principal: https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-6.2.0
# Modify policy below to grant service principal access to key vault to get CMK (see also script 1_create_cmk_cek_akv.ps1)

#$fileExe = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150\sqlpackage.exe"
$fileExe = "bin\sqlpackage.exe"

#az login --service-principal --username $env:clientId --password $env:clientSecret --tenant $env:tenantId
#$token = az account get-access-token --resource=https://database.windows.net/ --subscription $env:SUBSCRIPTIONID --query accessToken --output tsv

# todo: parameterize dacpac such that 1 dacpac deployment script is needed
#$params='/sf:"data\test-dacpac-sql-encrypted.dacpac" /a:Publish /AccessToken:' + $token + ' /tcs:"Server = ' + $env:SQLSERVER + '.database.windows.net; Database = ' + $env:SQLDATABASE + '; Column Encryption Setting=enabled;" /p:BlockOnPossibleDataLoss=false /AzureKeyVaultAuthMethod:ClientIdSecret /ClientId:' + $env:clientId + ' /Secret:' + $env:clientSecret + ' /p:ExcludeObjectType="ColumnEncryptionKeys" /p:ExcludeObjectType="ColumnMasterKeys"'
$userPassword = Get-AzKeyVaultSecret -VaultName $env:AKV -Name "SQLPassword" -AsPlainText
$params='/sf:"data\testdacpacsql-unencrypted.dacpac" /a:Publish /tcs:"Server = ' + $env:SQLSERVER + '.database.windows.net; Database = ' + $env:SQLDATABASE + '; User ID=' + $env:SQLLOGIN + ';Password="' + $userPassword + '"; Column Encryption Setting=enabled;" /p:BlockOnPossibleDataLoss=false /AzureKeyVaultAuthMethod:ClientIdSecret /ClientId:' + $env:clientId + ' /Secret:' + $env:clientSecret + ' /p:ExcludeObjectType="ColumnEncryptionKeys" /p:ExcludeObjectType="ColumnMasterKeys"'

$paramsSplit=$params.split(" ")
#
#Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $env:RG -ServerName $env:SQLSERVER -DisplayName $env:clientId
#
Write-Host $paramsSplit
& $fileExe $paramsSplit
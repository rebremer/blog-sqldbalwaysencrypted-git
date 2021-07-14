#
# 1. Powershell script to deploy SQLserver/SQLDB
# See https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-powershell
# 
#Connect-AzAccount
# The SubscriptionId in which to create these objects
# Set server name - the logical server name has to be unique in the system
# The sample database name
# The ip address range that you want to allow to access your server
Add-Type -AssemblyName 'System.Web'
# Don't do this in production situation. Rather, use private link or VNET service endpoint to access the database
$startIp = "0.0.0.0"
$endIp = "255.255.255.255"

$AKVInstance = Get-AzKeyVault -VaultName $env:AKV -ResourceGroupName $env:RG -ErrorAction SilentlyContinue
if (!$AKVInstance) {
    New-AzKeyVault -VaultName $env:AKV -ResourceGroupName $env:RG -Location $env:LOC # Creates a new key vault - skip if your vault already exists.
}
Set-AzKeyVaultAccessPolicy -VaultName $env:AKV -ResourceGroupName $env:RG -PermissionsToSecrets get, set, list -ServicePrincipalName $env:clientId

# Create a server with a system wide unique server name
$serverInstance = Get-AzSqlServer -ServerName $env:SQLSERVER -ResourceGroupName $env:RG -ErrorAction SilentlyContinue
if (!$serverInstance) {
    $userPassword = [System.Web.Security.Membership]::GeneratePassword(30,10)
    $secureUserPassword= ConvertTo-SecureString $userPassword -AsPlainText -Force
    #
    $server = New-AzSqlServer -ResourceGroupName $env:RG `
        -ServerName $env:SQLSERVER `
        -Location $env:LOC `
        -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:SQLLOGIN, $secureUserPassword)

    $akvSecret = Set-AzKeyVaultSecret -VaultName $env:AKV -Name "SQLPassword" -SecretValue $secureUserPassword
    #Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $env:RG -ServerName $env:SQLSERVER -DisplayName $azureCtx.Account.Id
}

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRuleInstance = Get-AzSqlServerFirewallRule -ResourceGroupName $env:RG -ServerName $env:SQLSERVER -FirewallRuleName "AllowedIPs" -ErrorAction SilentlyContinue
if (!$serverFirewallRuleInstance) {
    $serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $env:RG `
        -ServerName $env:SQLSERVER `
        -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
}

# Create a blank database with an S0 performance level
$databaseInstance = Get-AzSqlDatabase -ResourceGroupName $env:RG -ServerName $env:SQLSERVER -DatabaseName $env:SQLDATABASE -ErrorAction SilentlyContinue
if (!$databaseInstance) {
    $database = New-AzSqlDatabase  -ResourceGroupName $env:RG `
        -ServerName $env:SQLSERVER `
        -DatabaseName $env:SQLDATABASE `
        -Edition "GeneralPurpose" -Vcore 2 -ComputeGeneration "Gen5"
}
# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName

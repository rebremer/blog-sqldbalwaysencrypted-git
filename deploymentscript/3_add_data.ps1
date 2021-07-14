#
# 3. Add data to dbo.patient using ADFv2
# 
# See this link how to configure always encrypted in ADFv2: https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-sql-database#linked-service-properties
# In this pipeline, data is added using PowerShell
#
#
$sqlConn = New-Object System.Data.SqlClient.SqlConnection
$userPassword = Get-AzKeyVaultSecret -VaultName $env:AKV -Name "SQLPassword" -AsPlainText
#$sqlConn.ConnectionString = 'Server = ' + $env:SQLSERVER + '.database.windows.net; Database = ' + $env:SQLDATABASE + '; Column Encryption Setting=enabled;'
$sqlConn.ConnectionString = 'Server = ' + $env:SQLSERVER + '.database.windows.net; User ID=' + $env:SQLLOGIN + ';Password="' + $userPassword + '";Database = ' + $env:SQLDATABASE + '; Column Encryption Setting=enabled;'
#$sqlConn.AccessToken = $($token)
$sqlConn.Open()
$sqlcmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $sqlConn
$sqlcmd.CommandText = "INSERT INTO [dbo].[Patients] (SSN, FirstName, LastName, BirthDate) VALUES (@Param1, @Param2, @Param3, @Param4)"
$sqlcmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Param1",[Data.SQLDBType]::Char,11)))
$sqlcmd.Parameters["@Param1"].Value = "12345678901"
$sqlcmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Param2",[Data.SQLDBType]::VarChar,50)))
$sqlcmd.Parameters["@Param2"].Value = "Rene"
$sqlcmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Param3",[Data.SQLDBType]::VarChar,50)))
$sqlcmd.Parameters["@Param3"].Value = "Bremer"
$sqlcmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Param4",[Data.SQLDBType]::Date)))
$sqlcmd.Parameters["@Param4"].Value = "1980-05-15"
$sqlcmd.ExecuteNonQuery();
$sqlConn.Close()
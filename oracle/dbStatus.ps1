add-type -AssemblyName System.Data.OracleClient

$username = "JLUTSEY"
$securedValue = Get-Content -Path "Microsoft.PowerShell.Core\FileSystem::\\neen-dsk-011\it$\database\users\James\JamesDownloads\Tickets\PDU014216_04172019.txt" | ConvertTo-SecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
$data_source = Read-Host "database"
$connection_string = "User Id=$username;Password=$password;Data Source=$data_source"

$statement = "select instance_name||': '||status from " + 'v$instance'

try{
    $con = New-Object System.Data.OracleClient.OracleConnection($connection_string)

    $con.Open()

    $cmd = $con.CreateCommand()
    $cmd.CommandText = $statement

    $result = $cmd.ExecuteOracleScalar()
    Write-Host $result.Value

} 
catch {
    Write-Error ("Database Exception: {0}`n{1}" -f `
        $con.ConnectionString, $_.Exception.ToString())
} 
finally {
    if ($con.State -eq 'Open') { $con.close() }
}
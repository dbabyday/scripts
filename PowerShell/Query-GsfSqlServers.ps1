$SqlServers = @()
$SqlServers += "acc-sql-dv-001"
$SqlServers += "dcc-sql-dv-017"
$SqlServers += "acc-sql-ts-006"
$SqlServers += "dcc-sql-ts-003"
$SqlServers += "acc-sql-qa-004"
$SqlServers += "dcc-sql-qa-010"
$SqlServers += "xia-sql-qa-008"
$SqlServers += "acc-sql-qa-003"
$SqlServers += "dcc-sql-qa-009"
$SqlServers += "xia-sql-qa-007"
$SqlServers += "acc-sql-pd-001"
$SqlServers += "gcc-sql-pd-023"
$SqlServers += "xia-sql-pd-011"
$SqlServers += "acc-sql-pd-008"
$SqlServers += "gcc-sql-pd-019"
$SqlServers += "xia-sql-pd-010"


$SqlServers | ForEach-Object{
	$_

        $sqlconn = new-object System.Data.SqlClient.SqlConnection("server=$_;Trusted_Connection=true");
        $query = "SELECT COUNT(*) FROM sys.tables WHERE name=N'tempdb_SpaceUsed';"

        $sqlconn.Open()
        $sqlcmd = new-object System.Data.SqlClient.SqlCommand ($query, $sqlconn);
        $sqlcmd.CommandTimeout = 0;
        $dr = $sqlcmd.ExecuteReader();

        while ($dr.Read()) 
        { 
        	$dr.GetValue(0);
        }

        $dr.Close()
        $sqlconn.Close()
}

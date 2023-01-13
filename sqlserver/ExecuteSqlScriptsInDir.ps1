# run as .admin account (our reglar named accounts do not have database privileges)

$sqlFileDir="\\neen-dsk-011\it$\database\users\James\JamesDownloads\CTASK072673\GSF"
$logFileDir="\\neen-dsk-011\it$\database\users\James\JamesDownloads\CTASK072673\GSF\out"
$server="Gcc-sql-pd-025"
$database="Pirates_PROD "

Get-ChildItem –Path $sqlFileDir -Recurse -Filter *.sql | 
    Sort-Object FullName |
    Foreach-Object {
        $file=$_.Name
        $sqlFile=$_.FullName
        $logFile=$logFileDir + '\' + ($file).Replace(".sql",".log")
        sqlcmd -S $server -d $database -e -I -i $sqlFile -o $logFile
    }
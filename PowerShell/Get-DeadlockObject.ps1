param (
    [Parameter(Mandatory=$true)]
    [string]$FilePath
)

if (Test-Path $FilePath) {
    [xml]$deadlockXml = Get-Content $FilePath

    # 1. Identify the Victim ID
    $victimId = $deadlockXml.deadlock.'victim-list'.victimProcess.id

    # 2. Create a lookup table to map internal process IDs (e.g., process24bc...) to SPIDs (e.g., 379)
    $processMap = @{}
    $deadlockXml.deadlock.'process-list'.process | ForEach-Object {
        $processMap[$_.id] = $_.spid
    }

    # 3. Extract the keylock resources involved in the actual conflict
    $conflictResources = $deadlockXml.deadlock.'resource-list'.keylock | Where-Object { $_.objectname -ne $null }
    
    # 4. Get IDs of only the processes directly involved in those specific locks
    $involvedProcessIds = $conflictResources.ChildNodes.owner.id + $conflictResources.ChildNodes.waiter.id | Select-Object -Unique

    Write-Host "`n"
    Write-Host "--- DEADLOCK CONFLICT OBJECTS ---" -ForegroundColor Cyan
    
    # Enrich the resource output by looking up the SPIDs for owners and waiters
    $resourceDisplay = foreach ($res in $conflictResources) {
        [PSCustomObject]@{
            ObjectName = $res.objectname
            IndexName  = $res.indexname
            LockMode   = $res.mode
            OwnerSPID  = $processMap[$res.'owner-list'.owner.id]
            WaiterSPID = $processMap[$res.'waiter-list'.waiter.id]
        }
    }
    $resourceDisplay | Format-Table -AutoSize

    # 5. Filter the process list to only show those in the deadlock cycle
    $processes = $deadlockXml.deadlock.'process-list'.process | Where-Object { $involvedProcessIds -contains $_.id }

    foreach ($proc in $processes) {
        $frame = $proc.executionStack.frame
        
        if ($proc.id -eq $victimId) {
            Write-Host "--- VICTIM (Rolled Back) ---" -ForegroundColor Red
        }
        else {
            Write-Host "--- WINNER (Committed) ---" -ForegroundColor Green
        }

        [PSCustomObject]@{
            SPID       = $proc.spid
            Procedure  = $frame.procname
            LockMode   = $proc.lockMode
            Isolation  = $proc.isolationlevel
            SQLQuery   = ($frame.'#text' -replace '\s+', ' ').Trim()
        } | Format-List
    }
}
else {
    Write-Error "File not found: $FilePath"
}
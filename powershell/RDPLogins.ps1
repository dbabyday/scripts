function Get-PLXSRdpSessions {
param (
      [parameter(mandatory=$true,parametersetname="filepath")]     [string]$filepath
    , [parameter(mandatory=$true,parametersetname="computername")] [string[]]$computername
    , [parameter(mandatory=$true,ValueFromPipeline=$true)]         [string]$username
)
    begin {
        if ($filepath) {
            $computername = Get-Content $filepath
        }
        $qty = $computername.count;
        $count = 1;
        $loggedIn = New-Object System.Collections.Generic.List[System.Object]
        $username = "*" + $username + "*";
    } # begin

    process {
        # Loop through the list to query each server for login sessions
        ForEach ($c in $computername) 
        {
            Write-Host (get-date) "- checking $count of $qty : $c";

            $queryResults = (qwinsta /server:$c)

            # check if the account is in the results
            if ($queryResults -like $username)
            {
                # add the computer to the list
                $loggedIn.Add($c);
            }

            $count++;
        }
    } # process
    end {
        # display the results
        Write-Host "";
        Write-Host "";
        Write-Host "";
        Write-Host "-----------------------------------------------";
        Write-Host "--// logged in by $username";
        Write-Host "-----------------------------------------------";
        Write-Host "";
        if ($loggedIn.count -eq 0)
        {
            Write-Host "none";
        }
        else
        {
            $loggedIn;
        }
    } # end
} # function



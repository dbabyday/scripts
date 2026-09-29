Resolve-CNameHost -CNames $gsfCnames -SortBy Environment, Workload, Region | Format-Table -AutoSize
#Resolve-CNameHost -CNames $gsfCnames -Region 'APAC', 'AMER' -SortBy Region, Environment | Format-Table -AutoSize
#Resolve-CNameHost -CNames $gsfCnames -Environment 'PROD' -SortBy Region, Workload | Format-Table -AutoSize
#Resolve-CNameHost -CNames $gsfCnames -Workload 'OLTP' -Region 'APAC' -SortBy @{Expression='CNAME'; Descending=$true} | Format-Table -AutoSize

Resolve-CNameHost -CNames $wmsCnames -SortBy Environment, Region | Format-Table -AutoSize
#Resolve-CNameHost -CNames $wmsCnames -Region 'APAC', 'AMER' -SortBy Region, Environment | Format-Table -AutoSize
#Resolve-CNameHost -CNames $wmsCnames -Environment 'PROD' -SortBy Region, Workload | Format-Table -AutoSize
#Resolve-CNameHost -CNames $wmsCnames -Workload 'OLTP' -Region 'APAC' -SortBy @{Expression='CNAME'; Descending=$true} | Format-Table -AutoSize

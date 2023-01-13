""
Get-Date -format s
'$source = ' + $source
'$destination = ' + $destination
$x = (Get-ChildItem $source -recurse | Measure-Object -property length -sum)
"{0:N2}" -f ($x.sum / 1MB) + " MB Total"
$y = (Get-ChildItem $destination -recurse | Measure-Object -property length -sum)
"{0:N2}" -f ($y.sum / 1MB) + " MB Moved"
"{0:N2}" -f (($x.sum - $y.sum) / 1MB) + " MB Remaining"
"{0:N0}" -f ($y.sum / $x.sum * 100) + "% complete"
""
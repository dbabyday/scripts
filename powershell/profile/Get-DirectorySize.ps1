([math]::Round((Get-ChildItem -Recurse | Measure-Object -Sum Length).Sum/1024/1024,0)).ToString() + ' MB'
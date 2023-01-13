<########################################################################
# 
# Refresh local working directories from my (james.lutsey) network share
#     - use after returning from WFH
# 
########################################################################>


$localDocumentation = 'C:\JamesDocumentation'
$localProjects      = 'C:\JamesProjects'
$localScripts       = 'C:\JamesScripts'
$shareDocumentation = '\\neen-dsk-010\users24$\james.lutsey\JamesDocumentation'
$shareProjects      = '\\neen-dsk-010\users24$\james.lutsey\JamesProjects'
$shareScripts       = '\\neen-dsk-010\users24$\james.lutsey\JamesScripts'


#--------------------------------------
#--// CLEAR OUT LOCAL DIRECTORIES  //--
#--------------------------------------

Get-ChildItem -Path $localDocumentation | ForEach {
	$p = $_.FullName
	Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
}

Get-ChildItem -Path $localProjects | ForEach {
	$p = $_.FullName
	Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
}

Get-ChildItem -Path $localScripts | ForEach {
	$p = $_.FullName
	Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
}


#--------------------------------------
#--// COPY FROM SHARE TO LOCAL     //--
#--------------------------------------

Get-ChildItem -Path $shareDocumentation | ForEach {
	$p = $_.FullName
	Copy-Item -Path $p -Destination $localDocumentation -Recurse
}

Get-ChildItem -Path $shareProjects | ForEach {
	$p = $_.FullName
	Copy-Item -Path $p -Destination $localProjects -Recurse
}

Get-ChildItem -Path $shareScripts | ForEach {
	$p = $_.FullName
	Copy-Item -Path $p -Destination $localScripts -Recurse
}






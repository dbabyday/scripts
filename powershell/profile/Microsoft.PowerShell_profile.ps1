



#-------------------------------------
# DISPLAY
#-------------------------------------

# directory
Set-Location -Path \\neen-dsk-011\it$\database\users\James\JamesScripts

# window title
$Shell = $Host.UI.RawUI
if ( $env:USERNAME -eq "james.lutsey" ) {
	$Shell.WindowTitle="james"
}
elseif ( $env:USERNAME -eq "james.lutsey.admin" ) {
	$Shell.WindowTitle=".admin"
}

# display prompt
function prompt { 
	if ($PWD.Path -match "\\\\neen-dsk-011\\it\$\\database\\users\\James") {
		if ( $env:USERNAME -eq "james.lutsey.admin" ) {
			"(.admin)PS ~" + $PWD.Path.Substring($PWD.Path.IndexOf("\James") + 6, $PWD.Path.Length - $PWD.Path.IndexOf("\James") - 6) + "> " 
		}
		else {
			"PS ~" + $PWD.Path.Substring($PWD.Path.IndexOf("\James") + 6, $PWD.Path.Length - $PWD.Path.IndexOf("\James") - 6) + "> " 
		}
	}
	else {
		if ( $env:USERNAME -eq "james.lutsey.admin" ) {
			"(.admin)PS " + $PWD.Path + "> ";
		}
		else {
			"PS " + $PWD.Path + "> ";
		}
		
	}
}




#-------------------------------------
# PREP
#-------------------------------------

# directory for files used to create functions and aliases
$profileDir="\\neen-dsk-011\it$\database\users\James\JamesScripts\PowerShell\profile"




#-------------------------------------
# VARIABLES FOR QUICK REFERENCE
#-------------------------------------

$dbadoc="\\neen-dsk-011\IT$\database\DBA Plexus\OneNote\SQLDBA\SQL Server.one"
. $profileDir\Set-VariableYeti.ps1


#-------------------------------------
# FUNCTIONS
#-------------------------------------

#. $profileDir\Get-PathEnvironmentVariable.ps1
. $profileDir\Connect-Psftp.ps1
. $profileDir\Connect-Sqlplus.ps1
. $profileDir\Get-DriveSpace.ps1
. $profileDir\Get-LocalGroupMembers.ps1
. $profileDir\Get-Services.ps1
. $profileDir\Publish-SsisIsPac.ps1
. $profileDir\Start-PowerShellAsAdmin.ps1
. $profileDir\Start-SsmsAsAdmin.ps1
. $profileDir\Start-Ssms18AsAdmin.ps1
. $profileDir\Update-FileLineEndingsUnix.ps1

#-------------------------------------
# ALIASES
#-------------------------------------

# change directories
if (-Not (Get-Alias -Name home -ErrorAction SilentlyContinue)) { Set-Alias -Name home -Value "$profileDir\Set-LocationHome.ps1" }
if (-Not (Get-Alias -Name doc  -ErrorAction SilentlyContinue)) { Set-Alias -Name doc  -Value "$profileDir\Set-LocationDocumentation.ps1" }
if (-Not (Get-Alias -Name dl   -ErrorAction SilentlyContinue)) { Set-Alias -Name dl   -Value "$profileDir\Set-LocationDownloads.ps1" }
if (-Not (Get-Alias -Name p    -ErrorAction SilentlyContinue)) { Set-Alias -Name p    -Value "$profileDir\Set-LocationProjects.ps1" }
if (-Not (Get-Alias -Name q    -ErrorAction SilentlyContinue)) { Set-Alias -Name q    -Value "$profileDir\Set-LocationQueryTuning.ps1" }
if (-Not (Get-Alias -Name s    -ErrorAction SilentlyContinue)) { Set-Alias -Name s    -Value "$profileDir\Set-LocationScripts.ps1" }

# directory/file/drive info
if (-Not (Get-Alias -Name dirs     -ErrorAction SilentlyContinue)) { Set-Alias -Name dirs     -Value "$profileDir\Get-Directories.ps1" }
if (-Not (Get-Alias -Name dirsize  -ErrorAction SilentlyContinue)) { Set-Alias -Name dirsize  -Value "$profileDir\Get-DirectorySize.ps1" }
if (-Not (Get-Alias -Name fn       -ErrorAction SilentlyContinue)) { Set-Alias -Name fn       -Value "$profileDir\Get-ChildItemFullName.ps1" }
if (-Not (Get-Alias -Name gds      -ErrorAction SilentlyContinue)) { Set-Alias -Name gds      -Value "Get-DriveSpace" }
if (-Not (Get-Alias -Name ll       -ErrorAction SilentlyContinue)) { Set-Alias -Name ll       -Value "$profileDir\Get-ChildItemSortName.ps1" }
if (-Not (Get-Alias -Name lt       -ErrorAction SilentlyContinue)) { Set-Alias -Name lt       -Value "$profileDir\Get-ChildItemSortLastWriteTime.ps1" }
if (-Not (Get-Alias -Name glogin   -ErrorAction SilentlyContinue)) { Set-Alias -Name glogin   -Value "$profileDir\Get-glogin.ps1" }
if (-Not (Get-Alias -Name tnsnames -ErrorAction SilentlyContinue)) { Set-Alias -Name tnsnames -Value "$profileDir\Get-tnsnames.ps1" }
if (-Not (Get-Alias -Name ule      -ErrorAction SilentlyContinue)) { Set-Alias -Name ule      -Value "Update-FileLineEndingsUnix" }

# open applicaitons
if (-Not (Get-Alias -Name ca     -ErrorAction SilentlyContinue)) { Set-Alias -Name ca     -Value "$profileDir\Open-CyberArk.ps1" }
if (-Not (Get-Alias -Name cv     -ErrorAction SilentlyContinue)) { Set-Alias -Name cv     -Value "$profileDir\Start-CommVault.ps1" }
if (-Not (Get-Alias -Name dbadoc -ErrorAction SilentlyContinue)) { Set-Alias -Name dbadoc -Value "$profileDir\Open-DbaDocumentation.ps1" }
if (-Not (Get-Alias -Name np     -ErrorAction SilentlyContinue)) { Set-Alias -Name np     -Value "C:\Program Files\Notepad++\notepad++.exe" }
if (-Not (Get-Alias -Name psa    -ErrorAction SilentlyContinue)) { Set-Alias -Name psa    -Value "Start-PowerShellAsAdmin" }
if (-Not (Get-Alias -Name rdp    -ErrorAction SilentlyContinue)) { Set-Alias -Name rdp    -Value "$profileDir\Open-RDP.ps1" }
if (-Not (Get-Alias -Name ssms   -ErrorAction SilentlyContinue)) { Set-Alias -Name ssms   -Value "Start-SsmsAsAdmin" }
if (-Not (Get-Alias -Name ssms18 -ErrorAction SilentlyContinue)) { Set-Alias -Name ssms18 -Value "Start-Ssms18AsAdmin" }
if (-Not (Get-Alias -Name subl   -ErrorAction SilentlyContinue)) { Set-Alias -Name subl   -Value "C:\Program Files\Sublime Text\sublime_text.exe" }
if (-Not (Get-Alias -Name tm     -ErrorAction SilentlyContinue)) { Set-Alias -Name tm     -Value "$profileDir\Open-TeamMeetingOneNote.ps1" }
if (-Not (Get-Alias -Name toad   -ErrorAction SilentlyContinue)) { Set-Alias -Name toad   -Value "C:\Program Files\Quest Software\Toad for Oracle 2023 R1 Edition\Toad for Oracle 16.3\Toad.exe" }

# other
if (-Not (Get-Alias -Name c    -ErrorAction SilentlyContinue)) { Set-Alias -Name c    -Value "$profileDir\Clear-Clipboard.ps1" }
if (-Not (Get-Alias -Name gs   -ErrorAction SilentlyContinue)) { Set-Alias -Name gs   -Value "Get-Services" }
if (-Not (Get-Alias -Name gsf  -ErrorAction SilentlyContinue)) { Set-Alias -Name gsf  -Value "$profileDir\Get-GsfServers.ps1" }
if (-Not (Get-Alias -Name lock -ErrorAction SilentlyContinue)) { Set-Alias -Name lock -Value "$profileDir\Lock-Computer.ps1" }
if (-Not (Get-Alias -Name lgm  -ErrorAction SilentlyContinue)) { Set-Alias -Name lgm  -Value "Get-LocalGroupMembers" }
if (-Not (Get-Alias -Name psf  -ErrorAction SilentlyContinue)) { Set-Alias -Name psf  -Value "Connect-Psftp" }
if (-Not (Get-Alias -Name sj   -ErrorAction SilentlyContinue)) { Set-Alias -Name sj   -Value "Connect-Sqlplus" }
if (-Not (Get-Alias -Name y    -ErrorAction SilentlyContinue)) { Set-Alias -Name y    -Value "$profileDir\Set-ClipboardYeti" }




#-------------------------------------
# CLEAN UP
#-------------------------------------

Clear-Host
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
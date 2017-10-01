#########
## Functions for action BANNER
## @ Author Slimane Terkemani (zximsoget004)
#########

# Action : Delete the banner
Function delBanner ($serverNodeList, $arguments) {

	# Run each server to handle : all actions
	foreach ($Server in $serverNodeList) {
		
		LogWrite ""
		$log = $Server.Server_Name + " - " + $Server.Server
		LogWrite $log
		
		# Remove a banner only on Windchill nodes
		if (!($Server.Server_Name -eq "PDF")) {

			$File = "\\"+$server.server+"\ptc\Windchill_10.1\Windchill\codebase\netmarkets\jsp\util\banner.txt"

			Invoke-Expression "cmd /C ""copy NUL $File > NUL"" "			
			LogWrite "   Banner removed ..."
		}
	}		
}

# Action : Add a banner
Function addBanner ($serverNodeList, $arguments) {
		
	$message = $arguments[2]	
	if ( $message -eq $null ) {
		
		exitProgram -err "message must be filled"
	}
		 
	# Run each server to handle : all actions
	foreach ($Server in $serverNodeList) {
		
		LogWrite ""
		$log = $Server.Server_Name + " - " + $Server.Server
		LogWrite $log
		
		# Add a banner only on Windchill nodes
		if (!($Server.Server_Name -eq "PDF")) {

			$File = "\\"+$server.server+"\ptc\Windchill_10.1\Windchill\codebase\netmarkets\jsp\util\banner.txt"

			echo '<div id="maintenance_banner"' | Out-File $File
			echo 'style="position: absolute;background-color: red;top: 3px;z-index:1000;left: 300px;font-size: 1em;border:3;color:#f00;padding:6px;color: white">' | Out-File $File -Append
			echo '<center>' | Out-File $File -Append					
			echo $message | Out-File $File -Append										
			echo '</center>' | Out-File $File -Append										
			echo '</div>' | Out-File $File -Append										
			
			LogWrite "   Banner updated ..."
		}
	}		
}	


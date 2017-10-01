#########
## Functions for action CLEANCACHE
## @ Author Slimane Terkemani (zximsoget004)
#########

# Clean a folder
Function cleanFolder ($path) {
	
	LogWrite "cmd /C ""rmdir /S /Q $path"" "
	# Remove the folder : I don't use remove-item because sometimes it fails with long path.
	Invoke-Expression "cmd /C ""rmdir /S /Q $path"" "
	# Create the folder
	New-Item -ItemType Directory -Force -Path $path		
}
	
# Action to clean caches
Function doClean ($serverNodeList, $arguments) {

	# Get Selected server : default=CORES
	$selectedServer = echo $arguments[2]
	
	# ALL,PDF,CORES is not accepted as server
	if ($selectedServer -eq "PDF") {
		
		exitProgram -err "'PDF' is not accepted."	
	}	
	
	# Clean all selected server
	foreach ($serverNode in $serverNodeList) {
	
		if (($selectedServer -eq $null -or $selectedServer -eq "ALL" -or $selectedServer -eq "CORES" -or $serverNode.Server_Name -eq $selectedServer) -and !($serverNode.Server_Name -eq "PDF")) {
			
			$path = "\\"+ $serverNode.server + "\ptc\Windchill_10.1\Windchill\tomcat\instances"	
			cleanFolder -path $path

			$path = "\\"+ $serverNode.server + "\ptc\Windchill_10.1\Windchill\tasks\codebase\com\infoengine\compiledTasks\file"	
			cleanFolder -path $path

			$path = "\\"+ $serverNode.server + "\ptc\Windchill_10.1\Windchill\codebase\wt\workflow\expr"	
			cleanFolder -path $path				
		}		
	}	
}	


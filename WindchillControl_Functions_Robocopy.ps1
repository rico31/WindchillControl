#########
## Functions for action ROBOCOPY
## @ Author Slimane Terkemani (zximsoget004)
#########

# Action to robocopy windchill nodes		
Function doRobocopy ($serverNodeList, $arguments) {

	# Argument 4 : Server source
	$serverSource = echo $arguments[2]
	
	# Argument 5 : Server destination
	$serverDestination = echo $arguments[3]
	
	# ALL,PDF,CORES is not accepted as server
	if (($serverSource -eq "PDF") -or ($serverSource -eq "ALL") -or ($serverSource -eq "CORES") -or ($serverDestination -eq "PDF") -or ($serverDestination -eq "ALL") -or ($serverDestination -eq "CORES")) {
		
		exitProgram -err "'ALL', 'CORES' or 'PDF' are not accepted. Only a specific windchill windchill node"	
	}	
	
	# source and destination must be filled and different
	if (($serverSource-eq $null) -or ($serverDestination-eq $null) -or ($serverSource -eq $serverDestination)) { 
		
		exitProgram -err  "The source and destination servers must be filled and different"	
	}	
	
	# Get servers	
	$serverDestinationAdr = $null
	$serverSourceAdr = $null
	foreach ($serverNode in $serverNodeList)
	{					
						
		if ($serverNode.Server_Name -eq $serverSource) {
		
			$serverSourceAdr = $serverNode.server
		}
		
		if ($serverNode.Server_Name -eq $serverDestination) {
		
			$serverDestinationAdr = $serverNode.server
		}
	}  
	
	# Check if servers are found
	if ($serverSourceAdr -eq $null) {

		exitProgram -err  "The source server name '$serverSource' is not defined for the cluster '$clusterName'."	
	}

	if ($serverDestinationAdr -eq $null) {

		exitProgram -err  "The destination server name '$serverDestination' is not defined for the cluster '$clusterName'."	
	}
	
	# Run command
	$robocopyCmd = "robocopy \\"+$serverSourceAdr+"\ptc\Windchill_10.1 \\"+$serverDestinationAdr+"\ptc\Windchill_10.1 /MIR /R:1 /W:1 /XJ /LOG:C:\temp\roboCopyFrom"+$serverSource+"To"+$serverDestination+".log"
	LogWrite $robocopyCmd
	Invoke-Expression $robocopyCmd	
}	

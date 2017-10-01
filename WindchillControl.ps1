### This script is based on a xml document "clusterInfo.xml" and permits to handle cluster or monolithic windchill servers.

### ---  Current folder
$folder = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

### ---  Common Functions
. $folder/WindchillControl_Functions.ps1

### ---  Execution date begin
$date = Get-Date

### ---  Get Arguments

# mode interactive
$modeInteractive = 'true' # default value = true
if ($args -contains '-ni') {

	$modeInteractive = 'false'
	
	# remove the "-ni" of the list of arguments
	$argsList = New-Object System.Collections.ArrayList(,$args)
	$argsList.remove('-ni')
	$args = $argsList.toArray()	
}

# Argument 0 : Cluster name
$clusterName = echo $args[0]
$clusterName = $clusterName.toUpper()

# Argument 1 : Actions to do = status 
$action = echo $args[1]

### ---  Begin log
LogWrite ""
LogWrite "*****************************************************"
LogWrite "$date - WindchillControl.ps1 $args"
LogWrite "*****************************************************"

#Get Cluster Info
$clusterInfo = getClusterInfo
$isProductionServer = $clusterInfo.isProductionServer
$isBT1Server=$clusterInfo.isBT1Server
$isSameCluster = $clusterInfo.isSameCluster
$serverNodeList = $clusterInfo.serverNodeList
$logsPath = $clusterInfo.logsPath
$foldersPath = $clusterInfo.foldersPath
$acceptedClusters = $clusterInfo.acceptedClusters
$database = $clusterInfo.database
$fullVersion = $clusterInfo.fullVersion

### --- main
if ( ("help","-help","-h","usage","-usage","-u") -contains $clusterName ) {

	displayUsage
	exitProgram
}

# Cluster Info must be filled
if ($clusterName -eq $null) { 
		
	exitProgram -err  "The name of cluster must be filled."	
}

# Action must be filled
if ($action -eq $null) { 
		
	exitProgram -err  "The action must be filled."	
}

# Cluster Info not accepted
if (($serverNodeList -eq $null) -or (($serverNodeList | Measure-Object).count -eq 0)) {

	exitProgram -err "The cluster name '$clusterName' is not accepted."	
}

# Production mode security
if ($isProductionServer -eq 'true') {

	confirmAction -title "The selected cluster '$clusterName' is a PRODUCTION server" -modeInteractive $modeInteractive
}

# same cluster?
if ($isSameCluster -eq 'false') {

	confirmAction -title "The current server '$currentHost' doesn't belong to the selected cluster '$clusterName'" -modeInteractive $modeInteractive
}

# Execute Actions
if ($action -eq "status") { 
		
	doStatus -serverNodeList $serverNodeList -arguments $args -withDetail 'false' 
} elseif ($action -eq "fullstatus") { 
		
	doStatus -serverNodeList $serverNodeList -arguments $args -withDetail 'true' 
} elseif ($action -eq "start") { 
		
	doStart	-serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "stop") { 
		
	doStop	-serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "fullstop") { 
		
	doStop	-serverNodeList $serverNodeList -arguments $args -fullStop 'true'
} elseif ($action -eq "cleancache") { 
		 
	doClean	-serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "robocopy") { 
		
	doRobocopy -serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "delBanner") {

	delBanner -serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "addBanner") {

	addBanner -serverNodeList $serverNodeList -arguments $args
} elseif ($action -eq "checkStartup") {

	checkStartup -serverNodeList $serverNodeList -logsPath $logsPath -arguments $args
} elseif ($action -eq "clone") {
	
	if ($isBT1Server -eq 'False') {
	
		exitProgram -err  "The action 'CLONE' is only accepted on BT1 server"	
	} else {
		
		doClone -clusterName $clusterName -foldersPath $foldersPath -database $database -fullVersion $fullVersion -arguments $args
	}
} elseif ($action -eq "archiveLogs") {

    archiveLogs -logsPath $logsPath -arguments $args
} else {

	# Errors
	exitProgram -err  "The action '$action' is not autorized. Only following actions are accepted : STATUS, FULLSTATUS, START, STOP, FULLSTOP, CLEANCACHE, ROBOCOPY, ADDBANNER, DELBANNER, CHECKSTARTUP, CLONE, ARCHIVELOGS."		
}

exitProgram
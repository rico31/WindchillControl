#########
## Common functions
#########

# Current folder
$folder = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

### ---  Functions for Actions
. $folder/WindchillControl_Functions_CleanCache.ps1
. $folder/WindchillControl_Functions_Robocopy.ps1
. $folder/WindchillControl_Functions_Status.ps1
. $folder/WindchillControl_Functions_Stop.ps1
. $folder/WindchillControl_Functions_Start.ps1
. $folder/WindchillControl_Functions_Banner.ps1
. $folder/WindchillControl_Functions_CheckStartup.ps1
. $folder/WindchillControl_Functions_Clone.ps1
. $folder/WindchillControl_Functions_ArchiveLogs.ps1

# Cluster configuration
$clusterInfoFilePath = "$folder/clusterInfo.xml"

# Current server
$currentHost = Invoke-Command -ScriptBlock {hostname}

# Log file
$logFile = "c:/temp/WindchillControl.log"

# Backup Colors of shell
$defaultBg = $host.ui.rawui.BackgroundColor
$defaultFg = $host.ui.rawui.ForegroundColor

# Change the background of shell
$host.ui.rawui.BackgroundColor = 'Black'

# Define foreground color
$COLOR_LOG = 'White'
$COLOR_LOG_ERR = "Red"
$COLOR_LOG_WARN = "Yellow"
$COLOR_LOG_SUCCESS = "Green"

# Function : exit program with/without error logging
Function exitProgram ($err) {

	if ($err -ne $null) {
		
		LogError $err	
		
		# display usage
		displayUsage
	}		
	
	LogWrite "Program exited."
	
	# reset colors
	$host.ui.rawui.BackgroundColor = $defaultBg
	$host.ui.rawui.ForegroundColor = $defaultFg
		
	if ($err -ne $null) {
					
		exit 1
	} else {
	
		exit 0
	}
}

# Function : Write log
Function LogWrite {

   Param ($logstring, $color=$COLOR_LOG)
   write-host $logstring -foregroundcolor $color
   Add-content $logFile -value $logstring -ErrorAction SilentlyContinue
   Start-Sleep -m 100
}

# Function : Write Error log
Function LogError {
 
   param ($logstring)
   $msg = "ERROR - " + $logstring
   LogWrite $msg $COLOR_LOG_ERR   
}

# Function : Write Warning log
Function LogWarn {
 
   param ($logstring)
   $msg = "WARNING - " + $logstring
   LogWrite $msg $COLOR_LOG_WARN   
}

# Function : Write Success log
Function LogSuccess{
 
   param ($logstring)
   LogWrite $logstring $COLOR_LOG_SUCCESS   
}

# Function : display usage
Function displayUsage () {
	LogWrite ""
	LogWrite " USAGE : WindchillControl <CLUSTER_NAME> <ACTION + ARGUMENTS> <'Optional' INTERACTIVE MODE>"
	LogWrite ""
	LogWrite "      * A log is generated in the folder c:\temp of the host where is launched the WindchillControl."
	LogWrite ""
	LogWrite "  *** Authorized <CLUSTER_NAME> 'found in clusterInfo.xml'"
	LogWrite ""
	if (!($acceptedClusters -eq $null)) {		
		foreach ($acceptedCluster in $acceptedClusters.values) {			
			$msg = "       * "+$acceptedCluster.clusterName
			for($i=1; ($i + $acceptedCluster.clusterName.length) -le 70; $i++){$msg += " "}
			$msg += " "
			$msg += ": "+$acceptedCluster.instanceName
			LogWrite $msg			
		}
	}
	LogWrite ""
	LogWrite "  *** Authorized <ACTION> "
	LogWrite ""
	LogWrite "      * STATUS"
	LogWrite "           - <ARG 1> = < 'Optional except if other arguments' SELECTED_SERVER>  : ALL (default), PDF, CORES and all windchill nodes (BT1, BT2, ...)."
	LogWrite "           - <ARG 2> = < 'Optional except if other arguments' SELECTED_SERVICE> : ALL (default), serviceWDS, serviceMaster, serviceApache,"
	LogWrite "                                                                                  serviceWindchill, servicePartsLink, serviceCognos, "
	LogWrite "                                                                                  serviceAdobe, serviceAdobeDB, serviceAdobeWorker, serviceDSMCore." 			
	LogWrite "      * FULLSTATUS"
	LogWrite "           - same <ARGUMENTS> than action STATUS"		
	LogWrite "      * START"
	LogWrite "           - same <ARGUMENTS> than action STATUS"		
	LogWrite "      * STOP"
	LogWrite "           - same <ARGUMENTS> than action STATUS"		
	LogWrite "      * FULLSTOP"
	LogWrite "           - same <ARGUMENTS> than action STATUS"		
	LogWrite "      * CLEANCACHE"
	LogWrite "           - <ARG 1> = < 'Optional except if other arguments' SELECTED_SERVER>  : ALL (default), CORES and all windchill nodes (BT1, BT2, ...)."
	LogWrite "                                                                                  node PDF not authorized."	
	LogWrite "      * ROBOCOPY"
	LogWrite "           - <ARG 1> = <SOURCE_SERVER>                                          : A specific windchill node."
	LogWrite "           - <ARG 2> = <DESTINATION_SERVER>                                     : A specific windchill node."	
	LogWrite "      * ADDBANNER"
	LogWrite "           - <ARG 1> = <MESSAGE>                                                : Message to display (between double quot)."
	LogWrite "                                                                                  Accept HTML syntax."	
	LogWrite "      * DELBANNER"
	LogWrite "           - no arguments (or interactive mode)"	
	LogWrite "      * CHECKSTARTUP"
	LogWrite "           - <ARG 1> = <DATE>                                                   : Date (Format: dd/MM/yyyy hh:MM)"
	LogWrite "           - <ARG 2> = < 'Optional except if other arguments' STACK TRACE>      : True | False (Default value)"	
	LogWrite "      * CLONE"
	LogWrite "           - <ARG 1> = <DATABASE system user>                                   : LOGIN"
	LogWrite "           - <ARG 2> = <DATABASE system user>                                   : PASSWORD"	
	LogWrite "      * ARCHIVELOGS"
    LogWrite "           - <ARG 1> = <OPERATION>                                              : COPY, MOVE or LIST"
	LogWrite "                - COPY                                                          : The operation executed is a copy from source to destination."
	LogWrite "                                                                                  Means that files are keep on source"    
    LogWrite "                - MOVE                                                          : The operation executed is a move from source to destination."
	LogWrite "                                                                                  Means that files are not keep on source" 
    LogWrite "                - LIST                                                          : Undo mode: no action are done on files, but list all files"
	LogWrite "                                                                                  candidats to operation."
	LogWrite "                                                                                  If not already existing, destination folders are created by this mode" 
	LogWrite "           Description"
	LogWrite "                - Manage Connect Windchill Corporate Logs files( Apache and Windchill) from all cluster nodes involved."    
    LogWrite "                - For each file from Apache or Windchill folder source, copy or move them to Apache or Windchill destination folder."
    LogWrite "                - Each file must match a rule linked to its last modified date:"
    LogWrite "                     - For Apache : takes all files modified 1 day ago (hard coding)"
    LogWrite "                     - For Windchill: take all files modified 7 days ago"
    LogWrite ""
	LogWrite "  *** <INTERACTIVE MODE>"
	LogWrite "      * By default interactive mode is flaged to true."
	LogWrite "        If you don't want interactive mode (only for scheduled tasks), please add the argument '-ni' anywhere"    
	LogWrite "        Example :"    
	LogWrite "             - WindchillControl PDM-INT02 fullstop -ni"    
	LogWrite "             - WindchillControl PDM-INT02 stop -ni BT1 serviceMaster"    
	LogWrite "             - WindchillControl PDM-INT02 stop BT1 serviceMaster -ni"
	LogWrite " *** End of usage "
}	

# Function confirm
Function confirmAction($title,$modeInteractive) {
	
	if (!($modeInteractive -eq 'false')) {
	
		$message = "Could you confirm your action?"

		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "The action is canceled."
	
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "The action is confirmed."	
	
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($no,$yes)

		$result= $host.ui.PromptForChoice($title, $message, $options, 0) 
	
		if ($result -eq 0) {
	
			LogWrite "Operation canceled..."
			exitProgram
		}
	}
}

# Function : Get cluster info
Function getClusterInfo () {
		
	$serverNodeList = New-Object System.Collections.Specialized.OrderedDictionary	
	# Is current host belong to selected cluster
	$isSameCluster = 'false';
	# Is current host equals BT1
	$isBT1Server = 'false';
	
	# Cluster configuration file	
	[xml]$clusterInfoFile = Get-Content $clusterInfoFilePath		
	$cluster = $(Select-Xml "//ClusterInfo/Cluster[@name='$clusterName']" $clusterInfoFile).node			
	
	if (!($cluster -eq $null)) { 
		
		# Production or not production cluster
		$isProductionServer = $cluster.isProductionServer
		
		# is cluster handle by this script
		$WindchillControl = $cluster.WindchillControl
		
		if ($WindchillControl -eq "true") {
		
			# Servers of cluster
            $i = 0	
			foreach ($serverNode in $cluster.ServerNode)
			{
				
				# is host belong to the selected cluster
				if ($serverNode.server -Match $currentHost) {
				
					$isSameCluster = 'true'
					if ($serverNode.name -eq 'BT1') {
						
						$isBT1Server = 'true'
					}					
				}
				
				# List of servers / services
				$serverNodeList.add($i, 
					@{  Server_Name = $serverNode.name; 
						Server = $serverNode.server; 					
						ServiceWDS = $serverNode.Services.WDS;
						ServiceMaster = $serverNode.Services.MasterServerManager;
						ServiceApache = $serverNode.Services.Apache;
						ServiceWindchill = $serverNode.Services.Windchill;
						ServicePartsLink = $serverNode.Services.PartsLink;
						ServiceCognos = $serverNode.Services.Cognos;
						ServiceDSMCore = $serverNode.Services.DSMCore;
						ServiceAdobe = $serverNode.Services.Adobe;
						ServiceAdobeDB = $serverNode.Services.AdobeDB;
						ServiceAdobeWorker = $serverNode.Services.AdobeWorker
						
					})				
				
				$i = $i + 1							
			}  
			
			#Logs
			$logsPath = New-Object System.Collections.Specialized.OrderedDictionary
			$indexLog = 0
			foreach ($log in $cluster.Logs.log)
			{			                
				$logsPath.add($indexLog,
                    @{  node = $log.node;
                        category = $log.category;
                        folder = $log.folder;
                        archive = $log.archive
                    })
				$indexLog = $indexLog + 1;
			}
			
			#Folders
			$foldersPath = New-Object System.Collections.Specialized.OrderedDictionary
			$indexFolder = 0
			foreach ($folder in $cluster.Folders.Folder)
			{						
				$foldersPath.add($indexFolder,
					@{	name = $folder.name;
						location = $folder.location;						
					})
				$indexFolder = $indexFolder + 1;
			}
			
			#Database
			$database = @{ ServerName = $cluster.Database.ServerName; ServerPort = $cluster.Database.ServerPort; ServerSID = $cluster.Database.ServerSID }
			
		}
	}
	
	# List of all accepted cluster
	$allClusters = $clusterInfoFile.clusterInfo.cluster | select name, WindchillControl, instanceName
	$acceptedClusters = New-Object System.Collections.Specialized.OrderedDictionary
	$indexAcceptedCluster = 0
	if (!($allClusters -eq $null)) { 
			
		# Servers of cluster
		foreach ($clusterNode in $allClusters) {
		
			# is cluster handle by this script	
			if ($clusterNode.WindchillControl -eq "true") {
				$acceptedClusters.add($indexAcceptedCluster,
					@{	clusterName = $clusterNode.name;
						instanceName = $clusterNode.instanceName
					})
				$indexAcceptedCluster = $indexAcceptedCluster + 1;
			}
		}
	}
	
	# Result
	return @{isBT1Server=$isBT1Server;isSameCluster=$isSameCluster;isProductionServer=$isProductionServer;serverNodeList=$serverNodeList.values;logsPath=$logsPath;acceptedClusters=$acceptedClusters;foldersPath=$foldersPath;database=$database;fullVersion=$cluster.fullVersion}
}



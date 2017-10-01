#########
## Functions for action START
## @ Author Slimane Terkemani (zximsoget004)
#########

# Check Authorized service
Function checkService ($windowsService) {

	# Authorized service
	if ( !($windowsService -eq $null -or $windowsService -eq "ALL" -or $windowsService -eq "ServiceWDS" -or $windowsService -eq "ServiceMaster" -or $windowsService -eq "ServiceApache" -or $windowsService -eq "ServiceWindchill" -or $windowsService -eq "ServicePartsLink" -or $windowsService -eq "ServiceCognos" -or $windowsService -eq "ServiceDSMCore" -or $windowsService -eq "ServiceAdobe" -or $windowsService -eq "ServiceAdobeWorker") ) { 
					
		exitProgram -err  "The service '$windowsService' is not accepted."	
	}	
}

# Function : Log the status of a service
Function startService($serverName, $serverAddr, $serviceName, $serviceKey, $withDetail) {
	
	if (!($serviceName -eq $null)) {
	
		# Get service
		$Service_Windows = Get-Service -computername $serverAddr -name $serviceName -ErrorAction silentlycontinue -ErrorVariable err
		
		# Check error
		if ($Service_Windows -eq $null) {
						
			exitProgram -err  "   $serviceName - $err"
		} else {
				
			if ( $Service_Windows.Status -eq 'RUNNING' ) {
			
				# Warning if already started			
				LogWarn "   Service $serviceName already started"
			} elseif ( $Service_Windows.Status -eq 'STOPPED' ) {
			
				# Error if process still linked to a stopped service
				$process = Get-WmiObject -Class Win32_Service -computername $serverAddr | where {$_.name -eq $serviceName} | ForEach-Object {$processId = $_.ProcessId; gwmi Win32_Process -computername $serverAddr | where {$_.handle -eq $ProcessId} | Select processId,executablePath,CreationDate,CommandLine}				
				if (!($process -eq $null -or $process.processId -eq "0")) {
		
					exitProgram -err  "   Service $serviceName is stopped but process are still linked"
				}
				
				# start
				Start-Service -inputobject $Service_Windows
				$Service_Windows.WaitForStatus('Running', '00:01:00')
				$StatusDisplay = "Starting" + " - " + [String]$serverName + " - " + [String]$Service_Windows.Name 
				LogWrite $StatusDisplay	
			} else {
			
				exitProgram -err  "   Service $serviceName in status $Service_Windows.Status"
			}
		} 
	}
}

# Action : start
Function doStart ($serverNodeList, $arguments) {
	
	# Argument 4 : selected server
	$selectedServer = echo $arguments[2]
	
	# Argument 5 : selected service
	$selectedService = echo $arguments[3]
	
	# Check authorized service
	checkService -windowsService $selectedService	
	
	# Run each server to handle : all actions
	foreach ($Server in $serverNodeList) {
		
		LogWrite ""
		$log = $Server.Server_Name + " - " + $Server.Server
		LogWrite $log
		
		# Check server
		if ($selectedServer -eq $null -or $selectedServer -eq "ALL" -or $Server.Server_Name -eq $selectedServer -or ($selectedServer -eq "CORES" -and !($Server.Server_Name -eq "PDF"))) {

			# Check service
			if ($selectedService -eq $null -or $selectedService -eq "ALL") {
							
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWDS -serviceKey "ServiceWDS" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceApache -serviceKey "ServiceApache"  -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceMaster -serviceKey "ServiceMaster" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWindchill -serviceKey "ServiceWindchill" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServicePartsLink -serviceKey "ServicePartsLink" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceCognos -serviceKey "ServiceCognos" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceDSMCore -serviceKey "ServiceDSMCore" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobe -serviceKey "ServiceAdobe" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeDB -serviceKey "ServiceAdobeDB" -withDetail $withDetail
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeWorker -serviceKey "ServiceAdobeWorker" -withDetail $withDetail
			} else {
				
				LogWrite ""
				startService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.$selectedService -serviceKey $selectedService -withDetail $withDetail
			}						
		}
	}	

	LogWrite ""
	$argsCheckStartup = @($arguments[0],$arguments[1],$date.ToString('dd/MM/yyyy HH:mm'))
	checkStartup -serverNodeList $serverNodeList -logsPath $logsPath -arguments $argsCheckStartup
}	

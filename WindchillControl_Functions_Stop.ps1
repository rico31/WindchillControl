#########
## Functions for actions STOP & FULLSTOP
## @ Author Slimane Terkemani (zximsoget004)
#########

# Function : check authorized service
Function checkService ($windowsService) {

	# Authorized service
	if ( !($windowsService -eq $null -or $windowsService -eq "ALL" -or $windowsService -eq "ServiceWDS" -or $windowsService -eq "ServiceMaster" -or $windowsService -eq "ServiceApache" -or $windowsService -eq "ServiceWindchill" -or $windowsService -eq "ServicePartsLink" -or $windowsService -eq "ServiceCognos" -or $windowsService -eq "ServiceDSMCore" -or $windowsService -eq "ServiceAdobe" -or $windowsService -eq "ServiceAdobeWorker") ) { 
					
		exitProgram -err  "The service '$windowsService' is not accepted."	
	}	
}

# Function : stop a service
Function stopService($serverName, $serverAddr, $serviceName, $serviceKey, $fullstop) {
	
	if (!($serviceName -eq $null)) {
	
		# Get service
		$Service_Windows = Get-Service -computername $serverAddr -name $serviceName -ErrorAction silentlycontinue -ErrorVariable err
		
		# Check error
		if ($Service_Windows -eq $null) {
						
			exitProgram -err  "   $serviceName - $err"
		} else {
										
			if ( $Service_Windows.Status -eq 'STOPPED' ) {
			
				# Warning if already stopped			
				LogWarn "   Service $serviceName already stopped"
			} elseif ( $Service_Windows.Status -eq 'RUNNING' ) {
				
				# stop : stop all services except WindchillDS, Cognos, Master
				# fullstop = stop all 
				if ($fullstop -eq 'true' -or ($serviceKey -ne "ServiceWDS" -and $serviceKey -ne "ServiceCognos" -and $serviceKey -ne "ServiceMaster") ) {

					Stop-Service -Force -inputobject $Service_Windows
					$Service_Windows.WaitForStatus('Stopped', '00:01:00')
					$StatusDisplay = [String]$Service_Windows.status + " - " + [String]$serverName + " - " + [String]$Service_Windows.Name 
					LogWrite $StatusDisplay	
				} else {
				
					$StatusDisplay = [String]$Service_Windows.status + " - " + [String]$serverName + " - " + [String]$Service_Windows.Name 
					LogWrite $StatusDisplay	
				}				
			} else {
			
				exitProgram -err  "   Service $serviceName in status $Service_Windows.Status"
			}
		} 
	}
}

# Action : Stop
Function doStop ($serverNodeList, $arguments, $fullStop) {
	
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
							
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeWorker -serviceKey "ServiceAdobeWorker" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeDB -serviceKey "ServiceAdobeDB" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobe -serviceKey "ServiceAdobe" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServicePartsLink -serviceKey "ServicePartsLink" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWindchill -serviceKey "ServiceWindchill" -fullstop $fullstop				
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceMaster -serviceKey "ServiceMaster" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceDSMCore -serviceKey "ServiceDSMCore"  -fullstop $fullstop		
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceApache -serviceKey "ServiceApache"  -fullstop $fullstop				
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceCognos -serviceKey "ServiceCognos" -fullstop $fullstop
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWDS -serviceKey "ServiceWDS" -fullstop $fullstop
			} else {
				
				LogWrite ""
				stopService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.$selectedService -serviceKey $selectedService -fullstop $fullstop
			}						
		}
	}		
}	

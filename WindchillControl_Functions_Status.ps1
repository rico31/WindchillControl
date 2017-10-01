#########
## Functions for action STATUS & FULLSTATUS
## @ Author Slimane Terkemani (zximsoget004)
#########

# Check authorized service
Function checkService ($windowsService) {

	# Authorized service
	if ( !($windowsService -eq $null -or $windowsService -eq "ALL" -or $windowsService -eq "ServiceWDS" -or $windowsService -eq "ServiceMaster" -or $windowsService -eq "ServiceApache" -or $windowsService -eq "ServiceWindchill" -or $windowsService -eq "ServicePartsLink" -or $windowsService -eq "ServiceCognos" -or $windowsService -eq "ServiceDSMCore" -or $windowsService -eq "ServiceAdobe" -or $windowsService -eq "ServiceAdobeWorker") ) { 
					
		exitProgram -err  "The service '$windowsService' is not accepted."			
	}	
}

# Function : Log java Without parent
Function LogJavaWithoutParent($serverAddr, $withDetail) {
		
	$orphanProcesses = @()
	
	# Get all java Process
	$javaProcesses = gwmi Win32_Process -Filter "name = 'java.exe'" -computername $serverAddr | where {$_.executablePath -like '*Windchill*'} | Select ParentProcessId, handle,executablePath,CreationDate			    
	
	# Search orphans
	foreach ($javaProcess in $javaProcesses) {
		
		if (!($javaProcess -eq $null -or $javaProcess.handle -eq "0")) {
		
			# search the process parent
			$parentJavaProcess = gwmi Win32_Process -computername $serverAddr | where {$_.handle -eq $javaProcess.parentProcessId} | Select handle
			
			# check if orphan except java of wds is always orphan
			if (($parentJavaProcess -eq $null -or $parentJavaProcess.handle -eq "0") -and !($javaProcess.executablePath -like '*Windchill_10.1_WDS*')) {
			
				$orphanProcesses += $javaProcess
			}
		}	
	}
	
	# Error	: if service Running and no processes linked to it
	if (($orphanProcesses | Measure-Object).count -ne 0 ) {
		
		$log = "   Orphans java are found in this server..."
		LogWrite ""
		LogError $log
			
		if ( $withDetail -eq 'true' ) {
			
			foreach ($process in $orphanProcesses) {
			
				if (!($process -eq $null -or $process.handle -eq "0")) {

					# Log
					$log = "      " + $process.handle + " - " + $process.executablePath											
					LogError $log				
				}
			}
		}
	}
}

# Function : Log executables Of a Service
Function LogProcessesOfService($serverAddr, $service, $serviceKey, $parentProcessId, $prefix, $withDetail) {

	if ($parentProcessId -eq $null) {
		
		# Get Process link to the service
		$process = Get-WmiObject -Class Win32_Service -computername $serverAddr | where {$_.name -eq $service.name} | ForEach-Object {$processId = $_.ProcessId; gwmi Win32_Process -computername $serverAddr | where {$_.handle -eq $ProcessId} | Select processId,executablePath,CreationDate,CommandLine}
		$processes = @()
		if (!($process -eq $null -or $process.processId -eq "0")) {
		
			$processes += $process
		}
		$prefix = ""
		
		# Error	: if service Running and no processes linked to it
		if (($processes | Measure-Object).count -eq 0 -and $service.status -eq "RUNNING" ) {
			
			$log = $prefix + "      " + " No executables found and service running."
			LogError $log
		}
		
		# Error	: if service Stopped and processes still linked to it
		if (!(($processes | Measure-Object).count -eq 0) -and $service.status -eq "STOPPED" ) {
			
			$log = $prefix + "      " + " executables found and service stopped."
			LogError $log
		}
		
	} else {
	
		# Get processes link to parent process
		$processes = gwmi Win32_Process -computername $serverAddr  | where {$_.ParentProcessId -eq $parentProcessId} | Select processId,executablePath,CommandLine			
	}
	
	# Log & Recursivity
	if ( $withDetail -eq 'true' ) {
	
		foreach ($process in $processes) {
			
			if (!($process -eq $null -or $process.processId -eq "0")) {

				# Log
				$log = $prefix + "      " + $process.processId
				# Specific to Windchill
				if ( $serviceKey -eq "serviceWindchill" ) {
				
					if ( $process.CommandLine -like "*-Dwt.manager.serviceName=ServerManager*" ) {
					
						$log = $log + " - Server Manager"
					} elseif ( $process.CommandLine -like "*-Dwt.manager.serviceName=MethodServer*" ) {
					
						$log = $log + " - Method Server"
					} elseif ( $process.CommandLine -like "*-Dwt.manager.serviceName=Background*" ) {
					
						$log = $log + " - Background Method Server"
					}
				}
				
				# Write log
				$log = $log + " - " + $process.executablePath
				LogWrite $log
				
				# Get children process
				LogProcessesOfService -serverAddr $serverAddr -service $service -serviceKey $serviceKey -parentProcessId $process.processId -prefix "$prefix      " -withDetail $withDetail
			}
		}
	}
}

# Function : Log the status of a service
Function LogStatusService($serverName, $serverAddr, $serviceName, $serviceKey, $withDetail) {
	
	if (!($serviceName -eq $null)) {
	
		# Get service
		$Service_Windows = Get-Service -computername $serverAddr -name $serviceName -ErrorAction silentlycontinue -ErrorVariable err
		
		# Check error
		if ($Service_Windows -eq $null) {
						
			LogError "   $serviceName - $err"
		} else {
							
			# Status of services
			$StatusDisplay = "   " + [String]$Service_Windows.Status + " - " + [String]$serviceName
			LogWrite ""
			LogWrite $StatusDisplay			
			
			# executables linked to services
			LogProcessesOfService -serverAddr $serverAddr -service $Service_Windows	-serviceKey $serviceKey	-withDetail $withDetail			
		} 
	}
}

# Action : status
Function doStatus ($serverNodeList, $arguments, $withDetail) {

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
			
				
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWDS -serviceKey "ServiceWDS" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceMaster -serviceKey "ServiceMaster" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceApache -serviceKey "ServiceApache"  -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceWindchill -serviceKey "ServiceWindchill" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServicePartsLink -serviceKey "ServicePartsLink" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceCognos -serviceKey "ServiceCognos" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceDSMCore -serviceKey "ServiceDSMCore" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobe -serviceKey "ServiceAdobe" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeDB -serviceKey "ServiceAdobeDB" -withDetail $withDetail
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.ServiceAdobeWorker -serviceKey "ServiceAdobeWorker" -withDetail $withDetail
			} else {
				
				LogWrite ""
				LogStatusService -serverName $Server.Server_Name -serverAddr $Server.server -serviceName $Server.$selectedService -serviceKey $selectedService -withDetail $withDetail
			}	

			# Java without parents (could be found when windchill crashed)
			LogJavaWithoutParent -serverAddr $Server.server -withDetail $withDetail				
		}
	}				
}

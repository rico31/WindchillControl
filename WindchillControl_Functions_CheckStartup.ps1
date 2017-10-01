# Action : Convert date 2 string
function Convert-DateString ([String]$Date, [String[]]$Format)
{   
	[DateTime]$result = New-Object DateTime 
	$convertible = [DateTime]::TryParseExact(      
					$Date,      
					$Format,      
					[System.Globalization.CultureInfo]::InvariantCulture,      
					[System.Globalization.DateTimeStyles]::None,      
					[ref]$result)    
	if ($convertible) 
	{ 
		$result 
	}
} 

# Action : Check startup
Function checkStartup ($logsPath, $arguments) {

	$inputDate = $arguments[2]	
	#Modification because Slimane don't read the help
	$inputDate = $inputDate.Replace("h", ":")
	$inputDate = $inputDate.Replace("H", ":")
	$displayStackTrace = $arguments[3]
	
	if ( $inputDate -eq $null ) {	
		exitProgram -err "date must be filled"
	}

	$date = Convert-DateString -Date $inputDate -Format 'dd/MM/yyyy HH:mm','yyyy/MM/dd HH:mm'

	LogWrite "Converted date $date"
	LogWrite ""
		
	foreach ($logPath in $logsPath.Values) {
			
		if ($logPath.category -eq "Windchill") {
			$ServerName = $logPath.node;
			
			Try
			{
				$path = $logPath.folder
				$files = Get-ChildItem $path -Recurse -Filter *log4j.log | where-object {$_.lastwritetime -ge $date} 
				foreach ($file in $files)  { 
					$isStarted = $false
					$clusterNlogName = $file.FullName.Replace("$path", "")
					
					if ($displayStackTrace)
					{
						LogWrite "$ServerName - $clusterNlogName"
					}
					
					$lines = Get-Content $file.FullName

					foreach ($line in $lines) {
						if($stackError -And $displayStackTrace -And ( $line -match 'Nested exception' -Or $line -match 'at'))
						{
							LogError "  |_  $line"
						}
						
						if($stackError -And $displayStackTrace -And (-Not( $line -match 'Nested exception' -Or $line -match 'at')))
						{
							$stackError = $false
							LogWrite "..."
						}
						
						if ($displayStackTrace -And ($line -cmatch 'ERROR' -Or  $line -cmatch 'FATAL')) 
						{
							LogError "  |_  $line"
							$stackError = $true
						}
					
						if ($line -match 'BackgroundSOLR ready' -Or  $line -match 'MethodServer ready' -Or  $line -match 'BackgroundMethodServer ready' -Or  $line -match 'ServerManager ready' -Or  $line -match 'BackgroundBT2 ready')
						{ 
							if($displayStackTrace)
							{
								LogSuccess "  |_  $line"
							}
							$isStarted = $true
							break
						}
					}
					
					if(-Not($displayStackTrace))
					{
						$serviceName = ""
						
						if($clusterNlogName -match 'BackgroundMethodServer')
						{
							$serviceName = "BMS"
						}
						elseif ($clusterNlogName -match 'MethodServer')
						{
							$serviceName = "MS"
						}
						elseif ($clusterNlogName -match 'ServerManager')
						{
							$serviceName = "SM"
						}
						elseif ($clusterNlogName -match 'BackgroundBT2')
						{
							$serviceName = "BT2"
						}
						else
						{
							$serviceName = "Undefined service"
						}
						
						if($isStarted)
						{
							LogSuccess "$ServerName - $serviceName - Started - $clusterNlogName"
						}
						else
						{
							LogError "$ServerName - $serviceName - Not yet started - $clusterNlogName";
						}
					}
					else
					{
						LogWrite ""
					}
				} 
			
			}
			Catch
			{
				LogError "Maybe no file found under $ServerName"
			}
		}
	}
}
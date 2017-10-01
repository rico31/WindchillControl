#########
## Functions for action CLONE
## @ Author Slimane Terkemani (zximsoget004)

## Warning : Application must be stopped
## Warning : This script must be executed from application master node
## Warning : DATAPUMP of database must be manually copied from database server to clone folder  (because sftp command line not installed)
## Warning : at the end of clone, please check if all is correctly copied (check logs...) and restart application

#########

Function createCloneFolder($clonePATH) {

	LogWrite ""
	LogWrite "> Create Clone folder ..."
	New-Item -ItemType Directory -Force -Path $clonePATH				
	New-Item -ItemType Directory -Force -Path "$clonePATH\_LDIF"	
	# Others folder will be created by robocopy command
}

Function exportLDIF($clonePATH, $sourceAlias, $sourceWindchillVersion, $sourcePATH_WDS) {

	LogWrite ""
	LogWrite "> Export LDIF ..."
		
	$cmd = "CMD /C `"$sourcePATH_WDS\WindchillDS\server\bat\export-ldif.bat`" `"--ldifFile`" `"$clonePATH\_LDIF\$sourceAlias`_$sourceWindchillVersion.ldif`" `"--backendID`" `"userRoot`" `"--appendToLDIF`" `"--noPropertiesFile`""
	LogWrite $cmd
	Invoke-Expression $cmd	
}

Function exportDatabase($sourceAlias, $sourceWindchillVersion, $sourceDB_LOGIN, $sourceDB_PWD, $sourceDB_SID) {
 	
	LogWrite ""
	LogWrite "> Export Database ..."
	
	$cmd = "CMD /C `"expdp $sourceDB_LOGIN/$sourceDB_PWD@$sourceDB_SID full=y directory=DPUMP_DIR dumpfile=$sourceAlias`_$sourceWindchillVersion.dmp logfile=$sourceAlias_$sourceWindchillVersion.log`""
	LogWrite $cmd
	Invoke-Expression $cmd	
	LogWrite "commandline 'sftp' is not installed so please get dmp file and copy it manuall on clone 'folder = _DataBase'"
}

Function exportFoldersAndFiles($source, $destination, $title, $logFile) {

	LogWrite ""
	LogWrite "> Export $title ..."

	$cmd = "CMD /C `"robocopy $source $destination /MIR /R:1 /W:1 /XJ /LOG:C:\temp\$logFile`""
	LogWrite $cmd
	Invoke-Expression $cmd
}

# Action : clone an application
Function doClone ($clusterName, $foldersPath, $database, $fullVersion, $arguments, $withDetail) {

	#### GET INFO

	# Application Informations
	$sourceDB_LOGIN = echo $arguments[2]
	$sourceDB_PWD = echo $arguments[3]
	$sourceDB_SID=$database.ServerSID
	$sourceAlias=$clusterName
	$sourceWindchillVersion=$fullVersion
	$sourcePATH_WINDCHILL="E:\PRODUCT\ptc\Windchill_10.1"
	$sourcePATH_WINDCHILL_SPECIFIC="D:\PRODUCT\ptc"
	$sourcePATH_WDS="E:\PRODUCT\ptc\Windchill_10.1_WDS"
	$sourcePATH_PARTSLINK="E:\PRODUCT\ptc\Windchill_10.1_PartsLink"
	$sourcePATH_SOLR = $null
	$sourcePATH_VAULT = $null
	foreach ($folder in $foldersPath.values) {	
		
		# ---- PATH SOLR
		if ( $folder.name -eq 'SOLR' ) {
			$sourcePATH_SOLR=$folder.location
		}
		
		# ---- PATH VAULT
		if ( $folder.name -eq 'VAULT' ) {
			$sourcePATH_VAULT=$folder.location
		}		
	}	
	
	# Clone Informations
	# -- TARGET FOLDER = Argument 6
	$clonePATH = "\\coconnasfrpb01.corporate.eu.astrium.corp\FI5_depot\PTC\Clone\$sourceAlias\$sourceWindchillVersion"
	$clonePATH_WINDCHILL_SPECIFIC="$clonePATH\BT1\D\PRODUCT\ptc"
	$clonePATH_WDS="$clonePATH\BT1\E\PRODUCT\ptc\Windchill_10.1_WDS"
	$clonePATH_PARTSLINK="$clonePATH\BT1\E\PRODUCT\ptc\Windchill_10.1_PartsLink"
	$clonePATH_WINDCHILL="$clonePATH\BT1\E\PRODUCT\ptc\Windchill_10.1"
	$clonePATH_SOLR = "$clonePATH\_SOLR"
	$clonePATH_VAULT = "$clonePATH\_VAULT"
	
	#### CLONE IM
	# . Windchill stopped (prerequisite)
	# . Create clone folder if doesn't exist	
	createCloneFolder -clonePATH $clonePATH
	# . Export LDIF
	exportLDIF -clonePATH $clonePATH -sourceAlias $sourceAlias -sourceWindchillVersion $sourceWindchillVersion -sourcePATH_WDS $sourcePATH_WDS	
	# . Export Database
 	exportDatabase -sourceAlias $sourceAlias -sourceWindchillVersion $sourceWindchillVersion -sourceDB_LOGIN $sourceDB_LOGIN -sourceDB_PWD $sourceDB_PWD -sourceDB_SID $sourceDB_SID
	# . Export Windchill specific configuration
	exportFoldersAndFiles -source $sourcePATH_WINDCHILL_SPECIFIC -destination $clonePATH_WINDCHILL_SPECIFIC -title "Windchill specific" -logFile roboCopyD2Clone.log
	# . Export WindchillDS files
	exportFoldersAndFiles -source $sourcePATH_WDS -destination $clonePATH_WDS -title "WindchillDS" -logFile roboCopyWDS2Clone.log
	# . Export PartsLink files
	exportFoldersAndFiles -source $sourcePATH_PARTSLINK -destination $clonePATH_PARTSLINK -title "PartsLink" -logFile roboCopyPartsLink2Clone.log
	# . Export Windchill files
	exportFoldersAndFiles -source  $sourcePATH_WINDCHILL -destination $clonePATH_WINDCHILL -title "Windchill" -logFile roboCopyWindchill2Clone.log
	# . Export Solr
	exportFoldersAndFiles -source  $sourcePATH_SOLR -destination $clonePATH_SOLR -title "Solr" -logFile roboCopySolr2Clone.log
	# . Export Vault	
	exportFoldersAndFiles -source  $sourcePATH_VAULT -destination $clonePATH_VAULT -title "Vault" -logFile roboCopyVault2Clone.log
}

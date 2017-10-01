REM --- TITLE

:: This script permits to run some pre-actions required for a rehost
:: This scripts must be running on rehost source environment
:: This scripts could be running thru a Windows task and by night

REM --- WARNINGS

:: Please ensure you the source environment is stopped before to run this script.
:: Please ensure you the target environment is stopped before to run this script.
:: Please check free spaces on source database DPUMP
:: Please check target shares. Please create them if doesn't exist.
:: Logs are generated in c:\temp

REM --- PARAMETERS

:: %1 source database system login
:: %2 source database system password

REM --- LEGEND

:: SOURCE permits to describe the rehost source environment
:: TARTGET permits to describe the rehost target environment

REM --- VARIABLES DECLARATION

:: SOURCE - example with newPDM Corporate
set sourceAlias=PDM-PROD01
set sourceWindchillVersion=WINDCHILLM020_PHENIX4V10_2.5.1HF5
set sourceDatabaseSID=PDMPROD
set sourcePATH_WINDCHILL=E:\PRODUCT\ptc\Windchill_10.1
set sourcePATH_WINDCHILL_SPECIFIC=D:\PRODUCT\ptc\clusterNodeSpecifics
set sourcePATH_WDS=E:\PRODUCT\ptc\Windchill_10.1_WDS
set sourcePATH_PARTSLINK=E:\PRODUCT\ptc\Windchill_10.1_PartsLink
set sourcePATH_SOLR=\\coconnasfrpb01.corporate.eu.astrium.corp\PDMPROD_SOLR
set sourcePATH_VAULT=\\coconnasfrpb01.corporate.eu.astrium.corp\PDMPROD_VAULT\vaults

:: TARGET - example with newPDM Integration
set targetAlias=PDM-INT02
set targetPATH_BACKUP=\\coplfrt01.corporate.eu.astrium.corp\ptc\REHOST_BCK
set targetPATH_WINDCHILL=\\coplfrt01.corporate.eu.astrium.corp\ptc\Windchill_10.1
set targetPATH_WINDCHILL_SPECIFIC=\\coplfrt01.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics
set targetPATH_WINDCHILL_SPECIFIC_BCK=\\coplfrt01.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics_BCK
set targetPATH_WDS=\\coplfrt01.corporate.eu.astrium.corp\ptc\Windchill_10.1_WDS
set targetPATH_PARTSLINK=\\coplfrt01.corporate.eu.astrium.corp\ptc\Windchill_10.1_PartsLink
set targetPATH_SOLR=\\coconnasfrpr02.corporate.eu.astrium.corp\CLU_WIND1_SOL
set targetPATH_VAULT=\\coconnasfrpr02.corporate.eu.astrium.corp\CLU_WIND1_VAULT\vaults

:: TARGET - example with newPDM Migration
::set targetAlias=PDM-MIG01
::set targetPATH_BACKUP=\\copdfrp04.corporate.eu.astrium.corp\ptc\REHOST_BCK
::set targetPATH_WINDCHILL=\\copdfrp04.corporate.eu.astrium.corp\ptc\Windchill_10.1
::set targetPATH_WINDCHILL_SPECIFIC=\\copdfrp04.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics
::set targetPATH_WINDCHILL_SPECIFIC_BCK=\\copdfrp04.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics_BCK
::set targetPATH_WDS=\\copdfrp04.corporate.eu.astrium.corp\ptc\Windchill_10.1_WDS
::set targetPATH_PARTSLINK=\\copdfrp04.corporate.eu.astrium.corp\ptc\Windchill_10.1_PartsLink
::set targetPATH_SOLR=\\coconnasfrpr02.corporate.eu.astrium.corp\PDMMIG_SOLR
::set targetPATH_VAULT=\\coconnasfrpr02.corporate.eu.astrium.corp\PDMMIG_VAULT\vaults

:: TARGET - example with newPDM Maintenance
::set targetAlias=COPDFRI04
::set targetPATH_BACKUP=\\copdfri04.corporate.eu.astrium.corp\ptc\REHOST_BCK
::set targetPATH_WINDCHILL=\\copdfri04.corporate.eu.astrium.corp\ptc\Windchill_10.1
::set targetPATH_WINDCHILL_SPECIFIC=\\copdfri04.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics
::set targetPATH_WINDCHILL_SPECIFIC_BCK=\\copdfri04.corporate.eu.astrium.corp\ptc_D\clusterNodeSpecifics_BCK
::set targetPATH_WDS=\\copdfri04.corporate.eu.astrium.corp\ptc\Windchill_10.1_WDS
::set targetPATH_PARTSLINK=\\copdfri04.corporate.eu.astrium.corp\ptc\Windchill_10.1_PartsLink
::set targetPATH_SOLR=\\copdfri04.corporate.eu.astrium.corp\ptc\WorkArea\SOLR
::set targetPATH_VAULT=\\coconnasfrpr02.corporate.eu.astrium.corp\VAULT_SCRUM\COPDFRI04\vaults

REM --- ACTIONS

:: Clean target backup folder if exist
rmdir /S /Q %targetPATH_BACKUP%

:: Create target backup folder
mkdir %targetPATH_BACKUP%

:: Backup some resources
start /wait CMD /C robocopy %targetPATH_WINDCHILL%\Windchill\codebase\ext %targetPATH_BACKUP%\Windchill\codebase\ext /MIR /R:1 /W:1 /XJ
start /wait CMD /C robocopy %targetPATH_WINDCHILL%\Windchill\codebase\netmarkets %targetPATH_BACKUP%\Windchill\codebase\netmarkets /MIR /R:1 /W:1 /XJ
start /wait CMD /C robocopy %targetPATH_WINDCHILL%\Windchill\conf %targetPATH_BACKUP%\Windchill\conf /MIR /R:1 /W:1 /XJ
start /wait CMD /C copy %targetPATH_WINDCHILL%\Windchill\codebase\wt.properties %targetPATH_BACKUP%\Windchill\codebase\wt.properties
start /wait CMD /C copy %targetPATH_WINDCHILL%\Windchill\codebase\wvs.properties %targetPATH_BACKUP%\Windchill\codebase\wvs.properties
start /wait CMD /C mkdir %targetPATH_BACKUP%\Windchill\db
start /wait CMD /C copy %targetPATH_WINDCHILL%\Windchill\db\db.properties %targetPATH_BACKUP%\Windchill\db\db.properties

:: Export source LDIF
start /wait CMD /C %sourcePATH_WDS%\WindchillDS\server\bat\export-ldif.bat "--ldifFile" "%targetPATH_BACKUP%\%sourceAlias%_%sourceWindchillVersion%.ldif" "--backendID" "userRoot" "--appendToLDIF" "--noPropertiesFile"

:: Export source Database
start /wait CMD /C expdp %1/%2@%sourceDatabaseSID% full=y directory=DPUMP_DIR dumpfile=%sourceAlias%_%sourceWindchillVersion%.dmp logfile=%sourceAlias%_%sourceWindchillVersion%.log

:: Export source Windchill specific
start /wait CMD /C robocopy %targetPATH_WINDCHILL_SPECIFIC% %targetPATH_WINDCHILL_SPECIFIC_BCK% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyWindchillSpecificBck.log
start /wait CMD /C move c:\temp\roboCopyWindchillSpecificBck.log %targetPATH_BACKUP%\roboCopyWindchillSpecificBck.log
start /wait CMD /C robocopy %sourcePATH_WINDCHILL_SPECIFIC% %targetPATH_WINDCHILL_SPECIFIC% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyWindchillSpecific.log
start /wait CMD /C move c:\temp\roboCopyWindchillSpecific.log %targetPATH_BACKUP%\roboCopyWindchillSpecific.log

:: Export source WindchillDS
start /wait CMD /C robocopy %sourcePATH_WDS% %targetPATH_WDS% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyWDS.log
start /wait CMD /C move c:\temp\roboCopyWDS.log %targetPATH_BACKUP%\roboCopyWDS.log

:: Export source PartsLink
start /wait CMD /C robocopy %sourcePATH_PARTSLINK% %targetPATH_PARTSLINK% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyPartsLink.log
start /wait CMD /C move c:\temp\roboCopyPartsLink.log %targetPATH_BACKUP%\roboCopyPartsLink.log

:: Export source Windchill
start /wait CMD /C robocopy %sourcePATH_WINDCHILL% %targetPATH_WINDCHILL% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyWindchill.log
start /wait CMD /C move c:\temp\roboCopyWindchill.log %targetPATH_BACKUP%\roboCopyWindchill.log

:: Export source solR data
start /wait CMD /C robocopy %sourcePATH_SOLR% %targetPATH_SOLR% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopySolr.log
start /wait CMD /C move c:\temp\roboCopySolr.log %targetPATH_BACKUP%\roboCopySolr.log

:: Export source vault data
start /wait CMD /C robocopy %sourcePATH_VAULT% %targetPATH_VAULT% /MIR /R:1 /W:1 /XJ /LOG:c:\temp\roboCopyVault.log
start /wait CMD /C move c:\temp\roboCopyVault.log %targetPATH_BACKUP%\roboCopyVault.log

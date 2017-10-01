
$Error.Clear()
$ErrorActionPreference="Stop"

###################################################################
# Function : LogFiles-Manage
# INPUT ARG:
# srcDirectory: Source folder for files (absolute path terminated by a '\' char)
# destDirectory:Destination folder where to copy or move files (absolute path terminated by a '\' char)
# op: value: move or copy (default: copy) indicate the nature of operation:
#           COPY means we will copy files from source to destination
#           MOVE means we will move files from source to destination
#           LIST means neutral operation: we only list files candidats for operation (nothing is done on files)
# mtime: positif integer indicates the date of files to take account:
#           1 means we will take account all files modified 1 day ago
#           7 means we will take account all files modified 1 week (7 days) ago
###################################################################
# DATE                      AUTHOR                      COMMENT
# Decembre 2014             Eric Nieucel                Creation
###################################################################
Function LogFiles-Manage ([string]$srcDirectory, [string]$destDirectory, [string]$op, [int]$mtime)
{
    LogWrite "--------Begin of function LogFiles-Manage---------------"
    LogWrite "            Source folder     : $srcDirectory"
    LogWrite "            destination folder: $destDirectory"
    LogWrite "            Operation         : $op" 
    LogWrite "            mtime             : $mtime" 
    LogWrite "--------------------------------------------------------"

	### ---  Execution date begin
	$dateAndTime = Get-Date
	$date= $dateAndTime.Date 
	
    #Check existence of src folder
    if(!(Test-Path "$srcDirectory" -PathType container))
    { 
        # src folder does not exist... return
        exitProgram "Source folder: $srcDirectory..... does not exist... return"
    }
        
    #Create $destDirectory if does not exist
    if(!(Test-Path "$destDirectory" -PathType container))
    { #Destination folder does not exist: we create it. (output default messages to null)
        New-Item -path "$destDirectory" -type directory | Out-Null
        LogWrite "Destination folder: $destDirectory..... created OK"
    }
    else
    {
        LogWarn "Destination folder: $destDirectory..... already exists"
    }
    
    #Get all files (not folder) modify the day before the current day from $srcDirectory and copying them in destination directory

    $Files = Get-ChildItem -Path $srcDirectory | Where { ($_.PSIsContainer -eq $False) -and ($_.LastWriteTime.Date -le $date.AddDays(-$mtime))}

    $i =0
    Foreach ($File in $Files) 
    {
        $destFile=$destDirectory+$File
        if(!(Test-Path $destFile -PathType Leaf))
        {#Destination file does not exist: we apply operation on it.
            switch ($op.ToUpper()) 
            {
                    "COPY" { 
                    Copy-Item -Path $File.FullName -Destination $destDirectory
                    LogWrite "$File copied"  
                    $i++
                    }

                    "MOVE" {
                    Move-Item -Path $File.FullName -Destination $destDirectory
                    LogWrite "$File moved"  
                    $i++
                    }

                    "LIST" { #For Debug
                    LogWrite "$File  candidat to operation"
                    $i++
                    }

                    default {
                    $Msg="Function LogFiles-Manage in error:"+"third argument must be COPY or MOVE (case unsensitive)"
                    $Exception=New-Object System.ApplicationException($Msg,$_.Exception)
                    throw $Exception
                    }
            }
        }
        else
        {# Destination file already exist: we do not copied it
            if ( $op -eq "LIST" )
            { #With LIST option, keep trace of existing files.
              LogWrite "$File  already exits not candidat to operation"   
            }
        }
    }
    LogWrite "total of Files taken account: $i" 
    LogWrite "--------End of function LogFiles-Manage---------------"
}


###################################################################
# main
###################################################################
# DATE                      AUTHOR                      COMMENT
# Decembre 2014             Eric Nieucel                Creation
###################################################################
Function archiveLogs($logsPath, $arguments) {    


    #Get Arguments
    # Argument 0, 1, 2 : already managed by WindchillControl
    
    # Argument 3 : Operation
    $operation = echo $arguments[2].ToString().ToUpper()
    if ( !( ("COPY", "MOVE", "LIST") -contains $operation )) {  #Case unsensitive comparaison
        
        exitProgram -err  "   Operation $operation is not accepted. Only [COPY, MOVE, LIST]"
    }      
    
    # Script main body
    try { 

        # Run each server to handle : all actions
	    foreach ($logPath in $logsPath.values) {                
        
            if ($logPath.category -eq "Apache") {
                
                # Manage Apache log files
                LogFiles-Manage -srcDirectory $logPath.folder -destDirectory $logPath.archive -op $operation -mtime 1

            } elseif ($logPath.category -eq "Windchill") {

                # Manage Windchill log files
                LogFiles-Manage -srcDirectory $logPath.folder -destDirectory $logPath.archive -op $operation -mtime 7

            }                        
        }
    } Catch {
        
        $Msg="Process exception :"+ $_.Exception.Message
        LogError $Msg        
    }
}




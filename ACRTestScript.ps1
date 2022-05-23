

#!/bin/bash
# the above command will give information of our system
#Begin
#Validated on RDC to Push Images

######################################################

#Driect execution use this command
#C:\ACRTestScript.ps1 -acrlogin crfacetssb1 -dockerlogin crfacetssb1.azurecr.io -FacetsZipfile FacetsDockerDeploy-5.90.002.001.zip



################################################################################################
#            				 AZURE DOCKER LOGIN								      			   #
################################################################################################


param
(
	[string]$acrlogin,
	[string]$dockerlogin='azurecr.io',
	[string]$FacetsZipfile='.zip'
	
)

################################################################################################
#            				 TranscriptFile Logs							      			   #
################################################################################################


$dt = get-date -format yyyy-MM-dd_hh-mm
$TranscriptFolder = "C:\PSlogs\TranscriptFile"
$TranscriptFile = "C:\PSlogs\TranscriptFile\Output_Transcript_log-"+$dt+".txt"


if  ( !( Test-Path -Path $TranscriptFolder -PathType "Container" ) ) 
		{
            
            Write-Verbose "Create TranscriptFolder in $TranscriptFolder"
            New-Item -Path $TranscriptFolder -ItemType "Container" -ErrorAction Stop
        
            if ( !( Test-Path -Path $TranscriptFile -PathType "Leaf" ) ) 
			{
                Write-Verbose "Create TranscriptFile in $TranscriptFile"
                New-Item -Path $TranscriptFile -ItemType "File" -ErrorAction Stop
            }
        }



$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $TranscriptFile -append
Write-Host "Check C:\PSlogs\TranscriptFile\ to moniter the execution..."

start-sleep -Seconds 60

#################################################################################################
##            				 DIRECTORY CHECK AND CREATION					      			   #
#################################################################################################


# TESTED!!
Write-Host "Checking for Deploy, Build , License folder availability, if not will be created"


$errorlogfile = "C:\PSlogs\Error_Log.txt"
$errorlogfolder = "C:\PSlogs"
$Deployfolder = "C:\Deploy"
$Licensefolder = "C:\License"
$Licensefile = "C:\License\TriZettoLicense.xml"
$Buildfolder = "C:\Build"

try
{

if  ( !( Test-Path -Path $Deployfolder -PathType "Container" ) ) 
		{
            
            Write-Verbose "Create Deployfolder in: $Deployfolder"
            New-Item -Path $Deployfolder -ItemType Directory -ErrorAction Stop
			Write-Host "DeployFolder Created successfully"
        
         }

if  ( !( Test-Path -Path $Licensefolder -PathType "Container" ) ) 
		{
            
            Write-Verbose "Create Licensefolder  in: $Licensefolder"
            New-Item -Path $Licensefolder -ItemType Directory -ErrorAction Stop
			Write-Host "Licensefolder Created successfully"
			
			if ( !( Test-Path -Path $Licensefile -PathType "Leaf" ) ) 
			{
                Write-Verbose "Copy Licensefile in folder $Licensefile with name TriZettoLicense.xml"
                Copy-Item "C:\TriZettoLicense.xml" -Destination "C:\License" -Force -ErrorAction Stop
            }
        
         }
		 
if  ( !( Test-Path -Path $Buildfolder -PathType "Container" ) ) 
		{
            
            Write-Verbose "Create Buildfolder in: $Buildfolder"
            New-Item -Path $Buildfolder -ItemType Directory -ErrorAction Stop
			Write-Host "Buildfolder Created successfully"
        
         }
		 else
		 { 
			Write-Host "Build folder deleting all the files..."
			Get-ChildItem $Buildfolder -Force -Recurse | Remove-Item -Force -Recurse 
		 }


}
Catch
{
Write-host  "ERROR ACTION: Delete all the created directories...and re-run the script.!!"
throw

}

start-sleep -Seconds 60

################################################################################################
#            				 EXTRACTING THE ZIP-FILE INTO DEPLOY FOLDER		      			   #
################################################################################################



try
{
	
		Write-Host "Checking for ZipedFiles...in Deploy Folder"

		if ((Test-Path 'C:\Deploy\content') -and 
			(Test-Path 'C:\Deploy\Templates') -and
			(Test-Path 'C:\Deploy\Utilities') )
		{  
			Write-Host "content,Templates,Utilities folders already exists in Deploy folder"    
		}
		else
		{
			Expand-Archive C:\$FacetsZipfile -DestinationPath C:\Deploy -ErrorAction Stop
			Write-Host "content,Templates,Utilities extracted in Deploy folder" 
		}

}

Catch
{
			Write-error "Error Occured" 
			$_
			
			$host.PrivateData.ErrorBackgroundColor = "white"
			$host.PrivateData.ErrorForegroundColor = "Yellow"
			
			Get-ChildItem C:\Deploy -Force -Recurse | Remove-Item -Force -Recurse
			
			Write-Host "Error Action taken: all the folders in the deploy directory has been deleted, Try rerunning the script"
			
			Write-Host "Re-try to extract the files" 
			Expand-Archive C:\$FacetsZipfile -DestinationPath C:\Deploy -ErrorAction Stop
			
		
			
			#Get-ChildItem -Path C:\Deploy -Include *.* -File -Recurse | foreach { $_.Delete()}
			#throw #throw will come out of the ececution lifecycle of powershell
			
			

}

start-sleep -Seconds 60

################################################################################################
#            				 AZURE DOCKER LOGIN								      			   #
################################################################################################



Write-Output "DOCKER LOGIN INITIATED..."

$Pwd = Get-Content -Path 'C:\Credentials.txt'

docker login $dockerlogin -u $acrlogin -p $pwd #user succeeds
if ($LASTEXITCODE -ne 0) 
{
	Write-Output "INVALID CREDENTIALS PROVIDED, TRY RE-RUNNING THE SCRIPT"
	exit
}
else
{
	Write-Output "DOCKER LOGIN	WAS SUCCESSFUL"
}

start-sleep -Seconds 60

Write-Output "ACR LOGIN INITIATED..."

az acr login --name $acrlogin -u $acrlogin -p $pwd

start-sleep -Seconds 60



################################################################################################
#            				 FacetsDockerGenerate							      			   #
################################################################################################

#Bellow mentioned command has an application called FacetsDockerGenerate.exe, we need to mention where you want the files to be stored

#Example: FacetsDockerDeploy-5.90.002.001 will have the base-image for the entire application(i:e the zipped file present in C:\Deploy #directory)
#we need to build and deploy to which environment we need(Azure , AWS, local, etc)

# --LocalRepository : directory to store the Images 
# --Publish : all the iamges will be built ( in "build" directory ) and some files will be created (build version , provision, publish files)


Write-Output "Current Date used as ImageTag..."

$latestdate =Get-Date -Format "yyyy-MM-dd_HH-mm"
echo $latestdate 

Write-Output "FacetsDockerGenerate Initiated..."

cd C:\Deploy\Utilities\FacetsDockerGenerate

.\FacetsDockerGenerate.exe --DeployDirectory=C:\Deploy --BuildDirectory=C:\Build --ImageTag=$latestdate --LocalRepository=$dockerlogin --TriZettoLicenseFile=C:\License\TriZettoLicense.xml --Publish --Automated


Write-Output "FacetsDockerGenerate Completed...!!"

start-sleep -Seconds 60




################################################################################################
#            				 FacetsDockerGenerate Provision					      			   #
################################################################################################
# Provision file purpose is to create many files/folder
# It creates folder , so that once we build it, the data/content of the build can be stored there

Write-Output "FacetsDockerGenerator Provision Initiated..."
cd C:\Build

.\FacetsDockerGenerator_Invoke_Provision.ps1

Write-Output "FacetsDockerGenerator Provision Completed...!!"

start-sleep -Seconds 60




################################################################################################
#            				Remote Sign and Unlock DockerSupport File		      			   #
################################################################################################

cd C:\Build
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
Write-Output "Remote Sign Executed..."


cd C:\Build
Unblock-File -Path .\DockerSupport.psm1
Write-Output "DockerSupport File Executed..."

start-sleep -Seconds 60



################################################################################################
#            				FacetsDockerGenerator WINDOWS BUILD					   			   #
################################################################################################

#only 2 scenario can come, as mentioned in below comment

#1 Switch to Windows Conatiners...on right end of taskbar - docker icon -3rd time checked- executed without any error
#1 Switch to Linux Conatiners...on right end of taskbar - docker icon -4th time checked- executed without any error


Write-Output "NOTE WINDOWS BUILD INITIATED..."

cd C:\Build
.\FacetsDockerGenerator_Invoke_BuildWin.ps1

Write-Output "NOTE WINDOWS BUILD COMPLETE..!!"

#2 Docker context is windows

start-sleep -Seconds 60


################################################################################################
#            				SwitchDaemon									      			   #
################################################################################################
 
Write-Output "1ST SWITCH CONTEXT INITIATED... "

Cd C:\
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon

start-sleep -Seconds 60
#3 docker context ls linux

Write-Output "1ST SWITCH CONTEXT COMPLETE..!!"




################################################################################################
#            				FacetsDockerGenerator WINDOWS BUILD					   			   #
################################################################################################

start-sleep -Seconds 60
#4 docker context ls linux

Write-Output "NOTE LINUX BUILD INITIATED..."

cd C:\Build
.\FacetsDockerGenerator_Invoke_BuildLnx.ps1

Write-Output " NOTE LINUX BUILD COMPLETE..!!"




################################################################################################
#            				ACR PUSH (	FacetsDockerGenerator PUBLISH lINUX)			   	   #
################################################################################################
start-sleep -Seconds 60
#5 docker context ls linux

Write-Output "NOTE LINUX IMAGES PUSH INITIATED..."

cd C:\Build
.\FacetsDockerGenerator_Invoke_PublishLnx.ps1

Write-Output "NOTE LINUX IMAGES PUSH COMPLETE..!!"

start-sleep -Seconds 60


################################################################################################
#            				SwitchDaemon									      			   #
################################################################################################

start-sleep -Seconds 60
#6 docker context ls linux

Write-Output "2ND SWITCH CONTEXT INITIATED... "

Cd C:\
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon

Write-Output "2ND SWITCH CONTEXT COMPLETE..!!"



################################################################################################
#            				ACR PUSH (	FacetsDockerGenerator PUBLISH WINDOWS)			   	 #
################################################################################################
start-sleep -Seconds 60
#7 docker context ls windows


Write-Output "NOTE WINDOWS PUBLISH IMAGE INITIATED..."

cd C:\Build
.\FacetsDockerGenerator_Invoke_PublishWin.ps1

Write-Output "NOTE WINDOWS PUBLISH IMAGE COMPLETE..!!"

start-sleep -Seconds 60




################################################################################################
#            				 Function to Write Logs							      			   #
################################################################################################

Write-Output "Captured all the error logs in C:\PSlogs\Error_Files"

$dt=get-date -format yyyy-MM-dd_hh-mm

function WriteLog
{
Param ([string]$LogString)
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$LogMessage = "$Stamp $LogString"

		$errorlogfolder = "C:\PSlogs\Error_Files"
        $errorlogfile = "C:\PSlogs\Error_Files\Error_Log-"+$dt+".txt"
        
        
      if  ( !( Test-Path -Path $errorlogfolder -PathType "Container" ) ) 
		{
          
          Write-Verbose "Create error log folder in: $errorlogfolder"
          New-Item -Path $errorlogfolder -ItemType "Container" -ErrorAction Stop
        
            if ( !( Test-Path -Path $errorlogfile -PathType "Leaf" ) ) 
			{
                Write-Verbose "Create error log file in folder $errorlogfolder with name Error_Log.txt"
                New-Item -Path $errorlogfile -ItemType "File" -ErrorAction Stop
            }
       }


Add-content $errorlogfile -value $LogMessage
}

#Call the WriteLog function wherever you need
WriteLog $error #use this command to log error



# Do some stuff
Stop-Transcript



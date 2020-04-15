##
# Script that copies required files for lockscreen swithcer to C:\Program Files\SVV\LockScreen\, also registers needed scheduled task
# Author: Vegard Søbstad Alsli
# Company: Statens Vegvesen
# Version: 2.0
# Date: 10.10.2018
##
# CHANGELOG:
# 23.05.2018 Script created
# 23.05.2018 Added copy operation to programfiles
# 23.05.2018 Added registering og scheduled task
# 27.06.2018 Modified to install Lockscreen changer
# 10.10.2018 Removed image processing
# 10.10.2018 Switched to using the files directly from programfiles in stead of doing a copy at every logon. 
# 10.10.2018 Fixed problem with permissions when installing windows updates by changing the policy to use files in programfiles in stead of restricted default lock screen folder.
# 10.10.2018 Changed comment in script that refers to bginfo. Bginfo has nothing to do with the lock screen script
# 25.10.2018 Now prevents copying of thumds.db files from source files. This just causes problems if you ever need som folders deleted. Also tries to remove any thumbs.db files in the lockscreens folder locally.
##

#Logging
$LogLocation = "C:\Windows\SVVLogg\"
$LogFileName = "Install-LockScreenSwitcher.log"
Start-Transcript "C:\Windows\SVVLogg\$LogFileName" -Append

#Set variables
$SystemDrive = $env:SystemDrive
$ProgramFiles = $SystemDrive + "\Program Files\"
$FolderToCopy = "SVV"
$exclude = '*.db'


"Removing old files, some files might be in use and will probably not be removed..."
Get-Childitem $ProgramFiles\SVV\LockScreen -Recurse | ForEach {Remove-Item ($_.Fullname) -Recurse -Confirm:$false}

#Copy files to disk
"Copying files from source folder $FolderToCopy to $ProgramFiles..."
Copy-item $FolderToCopy $ProgramFiles -Exclude $exclude -Recurse -Force

#Create Scheduled task that changes lock screen at reboot
"Unregister old scheduled task..."
Unregister-ScheduledTask "ChangeLockscreen" -Confirm:$false
"Register scheduled task..."
Register-ScheduledTask -XML (get-content "ChangeLockscreen.xml" | Out-String) -TaskName "ChangeLockscreen" -Force

"Installation complete..."

"Trying to remove Thumbs.db files if they exist..."
Get-Childitem $ProgramFiles\SVV\LockScreen -Recurse -Include $exclude -Force | ForEach {Remove-Item ($_.Fullname) -Recurse -Confirm:$false}

#Stop logging
Stop-Transcript
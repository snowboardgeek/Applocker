# 3.6.2019 vegals: La til nytt hanskebilde der wurth logo er fjernet 
#


Start-Transcript "C:\Windows\SVVLogg\LockScreen.log" -Append

$AllowUserToChangeLockScreen = (Get-ItemProperty -Path $path -Name NoChangingLockScreen).NoChangingLockscreen

if ($AllowUserToChangeLockScreen -eq 1){
 "User is not allowed to change lockscreen before running script (Setting is correct)"
} else {
 "User is allowed to change lockscreen before running script (This is not correct)"
}

#Get random image folder
$Folder =  Get-ChildItem .\Lockscreens | Get-Random
"Folder used is $Folder"
$Images =  $Folder | Get-ChildItem | Select -expandProperty FullName

"Found the following images in $Folder :"
$Images

$NewLockScreenImage = $Images | select -first 1
"Image to set as lockscreen is: $NewLockScreenImage"
#Set local lock screen
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"

Set-ItemProperty -Path $path -Name LockScreenImage -Value $NewLockScreenImage -Verbose
Set-ItemProperty -Path $path -Name NoChangingLockScreen -Value 1 -Verbose

$LockScreenAfterChange = (Get-ItemProperty -Path $path -Name LockScreenImage).LockScreenImage

$AllowUserToChangeLockScreen = (Get-ItemProperty -Path $path -Name NoChangingLockScreen).NoChangingLockscreen

if ($AllowUserToChangeLockScreen -eq 1){
 "User is not allowed to change lockscreen after running script (Setting is correct)"
} else {
 "User is allowed to change lockscreen after running script (This is not correct)"
}
"Lock after script was run $LockScreenAfterChange"


Stop-Transcript
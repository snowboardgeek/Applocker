#Script for å kopiere inn standard filassosiasjoner xml fil. Benyttes i task sequence og for å rulle ut filen der den måtte mangle.

$SystemDrive = $env:systemdrive
Start-Transcript "$SystemDrive\Windows\SVVLogg\Copy-DefaultAppAssociations.log"
$DefaultXML = "DefaultAppAssociations.xml"
$LocalFolder = "$SystemDrive\Program Files\SVV\Filassosiasjoner\"

Remove-Item "$LocalFolder\$DefaultXML" -Force -Verbose
#Opprett mappe hvis den ikke finnes
if (Get-Item $LocalFolder){
    "Folder already exists"
} else {
    "Folder does not exist, creating folder..."
    New-Item $LocalFolder -ItemType Directory -Verbose
}

#Kopier filen til disk
"Copying script to disk..."
Copy-Item $DefaultXML "$LocalFolder\$DefaultXML" -Force -Verbose

Stop-Transcript
Exit
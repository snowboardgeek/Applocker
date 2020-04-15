set-executionpolicy -ExecutionPolicy Unrestricted

.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension ".htm" -Progid "htmlfile" -Appname "Internet Explorer"
.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension ".html" -Progid "htmlfile" -Appname "Internet Explorer"
.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension ".Url" -Progid "IE.AssocFile.URL" -Appname "Internet Explorer"
.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension ".website" -Progid "IE.AssocFile.WEBSITE" -Appname "Internet Explorer"
.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension "http" -Progid "IE.HTTP" -Appname "Internet Explorer"
.\Modify-AppAssocXmlv1.2.ps1 -Path "C:\Program Files\SVV\Filassosiasjoner\DefaultAppAssociations.xml" -Extension "https" -Progid "IE.HTTPS" -Appname "Internet Explorer"






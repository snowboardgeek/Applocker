# ChangeADGroupMembership.ps1
# Script By: glen nygaard
# Create a user list located in C:\Data\ADUser.csv
# create a csv like this: Column A = Username and paste in the users
# Edit line 17 and the following lines matching to your environment AD groups


# Import AD module
Import-module ActiveDirectory

# Store the data from ADUser.csv in the $List variable
$List = Import-CSV c:\Data\ADUser.csv

# Loop through users in the csv
ForEach ($User in $List)
{

# Add the specified users to the groups "" and "" in AD
Add-ADGroupMember -Identity "O365 - Excel_Force file extension to match file type" -Members $User.username
#Add-ADGroupMember -Identity Petun2 -Member $User.username
}
# ChangeADGroupMembership.ps1
# Script By: Glen Nygaard
# Create a user list located in C:\Data\ADUser.csv
# Edit line 17 and the following lines matching to your environment AD groups

# Import AD module
Import-module ActiveDirectory

# Store the data from ADUser.csv in the $List variable
$List = Import-CSV c:\Data\ADUser.csv

# Loop through users in the csv
ForEach ($User in $List)
{

# Add the specified users to the groups "Petun" and "Petun2" in AD
Add-ADGroupMember -Identity "O365 - Excel_Force file extension to match file type" -Member $User.username
#Add-ADGroupMember -Identity Petun2 -Member $User.username
}
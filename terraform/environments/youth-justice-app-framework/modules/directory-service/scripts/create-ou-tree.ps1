param (
    [Parameter(
        Position = 1)]
    [String]$Import_Folder = "C:\i2N\AD_Files",
    [Parameter(
        Position = 2)]
    [String]$OUTree_File = "OUTree-Default.csv"
)

$OUTreeFilePath        = "${Import_Folder}\${OUTree_File}"

  #import custom OU structure 
  $OUs = import-csv $OUTreeFilePath
  ForEach ($OU in $OUs)
        {New-ADOrganizationalUnit -Name $OU.Name -Path $OU.OUPath}
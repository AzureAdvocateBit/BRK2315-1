$results = cmd.exe /C winrm s winrm/config/client '@{TrustedHosts="poc-eus-admin"}'

$folder = "c:\temp"
$log = "c:\temp\azurelog.txt"
$date = Get-Date


New-Item -Path $folder -ItemType Directory
New-Item -Path $log -ItemType File
Add-Content -Value " WinRM and Remote Powershell setup - $date $results" -Path $log
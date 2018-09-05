# sign in
Write-Host "Logging in ...";
Login-AzureRmAccount | Out-Null

# select subscription
$subscriptionId = Read-Host -Prompt 'Input your Subscription ID'
$Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId | out-null

$rgname = "Igloo-POC-PR"

$Vnet= "Vnet-Igloo-POC"


#Check Available IP addresses
$networkID = "192.168.116."
For ($i=1; $i -lt 255; $i++) 
{
    $IP = $networkID + $i
    $Address =Get-AzureRmVirtualNetwork -Name $Vnet -ResourceGroupName $rgname | Test-AzureRmPrivateIPAddressAvailability -IPAddress $IP
    If ($Address.Available –eq $False) { Write-Host "$IP is not available" -ForegroundColor Red } else { Write-Host "$IP is available" -ForegroundColor Green}
}

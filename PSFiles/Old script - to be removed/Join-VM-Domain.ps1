#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"
$starttime = get-date

#region Prep & signin

# sign in
Write-Host "Logging in ...";
#Login-AzureRmAccount | Out-Null

# select subscription
#$subscriptionId = Read-Host -Prompt 'Input your Subscription ID'
#Select-AzureRmSubscription -SubscriptionID $subscriptionId | out-null

# select Resource Group
#$ResourceGroupName = Read-Host -Prompt 'Input the resource group for your network'

# select Location
#$Location = Read-Host -Prompt 'Input the Location for your network'

# select Location
#$VMListfile = Read-Host -Prompt 'Input the Location of the list of VMs to be created'

# Define a credential object
#Write-Host "You Will now be asked for a UserName and Password that will be applied to the windows Virtual Machine that will be created";
#$cred = Get-Credential 

#endregion
#>

#region Set Template and Parameter location

$Date = Get-Date -Format yyyyMMdd
$domainToJoin = "iglooaz.local"

#endregion

#region Deployment of VM from VMlist.CSV

$VMList = Import-CSV $VMListfile

ForEach ( $VM in $VMList) {

    $VMName = $VM.ServerName
    $VMsubnet = $VM.subnet
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName
    $vnetname = $vnet.Name
    $VMOS = $VM.OS

    if ($VMOS -eq "Windows") {
        Write-Output "     Joining '$vmName' to '$domainToJoin'..."
        $domainAdminUser= $domainToJoin + "\" + $cred.UserName.ToString()
        $domPassword= $cred.GetNetworkCredential().Password
        $DomainJoinPassword = $cred.Password

        $Results = Set-AzureRMVMExtension -VMName $VMName -ResourceGroupName $ResourceGroupName `
            -Name "JoinAD" `
            -ExtensionType "JsonADDomainExtension" `
            -Publisher "Microsoft.Compute" `
            -TypeHandlerVersion "1.3" `
            -Location $Location.ToString() `
            -Settings @{ "Name" = $domainToJoin.ToString(); "User" = $domainAdminUser.ToString(); "Restart" = "true"; "Options" = 3} `
            -ProtectedSettings @{"Password" = $domPassword}
        
        if ($Results.StatusCode -eq "OK"){
             Write-Output "     Successfully joined domain '$domainToJoin.ToString()'..."
        }
        Else{
             Write-Output "     Failled to join domain '$domainToJoin.ToString()'..."
        }
    }
}

#endregion

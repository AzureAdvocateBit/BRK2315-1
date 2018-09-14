#******************************************************************************
# Script Functions
# Execution begins here
#******************************************************************************
#region Functions
function Login {
    $needLogin = $true
    Try {
        $content = Get-AzureRmContext
        if ($content) {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch {
        if ($_ -like "*Login-AzureRmAccount to login*") {
            $needLogin = $true
        } 
        else {
            throw
        }
    }

    if ($needLogin) {
        $content=Login-AzureRmAccount
    }
    $content = Get-AzureRmContext
    return $content
}

#endregion


#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"
$starttime = get-date
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath


#region Prep & signin

# sign in
Write-Host "Logging in ...";
$AccountInfo=Login

# select subscription
$subscriptionId = $AccountInfo.Subscription.Id
Select-AzureRmSubscription -SubscriptionID $subscriptionId | out-null

# select Resource Group
$ResourceGroupName = "BRK2315Demo1"

# select Location
$Location = "Eastus"

# select Location
$VMListfile = $ScriptDir + "\csv_files\VMList.csv"

# Define a credential object
Write-Host "You Will now be asked for a UserName and Password that will be applied to the windows Virtual Machine that will be created";
$cred = Get-Credential

#region Set Template and Parameter location

# set  Root Uri of GitHub Repo (select AbsoluteUri)

$TemplateRootUriString = "https://raw.githubusercontent.com/pierreroman/BRK2315/master/ARM/"
$TemplateURI = New-Object System.Uri -ArgumentList @($TemplateRootUriString)

$TemplateAS = $TemplateURI.AbsoluteUri + "VMTemplate-AS.json"
$Template = $TemplateURI.AbsoluteUri + "VMTemplate.json"
$DCTemplate = $TemplateURI.AbsoluteUri + "AD-2DC.json"
$ASTemplate = $TemplateURI.AbsoluteUri + "AvailabilitySet.json"
$NSGTemplate = $TemplateURI.AbsoluteUri + "nsg.azuredeploy.json"
$StorageTemplate = $TemplateURI.AbsoluteUri + "VMStorageAccount.json"
$VnetTemplate = $TemplateURI.AbsoluteUri + "vnet-subnet.json"
$ASCTemplate = $TemplateURI.AbsoluteUri + "AvailabilitySetClassic.json"

$domainToJoin = "AzurePOC.local"

#endregion

# Start the deployment
Write-Output "Starting deployment"

Get-AzureRmResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0  | Out-Null

if ($notPresent) {
    Write-Output "Could not find resource group '$ResourceGroupName' - will create it."
    Write-Output "Creating resource group '$ResourceGroupName' in location '$Location'...."
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force

}
else {
    Write-Output "Using existing resource group '$ResourceGroupName'"
}

#endregion

#region Deployment of virtual network
Write-Output "Deploying virtual network..."

$Vnet_Results = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $VnetTemplate -TemplateParameterObject `
    @{ `
        vnetname='Vnet-POC'; `
        VnetaddressPrefix = '192.168.0.0/17'; `
        mgmtsubnetsname = 'mgmt'; `
        mgmtsubnetaddressPrefix = '192.168.105.0/24'; `
        publicdmzinsubnetsname = 'Inside'; `
        publicdmzinsubnetaddressPrefix = '192.168.114.0/24'; `
        publicdmzoutsubnetsname = 'Outside'; `
        publicdmzoutsubnetaddressPrefix = '192.168.113.0/24'; `
        websubnetsname = 'web'; `
        websubnetaddressPrefix = '192.168.115.0/24'; `
        bizsubnetsname = 'biz';`
        bizsubnetaddressPrefix = '192.168.116.0/24'; `
        datasubnetsname = 'data';`
        datasubnetaddressPrefix = '192.168.102.0/24'; `
        Gatewaysubnetsname = 'GatewaySubnet'; `
        GatewaysubnetaddressPrefix = '192.168.127.0/24'; `
    } -Force | out-null

$VNetName = $Vnet_Results.Outputs.VNetName.Value
$VNetaddressPrefixes =  $Vnet_Results.Outputs.VNetaddressPrefixes.Value

#endregion

#region Deployment of Storage Account
Write-Output "Deploying Storage Accounts..."
$DeploymentName = Get-Date -Format FileDateTime
$SA_Results = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $StorageTemplate -TemplateParameterObject `
    @{ `
        stdname = 'standardsa'; `
        premname = 'premiumsa'; `
        logname = 'logsa'; `
    } -Force

$std_storage_account=$SA_Results.Outputs.stdsa.Value
$prem_storage_account=$SA_Results.Outputs.premsa.Value
$log_storage_account=$SA_Results.Outputs.logsa.Value


Set-AzureRmCurrentStorageAccount -Name $std_storage_account -ResourceGroupName $ResourceGroupName | out-null

New-AzureStorageContainer -Name logs | out-null

#endregion

#region Deployment of Availability Sets

Write-Output "Starting deployment of Availability Sets"

$ASList = Import-CSV $VMListfile | Where-Object {$_.AvailabilitySet -ne "None"}
$ASListUnique = $ASList.AvailabilitySet | select-object -unique

ForEach ( $AS in $ASListUnique)
{
    $ASName=$AS
    $DeploymentName = Get-Date -Format FileDateTime
    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $ASTemplate -TemplateParameterObject `
        @{ AvailabilitySetName = $ASName.ToString() ; `
            faultDomains = 2 ; `
            updateDomains = 5 ; `
        } -Force | out-null
}
#endregion

#region Deployment of NSG

Write-Output "Starting deployment of NSG"

$NSGList = Import-CSV $VMListfile
$NSGListUnique = $NSGList.subnet | select-object -unique

ForEach ( $NSG in $NSGListUnique){
    $NSGName=$NSG+"-nsg"
    $DeploymentName = Get-Date -Format FileDateTime
    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $NSGTemplate -TemplateParameterObject `
        @{`
            networkSecurityGroupName=$NSGName.ToString(); `
         } -Force | out-null
}
#endregion

#region Deployment of DC
Write-Output "Starting deployment of New Domain with Controller..."
$DeploymentName = 'Domain-DC-'+ $Date

$userName=$cred.UserName
$password=$cred.GetNetworkCredential().Password

New-AzureRmResourceGroupDeployment -Name 'domain-AS' -ResourceGroupName $ResourceGroupName -TemplateFile $ASCTemplate -TemplateParameterObject `
    @{ AvailabilitySetName = 'POC-DC-AS' ; `
        faultDomains = 2 ; `
        updateDomains = 5 ; `
    } -Force | out-null

$DC_Results = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $DCTemplate -TemplateParameterObject `
    @{ `
        storageAccountName = $std_storage_account; `
        DCVMName = 'poc-eus-dc1'; `
        adminUsername = $userName; `
        adminPassword = $password; `
        domainName = 'AzurePOC.local'
        adAvailabilitySetName = 'POC-DC-AS'; `
        virtualNetworkName = 'Vnet-POC'; `
    } -Force | out-null

#endregion

#region Update DNS with IP from DC set above

Write-Output "Updating Vnet DNS to point to the newly create DC..."

$vmname = "poc-eus-dc1"
$vms = get-azurermvm
$nics = get-azurermnetworkinterface | where VirtualMachine -NE $null #skip Nics with no VM

foreach($nic in $nics)
{
    $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
    $prv =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
    if ($($vm.Name) -eq $vmname)
    {
        $IP = $prv
        break
    }
}

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -name 'Vnet-POC'
$vnet.DhcpOptions.DnsServers = $IP 
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

#endregion

#region Deployment of VM from VMlist.CSV

$VMList = Import-CSV $VMListfile

ForEach ( $VM in $VMList) {
    $VMName = $VM.ServerName
    $ASname = $VM.AvailabilitySet
    $VMsubnet = $VM.subnet
    $VMOS = $VM.OS
    $VMStorage = $vm.StorageAccount
    $VMSize = $vm.VMSize
    $VMDataDiskSize = $vm.DataDiskSize
    $DataDiskName = $VM.ServerName + "Data"
    $VMImageName = $vm.ImageName
    $Nic = $VMName + '-nic'
   

    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName
    $vnetname = $vnet.Name
    
    Get-AzureRmVM -Name $vmName -ResourceGroupName $ResourceGroupName -ev notPresent -ea 0 | out-null

    if ($notPresent) {
        Write-Output "Deploying $VMOS VM named '$VMName'..."
        $DeploymentName = 'VM-' + $VMName + '-' + $Date

        if ($ASname -eq "None") {
            New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $Template -TemplateParameterObject `
            @{ `
                    virtualMachineName            = $VMName; `
                    virtualMachineSize            = $VMSize; `
                    adminUsername                 = $cred.UserName; `
                    virtualNetworkName            = $vnetname; `
                    networkInterfaceName          = $Nic; `
                    adminPassword                 = $cred.Password; `
                    diagnosticsStorageAccountName = 'logsaiwrs4jpmap5k4'; `
                    subnetName                    = $VMsubnet; `
                    ImageURI                      = $VMImageName; `
            
            } -Force | out-null
        }
        else {
            New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateAS -TemplateParameterObject `
            @{ `
                    virtualMachineName            = $VMName; `
                    virtualMachineSize            = $VMSize; `
                    adminUsername                 = $cred.UserName; `
                    virtualNetworkName            = $vnetname; `
                    networkInterfaceName          = $Nic; `
                    adminPassword                 = $cred.Password; `
                    availabilitySetName           = $ASname.ToLower(); `
                    diagnosticsStorageAccountName = 'logsaiwrs4jpmap5k4'; `
                    subnetName                    = $VMsubnet; `
                    ImageURI                      = $VMImageName; `
            
            } -Force | out-null
        }

        if ($VMDataDiskSize -ne "None") {
            Write-Output "     Adding Data Disk to '$vmName'..."
            $storageType = 'StandardLRS'
            $dataDiskName = $vmName + '_datadisk1'

            $diskConfig = New-AzureRmDiskConfig -AccountType $storageType -Location $location -CreateOption Empty -DiskSizeGB $VMDataDiskSize
            $dataDisk1 = New-AzureRmDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $ResourceGroupName
            $VMdiskAdd = Get-AzureRmVM -Name $vmName -ResourceGroupName $ResourceGroupName 
            $VMdiskAdd = Add-AzureRmVMDataDisk -VM $VMdiskAdd -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
            Update-AzureRmVM -VM $VMdiskAdd -ResourceGroupName $ResourceGroupName | out-null
        }
        if ($VMOS -eq "Windows") {
            Write-Output "     Joining '$vmName' to '$domainToJoin'..."
            $domainAdminUser = $domainToJoin + "\" + $cred.UserName.ToString()
            $domPassword = $cred.GetNetworkCredential().Password
            $DomainJoinPassword = $cred.Password

            $Results = Set-AzureRMVMExtension -VMName $VMName -ResourceGroupName $ResourceGroupName `
                -Name "JoinAD" `
                -ExtensionType "JsonADDomainExtension" `
                -Publisher "Microsoft.Compute" `
                -TypeHandlerVersion "1.3" `
                -Location $Location.ToString() `
                -Settings @{ "Name" = $domainToJoin.ToString(); "User" = $domainAdminUser.ToString(); "Restart" = "true"; "Options" = 3} `
                -ProtectedSettings @{"Password" = $domPassword}
        
            if ($Results.StatusCode -eq "OK") {
                Write-Output "     Successfully joined domain '$domainToJoin.ToString()'..."
            }
            Else {
                Write-Output "     Failled to join domain '$domainToJoin.ToString()'..."
            }
        }
    }
    else {
        Write-Output "Virtual Machine '$VMName' already exist and will be skipped..."
    }
}

#endregion

$endtime = get-date
$procestime = $endtime - $starttime
$time = "{00:00:00}" -f $procestime.Minutes
write-host " Deployment completed in '$time' "


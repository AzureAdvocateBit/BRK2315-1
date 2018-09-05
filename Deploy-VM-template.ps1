$PSScriptRoot#******************************************************************************
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
#Login-AzureRmAccount | Out-Null
$AccountInfo=Login

# select subscription
$subscriptionId = $AccountInfo.Subscription.Id
#$subscriptionId = Read-Host -Prompt 'Input your Subscription ID'
Select-AzureRmSubscription -SubscriptionID $subscriptionId | out-null

# select Resource Group
#$ResourceGroupName = Read-Host -Prompt 'Input the resource group for your network'
$ResourceGroupName = "BRK2315-PS-Demo1"

# select Location
#$Location = Read-Host -Prompt 'Input the Location for your network'
$Location = "Eastus"

# select Location
#$VMListfile = Read-Host -Prompt 'Input the Location of the list of VMs to be created'
$VMListfile = $ScriptDir + "\PSFiles\VMList.csv"

# Define a credential object
Write-Host "You Will now be asked for a UserName and Password that will be applied to the windows Virtual Machine that will be created";
$Wincred = Get-Credential 

# Define a credential object
Write-Host "You Will now be asked for a UserName and Password that will be applied to the linux Virtual Machine that will be created";
$Linuxcred = Get-Credential 
#endregion


#region Set Template and Parameter location

$Date = Get-Date -Format yyyyMMdd

# set  Root Uri of GitHub Repo (select AbsoluteUri)

$TemplateRootUriString = "https://raw.githubusercontent.com/pierreroman/Igloo-POC/master/"
$TemplateURI = New-Object System.Uri -ArgumentList @($TemplateRootUriString)

$TemplateAS = $TemplateURI.AbsoluteUri + "VMTemplate-AS.json"
$Template = $TemplateURI.AbsoluteUri + "VMTemplate.json"

$domainToJoin = "iglooaz.local"

#endregion

#region check if image exist

$Image = Import-CSV $VMListfile| % {$_.ImageName}
$Image = $Image | select -uniq

ForEach ( $ImageName in $Image) {
    Get-AzureRmImage -ImageName $ImageName -ResourceGroupName $ResourceGroupName -ev notPresent -ea 0 | out-null
    Write-Output "Image $ImageName does not exist'..."
}



<#
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
   
    switch ($VMOS) {
        "Linux" {$cred = $Linuxcred}
        "Windows" {$cred = $Wincred}
        Default {Write-Host "No OS Defined...."}
    }

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
#>


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

# Define a credential object
#Write-Host "You Will now be asked for a UserName and Password that will be applied to the linux Virtual Machine that will be created";
#$Linuxcred = Get-Credential 
#endregion



$Windows2012sourceImageUri = 'https://igloostoragestdpocw.blob.core.windows.net/vhds/Windows2012R220170612221756.vhd'
$CentOS6sourceImageUri = 'https://igloostoragestdpocw.blob.core.windows.net/vhds/centos6temp220170612211517.vhd'
$CentOS7sourceImageUri = 'https://igloostoragestdpocw.blob.core.windows.net/vhds/centos7temp20170612170035.vhd'


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

    $storageAcc = Get-AzureRmStorageAccount -AccountName $VMStorage -ResourceGroupName $ResourceGroupName
    
    Write-Host "Processing '$VMName'...."
    Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName -ev notPresent -ea 0  | Out-Null

    if ($notPresent) {
        if ($ASname -ne "None") {
            Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -name $ASname -ev notPresent -ea 0  | Out-Null
            if ($notPresent) {
                Write-Output "Could not find Availability Set '$ASname'in '$ResourceGroupName' - It will be created."
                Write-Output "Creating Availability Set '$ASname'...."
                Write-host 
                New-AzureRmAvailabilitySet -Location $Location -Name $ASname -ResourceGroupName $ResourceGroupName | out-null
                $AS = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -name $ASname
                $ASID = $as.Id
            }
            else {
                Write-Output "Using existing Availability Set '$ASname'...."
                Write-host 
                $AS = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -name $ASname
                $ASID = $as.Id
            }
        }
        else {
            write-host "Virtual Machine not part of an availability set"
        }
   
        $vnet = Get-AzureRMVirtualNetwork -ResourceGroupName $ResourceGroupName
        $Subnets = $vnet.Subnets
    
        foreach ($Items in $Subnets) {
            $subnetname = $Items.Name
            if ($subnetname -eq $VMsubnet) {
                $subnetID = $Items.Id
                $nic = New-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -Location $location -SubnetId $subnetID -Force
                $nicID = $nic.Id
            }
        }

        if ($VMOS -eq "Windows") {

            if ($ASname -eq "None") {
                $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
            }
            else {
                Write-Host "Adding '$VMName' to '$ASname'...."
                $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $ASID
            }

            $vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nicID
            $vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $cred
            
            $diskName = $VMName + 'OsDisk'
            $osDiskUri = '{0}vhds/{1}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $diskName

            $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $Windows2012sourceImageUri -Windows


            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig
               
            if ($VMDataDiskSize -ne "none") {
                $DataDiskName = $VMName + "DataDisk"
                $DATADiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName + ".vhd"
                $Myvm = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName
                Add-AzureRmVMDataDisk -VM $Myvm -Name $DataDiskName -VhdUri $DATADiskUri -LUN 0 -Caching ReadOnly -DiskSizeinGB $VMDataDiskSize -CreateOption Empty | out-null
                Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $Myvm
            }
        }
        else {

            if ($ASname -eq "None") {
                $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
            }
            else {
                Write-Host "Adding '$VMName' to '$ASname'...."
                $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $ASID
            }
        
            $vmConfig = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nicID
            $vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential $Linuxcred

            $diskName = $VMName + 'OsDisk'
            $osDiskUri = '{0}vhds/{1}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $diskName

            if ($VMImageNAme -eq "CentOS6") {
                $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $CentOS6sourceImageUri -Linux
            }
            else {
                $vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $CentOS7sourceImageUri -Linux
            }
            Write-Host "create VM"

            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig

            if ($VMDataDiskSize -ne "none") {
                $DataDiskName = $VMName + "DataDisk"
                $DATADiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName + ".vhd"
                $Myvm = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName
                Add-AzureRmVMDataDisk -VM $Myvm -Name $DataDiskName -VhdUri $DATADiskUri -LUN 0 -Caching ReadOnly -DiskSizeinGB $VMDataDiskSize -CreateOption Empty | out-null
                Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $Myvm
            }
        }
    }
}
    #endregion
workflow Startup-DR
{   
    $starttime = get-date
    #connecting to the subscription using the AzureRunAsConnection

    $connectionName = "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName      
    "Logging in to Azure..."
    $account = Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

    write-Output $account
    
    #Select Azure Subscription
    $subscriptionId = "213b7faa-90e1-47d5-8ca6-9f98bb30758d"
    Select-AzureRmSubscription -SubscriptionID $subscriptionId

    #Identify Resource Group Target that include 'POC-DR' in the Resource Group name
    $ResourceGroups = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -match "POC-dr"}

        # enumerate the resource groups and process each of them
        foreach ($RGs in $ResourceGroups)
        {
            $RGName=$RGs.ResourceGroupName.ToString()
            Write-Output "Starting '$RGName'"

            #enumerate all VMs in the resource group and start it DC first.
            $vms= Get-AzureRmVM -ResourceGroupName $RGName
            foreach -Parallel ($vm1 in ($vms | where{$_.Name -match 'DC'})) 
            {     
               $Name=$vm1.Name.ToString()
               $StartOutPut = Start-AzureRmVM -Name $Name -ResourceGroupName $RGName
               Write-Output $Name
               Write-Output $StartOutPut
            }
            $vms= Get-AzureRmVM -ResourceGroupName $RGName
            foreach -Parallel ($vm2 in $vms) 
            {
                $Name=$vm2.Name.ToString()
                $StartOutPut = Start-AzureRmVM -Name $Name -ResourceGroupName $RGName
                Write-Output $Name
                Write-Output $StartOutPut
            }
        }
    $endtime = get-date
    $procestime = $endtime - $starttime
    $time = "{00:00:00}" -f $procestime.Minutes
    Write-Ouput " Deployment completed in '$time' "
}
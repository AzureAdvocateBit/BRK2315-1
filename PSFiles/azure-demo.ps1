
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

### Ensure $env:PSModulePath is updated with the location you used to install.
if (Get-Module -ListAvailable -Name AzureRM) {
    Write-Host "Module exists"
  } else {
    Write-Host "Module does not exist"
    Write-Host "Installing Module..."
    Import-Module AzureRM.NetCore
  }

### Supply your Azure Credentials
# sign in
Write-Host "Logging in ...";
$AccountInfo=Login

### Specify a name for Azure Resource Group
$resourceGroupName = "PSAzDemo" + (New-Guid | ForEach-Object guid) -replace "-",""
$resourceGroupName

### Create a new Azure Resource Group
New-AzureRmResourceGroup -Name $resourceGroupName -Location "East US"

### Deploy an Ubuntu 14.04 VM using Resource Manager cmdlets
### Template is available at
### http://armviz.io/#/?load=https:%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F101-vm-simple-linux%2Fazuredeploy.json
$dnsLabelPrefix = $resourceGroupName | ForEach-Object tolower
$dnsLabelPrefix

#[SuppressMessage("Microsoft.Security", "CS002:SecretInNextLine", Justification="Demo/doc secret.")]
$password = ConvertTo-SecureString -String "PowerShellRocks!" -AsPlainText -Force
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ./Compute-Linux.json -adminUserName psuser -adminPassword $password -dnsLabelPrefix $dnsLabelPrefixNew-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ./Compute-Linux.json -adminUserName psuser -adminPassword $password -dnsLabelPrefix $dnsLabelPrefix

### Monitor the status of the deployment
Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName

### Discover the resources we created by the previous deployment
Find-AzureRmResource -ResourceGroupName $resourceGroupName | Select-Object Name,ResourceType,Location

### Get the state of the VM we created
### Notice: The VM is in running state
Get-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName -ODataQuery '$expand=instanceView' | ForEach-Object properties | ForEach-Object instanceview | ForEach-Object statuses

### Discover the operations we can perform on the compute resource
### Notice: Operations like "Power Off Virtual Machine", "Start Virtual Machine", "Create Snapshot", "Delete Snapshot", "Delete Virtual Machine"
Get-AzureRmProviderOperation -OperationSearchString Microsoft.Compute/* | Select-Object OperationName,Operation

### Power Off the Virtual Machine we created
Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Compute/virtualMachines -ResourceName MyUbuntuVM -Action poweroff

### Check the VM state again. It should be stopped now.
Get-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName -ODataQuery '$expand=instanceView' | ForEach-Object properties | ForEach-Object instanceview | ForEach-Object statuses

### As you know, you may still be incurring charges even if the VM is in stopped state
### Deallocate the resource to avoid this charge
Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Compute/virtualMachines -ResourceName MyUbuntuVM -Action deallocate

### The following command removes the Virtual Machine
Remove-AzureRmResource -ResourceName MyUbuntuVM -ResourceType Microsoft.Compute/virtualMachines -ResourceGroupName $resourceGroupName

### Look at the resources that still exists
Find-AzureRmResource -ResourceGroupName $resourceGroupName | Select-Object Name,ResourceType,Location

### Remove the resource group and its resources
Remove-AzureRmResourceGroup -Name $resourceGroupName
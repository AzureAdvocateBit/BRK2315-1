# Ignite BRK2315 session files and demo
Code for the BRK2315 - Step away from the mouse, and no one gets hurt: Getting started with cloud command line options

Are you new to the Azure platform? That okay, we all started there. The Azure Portal is great for getting oriented and up and running, but to achieve a higher level of existence – you need to power up your command line skills. Come to this session if you are new to Azure command line tools and capabilities. Learn what you need to know, and what you can do, to deploy and manage your Azure environment using the available command tool options - PowerShell, Azure CLI, ARM templates, and more. We cover setup, update, usage, security, and script management.

# POC
Soft-POC-Deployment

This document Outlines the requirements for the deployment of the base infrastructure for a POC environment in Azure.

The process requires to execute multiple script using PowerShell.  You need to ensure your version of the command-line tools to manage your Azure services.  The updated version can be found <a href="https://www.microsoft.com/web/handlers/webpi.ashx/getinstaller/WindowsAzurePowershellGet.3f.3f.3fnew.appids" target="_blank">here</a> (https://www.microsoft.com/web/handlers/webpi.ashx/getinstaller/WindowsAzurePowershellGet.3f.3f.3fnew.appids).  The current version is v4.2.1 it was released on July 18 2017.

Files Included in this Repo:

1. PSFiles folder: The Powershell scripts
2. DSC folder: Desired Configuration Scripts for the DC and Domain Creation
3. csv_files: the list of vm required for the solution in a CSV format
4. custom_script: misc scripts used in the original POC.
5. Root:  JSON templates and Readme.md (this file)


# Deploy-ReferenceArchitecture.ps1

This script is the main script for the deployment of the infrastructure located in the PSFiles folder.

**This PowerShell script will deploy the following:**

* Resource Group
* Virtual Network using the vnet-subnet.json template
* Storage Accounts using the VMStorageAccount.json template
* Availability Sets using the AvailabilitySet.json template
* New Domain with Controller using the AD-2DC.json template
* Network Security Group using the nsg.azuredeploy.json template

It will also update the Vnet DNS definition to point to the newly create DC.  It will ask for the location on the VMList.csv where all the required VM are listed.  it will use the info in that list for the NSGs and Availability sets.

To execute the script, fork the repo to your own github subscription and clone it locally.  from the local copy execute:

.\Deploy-ReferenceArchitecture.ps1

**The script will ask you to input the following:**

1. Input your Subscription ID = The subscription you want to deploy to.
2. Input the resource group for your network = the Resource Group Name you want to deploy the solution to.
3. Input the Location for your network = the Azure Region you need to deploy to.  i.e.: 'West US' or 'East US 2'
4. Input the Location of the list of VMs to be created = the path and file name where the list of VM is defined.  i.e: C:\Users\PierreRoman\git\BRK2315\csv_files\VMList.csv
5. The script will prompt for username and credentials to be used for the creation of the VMs in this Resource Group.
 

![](https://github.com/pierreroman/BRK2315/blob/master/_images/executescript.png)

# Deploy-VM-template.ps1

This script is the script for the deployment of all the Virtual machines that make up the POC Solution.  It will utilize the information listed in the CSV file located in the csv_files folder in order to deploy the vms properly.

the info in the CSV is formatted with the following fields.

> Server,servername,OS,ImageName,StorageAccount,subnet,AvailabilitySet,DataDiskSize,VMSize

the script when executed, will ask for the following:

* Subscription ID
* Target Resource Group
* Location
* Location of the CSV file.
* Credentials for the Windows and Linux machines



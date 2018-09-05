az vm deallocate --resource-group Igloo-POC-rg --name centos7temp
az vm generalize --resource-group Igloo-POC-rg --name centos7temp
az image create --resource-group Igloo-POC-rg --name Centos6 --source centos7temp
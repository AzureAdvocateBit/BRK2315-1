az group create --name demo1 --location eastus
az group create --name demo2 --location eastus
az group create --name demo3 --location eastus
az group create --name demo4 --location eastus
az group create --name demo5 --location eastus
az container create --name mycontainer1 --image microsoft/aci-helloworld --resource-group demo1 --ip-address public
az container create --name mycontainer2 --image microsoft/aci-helloworld --resource-group demo2 --ip-address public
az container create --name mycontainer3 --image microsoft/aci-helloworld --resource-group demo3 --ip-address public
az container create --name mycontainer4 --image microsoft/aci-helloworld --resource-group demo4 --ip-address public
az container create --name mycontainer5 --image microsoft/aci-helloworld --resource-group demo5 --ip-address public

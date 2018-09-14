$CLIcontainer = docker ps --filter ancestor=azuresdk/azure-powershell-core:latest --filter status=running -q
If ($CLIcontainer) {
    docker attach $CLIcontainer
} 
else {
    docker pull azuresdk/azure-powershell-core:latest
    docker run -it -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/git:/root/git azuresdk/azure-powershell-core:latest
}
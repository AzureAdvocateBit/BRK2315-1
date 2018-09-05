$CLIcontainer = docker ps --filter ancestor=microsoft/azure-cli --filter status=running -q
If ($CLIcontainer) {
    docker attach $CLIcontainer
} 
else {
    docker pull microsoft/azure-cli
    docker run -it -v ${HOME}/.ssh:/root/.ssh -v ${HOME}/git:/root/git microsoft/azure-cli
}
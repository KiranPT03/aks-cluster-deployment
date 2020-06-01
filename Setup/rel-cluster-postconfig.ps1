param([Parameter(Mandatory=$false)] [string] $resourceGroup = "jio-iot-platform",
        [Parameter(Mandatory=$false)] [string] $clusterName = "jio-iot-aks-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "jioiotacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "jio-iot-kv",
        [Parameter(Mandatory=$false)] [string] $appgwName = "jio-iot-appgw",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "jio-iot-vnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "jio-iot-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "174.0.0.255",
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "rel-appgw-deploy",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/root/aks_tutorial/azure_deploy_script/Deployments/")


$projectName = "rel-iot"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"
$devNamespace = $projectName + "-dev"
$qaNamespace = $projectName + "-qa"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"

$acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$acrInfo)
{

    Write-Host "Error creating ACR info"
    return;

}

Write-Host $acrInfo.Id

$acrUserName = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPIdName
if (!$acrUserName)
{

    Write-Host "Error fetching ACR UserName"
    return;

}

$acrPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPSecretName
if (!$acrPassword)
{

    Write-Host "Error fetching ACR Password"
    return;

}

$dockerServer = $acrInfo.LoginServer
$dockerUserName = $acrUserName.SecretValueText
$dockerPassword = $acrPassword.SecretValueText

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Docker Login command
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"
Invoke-Expression -Command $dockerLoginCommand

# Configure ILB file
$ipReplaceCommand = "sed -e 's|<ILB_IP>|$ingControllerIPAddress|' $yamlFilePath/Common/$ingControllerFileName.yaml > $yamlFilePath/Common/tmp.$ingControllerFileName.yaml"
Invoke-Expression -Command $ipReplaceCommand
# Remove temp ILB file
$removeTempFileCommand = "mv $yamlFilePath/Common/tmp.$ingControllerFileName.yaml $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $removeTempFileCommand

# Create Namespaces
# DEV NS
$namespaceCommand = "kubectl create ns $devNamespace"
Invoke-Expression -Command $namespaceCommand

# QA NS
$namespaceCommand = "kubectl create ns $qaNamespace"
Invoke-Expression -Command $namespaceCommand

# nginx NS
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxILBCommand = "helm install $ingControllerName stable/nginx-ingress --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$networkNames = "-appgwName $appgwName -vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName -backendIPAddress $ingControllerIPAddress $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "Post-Config Successfully Done!"

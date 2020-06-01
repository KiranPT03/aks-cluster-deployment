param([Parameter(Mandatory=$false)] [string] $resourceGroup = "jio-iot-platform",
        [Parameter(Mandatory=$false)] [string] $clusterName = "jio-iot-aks-cluster",
        [Parameter(Mandatory=$false)] [string] $appNameKey = "APPNAME",
        [Parameter(Mandatory=$false)] [string] $appNameValue = "iotaks",
        [Parameter(Mandatory=$false)] [string] $ownerKey = "OWNER",
        [Parameter(Mandatory=$false)] [string] $ownerValue = "kiran.tavadare@ril.com",
        [Parameter(Mandatory=$false)] [string] $categoryKey = "CATEGORY",
        [Parameter(Mandatory=$false)] [string] $categoryValue = "JIO",
        [Parameter(Mandatory=$false)] [string] $envKey = "ENV",
        [Parameter(Mandatory=$false)] [string] $envValue = "DEV",
        [Parameter(Mandatory=$false)] [string] $location = "centralindia",
        [Parameter(Mandatory=$false)] [string] $userEmail = "kiran.tavadare@jioazurecloud.onmicrosoft.com",
        [Parameter(Mandatory=$false)] [string] $acrName = "jioiotacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "jio-iot-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "jio-iot-vnet",
        [Parameter(Mandatory=$false)] [string] $aksVNetPrefix = "174.0.0.0/16",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "jio-iot-subnet",
        [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix = "174.0.0.0/18",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "jio-iot-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix = "174.0.64.0/24",        
        [Parameter(Mandatory=$false)] [string] $appgwName = "jio-iot-appgw",        
        [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "rel-network-deploy",        
        [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "rel-acr-deploy",
        [Parameter(Mandatory=$false)] [string] $keyVaultTemplateFileName = "rel-keyvault-deploy",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "670e49bd-e963-404f-94f1-6aa5143aa638",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/root/aks_tutorial/azure_deploy_script/Deployments")

$projectName = "rel-iot"
$vnetRole = "Network Contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$certSecretName = $appgwName + "-cert-secret"
$logWorkspaceName = $projectName + "-lw"
$templatesFolderPath = $baseFolderPath + "/Templates"
$certPFXFilePath = $baseFolderPath + "/Certs/rel-iot.pfx"

# Assuming Logged In

# GET ObjectID
$loggedInUser = Get-AzADUser -UserPrincipalName $userEmail
$objectId = $loggedInUser.Id

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/$keyVaultTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $keyVaultTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$rgRef)
{

   $rgRef = New-AzResourceGroup -Name $resourceGroup -Location $location
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

}

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName 
if (!$logWorkspace)
{
   
   $logWorkspace = New-AzOperationalInsightsWorkspace `
   -ResourceGroupName $resourceGroup `
   -Location $location -Name $logWorkspaceName
   if (!$logWorkspace)
   {
        Write-Host "Error creating Log Workspace"
        return;
   }
}

$aksSP = New-AzADServicePrincipal -SkipAssignment
if (!$aksSP)
{

    Write-Host "Error creating Service Principal for AKS"
    return;

}

Write-Host $aksSP.DisplayName
Write-Host $aksSP.Id
Write-Host $aksSP.ApplicationId

$acrSP = New-AzADServicePrincipal -SkipAssignment
if (!$acrSP)
{

    Write-Host "Error creating Service Principal for ACR"
    return;

}

Write-Host $acrSP.DisplayName
Write-Host $acrSP.Id
Write-Host $acrSP.ApplicationId

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

Write-Host $certPFXFilePath
$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force
Write-Host $certPFXFilePath

$aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
-SecretValue $aksSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
-SecretValue $aksSP.Secret

$acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
-SecretValue $acrSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
-SecretValue $acrSP.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $aksSP.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if ($acrInfo)
{

    Write-Host $acrInfo.Id
    New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
    -Scope $acrInfo.Id -RoleDefinitionName acrpush

}

Write-Host "Pre-Config Successfully Done!"

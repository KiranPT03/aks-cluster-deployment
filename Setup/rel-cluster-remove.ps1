param([Parameter(Mandatory=$false)] [string] $resourceGroup = "jio-iot-platform",
        [Parameter(Mandatory=$false)] [string] $clusterName = "jio-iot-aks-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "jioiotacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "jio-iot-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "jio-iot-vnet",
        [Parameter(Mandatory=$false)] [string] $appgwName = "jio-iot-appgw",        
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "670e49bd-e963-404f-94f1-6aa5143aa638")

$projectName = "rel-iot"
$aksSPIdName = $clusterName + "-sp-id"
$publicIpAddressName = "$appgwName-pip"
$subscriptionCommand = "az account set -s $subscriptionId"
$logWorkspaceName = $projectName + "-lw"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzApplicationGateway -Name $appgwName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup -Force

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Remove-AzOperationalInsightsWorkspace `
-ResourceGroupName $resourceGroup `
-Name $logWorkspaceName -Force

Write-Host "Remove Successfully Done!"

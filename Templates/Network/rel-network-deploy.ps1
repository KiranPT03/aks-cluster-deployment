param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$false)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $aksVNetPrefix,
        [Parameter(Mandatory=$true)] [string] $aksSubnetName,
        [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetName,
        [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix `
-aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix `
-aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix
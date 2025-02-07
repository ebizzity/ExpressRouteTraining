@description('The location of all resources')
param location string = resourceGroup().location

@description('The name of the Hub vNet')
param vNetHubName string = 'vnet-hub'

@description('The name of the Spoke vNet')
param vNetSpokeName string = 'vnet-spoke'

@description('The name of the Virtual Machine')
param vmName string = 'Azure-vm1'

@description('The size of the Virtual Machine')
param vmSize string = 'Standard_B2als_v2'

@description('The administrator username')
param adminUsername string = 'azureuser'

@description('The administrator password')
@secure()
param adminPassword string = ''

@description('The name of the Azure Bastion host')
param bastionHostName string = 'bastion2'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2016-datacenter-gensecond'
  '2016-datacenter-server-core-g2'
  '2016-datacenter-server-core-smalldisk-g2'
  '2016-datacenter-smalldisk-g2'
  '2016-datacenter-with-containers-g2'
  '2016-datacenter-zhcn-g2'
  '2019-datacenter-core-g2'
  '2019-datacenter-core-smalldisk-g2'
  '2019-datacenter-core-with-containers-g2'
  '2019-datacenter-core-with-containers-smalldisk-g2'
  '2019-datacenter-gensecond'
  '2019-datacenter-smalldisk-g2'
  '2019-datacenter-with-containers-g2'
  '2019-datacenter-with-containers-smalldisk-g2'
  '2019-datacenter-zhcn-g2'
  '2022-datacenter-azure-edition'
  '2022-datacenter-azure-edition-core'
  '2022-datacenter-azure-edition-core-smalldisk'
  '2022-datacenter-azure-edition-smalldisk'
  '2022-datacenter-core-g2'
  '2022-datacenter-core-smalldisk-g2'
  '2022-datacenter-g2'
  '2022-datacenter-smalldisk-g2'
])
param OSVersion string = '2022-datacenter-azure-edition'

param vNetHubPrefix string = '10.1.0.0/22'
@description('Gateway subnet IP prefix MUST be within vnet IP prefix address space')
param gatewaySubnetIpPrefix string = '10.1.0.0/26'
param subnetBastionPrefix string = '10.1.0.64/26'
param vNetSpokePrefix string = '10.1.4.0/24'
param subnetSpokeName string = 'Subnet-1'
param subnetSpokePrefix string = '10.1.4.0/24'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

@description('Name of ER Gateway resource')
param erGatewayName string = 'er-gw'

@description('ExpressRoute Gateway SKU')
@allowed([
  'Standard'
  'HighPerformance'
  'UltraPerformance'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
])
param gatewaySku string = 'Standard'

@description('Name of the ExpressRoute circuit')
param erCircuitName string = 'er-ckt01'

@description('ExpressRoute peering location')
param erpeeringLocation string = 'Washington DC'

@description('Name of the ExpressRoute provider')
param serviceProviderName string = 'Megaport'

@description('Tier ExpressRoute circuit')
@allowed([
  'Premium'
  'Standard'
])
param erSKU_Tier string = 'Standard'

@description('Billing model ExpressRoute circuit')
@allowed([
  'MeteredData'
  'UnlimitedData'
])
param erSKU_Family string = 'MeteredData'

@description('Bandwidth ExpressRoute circuit')
@allowed([
  50
  100
  200
  500
  1000
  2000
  5000
  10000
])
param bandwidthInMbps int = 50

@description('autonomous system number used to create private peering between the customer edge router and MSEE routers')
param peerASN int = 65001

@description('point-to-point network prefix of primary link between the customer edge router and MSEE router')
param primaryPeerAddressPrefix string = '172.16.16.0/30'

@description('point-to-point network prefix of secondary link between the customer edge router and MSEE router')
param secondaryPeerAddressPrefix string = '172.16.16.4/30'

@description('VLAN Id used between the customer edge routers and MSEE routers. primary and secondary link have the same VLAN Id')
param vlanId int = 800

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)
var gatewayPublicIpAddressName = '${erGatewayName}-pip'
var erSKU_Name = '${erSKU_Tier}_${erSKU_Family}'
var nsgName = 'nsg'

resource vNetHub 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vNetHubName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetHubPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: subnetBastionPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetIpPrefix
        }
      }
    ]
  }
}

resource vNetSpoke 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vNetSpokeName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetSpokePrefix
      ]
    }
    subnets: [
      {
        name: subnetSpokeName
        properties: {
          addressPrefix: subnetSpokePrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource vNetHubSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  parent: vNetHub
  name: 'peering-to-${vNetSpokeName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vNetSpoke.id
    }
  }
  dependsOn: [
    gateway
  ]
}

resource vNetSpokeHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  parent: vNetSpoke
  name: 'peering-to-${vNetHubName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: vNetHub.id
    }
  }
  dependsOn: [
    gateway
  ]
}

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: '${bastionHostName}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: '${vNetHub.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'ipconfig1'
      }
    ]
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: '${vmName}-nic-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${vNetSpoke.id}/subnets/${subnetSpokeName}'
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource gatewayPublicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: gatewayPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource erCircuit 'Microsoft.Network/expressRouteCircuits@2023-09-01' = {
  name: erCircuitName
  location: location
  sku: {
    name: erSKU_Name
    tier: erSKU_Tier
    family: erSKU_Family
  }
  properties: {
    serviceProviderProperties: {
      serviceProviderName: serviceProviderName
      peeringLocation: erpeeringLocation
      bandwidthInMbps: bandwidthInMbps
    }
    allowClassicOperations: false
  }
}

/* resource peering 'Microsoft.Network/expressRouteCircuits/peerings@2023-09-01' = {
  parent: erCircuit
  name: 'AzurePrivatePeering'
  properties: {
    peeringType: 'AzurePrivatePeering'
    peerASN: peerASN
    primaryPeerAddressPrefix: primaryPeerAddressPrefix
    secondaryPeerAddressPrefix: secondaryPeerAddressPrefix
    vlanId: vlanId
  }
} */

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
}


resource gateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = {
  name: erGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetHubName, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: gatewayPublicIp.id
          }
        }
        name: 'gwIPconf'
      }
    ]
    gatewayType: 'ExpressRoute'
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    vpnType: 'RouteBased'
  }
  dependsOn: [
    vNetHub
  ]
}

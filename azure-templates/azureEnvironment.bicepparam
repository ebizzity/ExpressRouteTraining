using './azureEnvironment.bicep'

param vNetHubName = 'vnet-hub'
param vNetSpokeName = 'vnet-spoke'
param vmName = 'Azure-vm1'
param vmSize = 'Standard_B2als_v2'
param adminUsername = 'azureuser'
param gatewaySubnetIpPrefix = '10.1.0.0/26'
param bastionHostName = 'bastion2'
param OSVersion = '2022-datacenter-azure-edition'
param erGatewayName = 'er-gw'
param gatewaySku = 'Standard'
param vNetHubPrefix = '10.1.0.0/22'
param subnetBastionPrefix = '10.1.0.64/26'
param vNetSpokePrefix = '10.1.4.0/24'
param subnetSpokeName = 'Subnet-1'
param subnetSpokePrefix = '10.1.4.0/24'
param securityType = 'TrustedLaunch'
param erpeeringLocation = 'Washington DC'
param erCircuitName = 'er-ckt01'
param serviceProviderName = 'Megaport'
param erSKU_Tier = 'Standard'
param erSKU_Family = 'MeteredData'
param bandwidthInMbps = 50
param peerASN = 65001
param primaryPeerAddressPrefix = '172.16.16.0/30'
param secondaryPeerAddressPrefix = '172.16.16.4/30'
param vlanId = 800


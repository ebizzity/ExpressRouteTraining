using './onpremEnvironment.bicep'

param vnetName = 'onprem-vnet'
//param location = 'North Central US'
param vnetIpPrefix = '10.20.0.0/22'
param bastionSubnetIpPrefix = '10.20.1.0/26'
param gatewaySubnetIpPrefix = '10.20.2.0/26'
param bastionHostName = 'bastionhost1'
param vpnGatewayName = 'vpngw1'
param gatewaySku = 'VpnGw1'
param vmSubnetName = 'subnet1'
param vmSubnetIpPrefix = '10.20.3.0/26'
param vmNsgName = 'vmNsg'
param vpnType = 'RouteBased'
param adminUsername = 'azureuser'
param OSVersion = '2022-datacenter-azure-edition'
param vmSize = 'Standard_B2als_v2'
param vmName = 'on-prem-vm'
param securityType = 'TrustedLaunch'


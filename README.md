**Welcome to ExpressRoute hands-on Lab!**

In this lab we will be deploying 2 Azure environments.  One environment will simulate our 'On-Prem' network, and one will be our Azure Hub and Spoke deployment.

We will be provisioning an ExpressRoute circuit from Megaport, configuring a Cisco CSR 8000v router to bring up the circuit, and finally connecting it to Azure.  We will then configure a Site-to-Site VPN from the Cisco router at Megaport to connect our ExpressRoute to on-premise.

Architecture:

todo put image here from Visio

**Step #1 - Deploy Simulated on-prem and Azure environments via templates**
  
1. On-Prem
   1. Click to Deploy to Azure - 
   2. Click to Deploy to Azure Government

2. Azure
   1. Click to Deploy to Azure - [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Febizzity%2FExpressRouteTraining%2Frefs%2Fheads%2Fmain%2Fazure-temaplates%2FazureEnvironment.json)
   2. Click to Deploy to Azure Government

**Step #2 - Create Megaport ExpressRoute and MVE**

1. Login to Megaport Portal
2. Create MVE (Megaport Virtual Edge)
   1. Ensure we have enough interfaces (3 if doing full ER Resiliency)
   2. Generate SSH Key
   3. Add Megaport Internet to Primary interfaces

   This will provision for a few minutes, when completed we will be able to get our Megaport public IP address and use it to log in to the Cisco router

   Megaport Public IP Picture

   4. Copy SSH Key into ~\.ssh folder
   5. Login to Megaport MVE

      ```
      ssh -i .ssh\sshkey mveadmin@<Megaport_Public_IP>
      
      megaport-mve-97884#
      ```

    6. Now we can begin configuring the router
    7. Let's begin with checking our interfaces

    ```
    megaport-mve-97884#show ip int brief
    Interface              IP-Address      OK? Method Status                Protocol
    GigabitEthernet1       162.43.148.51   YES DHCP   up                    up
    GigabitEthernet2       unassigned      YES unset  administratively down down
    GigabitEthernet3       unassigned      YES unset  administratively down down
    ```

    8. Next let's enter configuration mode and define our ExpressRoute interfaces

    ```
    megaport-mve-97884#conf t
    Enter configuration commands, one per line.  End with CNTL/Z.
    megaport-mve-97884(config)#interface gi2
    megaport-mve-97884(config-if)#ip address 172.16.16.1 255.255.255.252
    megaport-mve-97884(config-if)#no shut
    megaport-mve-97884(config-if)#vlan-id dot1q 800
    megaport-mve-97884(config-if-vlan-id)#interface gi3
    megaport-mve-97884(config-if)#ip address 172.16.16.5 255.255.255.252
    megaport-mve-97884(config-if)#no shut
    megaport-mve-97884(config-if)#vlan-id dot1q 800
    megaport-mve-97884(config-if-vlan-id)#^Z
    megaport-mve-97884#

    megaport-mve-97884#show ip int brief
    Interface              IP-Address      OK? Method Status                Protocol
    GigabitEthernet1       162.43.148.51   YES DHCP   up                    up
    GigabitEthernet2       172.16.16.1     YES manual up                    up
    GigabitEthernet3       172.16.16.5     YES manual up                    up
    megaport-mve-97884#


```megaport-mve-97884#ping 172.16.16.2
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 172.16.16.2, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/1 ms
megaport-mve-97884#ping 172.16.16.6
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 172.16.16.6, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/1 ms
megaport-mve-97884#
megaport-mve-97884#
megaport-mve-97884#
megaport-mve-97884#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
megaport-mve-97884(config)#router bgp 64620
megaport-mve-97884(config-router)#neighbor 172.16.16.2 remote-as 12076
megaport-mve-97884(config-router)#neighbor 172.16.16.2 updat
megaport-mve-97884(config-router)#neighbor 172.16.16.2 update-so
megaport-mve-97884(config-router)#neighbor 172.16.16.2 update-source Gi2
megaport-mve-97884(config-router)#neighbor 172.16.16.2 ebgp-mult
megaport-mve-97884(config-router)#neighbor 172.16.16.2 ebgp-multihop 255
megaport-mve-97884(config-router)#neighbor 172.16.16.6 remote-as 12076
megaport-mve-97884(config-router)#neighbor 172.16.16.6 update-source gi3
megaport-mve-97884(config-router)#neighbor 172.16.16.6 ebgp-mu
megaport-mve-97884(config-router)#neighbor 172.16.16.6 ebgp-multihop 255
megaport-mve-97884(config-router)#^Z
megaport-mve-97884#show ip bgp summ
BGP router identifier 172.16.16.5, local AS number 64620
BGP table version is 1, main routing table version 1

Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
172.16.16.2     4        12076       5       5        1    0    0 00:01:08        0
172.16.16.6     4        12076       4       2        1    0    0 00:00:19        0
megaport-mve-97884#
```


```
megaport-mve-97884#show ip bgp
BGP table version is 3, local router ID is 172.16.16.5
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *    10.1.0.0/22      172.16.16.2                            0 12076 i
 *>                    172.16.16.6                            0 12076 i
 *    10.1.4.0/24      172.16.16.2                            0 12076 i
 *>                    172.16.16.6                            0 12076 i
megaport-mve-97884#
```
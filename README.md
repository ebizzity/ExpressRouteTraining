**Welcome to ExpressRoute hands-on Lab!**

In this lab we will be deploying 2 Azure environments.  One environment will simulate our 'On-Prem' network, and one will be our Azure Hub and Spoke deployment.

We will be provisioning an ExpressRoute circuit from Megaport, configuring a Cisco CSR 8000v router to bring up the circuit, and finally connecting it to Azure.  We will then configure a Site-to-Site VPN from the Cisco router at Megaport to connect our ExpressRoute to on-premise.

Architecture:

![Network-Architecture](images/Network-Architecture.png)

**Step #1 - Deploy Simulated on-prem and Azure environments via templates**
  
1. **On-Prem**
   
   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Febizzity%2FExpressRouteTraining%2Frefs%2Fheads%2Fmain%2Fon-prem-templates%2FonpremEnvironment.json)
 
2. **Azure**
   
   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Febizzity%2FExpressRouteTraining%2Frefs%2Fheads%2Fmain%2Fazure-templates%2FazureEnvironment.json)

**Step #2 - Create Megaport ExpressRoute and MVE**

1. Login to Megaport Portal
2. Create MVE (Megaport Virtual Edge)
   1. Ensure we have enough interfaces (3 if doing full ER Resiliency)
   2. Generate SSH Key
   3. Add Megaport Internet to Primary interfaces

   This will provision for a few minutes, when completed we will be able to get our Megaport public IP address and use it to log in to the Cisco router

   Megaport Public IP Picture

   4. Copy SSH Key into ~\\.ssh folder
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
        GigabitEthernet1       x.x.x.x         YES DHCP   up                    up
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
        GigabitEthernet1       x.x.x.x         YES DHCP   up                    up
        GigabitEthernet2       172.16.16.1     YES manual up                    up
        GigabitEthernet3       172.16.16.5     YES manual up                    up
        megaport-mve-97884#
        ```
       
**Step #3 - Configure Azure ExpressRoute and Connect to ERGW**  


1. Inspect the newly-deployed ExpressRoute ciruit created from the template above.
    
    ![unprovisioned circuit](images/er-ckt-cleanedup.png)

    Notice that we see a banner message indicating that we need to provision the circuit with the provider.

    Provide your service key to your instructor.

2. Instructor to provision ER Circuit.
    - Instructor to login to Megaport portal and create connection to MVE
    - Click Add Connection

        - ![Megaport-ER-connection-2](images/megaport-deploy-er-ckt.png)

    - Choose Cloud Connection

        - ![Megaport-ER-connection-1](images/megaport-deploy-er-ckt-1.png)

    - Choose Microsoft Azure

        - ![Megaport-ER-connection-2](images/megaport-deploy-er-ckt-2.png)

    - Enter the Service Key provided by student

        - ![Megaport-ER-connection-3](images/megaport-deploy-er-ckt-3.png)

    - Once they key is validated, Choose the Primary link of the circuit

        - ![Megaport-ER-connection-4](images/megaport-deploy-er-ckt-4.png)

    - Finally choose the interface on the MVE where we will connect the circuit and enter the student's vlan id, click ok, and click order.  You will now see the circuit in deploying status.
        - ![Megaport-ER-connection-5](images/megaport-deploy-er-ckt-5.png)
        - ![Megaport-ER-connection-6](images/megaport-circuits-order.png)
        - ![Megaport-ER-connection-7](images/megaport-circuits-deploying.png)

3. Check MSEE reachability after circuit provisioning is completed.

        ```
        megaport-mve-97884#ping 172.16.16.2
        Type escape sequence to abort.
        Sending 5, 100-byte ICMP Echos to 172.16.16.2, timeout is 2 seconds:
        !!!!!
        Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/1 ms
        megaport-mve-97884#ping 172.16.16.6
        Type escape sequence to abort.
        Sending 5, 100-byte ICMP Echos to 172.16.16.6, timeout is 2 seconds:
        !!!!!
        Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/1 ms
        ```
    
4. Configure BGP on CSR to peer with MSEE routers.
    - Log in to your Megaport Router and apply the following configuration.  Don't forget to enter configure mode! **Note:  you can copy and paste directly into the terminal**
    
    ```
    router bgp 64620
    bgp log-neighbor-changes
    neighbor 10.20.2.62 remote-as 65515
    neighbor 10.20.2.62 ebgp-multihop 255
    neighbor 10.20.2.62 update-source Tunnel11
    neighbor 172.16.16.2 remote-as 12076
    neighbor 172.16.16.2 ebgp-multihop 255
    neighbor 172.16.16.2 update-source GigabitEthernet2
    neighbor 172.16.16.6 remote-as 12076
    neighbor 172.16.16.6 ebgp-multihop 255
    neighbor 172.16.16.6 update-source GigabitEthernet3
    !
    ```

5. Check BGP Peering Status on CSR 8kv:

        ```
        megaport-mve-97884#show ip bgp summ
        BGP router identifier 172.16.16.5, local AS number 64620
        BGP table version is 1, main routing table version 1

        Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
        172.16.16.2     4        12076       5       5        1    0    0 00:01:08        0
        172.16.16.6     4        12076       4       2        1    0    0 00:00:19        0
        megaport-mve-97884#
        ```

6. At this point we are ready to connect the circuit to the ExpressRoute Gateway.  Perform the following steps:
    - Navigate to the ExpressRoute Gateway deployed from the templates above
    - Click Connections

        - ![ER-GW-Connection-1](images/ergw.png) 

    - Click Add
        - ![ER-GW-Connection-2](images/er-connections-add.png) 

    - Choose the resource group you are leveraging for this lab and choose ExpressRoute for the Connection type.

        - ![ER-GW-Connection-3](images/er-connection-setup-0.png)
    - For this lab, choose Standard Resiliency

        - ![ER-GW-Connection-4](images/er-connection-setup-1.png)
    - Choose the ERGW, provide a name for the connection, choose the provisioned ER circuit and deploy.

        - ![ER-GW-Connection-4](images/er-connection-setup-2.png)

7. Check for Routes from Azure on CSR 8kv:
    - Once the deployment for the connection has completed, we can go and check our received routes.  We should have routes for the Azure Hub, and the Azure Spoke, from both the Primary and Secondary circuits.

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

**Step #4 - Build VPN connection between Simulated On-Prem Environment and Megaport**

1. We need some information from the VPN Gateway.  Go to the Azure portal and get the Public IP Address we are going to leverage for the connection as well as the BGP peering IP address.

    - Navigate to the VPN Gateway deployed from the templates above
        - Click Properties

            - ![VPN-GW](images/vpn-gw.png)

            - Click Configure BGP

            - ![VPN-GW1](images/vpn-gw-add-connection-6-bgp.png) 

                - Note the IP Addresses down as we will need them in the next step

2. Log in to the Megaport CSR and enter the following configuration.  **NOTE: Be sure to update the placeholders with the appropriate IP addresses!**

    ```
    crypto ikev2 proposal Azure-Proposal
    encryption aes-cbc-256
    integrity sha1 sha256 sha384 sha512
    group 14 15 16
    crypto ikev2 proposal On-Prem-Ikev2-Proposal
    encryption aes-cbc-256
    integrity sha1 sha256 sha384 sha512
    group 14 15 16
    !
    crypto ikev2 policy Azure-Policy
    match address local <MEGAPORT_PUBLIC_IP>
    proposal Azure-Proposal
    !
    !
    crypto ikev2 profile Azure-Profile
    match address local <MEGAPORT_PUBLIC_IP>
    match identity remote address <VPN_GATEWAY_PUBLIC_IP> 255.255.255.255
    authentication remote pre-share key VPNDEMO!
    authentication local pre-share key VPNDEMO!
    lifetime 28800
    dpd 10 5 on-demand
    !
    !
    !
    !
    !
    !
    !
    !
    !
    !
    !
    !
    !
    crypto ipsec transform-set Azure-TransformSet esp-aes 256 esp-sha256-hmac
    mode tunnel
    !
    crypto ipsec profile Azure-IPsecProfile
    set transform-set Azure-TransformSet
    set ikev2-profile Azure-Profile
    !
    !
    !
    !
    !
    !
    !
    !
    !
    !
    interface Tunnel11
    ip address 172.16.15.1 255.255.255.252
    ip tcp adjust-mss 1350
    tunnel source GigabitEthernet1
    tunnel mode ipsec ipv4
    tunnel destination <VPN_GATEWAY_PUBLIC_IP>
    tunnel protection ipsec profile Azure-IPsecProfile
    !
    ```

3. Configure BGP on the CSR to exchange routes between On-prem and Azure.

    ```
    router bgp 64620
    neighbor 10.20.2.62 remote-as 65515
    neighbor 10.20.2.62 ebgp-multihop 255
    neighbor 10.20.2.62 update-source Tunnel11
    ```

4. Build VPN connection to Megaport in Azure
    - Create a net-new Local Network Gateway to represent the on-prem network in Azure.

    - Click Create

        - ![VPN-LNG1](images/vpn-lng-create-1.png) 

    - Choose the appropriate Resource Group, provide a name and the Public IP Address of the Megaport Router

        - ![VPN-LNG1](images/vpn-lng-create-1.5.png)

    - Configure BGP Settings

        - ![VPN-LNG1](images/vpn-lng-create-2.png)  

    - Now, Navigate to the VPN Gateway, click Connections

        - ![VPN-GW1](images/vpn-gw.png) 
        - ![VPN-GW2](images/vpn-gw-add-connection-1.png) 

    - Click Add

        - ![VPN-GW3](images/vpn-gw-add-connection-2.png) 

    - Choose Site-to-Site (IPSec) and the Connection Type and provide a name for the connection

        - ![VPN-GW4](images/vpn-gw-add-connection-3.png)

    - Choose the VPN Gateway
    - Choose the Local Network Gateway created above
    - Provide the PSK from the config file above 

        - ![VPN-GW5](images/vpn-gw-add-connection-4.png)

    - Choose custom IPsec/IKE Policy and use the following values:
    
        - ![VPN-GW6](images/vpn-gw-add-connection-5.png) 

**Cisco CSR 8kv configuration:**

```
crypto ikev2 proposal Azure-Proposal
 encryption aes-cbc-256
 integrity sha1 sha256 sha384 sha512
 group 14 15 16
crypto ikev2 proposal On-Prem-Ikev2-Proposal
 encryption aes-cbc-256
 integrity sha1 sha256 sha384 sha512
 group 14 15 16
!
crypto ikev2 policy Azure-Policy
 match address local <MEGAPORT_PUBLIC_IP>
 proposal Azure-Proposal
!
!
crypto ikev2 profile Azure-Profile
 match address local <MEGAPORT_PUBLIC_IP>
 match identity remote address <VPN_GATEWAY_PUBLIC_IP> 255.255.255.255
 authentication remote pre-share key VPNDEMO!
 authentication local pre-share key VPNDEMO!
 lifetime 28800
 dpd 10 5 on-demand
!
!
!
!
!
!
!
!
!
!
!
!
!
crypto ipsec transform-set Azure-TransformSet esp-aes 256 esp-sha256-hmac
 mode tunnel
!
crypto ipsec profile Azure-IPsecProfile
 set transform-set Azure-TransformSet
 set ikev2-profile Azure-Profile
!
!
!
!
!
!
!
!
!
!
interface Tunnel11
 ip address 172.16.15.1 255.255.255.252
 ip tcp adjust-mss 1350
 tunnel source GigabitEthernet1
 tunnel mode ipsec ipv4
 tunnel destination <VPN_GATEWAY_PUBLIC_IP>
 tunnel protection ipsec profile Azure-IPsecProfile
!
interface GigabitEthernet1
 ip address dhcp
 speed 10000
 no negotiation auto
!
interface GigabitEthernet2
 ip address 172.16.16.1 255.255.255.252
 negotiation auto
 vlan-id dot1q 800
 !
!
interface GigabitEthernet3
 ip address 172.16.16.5 255.255.255.252
 negotiation auto
 vlan-id dot1q 800
 !
!
router bgp 64620
 bgp log-neighbor-changes
 neighbor 10.20.2.62 remote-as 65515
 neighbor 10.20.2.62 ebgp-multihop 255
 neighbor 10.20.2.62 update-source Tunnel11
 neighbor 172.16.16.2 remote-as 12076
 neighbor 172.16.16.2 ebgp-multihop 255
 neighbor 172.16.16.2 update-source GigabitEthernet2
 neighbor 172.16.16.6 remote-as 12076
 neighbor 172.16.16.6 ebgp-multihop 255
 neighbor 172.16.16.6 update-source GigabitEthernet3
!
ip route 10.20.2.62 255.255.255.255 Tunnel11

```
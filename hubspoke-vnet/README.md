#### 1. Create the Resource Group
First, let's keep everything in one bucket for easy cleanup later.

Name: RG-HubSpoke-Lab

Region: East US (or your preferred region)


#### 2. Create the Hub VNet (The Transit Center)
This VNet will eventually hold your NAT Gateway and Bastion.

Name: VNet-Hub

Address Space: 10.100.0.0/16

Subnet: snet-hub-shared (10.100.1.0/24)

#### 3. Create the Spoke VNet (The Workload)
This is where your VM and App will live.

Name: VNet-Spoke-App

Address Space: 10.50.0.0/16

Subnet: snet-spoke-workload (10.50.1.0/24)


**Important: Peering is not transitive by default. If you have Spoke A and Spoke B both peered to a Hub, A cannot talk to B unless you tell the Hub to route them.**



#### 🔗 4. VNet Peering: Hub-and-Spoke Configuration

To enable the Hub-and-Spoke architecture, the peering must be configured to allow transit traffic.

| Setting | Direction: Hub -> Spoke | Direction: Spoke -> Hub |
| :--- | :--- | :--- |
| **Traffic Access** | Allow | Allow |
| **Forwarded Traffic** | **Enabled** | **Enabled** |
| **Gateway Transit** | "Use this VNet's Gateway" | "Use remote VNet's Gateway" |

**Why Enable Forwarded Traffic?**
Without this setting, the Hub cannot act as a "Transit" point. If the Spoke VM tries to send traffic through the Hub's NAT Gateway or Firewall, the Hub will block the packet because it originated from a different VNet (the Spoke).


#### 🌉 VNet Peering Logic
The peering between `VNet-Hub` and `VNet-Spoke-App` is configured with **Forwarded Traffic** enabled on both ends.

* **Forwarded Traffic (Hub side):** Essential so the Hub can accept outbound requests from the Spoke and pass them to the NAT Gateway.
* **Forwarded Traffic (Spoke side):** Essential so the Spoke can accept returning packets (replies) that are being passed back through the Hub.
* **Gateway Transit:** Currently set to **None** (to be updated if a VPN Gateway is added to the Hub).


#### 🚀 5. The Hub's "Exit Door" (NAT Gateway)
Now that the bridge is built, we need the "Exit Door" in the Hub.

Create a Public IP: (e.g., pip-hub-nat).

Create the NAT Gateway: (e.g., nat-hub-shared).

Associate it with the pip-hub-nat.

Associate with Subnet: Attach it to the snet-hub-shared subnet in VNet-Hub.




#### 🛠️ 5. The Routing Logic
1. Create a Route Table (UDR)
Search for Route Tables in the portal and click Create.

Name: rt-spoke-to-hub

Resource Group: RG-HubSpoke-Lab (Keep it in the same RG).

Region: Same as your VNets.

2. Add the "Default Route"
This is the "All traffic go this way" signpost.

Inside your new Route Table, click Routes > Add.

Route Name: To-Hub-Internet

Address Prefix: 0.0.0.0/0 (This means "The entire Internet").

Next hop type: This is the tricky part. For a NAT Gateway in a Hub-Spoke model, we usually use a Virtual Appliance (if you have a Firewall) or Virtual Network Gateway.



#### 6. Create NVA VM
Created nva vm inside hub vnet, by not providing public ip and  assigned nat gw ip, after loggin into this through bastion server of same vnet



#### Access NVA VM through bastion server and test internet connectivity through NAT-gateway or directly

#### 7. UDR (Route Tables) Update the routing rules of RT, we suppose to associate with the spoke vnet, spoke-workload-subnet
#### Once your NVA VM is up and you've enabled IP Forwarding in the Portal:

Note its Private IP (e.g., 10.100.1.4).

Go back to your Route Table (rt-spoke-to-hub).

Add the Route: * Prefix: 0.0.0.0/0

Next Hop: Virtual Appliance

Address: [Your NVA Private IP]

Associate that Route Table with your Spoke Subnet.


```bash
Destination type:  IP Addresses
Destination IP addresses/CIDR ranges: 0.0.0.0/0 (INTERNET)
Next hop type: NVA (Network Virtual Appliance) OR (Virtual Appliance)
Next hop address: Private IP of NVA VM, if public IP is disabled on NVA VM
```
#### 8. Enable IP Forwarding (Crucial!)
By default, Azure VMs drop any traffic that isn't meant for them. You have to tell Azure to let this VM act as a "middleman."

Go to the Networking tab of your new Hub VM.

Click on the Network Interface (NIC).

Under Settings, click IP configurations.

Set IP forwarding to Enabled and click Save.


SSH into your NVA VM and run:
```bash
# Below command must return 1
cat /proc/sys/net/ipv4/ip_forward 

# If not, Enable forwarding in the kernel
sudo sysctl -w net.ipv4.ip_forward=1

# Enable Masquerading (SNAT) so the internet knows how to reply to the Hub
# Replace eth0 with your actual interface name (usually eth0)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```


#### 9. 🗺️ The Packet's Journey
**The Spoke VM: Says "I want to go to https://www.google.com/search?q=google.com (8.8.8.8)." It checks its own internal routing table.**

**The UDR (Route Table): Sees the destination 8.8.8.8 fits inside 0.0.0.0/0. It tells the packet: "You must go to the NVA's Private IP (10.100.x.x) next."**

**The Peering Bridge: The packet crosses the VNet Peering into the Hub VNet.**

**The NVA VM: Receives the packet on its internal NIC. Because you enabled IP Forwarding and Iptables Masquerade, the NVA says: "I'll handle this for you," and sends the packet out to its own subnet.**

**The Hub Subnet: Sees a packet trying to leave for the internet. Since this subnet is associated with a NAT Gateway, it hands the packet to the NAT Gateway.**

**The NAT Gateway: Swaps the private IP for its Public IP and sends it to the real Google.**



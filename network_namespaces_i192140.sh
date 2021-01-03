#!/bin/bash
# Script by Muhammad Waleed Usman i192140 


#1.Creating two namespaces for our network
ip netns add I19-2140-1
ip netns add I19-2140-2
# Check that iproute2 indeed creates the files
# under `/var/run/netns`.
tree /var/run/netns/




#2.Creating two veth pairs
ip link add veth1 type veth peer name br-veth1
ip link add veth2 type veth peer name br-veth2
# Associate the non `br-` side
# with the corresponding namespace
ip link set veth1 netns I19-2140-1
ip link set veth2 netns I19-2140-2
# Assign the address 192.168.1.11 with netmask 255.255.255.0
ip netns exec I19-2140-1 ip addr add 192.168.1.11/24 dev veth1
# Assign the address 192.168.1.12 with netmask 255.255.255.0
ip netns exec I19-2140-2 ip addr add 192.168.1.12/24 dev veth2




#3.Creating a linux bridge 
ip link add name br1 type bridge
ip link set br1 up
# Check that the device has been created
ip link | grep br1



#4.Connect both namespaces with bridge using already created veth pairs
# Set the bridge veths from the default
ip link set br-veth1 up
ip link set br-veth2 up




#5.Set bridge and veth pairs up to ensure that they are working.
ip netns exec I19-2140-1 ip link set veth1 up
ip netns exec I19-2140-2 ip link set veth2 up
ip link set br-veth1 master br1
ip link set br-veth2 master br1
#Check that the bridge is working
bridge link show br1




#6.Assign IP addresses and ping 4 packet from IYY-XXXX-1 to IYY-XXXX-2 namespace. Use ping -c 4 to limit your ping to four packets. (Packet loss should be zero percent.)
ip addr add 192.168.1.10/24 brd + dev br1
#ping 192.168.1.12
ping 192.168.1.12 -c 4 # Limiting for packets


#7.Add default route in both namespaces and iptable rule on your machine to enable communication with the internet.
ip netns exec I19-2140-1 ip route
ip netns exec I19-2140-2 ip route
ip netns exec I19-2140-1 ping 192.168.1.12
ip netns exec I19-2140-2 ping 192.168.1.10
# 192.168.1.10 corresponds to the address assigned to the
# bridge device - reachable from both namespaces, as well as
# the host machine.
ip -all netns exec ip route add default via 192.168.1.10
ip netns exec I19-2140-1 ip route
ip netns exec I19-2140-2 ip route
#ip netns exec I19-2140-1 ping 8.8.8.8
#ping 8.8.8.8
#ping 8.8.8.8 -c 4
#To get around that, we can make use of NAT (network address translation) by placing an iptables rule in the POSTROUTING chain of the nat table:
iptables \
         -t nat \
         -A POSTROUTING \
         -s 192.168.1.0/24 \
         -j MASQUERADE
         
     
     
         
#8.Enable ipv4 ip_forwarding
sysctl -w net.ipv4.ip_forward=1





#9.Ping 4 packet to 8.8.8.8 from both namespaces. (packet loss should be zero percent)
#ip netns exec I19-2140-1 ping 8.8.8.8 -c 4
#Disable the firewall to connect to google dns server
sudo ufw disable
ip netns exec I19-2140-1 ping 8.8.8.8 -c 4
ip netns exec I19-2140-2 ping 8.8.8.8 -c 4





#10.Ping google.com from both namespaces (it will not work)
ip netns exec I19-2140-1 ping google.com -c 4
ip netns exec I19-2140-2 ping google.com -c 4






#11.Now search the internet how to enable this inside namespaces and make both namespaces to google.com.
$ vim /etc/resolv.conf
#Place this as the first non-commented line by "nameserver 8.8.8.8"
#You can verify this functionality with:
ip netns exec I19-2140-1 ping google.com -c 4
ip netns exec I19-2140-2 ping google.com -c 4




#12.Delete iptables rule, namespaces, veth pairs and linux bridge
#Delete iptables rule
iptables \
         -t nat \
         -D POSTROUTING \
         -s 192.168.1.0/24 \
         -j MASQUERADE
         
#Delete namespaces
ip netns delete I19-2140-1
ip netns delete I19-2140-2

#Delete veth pairs
ip link delete br-veth1
ip link delete br-veth2

#Delete the bridge
ip link set br1 down
brctl delbr br1
bridge link show br1

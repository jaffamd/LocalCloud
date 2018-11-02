#!/bin/sh
# This script configures the SonoConnect LocalCloud environment on the Raspberry Pi platform
# Usage: sudo /boot/configure-cloud.sh
# Licence: GPLv3
# Author: Elias Jaffa (@jaffa_md)
# Special thanks to: http://www.raspberryconnect.com/network/item/333-raspberry-pi-hotspot-access-point-dhcpcd-method

echo "Beginning configuration........."

# Install dependencies
sudo apt-get -y update
sudo apt-get -y upgrade

# Install dependencies
sudo apt-get -y install hostapd
sudo apt-get -y install dnsmasq
sudo apt-get -y purge dns-root-data
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Populate `/etc/hostapd/hostapd.conf`
sudo bash -c 'cat > /etc/hostapd/hostapd.conf' << EOF
interface=wlan0
driver=nl80211
ssid=LocalCloud
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Populate `/etc/default/hostapd`
sudo bash -c 'cat > /etc/default/hostapd' << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

# Populate `/etc/dnsmasq.conf`
sudo bash -c 'cat > /etc/dnsmasq.conf' << EOF
interface=wlan0
domain-needed
bogus-priv
dhcp-range=192.168.50.150,192.168.50.200,255.255.255.0,12h
EOF

# Populate '/etc/dhcpcd.conf'
sudo bash -c 'cat > /etc/dhcpcd.conf' << EOF
# Inform the DHCP server of our hostname for DDNS.
hostname

# Use the hardware address of the interface for the Client ID.
clientid

# Persist interface configuration when dhcpcd exits.
persistent

# Rapid commit support.
option rapid_commit

# A list of options to request from the DHCP server.
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
# Most distributions have NTP support.
option ntp_servers
# Respect the network MTU. This is applied to DHCP routes.
option interface_mtu

# A ServerID is required by RFC2131.
require dhcp_server_identifier

# Generate Stable Private IPv6 Addresses instead of hardware based ones
slaac private

nohook wpa_supplicant
interface wlan0
static ip_address=192.168.50.10/24
static routers=192.168.50.1
EOF

echo "Wifi configuration is finished!"

# Install the webserver software and restart the service
sudo apt-get install apache2 -y
sudo apt-get install php7.0 php7.0-gd sqlite php7.0-sqlite php7.0-curl php7.0-zip php7.0-xml php7.0-mbstring -y
sudo service apache2 restart

# Install the NextCloud software
cd /var/www/html
curl https://download.nextcloud.com/server/releases/nextcloud-13.0.4.tar.bz2 | sudo tar -jxv
sudo mkdir -p /var/www/html/nextcloud/data
sudo chown -R www-data:www-data /var/www/html/nextcloud/
sudo chmod 750 /var/www/html/nextcloud/data

# Add the local domain name to the hosts file
sudo echo "192.168.50.10   localcloud.com" >> /etc/hosts

# Redirect webpage to NextCloud rather than the default Apache2 landing page
sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/html\/nextcloud/' /etc/apache2/sites-available/000-default.conf

echo "NextCloud configuration complete.........."

#sudo update-rc.d dhcpcd disable
echo "System configuration is finished!"

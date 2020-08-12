set -x

CONSUL_VERSION="1.6.2"
curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
#curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
#curl --silent --remote-name https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

yum install unzip -y

unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul --version

consul -autocomplete-install
complete -C /usr/local/bin/consul consul

sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

cat > /etc/systemd/system/consul.service << EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
Type=notify
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

mkdir --parents /etc/consul.d
touch /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

cat > /etc/consul.d/consul.hcl << EOF
datacenter = "dc1"
data_dir = "/opt/consul"

recursors = [ "188.93.16.19",  "188.93.17.19"]
EOF

systemctl daemon-reload
systemctl enable consul


############################
# Configure DNS Forwarding #
############################
yum install iptables-services -y

systemctl enable iptables

cat > /etc/sysconfig/iptables << EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
-A PREROUTING -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600
-A OUTPUT -d 188.93.16.19/32 -p udp -m udp --dport 53 -j REDIRECT --to-ports 53
-A OUTPUT -d 188.93.16.19/32 -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 53
-A OUTPUT -d 188.93.17.19/32 -p udp -m udp --dport 53 -j REDIRECT --to-ports 53
-A OUTPUT -d 188.93.17.19/32 -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 53
COMMIT
EOF


sed -i 's|192.168.0.100|db.node.consul|g' /home/username/2_wait_pg_server_and_migrate.sh
sed -i 's|192.168.0.100|db.node.consul|g' /home/username/xpaste/.env

yum install -y unbound
mkdir /etc/unbound/unbound.conf.d
cat > /etc/unbound/unbound.conf.d/consul.conf << EOF
#Allow insecure queries to local resolvers
server:
  do-not-query-localhost: no
  domain-insecure: "consul"

#Add consul as a stub-zone
stub-zone:
  name: "consul"
  stub-addr: 127.0.0.1@8600
EOF

echo 'include: "/etc/unbound/unbound.conf.d/*.conf"' >> /etc/unbound/unbound.conf

systemctl enable unbound

mkdir /etc/systemd/system/unbound.service.d/

cat > /etc/systemd/system/unbound.service.d/override.conf << EOF
[Service]
ExecStartPre=/bin/sh -c 'echo nameserver 127.0.0.1 > /etc/resolv.conf'
EOF

systemctl daemon-reload


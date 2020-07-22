#!/bin/bash

cat << EOF
This script will download, install, and configure a Falcon SIEM Connector that will
leverage your API credentials to pull down and forward CrowdStrike alerts to a local Syslog Server.

You will need to provide a valid API UUID, API Key, and a Syslog Server IP.

EOF
read -p "API UUID: " client_id
echo ""
read -p "API Key: " client_secret
echo ""
read -p "Syslog Server IP: " syslog_server


git clone https://github.com/Starke427/CrowdStrike-SIEM-Connector
cd CrowdStrike-SIEM-Connector
rpm -Uvh cs.falconhoseclient-*
sed -i "s/= json/= syslog/g" /opt/crowdstrike/etc/cs.falconhoseclient.cfg
sed -i "s/client_id =/client_id = $client_id/g" /opt/crowdstrike/etc/cs.falconhoseclient.cfg              # Update API Key
sed -i "s/client_secret =/client_secret = $client_secret/g" /opt/crowdstrike/etc/cs.falconhoseclient.cfg  # Update API UUID
sed -i "s/send_to_syslog_server = false/send_to_syslog_server = true/g" /opt/crowdstrike/etc/cs.falconhoseclient.cfg  # Enable Syslog Forwarding
sed -i "s/host = localhost/host = $syslog_server/g" /opt/crowdstrike/etc/cs.falconhoseclient.cfg  # Configure
cat > /etc/systemd/system/cs.falconhoseclientd << EOF # Credit for Systemd service goes to Github.com/justintime/cs.falconhoseclientd.service
[Unit]
Description=CrowdStrike Falcon Host SIEM Connector
ConditionPathExists=/opt/crowdstrike/etc/cs.falconhoseclient.cfg

[Service]
User=daemon
UMask=022
LimitNOFILE=10000
TimeoutStopSec=90
WorkingDirectory=/opt/crowdstrike/bin
Environment="LOGGER_NAME=FALCON-SIEM-CONNECTOR"

Restart=on-failure
RestartSec=5
StartLimitInterval=60
StartLimitBurst=5
StartLimitAction=none

StandardOutput=null
StandardError=null
ExecStart=/opt/crowdstrike/bin/cs.falconhoseclient -nodaemon -config=/opt/crowdstrike/etc/cs.falconhoseclient.cfg 2>&1 | logger -t FALCON-SIEM-CONNECTOR[WARN] -i

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable cs.falconhoseclientd
systemctl start cs.falconhoseclientd

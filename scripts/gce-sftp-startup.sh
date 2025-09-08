#!/bin/bash
set -e

apt-get update -y
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

mkdir -p /home/demo/sftp
mkdir -p /opt/sftp-config

cat >/opt/sftp-config/sftp.json <<'EOF'
{
  "Users": [
    {"Username": "demo", "Password": "demo", "PrivateKeyPath": null, "PublicKeys": [], "Permissions": ["*"], "Root": "/home/demo/sftp"}
  ]
}
EOF

/usr/bin/docker run -d --name lotus-sftp-1 --restart always \
  -p 2222:22 \
  -v /opt/sftp-config/sftp.json:/app/config/sftp.json:ro \
  -v /home/demo/sftp:/home/demo/sftp \
  emberstack/sftp:latest



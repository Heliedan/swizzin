#!/bin/bash
# nginx configuration for altdash, at the root of the site in place of the panel
# Heliedan 2026 for Swizzin
# Run again by install/nginx.sh when nginx is installed again: it must give the same result each time.

if [[ -L /opt/swizzin/swizzin.cfg ]]; then
    echo_error "/opt/swizzin/swizzin.cfg is a symbolic link: altdash does not write through it"
    exit 1
fi
if ! grep -qs "^HOST = " /opt/swizzin/swizzin.cfg; then
    echo "HOST = '127.0.0.1'" >> /opt/swizzin/swizzin.cfg
fi

cat > /etc/nginx/apps/panel.conf << 'EON'
location / {
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  # Origin is passed through, so the panel's Socket.IO server can refuse websocket
  # handshakes opened from other sites. X-Forwarded-Host keeps the port the browser
  # used, so that check also passes when nginx is reached on a non-default port.
  proxy_set_header X-Forwarded-Host $http_host;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_pass http://127.0.0.1:8333;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "Upgrade";
}
EON

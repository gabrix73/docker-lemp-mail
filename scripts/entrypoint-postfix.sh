#!/bin/sh
# Entrypoint Postfix — apply environment variables and start

set -e

# Copy custom configurations
cp /etc/postfix/custom/main.cf /etc/postfix/main.cf
cp /etc/postfix/custom/master.cf /etc/postfix/master.cf

# Copy auxiliary files if they exist
[ -f /etc/postfix/custom/postscreen_access.cidr ] && \
  cp /etc/postfix/custom/postscreen_access.cidr /etc/postfix/postscreen_access.cidr

[ -f /etc/postfix/custom/helo_access ] && \
  cp /etc/postfix/custom/helo_access /etc/postfix/helo_access

# Initialize virtual mailbox/alias if they don't exist
touch /etc/postfix/virtual_mailbox /etc/postfix/virtual_alias
postmap /etc/postfix/virtual_mailbox
postmap /etc/postfix/virtual_alias

# Fix queue permissions
postfix set-permissions 2>/dev/null || true

# Update Postfix DB
newaliases 2>/dev/null || true

echo "[postfix] Starting..."
exec /usr/sbin/postfix start-fg

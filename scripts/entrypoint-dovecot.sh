#!/bin/sh
# Entrypoint Dovecot — apply variables and start

set -e

# Copy custom configurations
cp /etc/dovecot/custom/dovecot.conf /etc/dovecot/dovecot.conf
[ -f /etc/dovecot/custom/10-auth.conf ] && \
  cp /etc/dovecot/custom/10-auth.conf /etc/dovecot/conf.d/10-auth.conf

# Generate dovecot-sql.conf.ext from configuration
cat > /etc/dovecot/dovecot-sql.conf.ext <<SQL
driver = mysql
connect = host=mysql dbname=mailserver user=mailuser password=${MYSQL_ROOT_PASSWORD}

default_pass_scheme = SHA512-CRYPT

password_query = SELECT email as user, password FROM virtual_users WHERE email='%u'
user_query = SELECT \
  'maildir:/var/mail/%d/%n/Maildir' as mail, \
  1000 AS uid, \
  1000 AS gid, \
  CONCAT('*:bytes=', quota*1024*1024) AS quota_rule \
  FROM virtual_users WHERE email='%u'

iterate_query = SELECT email AS user FROM virtual_users
SQL

# Create mail directory if it doesn't exist
mkdir -p /var/mail

# Fix permissions
chown -R dovecot:dovecot /etc/dovecot/dovecot-sql.conf.ext
chmod 600 /etc/dovecot/dovecot-sql.conf.ext

echo "[dovecot] Starting..."
exec /usr/sbin/dovecot -F

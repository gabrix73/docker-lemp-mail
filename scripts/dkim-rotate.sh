#!/bin/bash
# ─────────────────────────────────────────────────────────────
# dkim-rotate.sh — DKIM key rotation every 6 months
# Run via cron: 0 3 1 */6 * /path/to/dkim-rotate.sh
# ─────────────────────────────────────────────────────────────
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ ! -f .env ]]; then
  echo ".env file not found — run from ~/Workspace/docker-mailwp/"
  exit 1
fi
export $(grep -v '^#' .env | xargs)

KEY_DIR="data/opendkim/keys/${DOMAIN}"
DATE=$(date +%Y%m)
NEW_SELECTOR="mail${DATE}"
OLD_SELECTOR="mail"

echo -e "${YELLOW}[!] DKIM rotation for ${DOMAIN}${NC}"
echo "    New selector: ${NEW_SELECTOR}"

# Generate new key
mkdir -p "${KEY_DIR}"
openssl genrsa -out "${KEY_DIR}/${NEW_SELECTOR}.private" 2048
openssl rsa -in "${KEY_DIR}/${NEW_SELECTOR}.private" \
            -pubout -out "${KEY_DIR}/${NEW_SELECTOR}.public"
chmod 600 "${KEY_DIR}/${NEW_SELECTOR}.private"

NEW_DKIM_PUBLIC=$(grep -v '^-' "${KEY_DIR}/${NEW_SELECTOR}.public" | tr -d '\n')

# Update opendkim.conf with new selector
sed -i "s/^Selector.*/Selector\t\t\t${NEW_SELECTOR}/" config/opendkim/opendkim.conf
sed -i "s|^KeyFile.*|KeyFile\t\t\t/etc/opendkim/keys/${DOMAIN}/${NEW_SELECTOR}.private|" config/opendkim/opendkim.conf

echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  UPDATE THE DKIM DNS RECORD BEFORE RESTARTING!${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════${NC}"
echo ""
echo "  Add this DNS record:"
echo ""
echo "  Name:  ${NEW_SELECTOR}._domainkey.${DOMAIN}"
echo "  Type:  TXT"
echo "  Value: \"v=DKIM1; k=rsa; p=${NEW_DKIM_PUBLIC}\""
echo ""
echo "  Also keep the old record ${OLD_SELECTOR}._domainkey for 48h"
echo "  (emails in transit may still use the old selector)"
echo ""
echo -e "${GREEN}[✓] Key generated. Update DNS then run:${NC}"
echo "    docker-compose restart opendkim"
echo ""

# Backup old key
if [[ -f "${KEY_DIR}/${OLD_SELECTOR}.private" ]]; then
  mv "${KEY_DIR}/${OLD_SELECTOR}.private" "${KEY_DIR}/${OLD_SELECTOR}.private.bak.${DATE}"
  echo "  Old key backed up: ${KEY_DIR}/${OLD_SELECTOR}.private.bak.${DATE}"
fi

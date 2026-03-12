#!/bin/bash
# ─────────────────────────────────────────────────────────────
# verify-dns.sh — Verify DNS record propagation
# ─────────────────────────────────────────────────────────────
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OK()   { echo -e "${GREEN}[✓]${NC} $1"; }
FAIL() { echo -e "${RED}[✗]${NC} $1"; ERRORS=$((ERRORS+1)); }
WARN() { echo -e "${YELLOW}[!]${NC} $1"; }
INFO() { echo -e "${BLUE}[i]${NC} $1"; }

ERRORS=0

# Load .env
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found — run setup.sh first"
  exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DNS verification for: ${DOMAIN}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# ─── A records ───────────────────────────────────────────────
echo "── A Records ──"
for host in "@" "www" "mail" "webmail"; do
  NAME="${host}.${DOMAIN}"
  [[ "$host" == "@" ]] && NAME="${DOMAIN}"
  RESULT=$(dig +short A "$NAME" 2>/dev/null | head -1)
  if [[ "$RESULT" == "$SERVER_IP" ]]; then
    OK "$NAME → $RESULT"
  elif [[ -n "$RESULT" ]]; then
    WARN "$NAME → $RESULT (expected: $SERVER_IP)"
  else
    FAIL "$NAME → not found"
  fi
done

echo ""

# ─── MX record ──────────────────────────────────────────────
echo "── MX Record ──"
MX=$(dig +short MX "${DOMAIN}" 2>/dev/null | awk '{print $2}' | sed 's/\.$//')
if [[ "$MX" == "$MAIL_DOMAIN" ]]; then
  OK "MX → $MX"
else
  FAIL "MX → '${MX}' (expected: ${MAIL_DOMAIN})"
fi

echo ""

# ─── SPF ────────────────────────────────────────────────────
echo "── SPF ──"
SPF=$(dig +short TXT "${DOMAIN}" 2>/dev/null | grep "v=spf1" | tr -d '"')
if echo "$SPF" | grep -q "ip4:${SERVER_IP}"; then
  OK "SPF → $SPF"
elif [[ -n "$SPF" ]]; then
  WARN "SPF found but IP ${SERVER_IP} not included: $SPF"
else
  FAIL "SPF → not found"
fi

echo ""

# ─── DKIM ───────────────────────────────────────────────────
echo "── DKIM ──"
DKIM=$(dig +short TXT "mail._domainkey.${DOMAIN}" 2>/dev/null | tr -d '"' | tr -d ' ')
if echo "$DKIM" | grep -q "v=DKIM1"; then
  OK "DKIM → record found"
  INFO "  Selector: mail._domainkey.${DOMAIN}"
else
  FAIL "DKIM → not found (mail._domainkey.${DOMAIN})"
fi

echo ""

# ─── DMARC ──────────────────────────────────────────────────
echo "── DMARC ──"
DMARC=$(dig +short TXT "_dmarc.${DOMAIN}" 2>/dev/null | tr -d '"')
if echo "$DMARC" | grep -q "v=DMARC1"; then
  OK "DMARC → $DMARC"
  POLICY=$(echo "$DMARC" | grep -o 'p=[a-z]*' | cut -d= -f2)
  if [[ "$POLICY" == "none" ]]; then
    WARN "  Policy: none (monitoring only — ok to start)"
  elif [[ "$POLICY" == "quarantine" ]]; then
    INFO "  Policy: quarantine"
  elif [[ "$POLICY" == "reject" ]]; then
    OK "  Policy: reject (maximum protection)"
  fi
else
  FAIL "DMARC → not found (_dmarc.${DOMAIN})"
fi

echo ""

# ─── PTR ────────────────────────────────────────────────────
echo "── PTR (reverse DNS) ──"
PTR=$(dig +short -x "${SERVER_IP}" 2>/dev/null | sed 's/\.$//')
if [[ "$PTR" == "$MAIL_DOMAIN" ]]; then
  OK "PTR ${SERVER_IP} → $PTR"
else
  WARN "PTR ${SERVER_IP} → '${PTR}' (expected: ${MAIL_DOMAIN})"
  WARN "  Configure PTR in your VPS control panel"
fi

echo ""

# ─── SMTP connectivity test ──────────────────────────────────
echo "── SMTP Connectivity ──"
if timeout 5 bash -c "echo > /dev/tcp/${SERVER_IP}/25" 2>/dev/null; then
  OK "Port 25 (SMTP) open"
else
  FAIL "Port 25 (SMTP) unreachable"
fi
if timeout 5 bash -c "echo > /dev/tcp/${SERVER_IP}/587" 2>/dev/null; then
  OK "Port 587 (Submission) open"
else
  WARN "Port 587 (Submission) unreachable"
fi
if timeout 5 bash -c "echo > /dev/tcp/${SERVER_IP}/993" 2>/dev/null; then
  OK "Port 993 (IMAPS) open"
else
  WARN "Port 993 (IMAPS) unreachable"
fi

echo ""

# ─── Final result ────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}  All DNS records are correct!${NC}"
  echo -e "${GREEN}  You can start the stack: docker-compose up -d${NC}"
else
  echo -e "${RED}  ${ERRORS} issue(s) found — fix them before starting${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

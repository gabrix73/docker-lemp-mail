#!/bin/bash
# Generate the complete DNS report for the client
DOMAIN="$1"
MAIL_DOMAIN="$2"
SERVER_IP="$3"
DKIM_PUBLIC="$4"

cat <<EOF
═══════════════════════════════════════════════════════════════
  DNS RECORDS TO CONFIGURE — ${DOMAIN}
  Generated on: $(date)
═══════════════════════════════════════════════════════════════

Configure these records in your DNS provider's control panel
(Cloudflare, OVH, Gandi, Aruba, cPanel, etc.)

────────────────────────────────────────────────────────────
  STEP 1 — SSL CERTIFICATE (Let's Encrypt DNS challenge)
────────────────────────────────────────────────────────────
  During setup, a TXT value will be shown for you to add:

  Name                   Type   Value
  _acme-challenge        TXT    (shown during setup.sh)
  _acme-challenge.mail   TXT    (shown during setup.sh)

  ⚠ Add these records BEFORE confirming in the wizard.
  You can delete them after obtaining the certificate.

────────────────────────────────────────────────────────────
  STEP 2 — A RECORDS
────────────────────────────────────────────────────────────
  Name          Type   Value
  @             A      ${SERVER_IP}
  www           A      ${SERVER_IP}
  mail          A      ${SERVER_IP}
  webmail       A      ${SERVER_IP}

────────────────────────────────────────────────────────────
  STEP 3 — MX RECORD (incoming mail)
────────────────────────────────────────────────────────────
  Name          Type   Priority   Value
  @             MX     10         ${MAIL_DOMAIN}.

────────────────────────────────────────────────────────────
  STEP 4 — TXT SPF (authorizes the server to send email)
────────────────────────────────────────────────────────────
  Name          Type   Value
  @             TXT    "v=spf1 mx a ip4:${SERVER_IP} ~all"

  NOTE: ~all = softfail (recommended initially)
        -all = fail (more restrictive, after testing period)

────────────────────────────────────────────────────────────
  STEP 5 — TXT DKIM (email digital signature)
────────────────────────────────────────────────────────────
  Name                  Type   Value
  mail._domainkey       TXT    "v=DKIM1; k=rsa; p=${DKIM_PUBLIC}"

  NOTE: if the record is too long, some providers require
        splitting it into two strings (max 255 characters each)
        Cloudflare example: paste it all, it splits automatically.

────────────────────────────────────────────────────────────
  STEP 6 — TXT DMARC (anti-spoofing policy)
────────────────────────────────────────────────────────────
  Name          Type   Value
  _dmarc        TXT    "v=DMARC1; p=none; rua=mailto:dmarc@${DOMAIN}; ruf=mailto:dmarc@${DOMAIN}; fo=1; adkim=r; aspf=r; pct=100; sp=none"

  NOTE: p=none = monitoring only (required initially)
        After 2 weeks without issues → p=quarantine → p=reject

────────────────────────────────────────────────────────────
  STEP 7 — PTR (reverse DNS — in VPS control panel)
────────────────────────────────────────────────────────────
  Configure in your VPS/hosting control panel (NOT at registrar):
  ${SERVER_IP}  →  ${MAIL_DOMAIN}

  Providers: OVH → IP Manager | Hetzner → Networking | Scaleway → IP

════════════════════════════════════════════════════════════════
  AFTER CONFIGURATION
════════════════════════════════════════════════════════════════
  Wait for DNS propagation (2-48 hours, usually 15-30 minutes).

  Then verify:
    bash verify-dns.sh

  Online tools:
    https://mxtoolbox.com
    https://dmarcian.com/dmarc-inspector/
    https://mail-tester.com  (send a test email, get a score)

═══════════════════════════════════════════════════════════════
EOF

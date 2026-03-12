# docker-mailwp

[![Build & Push](https://github.com/gabrix73/docker-mailwp/actions/workflows/docker-build.yml/badge.svg)](https://github.com/gabrix73/docker-mailwp/actions/workflows/docker-build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/gabrix73/mailwp-php)](https://hub.docker.com/r/gabrix73/mailwp-php)

**Production-ready mail server + WordPress stack in Docker.**
One wizard. One command. Fully configured in minutes.

Postfix · Dovecot · Rspamd · OpenDKIM · OpenDMARC · ClamAV · Nginx · PHP 8.3 · MySQL 8 · Roundcube · Fail2ban

---

## Features

- **Interactive setup wizard** — enter your domain, everything else is automatic
- **Let's Encrypt SSL** via DNS challenge — no port 80 required during cert issuance
- **Wildcard certificate** (`*.yourdomain.com`) covers all subdomains
- **Email authentication out of the box** — SPF, DKIM, DMARC configured and ready
- **DNS report generated automatically** — copy-paste records for your DNS provider
- **Multi-layer spam protection** — Postscreen + RBL blacklists + Rspamd + ClamAV
- **Separate milters** — Rspamd, OpenDKIM, OpenDMARC run independently for stability
- **Brute-force protection** — Fail2ban monitors Postfix, Dovecot, Nginx
- **WordPress + Roundcube webmail** on the same server
- **Production & development modes** — Let's Encrypt or self-signed certificate
- **DKIM key rotation script** — run every 6 months with guided DNS update instructions

---

## Stack

| Container | Image | Role |
|---|---|---|
| `nginx` | `nginx:stable-alpine` | Reverse proxy, HTTPS termination |
| `php` | `gabrix73/mailwp-php:latest` | PHP 8.3-FPM (WordPress + Roundcube) |
| `mysql` | `mysql:8.0` | Database |
| `postfix` | `gabrix73/mailwp-postfix:latest` | SMTP + Postscreen |
| `dovecot` | `gabrix73/mailwp-dovecot:latest` | IMAP / POP3 / LMTP |
| `rspamd` | `rspamd/rspamd:latest` | Antispam milter |
| `opendkim` | `instrumentisto/opendkim:latest` | DKIM signing milter |
| `opendmarc` | `instrumentisto/opendmarc:latest` | DMARC verification milter |
| `clamav` | `clamav/clamav:stable` | Antivirus |
| `redis` | `redis:7-alpine` | Rspamd Bayes backend |
| `fail2ban` | `crazymax/fail2ban:latest` | Brute-force protection |

---

## Quick Start

### Prerequisites

- Docker + Docker Compose
- A domain name (e.g. `example.com`)
- A VPS with a public IP address
- Open ports: **25, 80, 110, 143, 443, 465, 587, 993, 995**

### Install

```bash
git clone https://github.com/gabrix73/docker-mailwp.git
cd docker-mailwp
bash setup.sh
```

The wizard will ask for:
1. **Mode** — Production (Let's Encrypt) or Development (self-signed)
2. **Domain** — e.g. `example.com`
3. **Admin email**
4. **Server IP** — auto-detected, confirm or override

Everything else is generated automatically: passwords, DKIM keys, SSL certificate, configs, DNS report.

---

## SSL Certificate (DNS Challenge)

No port 80 dependency. The wizard uses `acme.sh` in manual DNS mode:

1. `setup.sh` shows a `_acme-challenge` TXT record value
2. You add it to your DNS panel (takes ~2 minutes)
3. Press ENTER — certificate is issued and saved
4. Nginx starts with HTTPS already configured

Works behind firewalls, NAT, or any hosting environment.

---

## DNS Configuration

After setup, a `dns-records.txt` file is generated with all required records ready to copy-paste:

```
STEP 1 — SSL (acme-challenge TXT — temporary)
STEP 2 — A records      (@, www, mail, webmail)
STEP 3 — MX record
STEP 4 — SPF            (v=spf1 mx a ip4:YOUR_IP ~all)
STEP 5 — DKIM           (mail._domainkey TXT)
STEP 6 — DMARC          (_dmarc TXT)
STEP 7 — PTR            (reverse DNS — set in VPS panel)
```

Verify propagation after configuring:

```bash
bash verify-dns.sh
```

---

## Mail Protection Layers

```
Internet
  │
  ▼
Postscreen ──── RBL checks (Spamhaus, Barracuda, SpamCop)
                Greylisting, protocol inspection, rate limiting
  │
  ▼
Postfix ──────── HELO/PTR/FQDN restrictions, anvil rate limits
  │
  ▼
Rspamd ────────── Bayes scoring, SPF/DKIM verify, URL blacklists  [milter]
OpenDKIM ─────── DKIM signing (outbound) + verification           [milter]
OpenDMARC ────── DMARC policy enforcement                         [milter]
ClamAV ────────── Antivirus attachment scanning
  │
  ▼
Dovecot ─────── LMTP delivery → Maildir
```

---

## User Management

Mail users are stored in MySQL:

```bash
# Connect to the mail database
docker exec -it mailwp-mysql mysql -u root -p mailserver

# Add a user
INSERT INTO virtual_users (domain_id, email, password, quota)
VALUES (
  1,
  'user@example.com',
  ENCRYPT('password', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))),
  1024   -- quota in MB
);

# List users
SELECT email, quota FROM virtual_users;

# Delete a user
DELETE FROM virtual_users WHERE email = 'user@example.com';
```

---

## Access

| Service | URL |
|---|---|
| WordPress | `https://yourdomain.com` |
| Webmail (Roundcube) | `https://webmail.yourdomain.com` |
| Rspamd UI | `http://localhost:11334` *(local only)* |

---

## Useful Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Live logs
docker-compose logs -f postfix
docker-compose logs -f rspamd

# Mail queue
docker exec -it mailwp-postfix mailq

# Flush queue
docker exec -it mailwp-postfix postqueue -f

# Restart a single service
docker-compose restart opendkim
```

---

## DKIM Key Rotation

Rotate every 6 months:

```bash
bash scripts/dkim-rotate.sh
```

The script generates a new key, shows the DNS record to update, and backs up the old key. Keep the old DNS record for 48 hours before removing it.

---

## Backup

All persistent data lives in `data/`. Back it up regularly:

```bash
docker-compose stop mysql
tar -czf backup-$(date +%Y%m%d).tar.gz data/ .env
docker-compose start mysql
```

---

## Project Structure

```
docker-mailwp/
├── setup.sh                  ← interactive setup wizard
├── verify-dns.sh             ← DNS propagation checker
├── docker-compose.yml
├── .env                      ← generated by setup.sh (keep private)
├── dns-records.txt           ← generated by setup.sh
├── build/                    ← custom Dockerfiles
│   ├── php/                  ← PHP 8.3 + WordPress extensions
│   ├── postfix/
│   └── dovecot/
├── config/                   ← service configurations
│   ├── nginx/
│   ├── postfix/
│   ├── dovecot/
│   ├── rspamd/
│   ├── opendkim/
│   ├── opendmarc/
│   ├── clamav/
│   ├── fail2ban/
│   ├── php/
│   ├── mysql/
│   ├── roundcube/
│   └── wordpress/
├── scripts/
│   ├── entrypoint-postfix.sh
│   ├── entrypoint-dovecot.sh
│   ├── generate-dns-report.sh
│   └── dkim-rotate.sh
└── data/                     ← persistent volumes (back this up!)
```

---

## CI/CD

GitHub Actions automatically builds and pushes all three custom images to Docker Hub on every push to `main` and on version tags (`v*.*.*`).

Images are built for `linux/amd64` and `linux/arm64` (Apple Silicon, Raspberry Pi).

Required GitHub secrets:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## License

MIT — free to use, modify, and distribute.

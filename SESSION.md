# Progetto: docker-lemp-mail

**Avviato:** 2026-03-12
**Obiettivo:** Stack Docker completo per mail server + WordPress con wizard di setup

## Stack
- Nginx (reverse proxy + HTTPS)
- PHP 8.3-fpm (Alpine)
- MySQL 8.0
- WordPress
- Roundcube (webmail)
- Postfix + Postscreen (MTA)
- Dovecot (IMAP/POP3/LMTP + Sieve)
- Rspamd (milter antispam + Bayes + Redis)
- OpenDKIM (milter firma DKIM)
- OpenDMARC (milter verifica DMARC)
- ClamAV (antivirus)
- Fail2ban (bruteforce protection)
- acme.sh (Let's Encrypt via DNS challenge — installato sull'host, non in Docker)
- Redis (backend Rspamd Bayes)

## Stato attuale — COMPLETATO ✓
- [x] Struttura directory
- [x] docker-compose.yml (13 container, 3 reti, healthcheck)
- [x] setup.sh wizard completo (prod/dev, dominio, DKIM, certs, DNS report)
- [x] Config Postfix main.cf + master.cf + Postscreen + RBL
- [x] Config Dovecot (IMAP/POP3/LMTP/Sieve/SQL auth/quota)
- [x] Config Rspamd milter + Bayes + Redis
- [x] Config OpenDKIM milter
- [x] Config OpenDMARC milter
- [x] Config Nginx (nginx.conf + sites/wordpress.conf + sites/webmail.conf)
- [x] Config PHP 8.3 (OPcache, limiti, sicurezza sessioni)
- [x] Config MySQL (utf8mb4, InnoDB tuning)
- [x] Config ClamAV (clamd.conf)
- [x] Config Fail2ban (postfix, dovecot, nginx + filtri custom)
- [x] Dockerfile PHP 8.3 Alpine (imagick, apcu, pdo_mysql, gd, intl...)
- [x] Dockerfile Postfix (Debian bookworm)
- [x] Dockerfile Dovecot (mysql, sieve, lmtp, managesieve)
- [x] Entrypoint Postfix + Dovecot
- [x] Roundcube config.inc.php template
- [x] WordPress wp-config.php template (chiavi via API WP)
- [x] mysql-init.sql (generato da setup.sh — DB mailserver + WP + RC)
- [x] Script generate-dns-report.sh (tutti i record pronti da copiare)
- [x] Script verify-dns.sh (A, MX, SPF, DKIM, DMARC, PTR, porte)
- [x] Script dkim-rotate.sh (rotazione chiave ogni 6 mesi)
- [x] README.md utente finale
- [x] .gitignore

## Stato aggiuntivo (sessione 2026-03-12 — parte 2)
- [x] Tutto tradotto in inglese (commenti, wizard, report DNS, messaggi)
- [x] README.md pubblico (GitHub/Dockerhub) con badge, stack table, quick start, architettura
- [x] .github/workflows/docker-build.yml — CI/CD GitHub Actions
  - Build PHP + Postfix + Dovecot su push/tag
  - Multi-arch: linux/amd64 + linux/arm64
  - Cache GHA per build veloci
  - Auto-update Docker Hub README description
- [x] LICENSE (MIT)
- [x] DNS challenge acme.sh (no porta 80, wildcard cert)

## Prossimi passi (prossima sessione)
1. Creare repo GitHub + push iniziale
2. Configurare secrets GitHub (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
3. Test su VPS reale
4. Script `add-user.sh` per gestione utenti mail da CLI
5. Sostituire gabrix73 con username reale nel README e workflow

## Note architetturali
- Rspamd, OpenDKIM, OpenDMARC come milter separati (deliberato per stabilità)
- Postfix → LMTP → Dovecot per consegna locale
- acme.sh installato sull'host (non container), DNS challenge manuale: wizard mostra TXT → utente aggiorna DNS → premi INVIO → cert salvato in data/certs/
- Nessuna dipendenza porta 80/Nginx per il cert — Nginx parte già con SSL
- Modalità prod (VPS/Let's Encrypt DNS challenge) e dev (self-signed 10 anni)
- DNS report + verify-dns.sh guidano il cliente autonomamente
- Auth mail via MySQL (virtual_users, virtual_domains, virtual_aliases)
- Quota per utente configurabile in DB (default 1GB)
- setup.sh genera tutto: .env, DKIM key, wp-config, roundcube config, mysql-init.sql, dns-records.txt

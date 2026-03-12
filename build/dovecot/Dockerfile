FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    dovecot-core \
    dovecot-imapd \
    dovecot-pop3d \
    dovecot-lmtpd \
    dovecot-mysql \
    dovecot-sieve \
    dovecot-managesieved \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 24 110 143 993 995 4190 12345

CMD ["/usr/sbin/dovecot", "-F"]

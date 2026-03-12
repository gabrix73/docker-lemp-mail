<?php
// ─────────────────────────────────────────────────────────────
// Roundcube — main configuration
// Values substituted by setup.sh via sed
// ─────────────────────────────────────────────────────────────

$config = [];

// Database
$config['db_dsnw'] = 'mysql://MYSQL_RC_USER_PLACEHOLDER:MYSQL_RC_PASSWORD_PLACEHOLDER@mysql/MYSQL_RC_DB_PLACEHOLDER';

// IMAP (Dovecot)
$config['imap_host'] = 'ssl://dovecot:993';
$config['imap_conn_options'] = [
    'ssl' => [
        'verify_peer'       => false,
        'verify_peer_name'  => false,
    ],
];

// SMTP (Postfix submission)
$config['smtp_host'] = 'tls://postfix:587';
$config['smtp_port'] = 587;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['smtp_conn_options'] = [
    'ssl' => [
        'verify_peer'       => false,
        'verify_peer_name'  => false,
    ],
];

// Default domain
$config['username_domain'] = 'DOMAIN_PLACEHOLDER';
$config['mail_domain']     = 'DOMAIN_PLACEHOLDER';

// UI
$config['product_name']  = 'Webmail';
$config['skin']          = 'elastic';
$config['language']      = 'it_IT';
$config['timezone']      = 'Europe/Paris';
$config['draft_autosave']= 60;

// Special folders
$config['sent_mbox']    = 'Sent';
$config['trash_mbox']   = 'Trash';
$config['drafts_mbox']  = 'Drafts';
$config['junk_mbox']    = 'Junk';

// Attachment upload limit (must match php.ini)
$config['max_message_size'] = '64M';

// Security
$config['des_key']           = 'ROUNDCUBE_DES_KEY_PLACEHOLDER'; // 24 char random
$config['ip_check']          = true;
$config['referer_check']     = true;
$config['force_https']       = true;
$config['login_autocomplete'] = 0;
$config['session_lifetime']  = 30;

// HTML preview (security)
$config['prefer_html']       = true;
$config['show_images']       = 0;  // do not autoload remote images

// Plugins
$config['plugins'] = [
    'archive',
    'zipdownload',
    'managesieve',
    'markasjunk',
    'emoticons',
];

// Logging
$config['log_driver']  = 'stderr';
$config['log_logins']  = true;
$config['log_session'] = false;

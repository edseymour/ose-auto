#!/bin/bash

. functions.sh

validate_config target
validate_config homepage

scmd $ssh_user@$target "sudo bash -c 'cat >/usr/lib64/firefox/browser/defaults/preferences/local-settings.js <<EOF
pref(\"general.config.filename\", \"firefox.cfg\");
pref(\"general.config.obscure_value\", 0);
EOF

sudo cat >/usr/lib64/firefox/firefox.cfg <<EOF
//
pref(\"browser.startup.homepage\", \"$homepage\");
pref(\"startup.homepage_override_url\", \"\");
pref(\"startup.homepage_welcome_url\", \"\");
pref(\"signon.rememberSignons\", false);
EOF'"






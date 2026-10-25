#!/bin/bash
# altdash upgrader: the latest release (or ALTDASH_TAG), with the App Store service or without it (ALTDASH_STORE)
# Heliedan 2026 for Swizzin

if [[ ! -f /install/.altdash.lock ]]; then
    echo_error "altdash doesn't appear to be installed!"
    exit 1
fi

#shellcheck source=sources/functions/altdash
. /etc/swizzin/sources/functions/altdash

altdash_check_variables || exit 1
altdash_release || exit 1
altdash_choose_store || exit 1

# Nothing to change: the panel keeps running, and the backup of the previous release stays
store_now=no
altdash_store_installed && store_now=yes
if [[ $(swizdb get altdash/release 2> /dev/null) == "$altdash_version" && $store_now == "$altdash_with_store" ]]; then
    echo_success "altdash is up to date ($altdash_version)"
    exit 0
fi

altdash_check_python || exit 1
altdash_deploy || exit 1
echo_success "altdash upgraded ($altdash_version)"

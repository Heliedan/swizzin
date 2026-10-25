#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "panel" || BAD=true
check_port_curl "altdash" || BAD=true
check_nginx "" || BAD=true
if [[ $(swizdb get altdash/store 2> /dev/null) == yes ]]; then
    check_service "swizzin-store" || BAD=true
    if [[ ! -S /run/swizzin-store/store.sock ]]; then
        echo_warn "The App Store service has no socket (/run/swizzin-store/store.sock)"
        BAD=true
    fi
fi

evaluate_bad "altdash"

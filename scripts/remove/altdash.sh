#!/bin/bash
# altdash remover
# Heliedan 2026 for Swizzin

#shellcheck source=sources/functions/altdash
. /etc/swizzin/sources/functions/altdash

# Stopped first: with no panel, nobody can start an installation from the App Store. One that runs is never cut off:
# the removal waits for its end (30 minutes at most).
systemctl stop panel >> "$log" 2>&1
if altdash_store_busy; then
    echo_info "The App Store is installing or uninstalling an application: waiting for it to finish"
    for _ in $(seq 180); do
        altdash_store_busy || break
        sleep 10
    done
    if altdash_store_busy; then
        systemctl start panel >> "$log" 2>&1
        echo_error "The App Store is still busy (or its service does not answer): altdash was NOT removed. Try again once it is done"
        exit 1
    fi
fi

# The settings and custom tiles, for a panel installed later
saved="$altdash_backups/removed-$(date +%Y%m%d-%H%M%S)"
if ! install -d -m 0700 "$altdash_backups" "$saved" ||
    { [[ -f /opt/swizzin/swizzin.cfg ]] && ! cp -a /opt/swizzin/swizzin.cfg "$saved/"; } ||
    { [[ -f /opt/swizzin/core/custom/profiles.py ]] && ! cp -a /opt/swizzin/core/custom/profiles.py "$saved/"; }; then
    systemctl start panel >> "$log" 2>&1
    echo_error "Could not save your panel settings in $saved: altdash was NOT removed"
    exit 1
fi

altdash_store_remove
systemctl disable -q --now panel >> "$log" 2>&1
rm -rf /opt/swizzin "$altdash_venv"
if [[ -z "$(ls -A /opt/.venv 2> /dev/null)" ]]; then
    rm -rf /opt/.venv
fi
rm -f /etc/nginx/apps/panel.conf /etc/sudoers.d/panel /etc/systemd/system/panel.service
systemctl daemon-reload
if [[ -f /install/.nginx.lock ]]; then
    systemctl reload nginx
fi
swizdb clear altdash/store > /dev/null 2>&1
swizdb clear altdash/release > /dev/null 2>&1
rm -f /install/.altdash.lock
echo_info "Your panel settings and custom tiles are saved in $saved, and earlier panels in $altdash_backups. For the official panel: box install panel"

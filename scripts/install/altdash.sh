#!/bin/bash
# altdash installer: Heliedan's edition of the Swizzin panel, in place of the panel
# Heliedan 2026 for Swizzin
#
# Unattended variables:
# - ALTDASH_STORE=yes|no: install the App Store service (default: ask, Yes)
# - ALTDASH_REPLACE_PANEL=yes|no: replace the panel when it is installed (default: ask, Yes)
# - ALTDASH_TAG=heliedan-x.y: install this release (heliedan-2.4 or later) instead of the latest one

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
#shellcheck source=sources/functions/altdash
. /etc/swizzin/sources/functions/altdash

altdash_check_variables || exit 1

# The panel, when it is installed, is replaced in place: its settings and custom tiles are kept, and it is saved in
# /var/backups/altdash. Anything else in /opt/swizzin is not Swizzin's panel, and is left alone.
replace_panel=no
if [[ -f /install/.panel.lock ]]; then
    replace_panel=$(_altdash_yes_no "$ALTDASH_REPLACE_PANEL")
    if [[ -z $replace_panel ]]; then
        echo_info "altdash takes the place of the panel: your settings and custom tiles are kept, and the panel is saved in $altdash_backups."
        if ask "Replace the panel with altdash?" Y; then replace_panel=yes; else replace_panel=no; fi
    fi
    if [[ $replace_panel != yes ]]; then
        echo_info "The panel was left as it is"
        exit 1
    fi
    if [[ ! -d /opt/swizzin || ! -x $altdash_venv/bin/python ]]; then
        echo_error "The panel is not complete (/opt/swizzin or $altdash_venv is missing): repair it first with box remove panel, then box install panel"
        exit 1
    fi
elif [[ -e /opt/swizzin ]]; then
    echo_error "/opt/swizzin exists, but Swizzin's panel is not installed: move it away first"
    exit 1
fi

if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "This package requires nginx to be installed!"
    if ask "Install nginx?" Y; then
        bash /usr/local/bin/swizzin/install/nginx.sh
    else
        exit 1
    fi
fi

altdash_release || exit 1
altdash_choose_store || exit 1

if [[ $replace_panel != yes ]]; then
    useradd -r swizzin -s /usr/sbin/nologin > /dev/null 2>&1
    apt_install python3-pip python3-venv acl
    python3_venv swizzin swizzin
elif ! dpkg -s acl > /dev/null 2>&1; then
    apt_install acl
fi
if ! altdash_check_python || ! altdash_deploy; then
    # A first install leaves nothing behind (the panel's own remove script keeps the swizzin user too)
    if [[ $replace_panel != yes ]]; then
        rm -rf "$altdash_venv"
        if [[ -z "$(ls -A /opt/.venv 2> /dev/null)" ]]; then rm -rf /opt/.venv; fi
    fi
    exit 1
fi

echo_progress_start "Setting permissions"
setfacl -m g:swizzin:rx /home/*
if [[ -f /install/.deluge.lock ]]; then
    touch /install/.delugeweb.lock
fi
echo_progress_done

touch /install/.altdash.lock
rm -f /install/.panel.lock
if [[ $replace_panel == yes ]]; then
    echo_info "The panel you replaced is saved in $altdash_backups. For the official panel again: box remove altdash, then box install panel"
fi
echo_success "altdash installed ($altdash_version)"

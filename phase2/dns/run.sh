#!/bin/sh
set -eu

if [ "$#" -gt 3 ]; then
    printf 'Usage: sh %s [interface|vpn] [port] [hosts-file]\n' "$0" >&2
    exit 2
fi

config_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
interface=${1:-en0}
port=${2:-53}
hosts_file=${3:-}
case "$port" in
    53|1053) ;;
    *) printf 'Use port 53 for the demo or 1053 for rehearsal.\n' >&2; exit 2 ;;
esac

if [ "$interface" = vpn ]; then
    bind_ip=${TEAM67_VPN_IP:-}
    if [ -z "$bind_ip" ]; then
        printf 'Set TEAM67_VPN_IP to this Mac\047s connected Tailscale IPv4 address.\n' >&2
        exit 2
    fi
    # Resolve the actual tunnel device rather than assuming a fixed utun number.
    interface=$(/sbin/ifconfig | awk -v ip="$bind_ip" '
        /^[^[:space:]]/ { device=$1; sub(/:$/, "", device) }
        device ~ /^utun[0-9]+$/ && $1 == "inet" && $2 == ip { print device; exit }
    ')
    if [ -z "$interface" ]; then
        printf 'IPv4 %s is not assigned to an active VPN interface on this Mac.\n' "$bind_ip" >&2
        exit 1
    fi
else
    bind_ip=$(/usr/sbin/ipconfig getifaddr "$interface" || true)
    if [ -z "$bind_ip" ]; then
        printf 'No IPv4 address on %s. Check the active network interface.\n' "$interface" >&2
        exit 1
    fi
fi

if ! dnsmasq=$(command -v dnsmasq); then
    printf 'dnsmasq was not found. Install it with brew install dnsmasq.\n' >&2
    exit 1
fi

set -- --conf-file="$config_dir/dnsmasq.conf" --port="$port" \
    --listen-address="127.0.0.1,$bind_ip" --keep-in-foreground \
    --log-facility=-

if [ -n "$hosts_file" ]; then
    if [ ! -f "$hosts_file" ] || [ ! -r "$hosts_file" ]; then
        printf 'Cannot read hosts file: %s\n' "$hosts_file" >&2
        exit 1
    fi
    hosts_dir=$(CDPATH= cd -- "$(dirname -- "$hosts_file")" && pwd)
    set -- "$@" --addn-hosts="$hosts_dir/$(basename -- "$hosts_file")"
else
    # Either resolver can use this rehearsal answer. Both should map to Nakul.
    probe_ip=${TEAM67_PROBE_IP:-$bind_ip}
    set -- "$@" --host-record="dnscheck.team67.test,$probe_ip"
fi

"$dnsmasq" --test "$@"
printf 'Team 67 DNS on %s (%s), port %s. Control-C stops this instance.\n' \
    "$bind_ip" "$interface" "$port"

if [ "$port" = 53 ]; then
    # Use the terminal for the administrator prompt. Keep this process visible.
    exec sudo "$dnsmasq" "$@" --pid-file="${TMPDIR:-/tmp}/team67-dnsmasq-53.pid"
fi

exec "$dnsmasq" "$@" --pid-file="${TMPDIR:-/tmp}/team67-dnsmasq-1053.pid"

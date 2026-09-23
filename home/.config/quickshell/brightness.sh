#!/usr/bin/env bash
set -euo pipefail

STEPS=20
DIMMEST=0.01

case ${1:-} in up|down|set|dim|restore|get) ;; *) echo "usage: $0 up|down|set <percent>|dim <raw>|restore|get" >&2; exit 2 ;; esac

run=${XDG_RUNTIME_DIR:-/tmp}
quiet=$run/brightness.quiet
saved=$run/brightness.saved
for d in /sys/class/backlight/*; do break; done
[ "$1" = get ] || { exec 9>"$run/brightness.lock"; flock 9; }
[ -r "$d/brightness" ] || exit 1
read -r raw < "$d/brightness"
read -r max < "$d/max_brightness"

write() { exec brightnessctl -q -d "${d##*/}" -n0 set "$1"; }

case $1 in
dim)
    case ${2:-} in ''|*[!0-9]*) exit 2 ;; esac
    [ -s "$saved" ] && [ -s "$quiet" ] && read -r r < "$quiet" && [ "$r" = "$raw" ] && exit 0
    echo "$raw" > "$saved"
    [ "$raw" -gt "$2" ] || exit 0
    echo "$2" > "$quiet"; write "$2" ;;
restore)
    [ -s "$saved" ] || exit 0
    read -r r < "$saved"; : > "$saved"
    [ "$r" != "$raw" ] || exit 0
    echo "$r" > "$quiet"; write "$r" ;;
esac

q=0
[ "$1" = get ] && [ -s "$quiet" ] && read -r r < "$quiet" && [ "$r" = "$raw" ] && q=1

out=$(awk -v op="$1" -v arg="${2:-0}" -v raw="$raw" -v max="$max" -v n="$STEPS" -v lo="$DIMMEST" -v dev="${d##*/}" -v q="$q" '
function toraw(p,  t) {
    if (p <= 0) return 0
    t = (p - 1/n) / (1 - 1/n)
    if (t < 0) t = 0
    if (t > 1) t = 1
    return int(max * exp((1 - t) * log(lo)) + 0.5)
}
function topct(r,  p) {
    if (r <= 0) return 0
    p = 1/n + (1 - 1/n) * (1 - log(r / max) / log(lo))
    return p < 0.01 ? 0.01 : p > 1 ? 1 : p
}
BEGIN {
    cur = topct(raw)
    if (op == "get") { printf "%s %.4f %d %d %d\n", dev, cur, raw, max, q; exit }
    if (op == "set") {
        p = arg / 100
        if (p < 1/n) p = 1/n
        if (p > 1) p = 1
    } else {
        # snap off-grid values (slider, idle dim) onto the grid in the step direction
        x = cur * n
        if (op == "up") k = int(x + 0.25) + 1
        else { y = x - 0.25; k = int(y) + (y > int(y)) - 1 }
        if (k < 0) k = 0
        if (k > n) k = n
        p = k / n
        if ((p - cur) * (op == "up" ? 1 : -1) <= 0) exit
    }
    r = toraw(p)
    if (r != raw) print r
}')

if [ "$1" = get ]; then echo "$out"
elif [ -n "$out" ]; then [ -s "$quiet" ] && : > "$quiet"; write "$out"
fi

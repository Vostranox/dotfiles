function __adh_import_bash_history --description 'Import new Bash history without executing it'
    if test (string match -r '^[0-9]+' -- "$version") -lt 4
        return 0
    end
    test "$fish_private_mode" = 1; and return
    if set -q fish_history; and not contains -- "$fish_history" fish default
        return
    end
    set -l source "$HOME/.bash_history"
    set -q argv[1]; and set source "$argv[1]"
    test -f "$source"; and test -r "$source"; or return

    set -l signature (command stat -c '%d:%i:%s:%y' -- "$source" 2>/dev/null)
    if test $status -ne 0
        set signature (command stat -f '%d:%i:%z:%m:%c' "$source" 2>/dev/null)
    end
    test -n "$signature"; or return
    if test "$source" = "$__adh_bash_history_source"; and test "$signature" = "$__adh_bash_history_signature"
        return
    end
    set -l fields (string split -m 3 : -- "$signature")
    set -l identity "$fields[1]:$fields[2]"
    set -l size "$fields[3]"
    set -l offset 0
    set -l timestamped 0
    set -l record ''
    set -l initial 1
    if test "$source" = "$__adh_bash_history_source"; and test "$identity" = "$__adh_bash_history_identity"; and test "$size" -gt "$__adh_bash_history_size"
        set offset "$__adh_bash_history_offset"
        set timestamped "$__adh_bash_history_timestamped"
        set record "$__adh_bash_history_pending"
        set initial 0
    end

    set -l chunk ''
    command tail -c +(math "$offset + 1") -- "$source" | command head -c (math "$size - $offset") | read -lz chunk
    set -l lines (string split \n -- "$chunk")
    set -l partial "$lines[-1]"
    set -e lines[-1]
    set -l partial_bytes (printf %s "$partial" | command wc -c | string trim)
    set -l entries
    for line in $lines
        if string match -qr '^#[0-9]+$' -- "$line"
            test -n "$record"; and set -a entries "$record"
            set timestamped 1
            set record ''
        else if test "$timestamped" = 1
            if test -n "$record"
                set record "$record
$line"
            else
                set record "$line"
            end
        else if not string match -qr '^\s*(#|$)' -- "$line"
            set -a entries "$line"
        end
    end
    if test -z "$partial"
        test -n "$record"; and set -a entries "$record"
        set record ''
    end

    if test "$initial" = 1
        builtin history search --null | while read -lz previous
            set -f __adh_seen_(string escape --style=var -- "$previous") 1
        end
    end
    set -l imported
    for entry in $entries[-1..1]
        string match -qr '^\s*(#|$)' -- "$entry"; and continue
        set -l key __adh_seen_(string escape --style=var -- "$entry")
        set -q "$key"; and continue
        set -f "$key" 1
        set -a imported "$entry"
    end
    if set -q imported[1]
        builtin history append -- $imported[-1..1]
        builtin history save
    end
    set -g __adh_bash_history_source "$source"
    set -g __adh_bash_history_signature "$signature"
    set -g __adh_bash_history_identity "$identity"
    set -g __adh_bash_history_size "$size"
    set -g __adh_bash_history_offset (math "$size - $partial_bytes")
    set -g __adh_bash_history_timestamped "$timestamped"
    set -g __adh_bash_history_pending "$record"
end

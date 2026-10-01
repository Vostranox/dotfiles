function __adh_fish_clipboard --argument-names action --description 'Use the Windows clipboard on WSL, with native Fish fallbacks'
    set -l is_wsl 0
    if set -q WSL_DISTRO_NAME; or set -q WSL_INTEROP
        set is_wsl 1
    end

    switch $action
        case copy-commandline
            set -l text (commandline --current-selection | string collect)
            test -n "$text"; or set text (commandline | string collect)
            printf %s "$text" | __adh_fish_clipboard copy
        case paste-commandline
            set -l text (__adh_fish_clipboard paste | string collect -N)
            if test -n "$text"
                if functions -q __fish_paste
                    __fish_paste "$text"
                else
                    commandline --insert -- "$text"
                end
            end
        case copy
            set -l text ''
            read -lz text
            if test "$is_wsl" = 1; and command -q clip.exe; and command -q iconv
                printf %s "$text" | command iconv -f UTF-8 -t UTF-16LE 2>/dev/null | command clip.exe 2>/dev/null
                set -l result $pipestatus
                if test "$result[2]" = 0; and test "$result[3]" = 0
                    return 0
                end
            end
            printf %s "$text" | fish_clipboard_copy 2>/dev/null
        case paste
            if test "$is_wsl" = 1; and command -q powershell.exe
                command powershell.exe -NoLogo -NoProfile -NonInteractive -Command '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::Write(([string](Get-Clipboard -Raw -ErrorAction Stop)).Replace("`r`n", "`n"))' 2>/dev/null
                and return 0
            end
            fish_clipboard_paste 2>/dev/null
        case '*'
            return 2
    end
end

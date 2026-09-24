------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.0",
})

---------------------
---- MACHINE TYPE ----
---------------------

local function chassisSaysLaptop()
    local f = io.open("/sys/class/dmi/id/chassis_type", "r")
    if not f then return false end
    local t = tonumber(f:read("*l"))
    f:close()
    local PORTABLE = { [8] = true, [9] = true, [10] = true, [11] = true,
                       [14] = true, [30] = true, [31] = true, [32] = true }
    return PORTABLE[t] == true
end

local function hasSystemBattery()
    local p = io.popen("cat /sys/class/power_supply/BAT*/type " .. "/sys/class/power_supply/CMB*/type 2>/dev/null")
    if not p then return false end
    local out = p:read("*a") or ""
    p:close()
    return out:find("Battery", 1, true) ~= nil
end

local HOME    = os.getenv("HOME")
local LAPTOP  = chassisSaysLaptop() or hasSystemBattery()
local PROFILE = LAPTOP and "laptop" or "desktop"

local function startHypridle()
    hl.exec_cmd(string.format("sh -c 'pkill -x hypridle; exec hypridle -c \"%s/.config/hypr/hypridle-%s.conf\"'", HOME, PROFILE))
end

hl.on("config.reloaded", startHypridle)

-------------------
---- AUTOSTART ----
-------------------

swapOverviewGestures = nil
function overviewGestures(on)
    if swapOverviewGestures then swapOverviewGestures(on) end
    return hl.dsp.event("overviewgestures," .. tostring(on))
end

hl.on("hyprland.start", function ()
  hl.exec_cmd("protonmail-bridge --no-window")
  hl.exec_cmd("sh -c 'for i in $(seq 40); do busctl --user status org.kde.StatusNotifierWatcher >/dev/null 2>&1 && break; sleep 0.25; done; exec protonvpn-app --start-minimized'")
  startHypridle()
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd("qs --no-duplicate --daemonize")
  hl.exec_cmd("xdg-desktop-portal-hyprland")
  hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
  hl.exec_cmd("hyprctl setcursor Breeze_Light 30")
  hl.exec_cmd("fcitx5 -d --replace")

  hl.exec_cmd("emacs",          { workspace = "1 silent" })
  hl.exec_cmd("ghostty",        { workspace = "2 silent" })
  hl.exec_cmd("zen-browser",    { workspace = "3 silent" })
  hl.exec_cmd("signal-desktop", { workspace = "4 silent" })
  hl.exec_cmd("Telegram",       { workspace = "4 silent" })
  hl.exec_cmd("thunderbird",    { workspace = "4 silent" })
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "30")
hl.env("HYPRCURSOR_SIZE", "30")
hl.env("XCURSOR_THEME", "Breeze_Light")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XMODIFIERS", "@im=fcitx")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 1,

        col = {
            active_border   = { colors = {"#95a99f" } },
            inactive_border = "#282828",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "master",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

local smartGaps = {
    hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 }),
    hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 }),
    hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 }),
    hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 }),
}

local smartGapsOn = false
for _, rule in ipairs(smartGaps) do
    rule:set_enabled(smartGapsOn)
end

function toggleSmartGaps()
    smartGapsOn = not smartGapsOn
    for _, rule in ipairs(smartGaps) do
        rule:set_enabled(smartGapsOn)
    end
    return hl.dsp.event("smartgaps," .. tostring(smartGapsOn))
end

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,

        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,

        on_focus_under_fullscreen = 1,
    },

    binds = {
        movefocus_cycles_fullscreen = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        repeat_delay = 500,
        repeat_rate  = 33,

        follow_mouse = 0,

        sensitivity = 0,
    },
})

if LAPTOP then
    hl.config({
        input = { touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.8,
        }},

        gestures = {
            workspace_swipe_distance     = 400,
            workspace_swipe_cancel_ratio = 0.3,
        },
    })

    local SWIPE_SCALE    = 1.0
    local OVERVIEW_SCALE = 1.6
    local OVERVIEW_STEP  = 110
    local overviewAccum  = 0

    local function stepOverview(n)
        hl.dispatch(hl.dsp.exec_cmd("qs ipc call shell overviewStep " .. n))
    end

    local function bindWorkspaceSwipe()
        hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace", scale = SWIPE_SCALE })
    end

    local function bindOverviewSwipe()
        hl.gesture({
            fingers   = 3,
            direction = "horizontal",
            scale     = OVERVIEW_SCALE,
            action    = {
                start  = function() overviewAccum = 0 end,
                update = function(e)
                    overviewAccum = overviewAccum + ((e.delta and e.delta.x) or 0)
                    while overviewAccum >= OVERVIEW_STEP do
                        overviewAccum = overviewAccum - OVERVIEW_STEP
                        stepOverview(1)
                    end
                    while overviewAccum <= -OVERVIEW_STEP do
                        overviewAccum = overviewAccum + OVERVIEW_STEP
                        stepOverview(-1)
                    end
                end,
            },
        })
    end

    bindWorkspaceSwipe()

    -- removeGesture matches on scale, so each unset must name the scale the
    -- gesture it removes was bound with.
    swapOverviewGestures = function(on)
        if on then
            hl.gesture({ fingers = 3, direction = "horizontal", action = "unset", scale = SWIPE_SCALE })
            bindOverviewSwipe()
        else
            hl.gesture({ fingers = 3, direction = "horizontal", action = "unset", scale = OVERVIEW_SCALE })
            bindWorkspaceSwipe()
        end
    end

    hl.gesture({
        fingers   = 3,
        direction = "up",
        action    = function()
            hl.dispatch(hl.dsp.exec_cmd("qs ipc call shell overview"))
        end,
    })

    hl.gesture({
        fingers   = 3,
        direction = "down",
        action    = function()
            hl.dispatch(hl.dsp.exec_cmd("qs ipc call shell close"))
        end,
    })

    hl.gesture({
        fingers   = 4,
        direction = "up",
        action    = function()
            hl.dispatch(hl.dsp.exec_cmd("qs ipc call shell apps"))
        end,
    })

    hl.gesture({
        fingers   = 4,
        direction = "down",
        action    = function()
            hl.dispatch(hl.dsp.exec_cmd("qs ipc call shell close"))
        end,
    })
end

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

local closeWindowBind = hl.bind(mainMod .. " + X", hl.dsp.window.close())

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("loginctl lock-session && systemctl suspend"))
hl.bind(mainMod .. " + L", function()
    hl.dispatch(hl.dsp.exec_cmd("loginctl lock-session"))
    hl.timer(function()
        hl.dispatch(hl.dsp.exec_cmd(
            [[pgrep -x hyprlock >/dev/null && hyprctl dispatch 'hl.dsp.dpms({ action = "off" })']]))
    end, { timeout = 10000, type = "oneshot" })
end)

hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

hl.bind(mainMod .. " + Return", hl.dsp.layout("swapwithmaster master"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + space", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind(mainMod .. " + Tab",         hl.dsp.window.cycle_next({ tiled = true }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false, tiled = true }))
hl.bind(mainMod .. " + a",           hl.dsp.window.cycle_next({ tiled = true }))
hl.bind(mainMod .. " + e",           hl.dsp.window.cycle_next({ next = false, tiled = true }))

hl.bind(mainMod .. " + SHIFT + a", hl.dsp.layout("swapnext"))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.layout("swapprev"))

local WORKSPACES = 5

for i = 1, WORKSPACES do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- n, r, t, s, g
hl.bind(mainMod .. " + " .. "N",           hl.dsp.focus({ workspace = 1}))
hl.bind(mainMod .. " + SHIFT + " .. "N",   hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + " .. "R",           hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + " .. "R",   hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + " .. "T",           hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + " .. "T",   hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + " .. "S",           hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + " .. "S",   hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + " .. "G",           hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + " .. "G",   hl.dsp.window.move({ workspace = 5 }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd(HOME .. "/.config/quickshell/brightness.sh up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd(HOME .. "/.config/quickshell/brightness.sh down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("qs ipc call shell mediaNext || playerctl next"),         { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call shell mediaToggle || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("qs ipc call shell mediaToggle || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("qs ipc call shell mediaPrev || playerctl previous"),     { locked = true })

local SHOTS = HOME .. "/Pictures/screenshots"
hl.bind("Print", hl.dsp.exec_cmd("qs ipc call shell screenshot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
    [[sh -c 'mkdir -p "]] .. SHOTS .. [["; g=$(slurp) || exit 0; f="]] .. SHOTS ..
        [[/$(date +%F_%H%M%S)_${g#* }.png"; grim -g "$g" "$f" && wl-copy < "$f"']]))

-------------------
---- QUICKSHELL ---
-------------------

hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd("qs ipc call shell launcher"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("qs ipc call shell control"))
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd("qs ipc call shell bar"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs ipc call shell dock"))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd("qs ipc call shell notifications"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("qs ipc call shell overview"))

hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("fcitx5-remote -t"))

hl.bind(mainMod .. " + M", toggleSmartGaps)

hl.bind("ALT + Tab",         hl.dsp.exec_cmd("qs ipc call shell switchNext"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call shell switchPrev"))
hl.bind("ALT + right",       hl.dsp.exec_cmd("qs ipc call shell switchNext"))
hl.bind("ALT + left",        hl.dsp.exec_cmd("qs ipc call shell switchPrev"))
hl.bind("ALT + Escape",      hl.dsp.exec_cmd("qs ipc call shell switchCancel"))
hl.bind("ALT + ALT_L",
        hl.dsp.exec_cmd("qs ipc call shell switchCommit"),
        { release = true, transparent = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

for i = 1, WORKSPACES do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
end

local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

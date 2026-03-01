import XMonad
import Data.Monoid
import System.Exit
import XMonad.Util.SpawnOnce
import XMonad.Actions.SpawnOn
import XMonad.Layout.Spacing
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.Tabbed
import XMonad.Layout.NoBorders
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageDocks
import Graphics.X11.ExtraTypes.XF86
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import qualified XMonad.Actions.Warp as Warp

myModMask            = mod4Mask
myTerminal           = "alacritty"
myFocusFollowsMouse  = True
myClickJustFocuses   = False
myBorderWidth        = 1
myNormalBorderColor  = "#484848"
myFocusedBorderColor = "#95a99f"
myWorkspaces         = ["1","2","3","4","5"]

myTabConfig = def
  { fontName            = "xft:JetBrains Mono:size=7"
  , activeColor         = "#353a39"
  , inactiveColor       = "#282828"
  , urgentColor         = "#e45457"
  , activeTextColor     = "#c8c8d5"
  , inactiveTextColor   = "#c8c8d5"
  , urgentTextColor     = "#ffffff"
  , activeBorderColor   = "#52494e"
  , inactiveBorderColor = "#282828"
  , urgentBorderColor   = "#e45457"
  , activeBorderWidth   = 0
  , inactiveBorderWidth = 0
  , urgentBorderWidth   = 0
  , decoHeight          = 20 }

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
    , ((modm,               xK_Return), windows W.swapMaster)
    , ((modm,               xK_space ), sendMessage NextLayout)
    , ((modm,               xK_c     ), spawn "dmenu_run")
    , ((modm,               xK_d     ), spawn "if pgrep polybar; then killall polybar; else polybar; fi")
    , ((modm,               xK_l     ), spawn "i3lock -c 000000")
    , ((modm,               xK_q     ), spawn "i3lock -c 000000; sleep 2; systemctl suspend")
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
    , ((modm,               xK_w     ), withFocused $ windows . W.sink)
    , ((modm,               xK_m     ), sendMessage $ Toggle MIRROR)
    , ((modm,               xK_x     ), kill)
    , ((modm,               xK_z     ), spawn "xmonad --recompile; xmonad --restart")
    , ((modm,               xK_h     ), sendMessage Shrink)
    , ((modm,               xK_a     ), windows W.focusDown)
    , ((modm,               xK_e     ), windows W.focusUp)
    , ((modm,               xK_i     ), sendMessage Expand)
    , ((modm .|. shiftMask, xK_a     ), windows W.swapDown)
    , ((modm .|. shiftMask, xK_e     ), windows W.swapUp)
    , ((modm,               xK_p     ), windows W.focusMaster)
    , ((modm,               xK_comma ), sendMessage (IncMasterN 1))
    , ((modm,               xK_period), sendMessage (IncMasterN (-1)))
    ]
    ++
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_n, xK_r, xK_t, xK_s, xK_g]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1, xK_2, xK_3, xK_4, xK_5]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f) >> (Warp.warpToWindow 0.5 0.5))
        | (key, sc) <- zip [xK_o, xK_f, xK_u] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
    ++
    [ ((0, xF86XK_AudioMute),         spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
    , ((0, xF86XK_AudioLowerVolume),  spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%")
    , ((0, xF86XK_AudioRaiseVolume),  spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%")
    , ((0, xF86XK_MonBrightnessUp),   spawn "brightnessctl set +5%")
    , ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl set 5%-")
    , ((0, xF86XK_AudioPlay),         spawn "playerctl play-pause")
    , ((0, xF86XK_AudioNext),         spawn "playerctl next")
    , ((0, xF86XK_AudioPrev),         spawn "playerctl previous")
    ]

myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))]

myLayout = avoidStruts $ mkToggle (single MIRROR) layoutList
  where
    layoutList =
           noBorders (tabbed shrinkText myTabConfig)
       ||| tiledLayout
       ||| noBorders Full
    tiledLayout =
           smartBorders
         $ smartSpacingWithEdge 10
         $ Tall 1 (3/100) (1/2)

myManageHook = composeAll
               [ manageSpawn
               , manageDocks
               , className =? "Polybar" --> doIgnore
               , resource  =? "polybar" --> doIgnore
               ]

myEventHook = mempty

myLogHook = return ()

myStartupHook = do
  spawnOnce "xrdb -merge ~/.Xresources"
  spawnOnce "xsetroot -cursor_name left_ptr"
  spawnOnce "nm-applet"
  spawnOnce "blueman-applet"
  spawnOnce "nitrogen --restore"
  spawnOnce "protonmail-bridge --no-window"
  spawnOnce "/usr/lib/polkit-kde-authentication-agent-1"
  spawnOn "3" "zen-browser"
  spawnOn "2" "alacritty"
  spawnOn "1" "emacs"

main = xmonad $ ewmhFullscreen $ ewmh $ docks $ defaults

defaults = def {
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,
        keys               = myKeys,
        mouseBindings      = myMouseBindings,
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook,
        logHook            = myLogHook,
        startupHook        = myStartupHook <+> setWMName "LG3D"
}

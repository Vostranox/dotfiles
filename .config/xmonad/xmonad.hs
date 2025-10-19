import XMonad
import Data.Monoid
import System.Exit
import XMonad.Util.SpawnOnce
import XMonad.Actions.SpawnOn
import XMonad.Layout.Spacing
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
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

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    [ ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
    , ((modm,               xK_c     ), spawn "dmenu_run")
    , ((modm,               xK_x     ), kill)
    , ((modm,               xK_d     ), spawn "if pgrep polybar; then killall polybar; else polybar; fi")
    , ((modm,               xK_l     ), spawn "i3lock -c 000000")
    , ((modm,               xK_q     ), spawn "i3lock -c 000000; sleep 2; systemctl suspend")
    , ((modm,               xK_space ), sendMessage NextLayout)
    , ((modm,               xK_j     ), sendMessage $ Toggle MIRROR)
    , ((modm,               xK_w     ), withFocused $ windows . W.sink)
    , ((modm,               xK_a     ), windows W.focusDown)
    , ((modm,               xK_e     ), windows W.focusUp  )
    , ((modm .|. shiftMask, xK_a     ), windows W.swapDown  )
    , ((modm .|. shiftMask, xK_e     ), windows W.swapUp    )
    , ((modm,               xK_p     ), windows W.focusMaster  )
    , ((modm,               xK_Return), windows W.swapMaster)
    , ((modm,               xK_h     ), sendMessage Shrink)
    , ((modm,               xK_i     ), sendMessage Expand)
    , ((modm,               xK_comma ), sendMessage (IncMasterN 1))
    , ((modm,               xK_period), sendMessage (IncMasterN (-1)))
    , ((modm,               xK_z     ), spawn "xmonad --recompile; xmonad --restart")
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
    ]
    ++
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_n, xK_r, xK_t, xK_s, xK_g]
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

myLayout = avoidStruts $ smartSpacingWithEdge 10 $ mkToggle (single MIRROR) $ (noBorders Full ||| smartBorders tiled)
  where
    nmaster = 1
    ratio   = 1/2
    delta   = 3/100
    tiled   = Tall nmaster delta ratio

myManageHook = composeAll
               [ manageSpawn
               , manageDocks
               , className =? "Polybar" --> doIgnore
               , resource  =? "polybar" --> doIgnore
               ]

myEventHook = mempty

myLogHook = return ()

myStartupHook = do
  spawnOnce "nitrogen --restore"
  spawnOnce "xrdb -merge ~/.Xresources"
  spawnOnce "xsetroot -cursor_name left_ptr"
  spawnOnce "blueman-applet"
  spawnOnce "nm-applet"
  spawnOnce "caffeine"
  spawnOnce "/usr/lib/polkit-kde-authentication-agent-1"
  spawnOn "1" "emacs"
  spawnOn "2" "alacritty"
  spawnOn "3" "zen-browser"

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

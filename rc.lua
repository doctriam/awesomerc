-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- LIBRARIES -----------------------------------------------------------------
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Custom Widgets
local battery_widget = require("widgets.battery-widget.batteryarc")
local volume_widget = require("widgets.volumearc-widget.volumearc")
local brightness_widget = require("widgets.brightnessarc-widget.brightnessarc")
-- Custom Theme
local custom_theme = require("themes.zenburn.theme")
local mysystray
-- HOTKEYS REQUIREMENT -------------------------------------------------------
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- ERROR HANDLING ------------------------------------------------------------
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end

-- Themes define colours, icons, font and wallpapers.
beautiful.init(custom_theme)

-- VARIABLES ----------------------------------------------------------------- 
-- This is used later as the default terminal and editor to run.
terminal = "xfce4-terminal"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"

-- LAYOUTS -------------------------------------------------------------------
-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
}

-- Set terminal
menubar.utils.terminal = terminal -- Set the terminal for applications that require it

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- Mouse configuration
local taglist_buttons = gears.table.join(
    -- Click on tag number to open the tag
    awful.button({ }, 1, function(t) t:view_only() end),
    -- Mod + left-click on new tag to move focused client from
    -- old tag
    awful.button({ modkey }, 1, function(t)
                              if client.focus then
                                  client.focus:move_to_tag(t)
                              end
                          end),
    -- Right-click on non-focused tag to view clients from that
    -- tag on current tag
    awful.button({ }, 3, awful.tag.viewtoggle),
    -- Mod + right-click on non-focused to tag view focused
    -- client on selected tag
    awful.button({ modkey }, 3, function(t)
                              if client.focus then
                                  client.focus:toggle_tag(t)
                              end
                          end),
    -- Scroll-wheel to navigate to previous or next tag
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)
local tasklist_buttons = gears.table.join(
    -- Left-click tasklist item to focus, minimize, or
    -- maximize the client
    awful.button({ }, 1, function (c)
                          if c == client.focus then
                              c.minimized = true
                          else
                              c:emit_signal(
                                  "request::activate",
                                  "tasklist",
                                  {raise = true}
                              )
                          end
                      end),
    -- Right-click on tasklist to view dropdown list of all
    -- available clients
    awful.button({ }, 3, function()
                          awful.menu.client_list({ theme = { width = 250 } })
                      end),
    -- Scroll-wheel on tasklist to focus next or previous
    -- client
    awful.button({ }, 4, function ()
                          awful.client.focus.byidx(1)
                      end),
    awful.button({ }, 5, function ()
                          awful.client.focus.byidx(-1)
                      end))

-- WALLPAPER and TASKBAR -----------------------------------------------------
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Set wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- TASKBAR WIDGETS -------------------------------------------------------
    -- Create a promptbox widget
    s.mypromptbox = awful.widget.prompt({
        bg = '#cc9393',
        fg = '#ffffff',
        prompt = ' Run: '
    })
    
    -- Create layout widget with layout-switching functionality
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        -- Navigate layouts by using mouse functions on layout icon
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    local layoutnotification
    s.mylayoutbox:connect_signal("mouse::enter", function()
        naughty.destroy(layoutnotification)
        layoutnotification = naughty.notify {
            title = "Layouts",
            text = "Modkey + Space or left-click on\nicon or press to swap layouts.",
            timeout = 5,
            hover_timeout = 0.1,
        }
    end)
    s.mylayoutbox:connect_signal("mouse::leave", function()
        naughty.destroy(layoutnotification)
    end)

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        style = {
            shape = gears.shape.circle,
            bg_focus = '#709080',
            bg_occupied = '#1e2320',
            bg_urgent = '#cc9393',
        },
    }
    
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            bg_focus = '#709080',
            bg_minimize = '#cc9383',
            shape_border_width = 2,
            shape_border_color = '#777777',
            shape = gears.shape.rounded_rect,
        },
        layout = {
            spacing = 5,
            layout = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        {
                            id = 'icon_role',
                            widget = wibox.widget.imagebox,
                        },
                        margins = 2,
                        widget = wibox.container.margin,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left = 10,
                right = 10,
                widget = wibox.container.margin
            },
            id = 'background_role',
            widget = wibox.container.background,
        },
    }
    
    -- Create system tray with hide functionality
    awful.screen.connect_for_each_screen(function(s)
            s.systray = wibox.widget.systray()
            s.systray.visible = true
        end
    )
    mysystray = wibox.widget {
        {
            s.systray,
            left = 12.5,
            top = 3,
            bottom = 3,
            right = 12.5,
            visible = true,
            widget = wibox.container.margin,
        },
        bg = beautiful.border_normal,
        shape_border_width = 3,
        shape_border_color = "#dfdfdf",
        shape = gears.shape.rounded_rect,
        shape_clilp = true,
        widget = wibox.container.background,
    }
    
    -- System tray label
    local systraynotification
    mysystray:connect_signal("mouse::enter", function()
        naughty.destroy(systraynotification)
        systraynotification = naughty.notify {
            title = "System Tray",
            text = "Click Modkey + '=' to toggle.\nOnly displays on primary screen.",
            timeout = 5,
            hover_timeout = 0.1,
        }
    end)
    mysystray:connect_signal("mouse::leave", function()
        naughty.destroy(systraynotification)
    end)
    
    -- Create clock with calendar pop-up
    local mytextclock = wibox.widget.textclock()
    local month_calendar = awful.widget.calendar_popup.month({
        start_sunday = true,
        long_weekdays = true,
        margin = 2
    })
    month_calendar:attach( mytextclock, "tr")

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, bg = '#11111100' })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        expand = "none",
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- mylauncher,
            wibox.widget.textbox(" "),
            s.mytasklist,
            wibox.widget.textbox("   "),
            s.mypromptbox,
        },
        s.mytaglist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            --mykeyboardlayout
            mytextclock,
            wibox.widget.textbox(" "),
            volume_widget({
                main_color = '#dfdfdf',
                mute_color = '#ff0000',
                thickness = 3,
                height = 24,
            }),
            wibox.widget.textbox(" "),
            brightness_widget({
                color = '#dfdfdf'
            }),
            wibox.widget.textbox(" "),
            battery_widget({
                main_color = '#dfdfdf',
                show_current_level = true,
                arc_thickness = 3,
            }),
            wibox.widget.textbox(" "),
            mysystray,
            wibox.widget.textbox(" "),
            s.mylayoutbox,
            wibox.widget.textbox(" "),
        },
    }
end)

-- KEYBOARD SHORTCUTS --------------------------------------------------------
globalkeys = gears.table.join(
    -- SYSTEM
    awful.key({ modkey }, "s", hotkeys_popup.show_help,
              {description="keyboard shortcuts", group="_System"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "_System"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "logout", group = "_System"}),
    awful.key({ modkey }, "l", function () awful.util.spawn_with_shell("~/.config/awesome/scripts/lock.sh") end,
              {description = "lock system", group = "_System"}),
    awful.key({ modkey }, "z", function () awful.util.spawn_with_shell("~/.config/awesome/scripts/hibernate.sh") end,
              {description = "suspend system", group = "_System"}),
        -- Controls
    awful.key({ modkey, "Shift" }, "s", function () awful.util.spawn("xfce4-screenshooter -r -c") end,
              {description = "select screenshot region", group = "_System"}),
    awful.key({ }, "F8", function () awful.util.spawn_with_shell("~/.config/awesome/scripts/monitor.sh") end,
              {description = "monitor auto-detect", group = "_System"}),
    awful.key({ modkey }, "=", function ()
              awful.screen.focused().systray.visible = not awful.screen.focused().systray.visible
          end,
              {description = "toggle system tray", group = "_System"}),
        -- Keyboard Volume Controls
    awful.key({}, "XF86AudioRaiseVolume", function() awful.spawn("amixer -D pulse sset Master 5%+") end),
    awful.key({}, "XF86AudioLowerVolume", function() awful.spawn("amixer -D pulse sset Master 5%-") end),
    awful.key({}, "XF86AudioMute", function() awful.spawn("amixer -D pulse sset Master toggle") end),
    
    -- PROGRAMS
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "terminal", group = "_Programs"}),
    awful.key({ modkey }, "p", function () awful.util.spawn("pamac-manager") end,
              {description = "pamac manager", group = "_Programs"}),
    awful.key({ modkey }, "v", function () awful.util.spawn("pavucontrol") end,
              {description = "pulse audio sound", group = "_System"}),
    awful.key({ modkey }, "b", function () awful.util.spawn("brave") end,
              {description = "Brave Browser", group = "_Programs"}),
    awful.key({ modkey }, "F12", function () awful.util.spawn("barrier") end,
              {description = "Barrier [wireless KVM]", group = "_Programs"}),
    awful.key({ modkey },  "f",     function () awful.util.spawn("thunar") end,
              {description = "thunar file manager", group = "_Programs"}),
        -- Run
    awful.key({ modkey, "Control" }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "_Programs"}),
    awful.key({ modkey }, "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "_Programs"}),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "_Programs"}),

    -- NAVIGATE
        -- Tag
    awful.key({ modkey, "Control" }, "Left",   awful.tag.viewprev,
              {description = "Tag: previous", group = "_Navigation"}),
    awful.key({ modkey, "Control" }, "Right",  awful.tag.viewnext,
              {description = "Tag: next", group = "_Navigation"}),
        -- Screen
    awful.key({ modkey }, "Tab", function () awful.screen.focus_relative( 1) end,
              {description = "Screen: swap", group = "_Navigation"}),
    awful.key({ modkey, "Control"   }, "Tab", function () awful.client.movetoscreen() end,
              {description = "Screen: next", group = "_Navigation"}),
        -- Client
    awful.key({ modkey }, "j", function () awful.client.focus.byidx( 1) end,
        {description = "Client: focus next", group = "client"}),
    awful.key({ modkey }, "k", function () awful.client.focus.byidx(-1) end,
        {description = "Client: focus previous", group = "client"}),
    awful.key({ modkey, "Control"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "Client: move next", group = "_Navigation"}),
    awful.key({ modkey, "Control"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "Client: move previous", group = "_Navigation"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "Client: jump to urgent", group = "_Navigation"}),

    -- LAYOUT
    awful.key({ modkey,  "Shift" }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,  "Shift" }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous layout", group = "layout"}),
    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized client", group = "client"})
)

clientkeys = gears.table.join(
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move client to  master", group = "client"}),
    awful.key({ modkey,           }, "n", function (c) c.minimized = true end,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m", function (c)
            c.maximized = not c.maximized
            c:raise()
        end, {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m", function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end, {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m", function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end, {description = "(un)maximize horizontally", group = "client"})
)

-- Keyboard Tag Controls ----------------------------------------------------- 
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9, function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end, {description = "navigate to tag #", group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end, {description = "toggle tag #", group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end, {description = "move client to tag #", group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end, {description = "toggle focused client on tag #", group = "tag"})
    )
end

-- Mouse Client Controls -----------------------------------------------------
clientbuttons = gears.table.join(
    -- Left-Click to focus client
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    -- Mod + Left-Click client and drag to move window
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    -- Mod + Right-Click client and drag to resize window
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)


-- RULES ---------------------------------------------------------------------
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}


-- SIGNALS -------------------------------------------------------------------
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    c.shape = function (cr,w,h)
        gears.shape.rounded_rect(cr,w,h,20)
    end
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- TITLEBARS -----------------------------------------------------------------
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- MOUSE SLOPPY FOCUS --------------------------------------------------------
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- AUTOSTART -----------------------------------------------------------------
awful.util.spawn("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
awful.util.spawn("xcompmgr -C")  -- Required for transparent backgrounds
awful.util.spawn("xfce4-clipman")  -- Required for screenshots
awful.util.spawn("blueman-applet")  -- Bluetooth controls in systray
awful.util.spawn("nm-applet")  -- Network manager in systray
awful.util.spawn_with_shell("~/.config/awesome/scripts/monitor.sh")
    -- Autodetect monitors on login

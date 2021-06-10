#!/usr/bin/env python3

from i3ipc import Connection, Event
import os, time

# moveWindowToWorkspace() moves a given window to a given workspace.
def moveWindowToWorkspace(window, workspace):
    window.command('move window to workspace ' + workspace)

# getWindows() returns a list of all open windows on the desktop.
def getWindows(i3):
    windows = []
    for con in i3.get_tree():
        if con.window and con.parent.type != 'dockarea':
            windows.append(con)
    return windows

# getWindowByName() returns a window with the given name.
def getWindowByName(name, windows):
    for win in windows:
        if name in win.name:
            return win
    return

# filterWindowsByClass() returns a filter list of windows by class.
def filterWindowsByClass(windowClass, windows):
    return [w for w in windows if w.window_class == windowClass]

# doesWindowExist() returns if a given window exists.
def doesWindowExist(window):
    return window != None

# switchWorkspace() switches currently selected workspace.
def switchWorkspace(workspace):
    i3.command('workspace ' + workspace)

# execI3() runs a command from i3wm.
def execI3(program):
    i3.command('exec ' + program)

# launchProgram() launches a program on a given workspace.
def launchProgram(program, workspace):
    switchWorkspace(workspace)
    execI3(program)
    
# isProgramRunning() returns if a program is running and if it is
# moves it to a given workspace.
def isProgramRunning(name, windows, workspace):
    for n in name:
        program = getWindowByName(n, windows)
        if doesWindowExist(program):
            moveWindowToWorkspace(program, workspace)
            return True
    return False

i3 = Connection()
firefoxWindows = filterWindowsByClass('Firefox', getWindows(i3))
switchWorkspace('10')
switchWorkspace('1')

# Music
if not isProgramRunning(['music.youtube.com'], firefoxWindows, '10'):
    launchProgram('firefox --new-window music.youtube.com', '10')

# Stocks
if not isProgramRunning(['Robinhood', 'Webull'], firefoxWindows, '10'):
    os.system('python ~/.config/scripts/launch-stocks-tracker.py')

# Videos
if not isProgramRunning(['odysee.com', 'lbry.tv', 'www.youtube.com',
                         ' - YouTube', 'hulu.com', 'netflix.com'], firefoxWindows, '10'):
    launchProgram('firefox --new-window youtube.com/feed/subscriptions', '10')
    launchProgram('sleep 1 && firefox -new-tab odysee.com/$/following', '10')

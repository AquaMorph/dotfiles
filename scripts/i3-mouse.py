#!/usr/bin/env python3
import i3ipc
import sys
import os
import time
import pyautogui
from enum import Enum

# Enum for mouse direction
class Direction(Enum):
    UP = 1
    LEFT = 2
    RIGHT = 3
    DOWN = 4
    NONE = 5

# getPoints() returns x and y movement of mouse
def getPoints():
    sen = 10
    t = 0
    delay = 0.01

    x,y = pyautogui.position()
    while True:
        time.sleep(delay)
        t += delay
        if t > 0.5:
            return
        xp, yp = pyautogui.position()
        dx = x - xp
        dy = y - yp
        if abs(dx) > sen or abs(dy) > sen:
            break
    return dx, dy

#pointsToDirection() converts mouse movement points to a direction
def pointsToDirection(points):
    if points is None:
        return
    x, y = points
    if abs(x) > abs(y):
        if x < 0:
            return Direction.RIGHT
        else:
            return Direction.LEFT
    else:
        if y > 0:
            return Direction.UP
        else:
            return Direction.DOWN

i3 = i3ipc.Connection()
focused = i3.get_tree().find_focused()
command = sys.argv[1]

if command in ['back', 'forward']:
   if focused.window_instance not in ['overwatch.exe']:
      if sys.argv[1] == 'forward':
         i3.command('workspace prev_on_output')
      else:
         i3.command('workspace next_on_output')

elif command == 'thumb':
   direction = pointsToDirection(getPoints())
   if direction == Direction.UP:
      i3.command('move up')
   elif direction == Direction.RIGHT:
      i3.command('move right')
   elif direction == Direction.DOWN:
      i3.command('move down')
   elif direction == Direction.LEFT:
      i3.command('move left')

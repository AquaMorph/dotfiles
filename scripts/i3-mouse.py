#!/usr/bin/env python3
import i3ipc
import sys
import os


up = sys.argv[1] == 'up'

i3 = i3ipc.Connection()
focused = i3.get_tree().find_focused()
if focused.window_instance not in ['overwatch.exe']:
   if sys.argv[1] == 'forward':
      os.system('i3-msg workspace prev_on_output')
   else:
      os.system('i3-msg workspace next_on_output')

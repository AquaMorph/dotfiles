#!/usr/bin/env python3

import i3ipc, os

def onWindowClose(conn, win):
    if(win.ipc_data['container']['window_properties']['class'] == 'Bitwig Studio'):
        print(win.ipc_data['container']['window_properties']['title'])
        if(win.ipc_data['container']['window_properties']['title'] !=
           'DSP Performance Graph'):
            os.system('sh ~/.config/scripts/audio/aquamix.sh -n')
            os.system('sh ~/.config/scripts/audio/synth-power-prompt.sh')

i3 = i3ipc.Connection()
i3.on('window::close', onWindowClose)
i3.main()





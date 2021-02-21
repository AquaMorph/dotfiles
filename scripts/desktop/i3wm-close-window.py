#!/usr/bin/env python3

import i3ipc, os

def onWindowClose(conn, win):
    if(win.ipc_data['container']['window_properties']['class'] == 'Bitwig Studio'):
        os.system('sh ~/dotfiles/scripts/audio/aquamix.sh -n')

i3 = i3ipc.Connection()
i3.on('window::close', onWindowClose)
i3.main()



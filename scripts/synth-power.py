
#!/usr/bin/env python3

# Program to control synth power state.

import configparser
from homeassistant import HomeAssistant

# Parse settings config
configString = '[Settings]\n' + open('../settings.conf').read()
configParser = configparser.RawConfigParser()
configParser.read_string(configString)

# Load needed credentials
HA_IP = configParser.get('Settings', 'HA_IP')
HA_TOKEN = configParser.get('Settings', 'HA_TOKEN')

ha = HomeAssistant(HA_IP, HA_TOKEN)
ha.runScene('scene.synths_on')


#!/usr/bin/env python3

# Program to control synthesizers power state.

import argparse
import configparser
import os,sys,inspect
currentDir = os.path.dirname(os.path.abspath(
    inspect.getfile(inspect.currentframe())))
parentDir = os.path.dirname(currentDir)
sys.path.insert(0, parentDir) 
from homeassistant import HomeAssistant

# Parse settings config
SCRIPT_DIR = os.path.abspath(os.path.dirname(sys.argv[0]))
configString = '[Settings]\n' + open(SCRIPT_DIR + '/../../settings.conf').read()
configParser = configparser.RawConfigParser()
configParser.read_string(configString)

# Load needed credentials
HA_IP = configParser.get('Settings', 'HA_IP')
HA_TOKEN = configParser.get('Settings', 'HA_TOKEN')

# Set power state of the Eurorack.
def setEurorackPower(state):
    ha.setOnOff('switch.eurorack_lower', state)
    ha.setOnOff('switch.eurorack_top', state)

# Set power state of the Behringer DeepMind 12.
def setDeepMind12Power(state):
    ha.setOnOff('switch.deepmind_12', state)

# Set power state of the ASM Hydrasynth.
def setHydrasynthPower(state):
    ha.setOnOff('switch.hydrasynth', state)

# Set power state of the Arturia MatrixBrute.
def setMatrixBrutePower(state):
    ha.setOnOff('switch.matrixbrute', state)

# Set power state of all synthesizers.
def setSynthsPower(state):
    setEurorackPower(state)
    setDeepMind12Power(state)
    setHydrasynthPower(state)
    setMatrixBrutePower(state)

parser = argparse.ArgumentParser(
    description='Control power state of synthesizers.')
parser.add_argument('-d', '--daw', action='store_true',
                    help='enable DAW mode',
                    dest='daw', default=False, required=False)
parser.add_argument('-o', '--off', action='store_true',
                    help='turn all synths off',
                    dest='off', default=False, required=False)
args = parser.parse_args()

ha = HomeAssistant(HA_IP, HA_TOKEN)

if args.daw:
    setSynthsPower(True)
elif args.off:
    setSynthsPower(False)

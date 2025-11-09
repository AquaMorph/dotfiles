#!/bin/bash

# Script to stop ES-9 audio interface

pkill alsa_in
pkill alsa_out
pkill es-5-pipewire

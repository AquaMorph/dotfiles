# Dotfiles

A collection of config files and scripts for Fedora GNU/Linux.

## Install

Run the following command to install

```sh
cd ~ && git clone git@github.com:AquaMorph/dotfiles.git && sh ~/dotfiles/install.sh
```
Install the needed Python packages

```sh
pip install -r requirements.txt
```

## Scripts

### frc-photo-checklist.py

Python script to generate a Todoist checklist for taking photos at an FRC event.

```sh
python frc-photo-checklist.py [Event Key]
```

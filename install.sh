#! /bin/bash

# Load user settings from config file.
if [ -e ~/.config/settings.conf ]; then 
    . ~/.config/settings.conf
fi

dotdir=~/dotfiles

#      src                                dest                   sudo
files=($dotdir/systemd                    ~/.config/             'n'
       $dotdir/settings.conf              ~/.config/             'n')

# arg parser
for arg in "$@"
do
    # Skip commands that need root access
    if [[ $arg == *"-nr"* ]]; then
	noRoot=true
    fi
done

# Check emacs setup
function emacs {
    if ! [ -d ~/.emacs.d ]; then
	echo Installing emacs config
	cd ~
	git clone git@github.com:AquaMorph/.emacs.d.git
    else
	echo Checking for emacs config updates
	cd ~/.emacs.d
	git pull
    fi
    
}

# Check managed dotfiles
function dotfiles {
    echo Setting up dotfiles...

    # Loop through config files
    for (( i=0; i<${#files[@]} ; i+=3 )) ; do
      # Check if sudo is needed
      pre=''
      if [[ ${files[i+2]} == *'y'* ]]; then
          if [ $noRoot ]; then
              echo Skipping ${files[i]} because root is required
	      continue
	  fi
	  pre='sudo'
      fi

      destPath=${files[i+1]}$(basename "${files[i]}")

      # Check if file already exists
      if [ -e $destPath ]; then
	  # Check if path is not a sybolic link
	  if ! [ -L $destPath ]; then
	      echo Backing up $destPath
	      $pre mv $destPath ${destPath}.bak
	      # File already set up
	  else
	      echo The file $destPath is already set up
	      continue
	  fi
	  # Create missing directories
      else
	  $pre mkdir -p "$(dirname "$destPath")"
      fi
      echo Creating symbolic link from ${files[i]} to ${files[i+1]}
      $pre ln -sf ${files[i]} ${files[i+1]}
    done
}

# Check dotfiles for updates
function update {
    echo Checking for dotfile updates
    startTime=$(date +%s -r $dotdir)
    cd $dotdir && git pull
    endTime=$(date +%s -r $dotdir)
    if (( "$startTime" < "$endTime" )); then
	sh $dotdir/scripts/setup.sh
	exit
    fi
}

# Set up settings config file
function setup {
    if [ -e $dotdir/settings.conf ]; then 
	echo Settings file already created
    else
	echo Setting up settings config...

	# Computer shortname
	echo What is the computer shortname?
	read computer
	echo computer=$computer >> $dotdir/settings.conf
    fi
}

function systemd {
    echo 'Setting up custom systemd services...'
    systemctl --user enable es-9
    systemctl --user enable i3wm-close-window
}

function stow_dotfiles {
    stow wireplumber
    stow zsh
    stow alacritty
    stow g13
    stow git
    stow gtk
    stow i3
    stow i3status
    stow kitty
    stow polybar
    stow rofi
    stow waybar
    stow mako
    stow scripts
    stow orcaslicer
}

function install_python_libs {
    pip install -r requirements.txt
}

setup
systemd
update
dotfiles
stow_dotfiles
install_python_libs
emacs

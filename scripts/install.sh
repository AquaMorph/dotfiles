#! /bin/bash

# Load user settings from config file.
. ~/.config/settings.conf

dotdir=~/dotfiles

#      src                                dest                   sudo
files=($dotdir/.zprofile                  ~/                     'n'
       $dotdir/.zshrc                     ~/                     'n'
       $dotdir/alacritty                  ~/.config/             'n'
       $dotdir/g13                        ~/.config/             'n'
       $dotdir/gtk-3.0/settings.ini       ~/.config/gtk-3.0/     'n'
       $dotdir/gtk-4.0/settings.ini       ~/.config/gtk-4.0/     'n'
       $dotdir/i3                         ~/.config/             'n'
       $dotdir/i3status                   ~/.config/             'n'
       $dotdir/kitty                      ~/.config/             'n'
       $dotdir/polybar                    ~/.config/             'n'
       $dotdir/rofi                       ~/.config/             'n'
       $dotdir/scripts                    ~/.config/             'n')

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
	sh $dotdir/scripts/install.sh
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

setup
update
dotfiles
emacs

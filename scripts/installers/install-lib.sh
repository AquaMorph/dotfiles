# Program version number comparison.
function versionGreater() {
    if [[ $1 == $2 ]];then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Check if installed to the most recent version.
function checkUptoDate() {
    if versionGreater $2 $3; then
	echo $1 is up to date. Installed version $2 web version $3
	exit
    else
	echo Updating $1 from $2 to $3...
    fi
}

# Returns installed programs with a given name.
function searchProgramInstalled() {
    dnf list | grep $1
}

# Filters string to Semantic Versioning.
function filterVersion() {
    grep -Po -m 1 '\d{1,4}\.\d{1,4}\.*\d{0,4}'
}

# Downloads a file to the given download directory with
# the given name.
function downloadPackage() {
    mkdir -p ~/Downloads/installers/${1}
    cd ~/Downloads/installers/${1}
    wget -O ${3} ${2}
}

# Program version number comparison
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

# Check if installed to the most recent version
function checkUptoDate() {
    if versionGreater $2 $3; then
	echo $1 is up to date. Installed version $2 Web version $3
	exit
    fi
}

function filterVersion() {
    grep -Go [0-9]\.[0-9]\.[0-9]
}

#!/usr/bin/env bash

required="build-essential pkg-config git stow"
optional="gnupg tmux rsync mosh"


ingredients="sethostname \
        setrepos \
        backports \
        terminology \
        packer \
      =
"

function add_ingredient {
    case $1 in
        sethostname)
            # Set hostname: The container needs to be called penguin, at least if you want to use the app shortcut
            # But you can rename the host.
            # You may get a complaint from sudo saying "unable to resolve host <whatever old name>". Safe to ignore it
            read -p "## Enter hostname for this container: " newname ; \
            echo "## It's safe to ignore the following sudo warning"
            sudo sed -i "s/127\.0\.1\.1.*/127\.0\.1\.1\t${newname}/" /etc/hosts
            sudo hostnamectl set-hostname ${newname} ; \
            ;;

        setrepos)
            # Add contrib, non-free Debian repos, as well as backports
            # These are in a separate file in /etc/apt/sources.lists.d for easy removal if desired
            sudo sh -c 'cat > /etc/apt/sources.list.d/crostini-pie.list' << EOF

            # Debian contrib and non-free repos as well as stretch-updates
            deb http://deb.debian.org/debian stretch contrib non-free
            deb http://deb.debian.org/debian stretch-updates main contrib non-free
            deb http://security.debian.org/debian-security/ stretch/updates contrib non-free
            deb http://ftp.debian.org/debian stretch-backports main contrib non-free
EOF
            sudo apt update
            ;;

        backports)
            # Steps through a list of packages to install, all from backports by default

            final=""
            echo "## Hit Enter to add each package to the list to be installed, or n to skip it"
            for pkg in ${optional}; do
                    read -p "#### Install ${pkg}? (Y/n)" yorn
                    case ${yorn} in
                        n) 
                            echo "#### Skipping ${pkg}"
                            ;;
                        *)
                            echo "#### Adding ${pkg} to the install list"
                            final="${final} ${pkg}"
                            ;;
                    esac
            done

            echo "##### Final list of packages:"
            echo "${final}"
            sudo apt-get -y -t stretch-backports install ${required} ${final}
            ;;

      
         

        packer)
            PKVersion="${choice:-1.2.3}"
            echo "#### Default packer version is ${PKVersion}"
            curl -o packer_${PKVersion}_linux_amd64.zip https://releases.hashicorp.com/packer/${PKVersion}/packer_${PKVersion}_linux_amd64.zip
            unzip packer_${PKVersion}_linux_amd64.zip
            rm packer_${PKVersion}_linux_amd64.zip
            sudo mkdir -p /usr/local/stow/packer
            sudo mv packer /usr/local/stow/packer/packer-${PKVersion}
            cd /usr/local/stow/packer
            sudo ln -s packer-${PKVersion} packer
            cd ..
            sudo stow -t /usr/local/bin packer
            cd
            ;;
    esac
}

function doyouwant {
    echo ""
    echo "## About to execute function: ${i}"
    echo "## Enter to proceed, n to skip this ingredient, or any other input will be treated as parameters for the function"
    read -e -p "## Install $1? (Y/n/args) " choice
    echo ""
    case ${choice} in
        n|N)    echo "## Skipping $1"
            ;;
        *)  echo "## Executing $1" 
            add_ingredient $1 $choice
            ;;
    esac
}

for i in ${ingredients}; do
    doyouwant $i
done

#!/usr/bin/env bash
set -o errtrace

main () {

echo "
██╗  ██╗ █████╗ ███████╗     ██████╗ ███╗   ██╗    ██╗   ██╗ █████╗  ██████╗ ██████╗  █████╗ ███╗   ██╗████████╗
██║ ██╔╝██╔══██╗██╔════╝    ██╔═══██╗████╗  ██║    ██║   ██║██╔══██╗██╔════╝ ██╔══██╗██╔══██╗████╗  ██║╚══██╔══╝
█████╔╝ ╚█████╔╝███████╗    ██║   ██║██╔██╗ ██║    ██║   ██║███████║██║  ███╗██████╔╝███████║██╔██╗ ██║   ██║   
██╔═██╗ ██╔══██╗╚════██║    ██║   ██║██║╚██╗██║    ╚██╗ ██╔╝██╔══██║██║   ██║██╔══██╗██╔══██║██║╚██╗██║   ██║   
██║  ██╗╚█████╔╝███████║    ╚██████╔╝██║ ╚████║     ╚████╔╝ ██║  ██║╚██████╔╝██║  ██║██║  ██║██║ ╚████║   ██║   
╚═╝  ╚═╝ ╚════╝ ╚══════╝     ╚═════╝ ╚═╝  ╚═══╝      ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   
"
	[[ $(id -u) -ne 0 ]] && error "This script needs to be run on sudo: sudo ./setup.sh"

	local OS_ENV="Ubuntu"
	local osrelease=($(lsb_release -d | awk -F"\t" '{print $2}'))
	local pkgtoinstall=()

	echo "Check if the sistem have Virtualization"
	[[ -z $( grep -Eo "vmx|svm" < /proc/cpuinfo | head -1)  ]] && error "Your PC does not have Intel VT or AMD-V"
	[[ "${osrelease[0]}" == "Fedora" ]] && OS_ENV="${osrelease[0]}"
	echo "$OS_ENV"
	if [[ "$OS_ENV" == "Fedora" ]]; then
		# Check programs
		echo "Checking if Vagrant and VirtualBox are installed"
		[[ -z "$(dnf list installed vagrant | grep  -o 'vagrant' | head -1)" ]] && pkgtoinstall+="vagrant "
		[[ -z "$(dnf list installed virtualbox | grep  -o 'VirtualBox' | head -1)" ]] && pkgtoinstall+="VirtualBox-6.1 virtualbox-guest-additions"
		# Install packages
		if [[ -n "${pkgtoinstall}" ]]; then
			echo "Installing packages"
			dnf install -y kernel-headers kernel-devel-"$(uname -r)" dkms ${pkgtoinstall}
		fi
		echo "All Packages are installed"
	elif [[ "$OS_ENV" == "Ubuntu" ]]; then
		# For Debian base distros
		echo "Installing packages"
		apt install -y build-essential linux-headers-"$(uname -r)"
		apt install -y gcc binutils make kernel-headers kernel-devel-"$(uname -r)" dkms
		if dpkg -S vagrant;then echo "package vagrant is alredy installed"; else apt install -y vagrant; fi 
		if dpkg -S virtualbox;then echo "package virtualbox is alredy installed"; else apt install -y virtualbox virtualbox-ext-pack; fi 
		echo "All Packages are installed"
	else
		error "Not match distros"
	fi

	# Setup for non-root commands
	usermod -a -G vboxusers "${SUDO_USER}"

	echo "Install vagrant disk size plugin"
	sudo -u "${SUDO_USER}" bash -c 'vagrant plugin install vagrant-disksize'

	echo "Start the vagrantfile"
	sudo -u "${SUDO_USER}" bash -c 'vagrant up --provider=virtualbox'

	# Finish configure VB
	echo "Setup virtualbox"
	/bin/bash /usr/lib/virtualbox/vboxdrv.sh setup
	echo "Install extension pack for virtualbox"
	sudo -u "${SUDO_USER}" bash -c 'url -L -o "Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack" "https://download.virtualbox.org/virtualbox/6.1.28/Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack" && virtualbox Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack'

	echo "Everithing seems fine, enjoy your Kubernetes cluster on Vagrant!"
	exit 1
}

error (){
  echo "$@"
  exit 1
}

main "$@"


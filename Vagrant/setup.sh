#!/usr/bin/env bash
set -o errtrace

main () {
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
		# shellcheck disable=SC2179
		[[ -z "$(dnf list installed vagrant | grep  -o 'vagrant' | head -1)" ]] && pkgtoinstall+="vagrant "
		# shellcheck disable=SC2179
		[[ -z "$(dnf list installed virtualbox | grep  -o 'VirtualBox' | head -1)" ]] && pkgtoinstall+="VirtualBox-6.1 virtualbox-guest-additions"
		# Install packages
		# Sellcheck disable=SC2128	
		if [[ -n "${pkgtoinstall}" ]]; then
			echo "Installing packages"
			dnf install -y gcc binutils make glibc-devel patch libgomp glibc-headers kernel-headers kernel-devel-"$(uname -r)" dkms ${pkgtoinstall}
			usermod -a -G vboxusers "${SUDO_USER}"
		
			# Finish configure VB
			echo "Setup virtualbox"
			/bin/bash /usr/lib/virtualbox/vboxdrv.sh setup
			echo "Install extension pack for virtualbox"
			udo -u "${SUDO_USER}" bash -c 'url -L -o "Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack" "https://download.virtualbox.org/virtualbox/6.1.28/Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack" && virtualbox Oracle_VM_VirtualBox_Extension_Pack-6.1.28.vbox-extpack'
		fi
		echo "All Packages are installed"
		echo "Install vagrant disk size plugin"
		sudo -u "${SUDO_USER}" bash -c 'vagrant plugin install vagrant-disksize'
		echo "Start the vagrantfile"
		sudo -u "${SUDO_USER}" bash -c 'vagrant up --provider=virtualbox'
	else
		echo "Ubuntu"
	fi
	
	echo "Everithing seems fine, enjoy your Kubernetes cluster on you own PC!"
	exit 1
}

error (){
  echo "$@"
  exit 1
}

main "$@"


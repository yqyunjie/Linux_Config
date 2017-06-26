#!/bin/sh

print_info()
{
	str=$@
	echo "\033[40;32;1m$str\033[0m"
}

print_debug()
{
	str=$@
	echo "\033[40;33;1m$str\033[0m"
}

print_error()
{
	str=$@
	echo "\033[40;31;5m$str\033[0m"
}


#Debug options
set -x
#echo off

#includes
CUR_DIR=$(cd `dirname $0`; pwd)
print_debug Including $CUR_DIR/switch.sh
. $CUR_DIR/switch.sh

configure_apt_get()
{
	print_info Configuring apt-get...
    # @todo Configure apt-get source

    # @todo Configure proxy, if needed
}

configure_package_install_tool()
{
    configure_apt_get
}

configure_network()
{
	if [ "$CONFIG_network" != "y\r" ];then
		return 0
	fi
	## @todo, make ip and etc configurable.
	print_info Configuring network...
	echo "auto eth0" >> /etc/network/interfaces
	echo "iface eth0 inet static" >> /etc/network/interfaces
	echo "address 192.168.119.129" >> /etc/network/interfaces
	echo "netmask 255.255.255.0" >> /etc/network/interfaces
	echo "gateway 192.168.119.1" >> /etc/network/interfaces
	/etc/init.d/networking restart
	print_info Network configuration done!
}

init()
{
    print_info Initializing...
    ##@todo Read installation config

    ##@todo Retrieve distribution info

	configure_network
    configure_package_install_tool
}

install_package()
{
    package=$1
    print_info Installing package $package...
    apt-get install $package
    return $?
}

expect_install_package_success() 
{
    package=$1
    install_package $1
    if [ $? = 0 ];then
        print_info Package $package installation success!
    else
        print_error Package $package installation fail!
        exit -1
    fi
}

expect_install_package_fail() 
{
    package=$1
    install_package $1
    if [ $? = 0 ];then
        print_error Package $package installation success!
        print_error Expect fail, quit!
        exit -1
    else
        print_info Package $package installation fail!
		print_info Expect fail, OK.
    fi
}

# Install vim and configure
setup_package_vim() 
{
	if [ "$INSTALL_vim" != "y\r" ];then
		print_info Do NOT install vim
		return 0
	else
		print_info Install vim
	fi
    # Install
    print_info Setting up vim...
    expect_install_package_success "vim"
    # Configure
    print_info Configuring vim...
    ##@todo Call vim sub-dir script
}

# Install wireshark
setup_package_wireshark()
{
	if [ "$INSTALL_wireshark" != "y" ];then
		return 0
	fi
	
	print_info Setting up wireshark...
	expect_install_package_success "wireshark"

	##@todo Configure wireshark
}

setup_package()
{
	name=$1
	package=$2
	if [ "$INSTALL_$1" != "y" ];then
		return 0
	fi
	
	print_info Setting up $1...
	expect_install_package_success $2
}

# Install python
setup_package_python()
{
	setup_package "python" "python"
}

append_line_into_file()
{
	file=$1
	line=$2
	if grep -Fxq "$line" $file
	then
		print_debug "Line \"$line\" NOT found!"
	else
		# code if not found
		echo "$line" >> $file
	fi
}
#
setup_bashrc()
{
	if [ "$CONFIG_bashrc" != "y" ];then
		return 0
	fi
	print_info Configuring bashrc...
	cp $CUR_DIR/resource/bashrc /etc/bashrc
	cp $CUR_DIR/resource/alias /etc/.alias
	. /etc/bashrc
	append_line_into_file "/etc/profile" ". /etc/bashrc"
	# @todo copy the bashrc to specified user home folder
}

# Initialize
init

# Config bashrc
setup_bashrc

# Setting up vim
setup_package_vim

# Wireshark
setup_package_wireshark

# Python
setup_package_python

print_info "Config finished"
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
ABS_HOME=`echo ~`
print_debug Including $CUR_DIR/switch.sh
. $CUR_DIR/switch.sh
. $CUR_DIR/variables.sh


configure_apt_get()
{
	print_info Configuring apt-get...
    # @todo Configure apt-get source

    # @todo Configure proxy, if needed
	#export http_proxy=http://135.245.48.34:8000
}

configure_package_install_tool()
{
    configure_apt_get
}

configure_network()
{
	if [ "$SWITCH_network" != "y\r" ];then
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
    apt-get --assume-yes install $package
    return $?
}

echoy_install()
{
	package=$1
	print_info Installing package $package...
	echo y | apt-get install $package
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
	if [ "$SWITCH_vim" != "y" ];then
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
    cp -r $CUR_DIR/resource/vimrc-master ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
}

# Install wireshark
setup_package_wireshark()
{
	if [ "$SWITCH_wireshark" != "y" ];then
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
	
	print_info Setting up $1...
	expect_install_package_success $2
}

# Install python
setup_package_python()
{
	if [ "$SWITCH_python" != "y" ];then
		return 0
	fi
	setup_package "python" "python"
}

copy_resource_file()
{
	src_file=$1
	dest=$2
	src=$CUR_DIR/resource/$1
	cp -f $src $dest
}
#
setup_bashrc()
{
	if [ $SWITCH_bashrc != "y" ];then
		return 0
	fi
	print_info Configuring bashrc...
	cp $CUR_DIR/resource/bashrc /etc/bashrc
	cp $CUR_DIR/resource/alias /etc/.alias
    
#	. /etc/bashrc
	append_line_into_file "/etc/profile" ". /etc/bashrc"
    
	# @todo copy the bashrc to specified user home folder
#    cp $CUR_DIR/resource/bashrc $ABS_HOME/.bashrc
#    cp $CUR_DIR/resource/alias $ABS_HOME/.alias
#    append_line_into_file "$ABS_HOME/.profile" ". $ABS_HOME/.bashrc"
}

# Append a line into the specified file, if the line does not exist
# Args: file: file which to be appended to
#		line: A line which will be appended
append_line_into_file()
{
	file="$1"
	line="$2"
    print_debug "Appending line $line into file $file"
	if grep -qFx "$line" "$file"
	then
		print_debug "Line \"$line\" NOT found!"
	else
		# insert line if not found
		echo -e "$line" >> "$file"
	fi
}

setup_screen()
{
	if [ $SWITCH_screen != "y" ];then
		return 0
	fi
	setup_package "screen" "screen"
	copy_resource_file "screenrc" "/etc/screenrc"
}

setup_tmux()
{
	if [ $SWITCH_tmux != "y" ];then
		return 0
	fi
	setup_package "tmux" "tmux"
	
	## @todo Configure the tmux
	#copy_resource_file "screenrc" "/etc/screenrc"
}

setup_git()
{
	if [ $SWITCH_git != "y" ];then
		return 0
	fi
	setup_package "git" "git"
	
	git config --global user.name "$CONFIG_git_user_name"
	git config --global user.email "$CONFIG_git_user_email"
	git config --global core.editor "$CONFIG_git_core_editor"
	git config --global merge.tool "$CONFIG_git_merge_tool"
	git config --global --list
}

setup_eclipse()
{
	if [ $SWITCH_eclipse != "y" ];then
		return 0
	fi
	
	setup_package "eclipse" "eclipse"
	## @todo
}

setup_openssh_server()
{
	if [ $SWITCH_openssh_server != "y" ];then
		return 0
	fi
	
	setup_package "openssh-server" "openssh-server"
    
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bk
    copy_resource_file sshd_config /etc/ssh/sshd_config
}

setup_gcc()
{
	if [ $SWITCH_gcc != "y" ];then
		return 0
	fi
	
	setup_package "gcc" "gcc"
}

setup_php()
{
	if [ $SWITCH_php != "y" ];then
		return 0
	fi
	
	setup_package "php" "php"
	setup_package "php-gd" "php-gd"
	setup_package "php-curl" "php-curl"
	setup_package "php-cli" "php-cli"
	setup_package "php-cgi" "php-cgi"
	setup_package "libapache2-mod-php" "libapache2-mod-php"
}

setup_apache2()
{
	if [ $SWITCH_apache2 != "y" ];then
		return 0
	fi
	
	setup_package "apache2" "apache2"
	
	## @todo
}

setup_samba()
{
	if [ $SWITCH_samba != "y" ];then
		return 0
	fi
	
	setup_package "samba" "samba"
	setup_package "smbclient" "smbclient"
	
	## configure
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bk
    copy_resource_file smb.conf /etc/samba/smb.conf
    /etc/init.d/samba restart
}

setup_tree()
{
	if [ $SWITCH_tree != "y" ];then
		return 0
	fi
	
	setup_package "tree" "tree"
}

setup_autoconf()
{
	if [ $SWITCH_autoconf != "y" ];then
		return 0
	fi
	
	setup_package "autoconf" "autoconf"
}

setup_wine()
{
	if [ $SWITCH_wine != "y" ];then
		return 0
	fi
	
	setup_package "wine-stable" "wine-stable"
}

setup_perl()
{
	if [ $SWITCH_perl != "y" ];then
		return 0
	fi
	
	setup_package "perl" "perl"
}

#######################################################################
# Initialize
init

# Install tcl and expect for the interactive operation
print_info "Installing tcl and expect for the interactive operation"
echoy_install "tcl"
echoy_install "expect"

# Setting up perl
setup_perl

# Setting up vim
setup_package_vim

# Wireshark
setup_package_wireshark

# Python
setup_package_python

setup_openssh_server

# Screen
setup_screen

# tmux
setup_tmux

# Git
setup_git

# gcc
setup_gcc

setup_eclipse

setup_apache2

setup_php

setup_tree

setup_autoconf

setup_wine

# Config bashrc last ones
setup_bashrc

print_info "Config finished"
#!/bin/bash
#
# install-salt-minion-centos6.sh
#
# Prepared by: Joseph Yennaco
# Contact: Joe.Yennaco@pci-sm.com
# PCI Strategic Management, LLC
# 15 New England Executive Park #2106
# Burlington, MA 01803
#
# Date: 1 March 2014
#
# Purpose: This script installs Salt Minion on CentOS6 using the EPEL repository and YUM.
#
# Prerequisites:
# 	-- Internet connectivity
#  	-- Run this script as root user
# 

# Get the current timestamp and append to logfile name
TIMESTAMP=$(date "+%Y-%m-%d-%H%M")
LOGFILE=/var/log/cons3rt-install-salt-minion-centos6-${TIMESTAMP}.log

# Set log commands
logTag=salt-minion
logInfo="logger -i -s -p local3.info -t ${logTag} [INFO] "
logWarn="logger -i -s -p local3.warning -t ${logTag} [WARNING] "
logErr="logger -i -s -p local3.err -t ${logTag} [ERROR] "

# Set a local variable for the location and filename of the bash profile
BASH_RC=/etc/bashrc

function install-salt-minion-centos6() {
	
	$logInfo "Running the install-salt-minion-centos6.sh install script @ $TIMESTAMP ..."
	
	# Source the bash profile to load JAVA_HOME
	$logInfo "Sourcing ${BASH_RC} ..."
	source ${BASH_RC}
	
	$logInfo "Printing the environment ..."
	printenv
	
	$logInfo "Enabling the EPEL repository ..."
	rpm -Uvh http://ftp.linux.ncsu.edu/pub/epel/6/i386/epel-release-6-8.noarch.rpm
	
	$logInfo "Installing salt-minion ..."
	yum -y --enablerepo=epel-testing install salt-minion
	
	$logInfo "Enabling salt-minion to start automatically upon boot ..."
	chkconfig salt-minion on
	
	# Check if DEPLOYMENT_HOME is set
	if [ -z ${DEPLOYMENT_HOME} ]
	then
		$logWarn "DEPLOYMENT_HOME is not set, cannot automatically connect to salt-master, salt-minion is installed but will not be started."
	else
		$logInfo "DEPLOYMENT_HOME is set to ${DEPLOYMENT_HOME}"
		
		propFile=${DEPLOYMENT_HOME}/fap-deployment.properties

		# Check if fap-deployment.properties is located in DEPLOYMENT_HOME
		if [ ! -f ${propFile} ]
		then 
			$logWarn "fap-deployment.properties file not found in DEPLOYMENT_HOME, cannot automatically connect to salt-master, salt-minion is installed but will not be started."
		else
			$logInfo "fap-deployment.properties file found in DEPLOYMENT_HOME.  Checking for salt-master as a Cons3rt Scenario Role Name ..."
			saltMaster=`cat $propFile | grep -i ipAddress.salt-master | awk -F = '{ print $2 }'` 
			
			# If no Scenario Role Name of salt-master was found, check for a Cons3rt Deployment Runtime Propery of salt-master
			if [ ! ${saltMaster} ]
			then
				$logInfo "salt-master not found as a Scenario Role Name. Checking for a Deployment Runtime Property ... "
				saltMaster=`cat $propFile | grep -i salt-master | awk -F = '{ print $2 }'`
			fi

			# If no salt-master was  found at all in fap-deployment.properties, warn and don't start, otherwise point to the salt-master and start salt-minion
			if [ ! ${saltMaster} ]
			then
				$logWarn "salt-master not defined in fap-deployment.properties, cannot automatically connect to salt-master, salt-minion is installed but will not be started."
			else
				$logInfo "salt-master is set to ${saltMaster}, setting up salt-minion to connect to salt-master ..."
				sed -i "s/#master: salt/master: ${saltMaster}/" /etc/salt/minion
	
				$logInfo "Start the salt-master service ..."
				service salt-minion start
	
				$logInfo "Checking to see if salt is running ..."
				salt --version
			fi
			
		fi
	
		

	fi
		
	$logInfo "Completed running the install-salt-minion-centos6.sh install script @ $TIMESTAMP!\n"
}

# Run the Installation function store output to the logfile
install-salt-minion-centos6 2>&1 | tee ${LOGFILE}

exit 0

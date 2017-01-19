#!/bin/bash
#
# This script tries to start mysqld with the right parameters to join an existing cluster
# or create a new one if the old one cannot be joined
#

LOG_MESSAGE="mysqld.sh:"
OPT="$@"

function do_install_db {
	if ! test -d /var/lib/mysql/mysql; then
		echo "${LOG_MESSAGE} Initializing MariaDb data directory..."
		if ! mysql_install_db; then
			echo "${LOG_MESSAGE} Failed to initialized data directory. Will hope for the best..."
			return 1
		fi
	fi
	return 0
}

function check_nodes {
	for node in ${1//,/ }; do
		[ "$node" = "$2" ] && continue
		if curl -f -s -o - http://$node:8081 && echo; then
			echo "${LOG_MESSAGE} Node at $node is healthy!"
			return 0
		fi
	done
	return 1
}

# Set 'TRACE=y' environment variable to see detailed output for debugging
if [ "$TRACE" = "y" ]; then
	set -x
fi

if [[ "$OPT" =~ /--wsrep-new-cluster/ ]]
then
	# --wsrep-new-cluster is used for the "seed" command so no recovery used
	echo "${LOG_MESSAGE} Starting a new cluster..."
	do_install_db

elif ! test -f /var/lib/mysql/ibdata1
then
	# Skip recovery on empty data directory
	echo "${LOG_MESSAGE} No ibdata1 found, starting a fresh node..."
	do_install_db
fi

# Start mysqld
echo "${LOG_MESSAGE} ----------------------------------"
echo "${LOG_MESSAGE} Starting with options: $OPT $START"
exec mysqld $OPT $START


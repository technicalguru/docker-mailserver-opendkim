#!/bin/bash

IMAGE_HOME=/usr/local/mailserver
IMAGE_TEMPLATES=$IMAGE_HOME/templates


# Check env vars
if [[ -z "${DKIM_DOMAIN}" ]]; then
	DKIM_DOMAIN=localdomain
fi
if [[ -z "${DKIM_DB_HOST}" ]]; then
	DKIM_DB_HOST=localhost
fi
if [[ -z "${DKIM_DB_NAME}" ]]; then
	DKIM_DB_NAME=dkim
fi
if [[ -z "${DKIM_DB_USER}" ]]; then
	DKIM_DB_USER=dkim
fi
if [[ -z "${DKIM_DB_PASS}" ]]; then
	DKIM_DB_PASS=dkim
fi
####################
# Helper functions
####################
# Replace a variable ina file
# Arguments:
# $1 - file to replace variable in
# $2 - Name of variable to be replaced
# $3 - Value to replace
replace_var() {
	# assign vars
	VARNAME=$2
	VARVALUE=${!VARNAME}
	# Sanitize for sed regex
	VARVALUE="${VARVALUE//:/\\:}"
	# replace with sed
	sed -i "s:__${VARNAME}__:${VARVALUE}:g" $1
}

# Copy a template file and replace all variables in there.
# The target file will not be touched if it exists before
# Arguments:
# $1 - the template file
# $2 - the destination file
copy_template_file() {
	TMP_SRC=$1
	TMP_DST=$2

	if [ ! -f $TMP_DST ]; then
		if [ ! -f $TMP_SRC ]; then
			echo "Cannot find $TMP_SRC" 1>&2
			exit 1
		fi
		echo "Creating $TMP_DST from template $TMP_SRC"
		cp $TMP_SRC $TMP_DST

		replace_var $TMP_DST 'DKIM_DOMAIN'
		replace_var $TMP_DST 'DKIM_DB_HOST'
		replace_var $TMP_DST 'DKIM_DB_NAME'
		replace_var $TMP_DST 'DKIM_DB_USER'
		replace_var $TMP_DST 'DKIM_DB_PASS'
	fi
	if [ ! -f $TMP_DST ]; then
		echo "Cannot create $TMP_DST" 1>&2
		exit 1
	fi
}

# Copy template files in a directory to a destination directory
copy_files() {
	SRC=$1
	DST=$2
	cd $SRC
	for file in *
	do
		if [ -f $SRC/$file ]
		then
			copy_template_file $SRC/$file $DST/$file
		fi
	done
}

# Configure opendkim
# Makes sure all opendkim config files are in place
configure_opendkim() {
	# opendkim.conf
	copy_template_file $IMAGE_TEMPLATES/opendkim.conf /etc/opendkim.conf

	# etc/default/opendkim
	copy_template_file $IMAGE_TEMPLATES/default/opendkim /etc/default/opendkim
}

check_database_user() {
	USER=$( echo "select host,user from mysql.user where user='$DKIM_DB_USER';" | mysql -u root --password=$DKIM_SETUP_PASS -h $DKIM_DB_HOST --skip-column-names)
	if [[ -z "$USER" ]]
	then
		# Create user
		echo "Creating user..."
		echo "CREATE USER '$DKIM_DB_USER'@'%' IDENTIFIED BY '$DKIM_DB_PASS';" | mysql -u root --password=$DKIM_SETUP_PASS -h $DKIM_DB_HOST
		if [[ $? -ne 0 ]]
		then
			echo "Cannot create user $DKIM_DB_USER" 1>&2
			exit 1
		fi
	fi
}

create_database() {
	echo "Creating database..."
	echo "CREATE DATABASE IF NOT EXISTS $DKIM_DB_NAME;" |  mysql -u root --password=$DKIM_SETUP_PASS -h $DKIM_DB_HOST
	if [[ $? -ne 0 ]]
	then
		echo "Cannot create database $DKIM_DB_NAME" 1>&2
		exit 1
	fi
	# Also authorize user now
	echo "Granting privileges..."
	echo "GRANT ALL PRIVILEGES ON \`$DKIM_DB_NAME\`.* TO '$DKIM_DB_USER'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql -u root --password=$DKIM_SETUP_PASS -h $DKIM_DB_HOST
	if [[ $? -ne 0 ]]
	then
		echo "Cannot grant privileges on database $DKIM_DB_NAME to user $DKIM_DB_USER" 1>&2
		exit 1
	fi
	# we need some delay for the privileges to be flushed
	sleep 2
}

create_tables() {
	FOO=$( echo "select * from $DKIM_DB_NAME.internal_hosts where hostname='localhost';" | mysql -u $DKIM_DB_USER --password=$DKIM_DB_PASS -h $DKIM_DB_HOST --skip-column-names $DKIM_DB_NAME)
	if [[ -z "$FOO" ]]
	then
		mysql -u $DKIM_DB_USER --password=$DKIM_DB_PASS -h $DKIM_DB_HOST $DKIM_DB_NAME <$IMAGE_HOME/create_tables.sql
		if [[ $? -ne 0 ]]
		then
			echo "Cannot create tables on database $DKIM_DB_NAME to user $DKIM_DB_USER" 1>&2
			exit 1
		fi
	else
		echo "Tables seem to exist."
	fi
}

check_database() {
	TABLES=$( echo "show tables;" | mysql -u $DKIM_DB_USER --password=$DKIM_DB_PASS -h $DKIM_DB_HOST --skip-column-names $DKIM_DB_NAME)
	if [[ -z "$TABLES" ]]
	then
		# Password not correct or database not initialized
		if [[ -z "$DKIM_SETUP_PASS" ]]
		then
			echo "Cannot check database setup. Your database denies access. Cannot proceed as there is no setup password provided (DKIM_SETUP_PASS)" 1>&2
			exit 1
		fi

		# Make sure that user is created
		check_database_user

		# Try to list the database
		DATABASES=$( echo "show databases like '$DKIM_DB_NAME';" | mysql -u root --password=$DKIM_SETUP_PASS -h $DKIM_DB_HOST --skip-column-names)
		if [[ $? -ne 0 ]]
		then
			echo "Cannot check database setup. Please check your database setup!" 1>&2
			exit 1
		fi

		# Check that $DKIM_DB_NAME is in the list of databases
		if [[ -z "$DATABASES" ]]
		then
			# No database yet
			create_database
		fi

	fi

	# will only create when not existing yet
	create_tables
}

# Stopping all (we got a TERM signal at this point)
_sigterm() {
	echo "Caught SIGTERM..."
	service opendkim stop
	service rsyslog stop
	kill -TERM "$TAIL_CHILD_PID" 2>/dev/null
}

#########################
# Installation check
#########################
check_database

#########################
# Startup procedure
#########################
cd $IMAGE_HOME

# Start log facility
service rsyslog start

# Configure OpenDKIM
configure_opendkim

# Start OpenDKIM
service opendkim start
touch /var/log/mail.log

# Tail the mail.log
trap _sigterm SIGTERM

tail -f /var/log/mail.log &
TAIL_CHILD_PID=$!

wait "$TAIL_CHILD_PID"



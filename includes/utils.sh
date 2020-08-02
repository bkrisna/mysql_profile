#!/bin/sh

probe ()
{
	local key=$1
	grep -w -e $key $CONFIG_FILE > /dev/null
	return $?
}

probe_dbnum() {
	local file=$1;
	local dbnum=$2;
	local retval=$(awk -F";" 'BEGIN {is_valid=1} { if ($1=="'$dbnum'") { is_valid=0; } } END {print is_valid}' $file);
	return $retval;
}

probe_sid ()
{
	local sid=$1
	local retval=$(awk -F";" 'BEGIN {is_valid=1} { if ($2=="'$sid'") { is_valid=0; } } END {print is_valid}' $CONFIG_FILE);
	return $retval;
}

wait_for_pid () {
	local _ret=$1;
	local verb="$2"           # created | removed
	local pid="$3"            # process ID of the program operating on the pid-file
	local pid_file_path="$4" # path to the PID file.
	local i=0;
	local msg='';
	local avoid_race_condition="by checking again"
	while test $i -ne $service_startup_timeout ; do
    	case "$verb" in
    		'created')
        		# wait for a PID-file to pop into existence.
        		test -s "$pid_file_path" && i='' && break
        		;;
      		'removed')
        		# wait for this PID-file to disappear
        		test ! -s "$pid_file_path" && i='' && break
        		;;
      		*)
        		msg "wait_for_pid () usage: wait_for_pid created|removed pid pid_file_path"
				eval $_ret="'$msg'";
        		exit 1
        		;;
    	esac
    	
		# if server isn't running, then pid-file will never be updated
    	if test -n "$pid"; 
		then
			if kill -0 "$pid" 2>/dev/null; then
        		:  # the server still runs
			else
        		# The server may have exited between the last pid-file check and now.  
        		if test -n "$avoid_race_condition"; then
          			avoid_race_condition=""
          			continue  # Check again.
        		fi

        		# there's nothing that will affect the file.
        		msg "The server quit without updating PID file ($pid_file_path)."
        		return 1  # not waiting any more.
      		fi
    	fi
		i=`expr $i + 1`
		sleep 1
  	done

  	if test -z "$i" ; then
    	return 0
  	else
    	return 1
  	fi
}

check_mysql_config() {
	local cfgfile=$1
	if test -s "$cfgfile"; then
		return 0;
	else
		return 1;
	fi
}

cek_db_instance() {
	local res=$2;
	local _ret='';
	local __ret=$1;
	local retval=0;
	local MYCONFIGFILE=$(echo $res | awk -F';' '{print $5}');
	local MYDATADIR='';
	local PIDFILENAME='';
	local MYPIDFILEPATH='';
	local isval=$(check_mysql_config $MYCONFIGFILE; echo $?);
	if [ $isval -eq 0 ]; then
		MYDATADIR=$(grep "^datadir" ${MYCONFIGFILE} | sed -e 's/^[^=]*=//' | sed -e 's/[\t ]//g;/^$/d');
		PIDFILENAME=$(grep "^pid_file" ${MYCONFIGFILE} | sed -e 's/^[^=]*=//' | sed -e 's/[\t ]//g;/^$/d');
		MYPIDFILEPATH=$MYDATADIR/$PIDFILENAME;
		if test -s "$MYPIDFILEPATH"; then
			MYPID=$(cat "$MYPIDFILEPATH");
			cek_pid=$(kill -0 "$MYPID" 2>/dev/null; echo $?);
			if [ $cek_pid -eq 0 ]; then
				retval=0;
				_ret="MYSQL Server is running with PID: $MYPID";
			else
				retval=1;
				_ret="MYSQL Server is not running, please start the db server	";
			fi
		else
			_ret="MYSQL Server is not running, please start the db server";
			retval=1;
		fi
	else
		_ret="Defailt file is not valid";
		retval=1;
	fi
	
	eval $__ret="'$_ret'";
	return $retval;
}

is_usepw() {
	MYPORT=$1;
	cek=$($MYSQL_BINDIR/mysql -uroot -h127.0.0.1 -P${MYPORT} -e exit > /dev/null 2>&1; echo $?);
	return $cek;
}

get_mysql_datadir() {
	local _ret=$1;
	local cfgfile=$2;
	local retval=0;
	local dir='';
	local isval=$(check_mysql_config $cfgfile; echo $?);
	if [ $isval -eq 0 ]; then
		dir=$(grep "^datadir" ${cfgfile} | sed -e 's/^[^=]*=//' | sed -e 's/[\t ]//g;/^$/d');
		retval=0;
	else
		dir='Default file is not valid';
		retval=1;
	fi
	eval $_ret="'$dir'";
	return $retval;
}
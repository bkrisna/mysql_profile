#!/bin/sh
## script base config 
HOME_DIR=$HOME;
#BASE_DIR=$HOME_DIR/.mysql_profile/;
BASE_DIR=/Users/bkrisna/Documents/05.other/mysql_profile;
BACKUP_DIR=$BASE_DIR/.backup;
CONFIG_FILE=$BASE_DIR/config;
MYSQL_BASE=/apps/mysql/mysql57;
MYSQL_BINDIR=$MYSQL_BASE/bin;
MYSQL_DATABASEDIR=/data;
service_startup_timeout=900;
re="^[0-9]*[.]{0,1}[0-9]*$";

#ops constant
SELECTDB=1;
ADDDB=2;
EDITDB=3;
DELETEDB=4;
STARTDB=5;
STOPDB=6;
CEKORPHAN=7;
CEKDEF=8;

sid=0;
port=1;
state=2;
default=3;

#include additional files
. $BASE_DIR/includes/utils.sh
. $BASE_DIR/includes/beauty.sh

init() {
	info_text "Detecting config file.";
	if [ ! -f $CONFIG_FILE ]; 
	then
		info_text "Config not found. Create new config files.";
		touch "$CONFIG_FILE";
		info_text "Config file creation done."
	else
		info_text "Config file found > "$CONFIG_FILE".";
	fi
	
	info_text "Declaring aliasses."
	shopt -s expand_aliases
	alias l="$BASE_DIR/main.sh -l";
	alias s=". $BASE_DIR/main.sh -s";
	alias a="$BASE_DIR/main.sh -a";
	alias d="$BASE_DIR/main.sh -d";
	alias e="$BASE_DIR/main.sh -e";
	alias status="$BASE_DIR/main.sh -ps"
	alias mysql="echo 'Please select DB first'";
	alias datadir="echo 'Please select DB first'";
	alias startdb="$BASE_DIR/main.sh -start";
	alias stopdb="$BASE_DIR/main.sh -stop";
	info_text "Done.";
}

get_db_number() {
	local dbfile=$3;
	local ops=$2
	local __dbsel=$1;
	local loop=true;
	local retval=0;
	local err=false;
	while $loop; do
		get_question $ops $err;
		read _dbsel;
		if [[ $_dbsel != '' ]]; then
			if [[ "$_dbsel" =~ $re ]]; then
				probe_dbnum $dbfile $_dbsel;
				retval=$?;
				if [ $_dbsel -eq 0 -o $retval -eq 0 ]; then
					if [ $_dbsel -eq 0 ]; then
						if [ $ops -eq ${STARTDB} -o $ops -eq ${STOPDB} -o $ops -eq ${CEKORPHAN} -o $ops -eq ${CEKDEF} ]; then
							loop=false;
						else
							return1line;
							err=true;
						fi
					else
						loop=false;
					fi	
				else
					return1line;
					err=true;
				fi
			else
				return1line;
				err=true;
			fi
		else
			loop=false;
		fi
	done
	eval $__dbsel="'$_dbsel'";
	return 0;
}

start_db_instance() {
	res=$1;
	MYSID=$(echo $res | awk -F';' '{print $2}');
	MYPORT=$(echo $res | awk -F';' '{print $3}');
	MYCONFIGFILE=$(echo $res | awk -F';' '{print $5}');
	info_text "Starting MySQL DB for $MYSID:$MYPORT"
	
	if [ -s "${MYCONFIGFILE}" ]; then
		MYDATADIR=$(grep "datadir" ${MYCONFIGFILE} | sed -e 's/^[^=]*=//' | sed -e 's/[\t ]//g;/^$/d');
		PIDFILENAME=$(grep "pid_file" ${MYCONFIGFILE} | sed -e 's/^[^=]*=//' | sed -e 's/[\t ]//g;/^$/d');
		MYHOME=$MYSQL_BASE/$MYSQL_SID;
		MYPIDFILEPATH=$MYDATADIR/$PIDFILENAME;
		if test -x $MYSQL_BINDIR/mysqld_safe
	    then
			local msg="";
	    	$MYSQL_BINDIR/mysqld_safe --defaults-file="$MYCONFIGFILE" --user=mysql >/dev/null &
	    	wait_for_pid msg created "$!" "$MYPIDFILEPATH"; return_value=$?
		  	if [[ $return_value = 0 ]]; then
				MYPID=$(cat $MYPIDFILEPATH);
				info_text "MySQL DB started for $MYSID:$MYPORT with PID: $MYPID";
				return $return_value
		  	else
				error_text "$msg";
				error_text "Couldn't start MySQL DB for $MYSID:$MYPORT.";
				return 1;
	  	  	fi
	    else
	      	error_text "Couldn't find MySQL server ($MYSQL_BINDIR/mysqld_safe)";
		  	return 1;
		fi
	else
		error_text "Unable to find config file ${MYCONFIGFILE}. Startup aborted."
		return 1;
	fi;
	return 0;
}

get_root_pw() {
	local _resvar=$2;
	MYPORT=$1;
	loop=true;
	err=false;
	while $loop; do
		if $err; then
			option_picked "${RED_TEXT}Wrong Password !!, ${ENTER_LINE}Please enter db root password. ${NORMAL}> ";
		else
			option_picked "${ENTER_LINE}Please enter db root password. ${NORMAL}> ";
		fi
		read -s root_pass;
		if [[ "$root_pass" != '' ]]; then
			cek=$($MYSQL_BINDIR/mysql -uroot -p${root_pass} -h127.0.0.1 -P${MYPORT} -e exit > /dev/null 2>&1; echo $?);
			if [ "$cek" -eq 0 ]; then
				loop=false;
			else
				return1line;
				err=true;
				loop=true;
			fi
		else
			return1line
			err=true;
			loop=true;
		fi
	done
	eval $_resvar="'$root_pass'";	
	return 0;
}

stop_db_instance() {
	res=$1;
	sall=$2;
	MYSID=$(echo $res | awk -F';' '{print $2}');
	MYHOME=$MYSQL_BASE/$MYSQL_SID;
	MYPORT=$(echo $res | awk -F';' '{print $3}');
	MYCONFIG=$(echo $res | awk -F';' '{print $5}');
	MYDATADIR=$MYSQL_DATABASEDIR/$MYSID/mysql_data/data/datadir;
	MYPIDFILEPATH=$MYDATADIR/$MYSID.pid
	if test -s "$MYPIDFILEPATH"; then
		mysqld_pid=$(cat "$MYPIDFILEPATH");
      	if (kill -0 $mysqld_pid 2>/dev/null); then
        	info_text "Shutting down MySQL for $MYSID:$MYPORT";
        	if [ "$sall" -eq 0 ]; then
				MYPID=$(cat $MYPIDFILEPATH);
				kill $MYPID;
			else
				cmd="$MYSQL_BINDIR/mysqladmin -uroot -h127.0.0.1 -P${MYPORT} shutdown";
				usepw=$(is_usepw ${MYPORT}; echo $?);
				if [ "$usepw" -eq 1 ]; then
					get_root_pw ${MYPORT} rootpw;
					cmd=$(echo $cmd " -p${rootpw} > /dev/null 2>&1");
				fi
				info_text "Executing shutdown command";
				eval "$cmd";
			fi
			return_value=$?

			if [ "$return_value" -eq 0 ]; then
				local msg='';
        		wait_for_pid msg removed "$mysqld_pid" "$MYPIDFILEPATH"; return_value=$?
				info_text "Shutdown complete.";
				return 0;
			else
				error_text "Unable to bring down $MYSID:$MYPORT. Please executed the command manually."
				return 1;
			fi
		else
        	error_text "MySQL server process #$mysqld_pid is not running!"
			return 1;
     	fi
	else
    	error_text "MySQL server PID file could not be found!";
		return 1;
    fi
	return 0;
}

main_ops() {
	local ops=$1;
	local loop=true;
	local dbsel='';
	while $loop; do
		clear;
		show_header $ops;
		list_db $CONFIG_FILE;
		get_db_number dbsel $ops $CONFIG_FILE;
		if [[ $dbsel != '' && "$dbsel" -ge 0 ]]; then
			local res=$(grep ^$dbsel\; $CONFIG_FILE);
			local mysid=$(echo $res | awk -F';' '{print $2}');
			local mystate=$(echo $res | awk -F';' '{print $4}');
			local myport=$(echo $res | awk -F';' '{print $3}');
			case $ops in
				${STARTDB} | ${STOPDB} )
					confirm_dialog $ops $dbsel $res;
					cfrm=$?;
					case $cfrm in
						0 )
							clear;
							show_header2 $ops $dbsel $res
							if [ "$dbsel" -eq 0 ]; then
								for hst in `cat $CONFIG_FILE`; do
									if [[ "$ops" -eq ${STARTDB} ]]; then
										start_db_instance $hst 0;
									elif [[ "$ops" -eq ${STOPDB} ]]; then
										stop_db_instance $hst 0;
									fi
									echo "-----------------------------------------------------------------";
								done;
							else
								if [[ "$ops" -eq ${STARTDB} ]]; then
									start_db_instance $res $dbsel; return_value=$?
								elif [[ "$ops" -eq ${STOPDB} ]]; then
									stop_db_instance $res $dbsel; return_value=$?
								fi
							fi
							show_footer $ops;
							loop=false;
							;;
						1 )
							loop=true;
							;;
						2 )
							info_text "Operation canceled."
							loop=false;
							;;
					esac
				;;
				${SELECTDB} )
					local mys="bin/mysql -uroot -p -h127.0.0.1 -P${myport} --prompt=\"[ ${mysid}:\\p (${mystate}) ] > \"";
					local myprompt="[ ${mysid}:${myport}(${mystate})@\\h: \\w ] \\n\\$> ";
					alias mysql="$MYSQL_BASE/$mys";
					alias datadir="cd $MYSQL_DATABASEDIR/$mysid;";
					clear;
					show_result $res;
					export PS1="$myprompt";
					if [ $(cek_db_instance msg $res; echo $?) -eq 0 ]; then
						eval "$MYSQL_BASE/$mys";
					fi
					loop=false;
				;;
				${DELETEDB} )
					clear;
					show_result $res;
					confirm_dialog $ops $dbsel $res;
					local cfrm=$?;
					case $cfrm in
						0 )
							cat $CONFIG_FILE | sed '/;'$mysid';/d' | awk -F';' 'BEGIN {c=1;} {print c";"$2";"$3";"$4";"$5; c++}' > /tmp/.tmp.$$
							dt=$(date '+%d%m%Y%H%M%S');
							mv $CONFIG_FILE $BACKUP_DIR/backup_config.$dt;
							mv /tmp/.tmp.$$ $CONFIG_FILE
							info_text "SID '$mysid' removed"
							loop=false;
							;;
						1 )
							loop=true;
							;;
						2 )
							info_text "Operation canceled."
							loop=false;
							;;
					esac
				;;
				${EDITDB} )
					clear;
					local newval='';
					show_form newval $ops $res;
					confirm_dialog $ops $dbsel $res;
					local cfrm=$?;
					case $cfrm in
						0 )
							local old=$(grep ^$dbsel\; $CONFIG_FILE);
							local new=$(echo $dbsel";""$newval");
							local dt=$(date '+%d%m%Y%H%M%S');
							awk -F";" '$1=='$dbsel' {$0="'$new'"} 1' $CONFIG_FILE > /tmp/.tmpe.$$;
							mv $CONFIG_FILE $BACKUP_DIR/backup_config.$dt;
							mv /tmp/.tmpe.$$ $CONFIG_FILE
							info_text "Save data completed";
							loop=false;
							;;
						1 )
							loop=true;
							;;
						2 )
							info_text "Operation canceled."
							loop=false;
							;;
					esac
				;;
			esac
		else
			loop=false;
			if [[ "$ops" -eq ${SELECTDB} ]]; then
				alias mysql="echo 'Please select DB first'";
				alias datadir="echo 'Please select DB first'";
		        export PS1="[\u@\h \W]\$ ";
			fi
		fi
	done
	return 0;
}

get_running_mysql() {
	
	
	if test -s "$temp_file2"; then 
		while $loop; do
			clear;
			show_header $ops;
			list_db $temp_file2;
			local dbsel='';
			get_db_number dbsel $ops;
			
		done
	fi
	
	cat /dev/null > $temp_file2;
	return 0;
}


cek_ops() {
	local ops=$1;
	local loop=true;
	local dbsel='';
	
	local ops=$1;
	local temp_file=/tmp/.tmp_ls.$$;
	local temp_file2=/tmp/.tmp_new;
	local count=0;
	
	if [[ $ops -eq ${CEKORPHAN} ]]; then
		ps -ef | grep "port=" | grep -v grep | sed -e "s/[[:space:]]\+/ /g" | sed -e 's/ /;/g' > $temp_file;
		for inst in `cat "$temp_file"`; do
			local default=$(echo $inst | awk -F"--" '{print $2}' | sed -e 's/^[^=]*=//' | sed -e 's/;//');
			local sid=$(echo $default | awk -F"/" '{if ($2 == "apps") {print $5} else {print $3}}');
			local port=$(echo $inst | awk -F"--" '{ print $NF }' | sed -e 's/^[^=]*=//' | sed -e 's/;//');
			local state='S';
			if [[ $(probe $port; echo $?) -ne 0 ]]; then
				local nn=$(($count + 1));
				echo $nn";"$sid";"$port";"$state";"$default >> $temp_file2;
				count=$nn;	
			fi
		done;
	elif [[ $ops -eq ${CEKDEF} ]]; then
		ps -ef | grep "port=" | grep -v grep | sed -e "s/[[:space:]]\+/ /g" | sed -e 's/ /;/g' > $temp_file;
		for inst in `cat "$temp_file"`; do
			local default=$(echo $inst | awk -F"--" '{print $2}' | sed -e 's/^[^=]*=//' | sed -e 's/;//');
			local sid=$(echo $default | awk -F"/" '{if ($2 == "apps") {print $5} else {print $3}}');
			local port=$(echo $inst | awk -F"--" '{print $NF}' | sed -e 's/^[^=]*=//' | sed -e 's/;//');
			if [[ $(probe "$port"; echo $?) -eq 0 ]]; then
				local res=$(grep \;$port\; $CONFIG_FILE);
				local olddef=$(echo $res | awk -F';' '{print $5}');
				if test "$default" != "$olddef"; then
					local nn=$(($count + 1));
					echo $nn";"$sid";"$olddef";"$port;
					echo $nn";"$sid";"$olddef";"$default >> $temp_file2;
					count=$nn;
				fi	
			fi
		done;
	fi
	
	if test -s "$temp_file2"; then 
		while $loop; do
			clear;
			show_header $ops;
			if [[ $ops -eq ${CEKORPHAN} ]]; then
				list_db $temp_file2;
			else
				list_db2 $temp_file2;
			fi
			get_db_number dbsel $ops $temp_file2;
			if [[ $dbsel != '' && "$dbsel" -ge 0 ]]; then
				local res=$(grep ^$dbsel\; $temp_file2);
				case $ops in
					${CEKORPHAN} )
						confirm_dialog $ops $dbsel $res;
						cfrm=$?;
						case $cfrm in
							0 )
								clear;
								show_header2 $ops $dbsel $res
								if [ "$dbsel" -eq 0 ]; then
									for hst in `cat $temp_file2`; do
										local num=$(($(cat $CONFIG_FILE | wc -l) + 1));
										local mysid=$(echo $hst | awk -F';' '{print $2}');
										local mystate=$(echo $hst | awk -F';' '{print $4}');
										local myport=$(echo $hst | awk -F';' '{print $3}');
										local defile=$(echo $hst | awk -F';' '{print $5}');
										echo $num";"$mysid";"$myport";"$mystate";""$defile" >> $CONFIG_FILE
										info_text "SID "$mysid" successfully added to db list.";
										echo "-----------------------------------------------------------------";
									done;
								else
									local mysid=$(echo $res | awk -F';' '{print $2}');
									local mystate=$(echo $res | awk -F';' '{print $4}');
									local myport=$(echo $res | awk -F';' '{print $3}');
									local defile=$(echo $res | awk -F';' '{print $5}');
									local num=$(($(cat $CONFIG_FILE | wc -l) + 1));
									echo $num";"$mysid";"$myport";"$mystate";""$defile" >> $CONFIG_FILE
									info_text "SID "$mysid" successfully added to db list.";
								fi
								show_footer $ops;
								loop=false;
								;;
							1 )
								loop=true;
								;;
							2 )
								info_text "Operation canceled."
								loop=false;
								;;
						esac
					;;
					${CEKDEF} )
						confirm_dialog $ops $dbsel $res;
						cfrm=$?;
						case $cfrm in
							0 )
								clear;
								show_header2 $ops $dbsel $res
								if [ "$dbsel" -eq 0 ]; then
									for hst in `cat $temp_file2`; do
										local mysid=$(echo $hst | awk -F';' '{print $2}');
										local newdef=$(echo $hst | awk -F';' '{print $4}');
										local old=$(grep \;$mysid\; $CONFIG_FILE);
										local oldnum=$(echo $old | awk -F';' '{print $1}');
										local oldstate=$(echo $old | awk -F';' '{print $4}');
										local oldport=$(echo $old | awk -F';' '{print $3}');
										local new=$(echo $oldnum";"$mysid";"$oldport";"$oldstate";"$newdef);
										local dt=$(date '+%d%m%Y%H%M%S');
										awk -F";" '$2=="'$mysid'" {$0="'$new'"} 1' $CONFIG_FILE > /tmp/.tmpe.$$;
										mv $CONFIG_FILE $BACKUP_DIR/backup_config.$dt;
										mv /tmp/.tmpe.$$ $CONFIG_FILE
										info_text "Save data completed";
										info_text "SID "$mysid" successfully added to db list.";
										echo "-----------------------------------------------------------------";
									done;
								else
									local mysid=$(echo $res | awk -F';' '{print $2}');
									local newdef=$(echo $res | awk -F';' '{print $4}');
									local old=$(grep \;$mysid\; $CONFIG_FILE);
									local oldnum=$(echo $old | awk -F';' '{print $1}');
									local oldstate=$(echo $old | awk -F';' '{print $4}');
									local oldport=$(echo $old | awk -F';' '{print $3}');
									local new=$(echo $oldnum";"$mysid";"$oldport";"$oldstate";"$newdef);
									local dt=$(date '+%d%m%Y%H%M%S');
									awk -F";" '$2=="'$mysid'" {$0="'$new'"} 1' $CONFIG_FILE > /tmp/.tmpe.$$;
									mv $CONFIG_FILE $BACKUP_DIR/backup_config.$dt;
									mv /tmp/.tmpe.$$ $CONFIG_FILE
									info_text "Save data completed";
									info_text "SID "$mysid" successfully added to db list.";
								fi
								show_footer $ops;
								loop=false;
								;;
							1 )
								loop=true;
								;;
							2 )
								info_text "Operation canceled."
								loop=false;
								;;
						esac
					;;
				esac
			else
				loop=false;
			fi
		done
	fi
	cat /dev/null > $temp_file2;
	return 0;
}

case $1 in
    -u | --usage )
		show_usage;
		;;
	-h | --help )
		show_usage;
		;;
	-s | --select )
		main_ops ${SELECTDB};
		;;
	-a | --add )
		clear;
		show_form newdata ${ADDDB} '';
		num=$(($(cat $CONFIG_FILE | wc -l) + 1));
		echo $num";"$newdata >> $CONFIG_FILE
		info_text $(echo $newdata | awk -F';' '{print "SID "$1" successfully added to db list."}');
		;;
	-d | --delete )
		main_ops ${DELETEDB}
		;;
	-e | --edit )
		main_ops ${EDITDB};
		;;
	-ps | --process-list )
		list_db $CONFIG_FILE;
		;;
	-i | --init )
		init
		;;
	-l | --list-command )
		show_alias;
		;;
	-start | --start-db )
		main_ops ${STARTDB};
		;;
	-stop | --stop-db )
		main_ops ${STOPDB};
		;;
	-c | --check )
		cek_ops ${CEKORPHAN};
		;;
	-cd | --check-default )
		cek_ops ${CEKDEF};
		;;
    * )                     
		show_usage;
		;;
esac

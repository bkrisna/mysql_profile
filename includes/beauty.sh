#!/bin/sh

#define color
NORMAL=`echo "\033[m"`
MENU=`echo "\033[36m"` #Blue
NUMBER=`echo "\033[33m"` #yellow
FGRED=`echo "\033[41m"`
RED_TEXT=`echo "\033[31m"`
ENTER_LINE=`echo "\033[33m"`


#beauty function
return1line() {
	echo -en "\033[1A\033[2K";
	return 0;
}

return2line() {
	echo -en "\033[1A\033[2K";
	echo -en "\033[1A\033[2K";
	return 0;
}

option_picked() {
    local COLOR='\033[01;31m' # bold red
    local RESET='\033[00;00m' # normal white
    local MESSAGE=${@}
    printf "${COLOR}${MESSAGE} ${RESET}";
	return 0;
}

error_text() {
	local MESSAGE=${@};
	printf "${RED_TEXT}!!Error!! ${NORMAL}${MESSAGE}\n";
	return 0;
}

info_text() {
	local MESSAGE=${@};
	printf "${NORMAL}${MESSAGE}${NORMAL}\n";
	return 0;
}

display_center(){
	local line=$1;
    local columns="$(tput cols)";
	printf "%*s\n" $(( (${#line} + columns) / 2)) "$line";
	return 0;
}

display_center_orn() {
  	local termwidth="$(tput cols)";
  	local padding="$(printf '%0.1s' ={1..500})";
  	printf "${MENU}%*.*s ${NORMAL}%s ${MENU}%*.*s${NORMAL}\n" 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding";
	return 0;
}

show_header() {
	local ops=$1;
	case $ops in
		${SELECTDB} )
			display_center_orn "Select Database Instance";
		;;
		${DELETEDB} )
			display_center_orn "Delete Database Instance";
		;;
		${EDITDB} )
			display_center_orn "Edit Database Instance";
		;;
		${STARTDB} )
			display_center_orn "Start Database Instance";
		;;
		${STOPDB} )
			display_center_orn "Shutdown Database Instance";
		;;
		${CEKORPHAN} )
			display_center_orn "Check Orphan DB Instance";
		;;
		${CEKDEF} )
			display_center_orn "Check Instance Default File";
		;;
	esac
	return 0;
}

show_header2() {
	local ops=$1;
	local opt=$2;
	local prm=$3;
	local dbname='';
	[ $opt -eq 0 ] && dbname="all db" || dbname=$(echo $prm | awk -F';' '{print $2":"$3}');
	display_center_orn "=";
	case $ops in
		${STARTDB} )
			display_center "Starting $dbname Instance";
		;;
		${STARTDB} )
			display_center "Shutdown $dbname Instance";
		;;
		${CEKORPHAN} )
			display_center "Add $dbname Instance to config file";
		;;
		${CEKDEF} )
			display_center "Add $dbname Default file to config file";
		;;
	esac
	display_center "Please do not close the session until it is finished";
	display_center_orn "=";
	display_center "";
	return 0;
}

show_footer() {
	local ops=$1;
	display_center "";
	display_center_orn "=";
	case $ops in
		${STARTDB} )
			display_center "Starting command ended.";
		;;
		${STOPDB} )
			display_center "Shutdown command ended.";
		;;
		${CEKORPHAN} | ${CEKDEF} )
			display_center "Command ended.";
		;;
	esac
	display_center_orn "=";
	return 0;
}

show_alias(){
	local wall='|';
	local corner='+';
	local termwidth=$([ $(tput cols) -ge 80 ] && tput cols || echo 80);
	local padding="$(printf '%0.1s' -{1..500})";
	local format_hdr="${MENU}${corner}%*.*s ${NORMAL}%s ${MENU}%*.*s${corner}${NORMAL}\n";
	local format_cnt="${MENU}${wall}${NUMBER} # ${RED_TEXT}%-20s : ${NORMAL}%-*s ${MENU}${wall}${NORMAL}\n";
	local format_ftr="${MENU}${corner}%*.*s${corner}${NORMAL}\n";
	local format_fil="${MENU}${wall}%*.*s${wall}${NORMAL}\n";
	
	local title="Command List";
	printf "${format_hdr}" 0 "$((((termwidth-4-${#title})/2)-1))" "$padding" "$title" 0 "$(((termwidth-2-${#title})/2))" "$padding";
	printf "${format_cnt}" 'a' "$((termwidth-29))" 'Add new DB Parameters';
	printf "${format_cnt}" 'd' "$((termwidth-29))" 'Delete DB Parameters';
	printf "${format_cnt}" 's' "$((termwidth-29))" 'Select DB Parameters';
	printf "${format_cnt}" 'e' "$((termwidth-29))" 'Edit DB Parameters';
	printf "${format_cnt}" 'l' "$((termwidth-29))" 'List command';
	printf "${format_cnt}" 'status' "$((termwidth-29))" 'Show status instance';
	printf "${format_cnt}" 'mysql' "$((termwidth-29))" 'Connect to selected DB';
	printf "${format_cnt}" 'datadir' "$((termwidth-29))" 'Goto selected DB datadir';
	printf "${format_cnt}" 'startdb' "$((termwidth-29))" 'Start DB Instances';
	printf "${format_cnt}" 'stopdb' "$((termwidth-29))" 'Stop DB Instances';
	printf "${format_ftr}" 0 "$(((termwidth-2)))" "$padding";
	return 0;
}


show_usage(){
	local wall='|';
	local corner='+';
	local termwidth=$([ $(tput cols) -ge 80 ] && tput cols || echo 80);
	local padding="$(printf '%0.1s' -{1..500})";
	local format_hdr="${MENU}${corner}%*.*s ${NORMAL}%s ${MENU}%*.*s${corner}${NORMAL}\n";
	local format_cnt="${MENU}${wall}${NUMBER} # ${RED_TEXT}%-20s : ${NORMAL}%-*s ${MENU}${wall}${NORMAL}\n";
	local format_ftr="${MENU}${corner}%*.*s${corner}${NORMAL}\n";
	local format_fil="${MENU}${wall}%*.*s${wall}${NORMAL}\n";
	
	local title="Command Parameter List";
	printf "${format_hdr}" 0 "$((((termwidth-4-${#title})/2)-1))" "$padding" "$title" 0 "$(((termwidth-2-${#title})/2))" "$padding";
	printf "${format_cnt}" '-i | --init' "$((termwidth-29))" 'Initialize Command';
	printf "${format_cnt}" '-u | --usage' "$((termwidth-29))" 'Show Parameter List';
	printf "${format_cnt}" '-a | --add' "$((termwidth-29))" 'Add New DB Instance Parameter';
	printf "${format_cnt}" '-e | --edit' "$((termwidth-29))" 'Edit DB Instance Parameter';
	printf "${format_cnt}" '-d | --delete' "$((termwidth-29))" 'Delete DB Instance Parameter';
	printf "${format_cnt}" '-s | --select' "$((termwidth-29))" 'Select Active DB Instance Parameter';
	printf "${format_cnt}" '-ps' "$((termwidth-29))" 'Show DB Process List';
	printf "${format_cnt}" '-start' "$((termwidth-29))" 'Start DB Instances';
	printf "${format_cnt}" '-stop' "$((termwidth-29))" 'Stop DB Instances';
	printf "${format_ftr}" 0 "$(((termwidth-2)))" "$padding";
	return 0;
}

list_db() {
	local list_file=$1;
	ps -ef | grep "port=" | grep -v grep > /tmp/.tmp_ls.$$
	printf "${MENU}+-----+------------+---------+-----+-----------------------------------------------+--------+${NORMAL}\n";
	printf "${MENU}| ${NORMAL}%3s ${MENU}| ${NORMAL}%10s ${MENU}| ${NORMAL}%7s ${MENU}| ${NORMAL}%3s ${MENU}| ${NORMAL}%-45s ${MENU}| ${NORMAL}%-6s ${MENU}|${NORMAL}\n" 'No' 'DB Name' 'DB Port' 'M/S' 'Default File' 'PID';
	printf "${MENU}+-----+------------+---------+-----+-----------------------------------------------+--------+${NORMAL}\n";
	for i in `cat $list_file`; do
		local num=$(echo $i | awk -F';' '{print $1}');
		local name=$(echo $i | awk -F';' '{print $2}');
		local port=$(echo $i | awk -F';' '{print $3}');
		local state=$(echo $i | awk -F';' '{print $4}');
		local config=$(echo $i | awk -F';' '{print $5}');
		#pid=$(ps -ef | grep "port=$port" | grep -v grep| awk '{print $2}');
		local pid=$(grep "port=$port"  /tmp/.tmp_ls.$$ | grep -v grep| awk '{print $2}');
		#echo -e "|\t $num \t|\t $name \t|\t $port \t|\t $state \t|";
		printf "${MENU}| ${NUMBER}%3s ${MENU}| ${NORMAL}%10s ${MENU}| ${NORMAL}%7s ${MENU}| ${RED_TEXT}%-3s ${MENU}| ${NORMAL}%-45s ${MENU}| ${NORMAL}%-6s ${MENU}|${NORMAL}\n" $num $name $port $state "$config" $pid;
	done;
	printf "${MENU}+-----+------------+---------+-----+-----------------------------------------------+--------+${NORMAL}\n";
}

list_db2() {
	local list_file=$1;
	printf "${MENU}+-----+------------+-----------------------------------------------+-----------------------------------------------+${NORMAL}\n";
	printf "${MENU}| ${NORMAL}%3s ${MENU}| ${NORMAL}%10s ${MENU}| ${NORMAL}%-45s ${MENU}| ${NORMAL}%-45s ${MENU}|${NORMAL}\n" 'No' 'DB Name' 'Old Default File' 'New Default File';
	printf "${MENU}+-----+------------+-----------------------------------------------+-----------------------------------------------+${NORMAL}\n";
	for i in `cat $list_file`; do
		local num=$(echo $i | awk -F';' '{print $1}');
		local name=$(echo $i | awk -F';' '{print $2}');
		local oldconfig=$(echo $i | awk -F';' '{print $3}');
		local newconfig=$(echo $i | awk -F';' '{print $4}');
		printf "${MENU}| ${NUMBER}%3s ${MENU}| ${NORMAL}%10s ${MENU}| ${NORMAL}%-45s ${MENU}| ${NORMAL}%-45s ${MENU}|${NORMAL}\n" "$num" "$name" "$oldconfig" "$newconfig";
	done;
	printf "${MENU}+-----+------------+-----------------------------------------------+-----------------------------------------------+${NORMAL}\n";
}

show_result(){
	local res=$1;
	local msg='';
	local corner="+";
	local wall="|";
	local lid="-";
	local termwidth=$([ $(tput cols) -ge 80 ] && tput cols || echo 80);
	local format_hdr="${MENU}${corner}%*.*s ${NORMAL}%s ${MENU}%*.*s${corner}${NORMAL}\n";
	local format_cnt="${MENU}${wall}${NUMBER} # ${NORMAL}%-20s : ${RED_TEXT}%-*s ${MENU}${wall}${NORMAL}\n";
	local format_ftr="${MENU}${corner}%*.*s${corner}${NORMAL}\n";
	local format_fil="${MENU}${wall}%*.*s${wall}${NORMAL}\n";
	local padding="$(printf '%0.1s' ${lid}{1..500})";
	local padding_empty="$(printf '%0.1s' ' '{1..500})";
	local MYSID=$(echo $res | awk -F';' '{print $2}');
	local MYSTATE=$(echo $res | awk -F';' '{print $4}');
	local MYPORT=$(echo $res | awk -F';' '{print $3}');
	local MYCONFIG=$(echo $res | awk -F';' '{print $5}');
	local MYDATADIR='';
	if test -s $MYCONFIG; then
		cek_db_instance msg $res;
		get_mysql_datadir MYDATADIR $MYCONFIG;
	else
		msg="Default file is not valid";
		MYDATADIR="$msg";
	fi
	
	local title="Selected Parameter";
	
	printf "${format_hdr}" 0 "$((((termwidth-4-${#title})/2)-1))" "$padding" "$title" 0 "$(((termwidth-2-${#title})/2))" "$padding";
	printf "${format_cnt}" 'MYSQL SID' "$((termwidth-29))" "$MYSID";
	printf "${format_cnt}" 'MYSQL PORT' "$((termwidth-29))" "$MYPORT";
	printf "${format_cnt}" 'MYSQL STATE' "$((termwidth-29))" "$MYSTATE";
	printf "${format_cnt}" 'MYSQL DEFAULT FILE' "$((termwidth-29))" "$MYCONFIG";
	printf "${format_cnt}" 'MYSQL DATADIR' "$((termwidth-29))" "$MYDATADIR";
	printf "${format_cnt}" 'MYSQL STATUS' "$((termwidth-29))" "$msg";
	printf "${format_ftr}" 0 "$(((termwidth-2)))" "$padding";
	return 0;
}

show_result2(){
	printf "${MENU}+---------------- ${NORMAL}Selected Parameter ${MENU}------------------------------+${NORMAL}\n";
	printf "${MENU}| %64s |${NORMAL}\n" " ";
	printf "${MENU}| ${NUMBER}1. ${NORMAL}%-14s : ${RED_TEXT}%-40s ${MENU} %6s ${NORMAL}\n" 'MYSQL_SID' $msid '|';
	printf "${MENU}| ${NUMBER}2. ${NORMAL}%-14s : ${RED_TEXT}%-40s ${MENU} %6s ${NORMAL}\n" 'MYSQL_PORT' $mport '|';
	printf "${MENU}| ${NUMBER}3. ${NORMAL}%-14s : ${RED_TEXT}%-40s ${MENU} %6s ${NORMAL}\n" 'MYSQL_STATE' $mstate '|';
	printf "${MENU}| ${NUMBER}4. ${NORMAL}%-14s : ${RED_TEXT}%-40s ${MENU} %6s ${NORMAL}\n" 'MYSQL_HOME' $mhome '|';
	printf "${MENU}| ${NUMBER}4. ${NORMAL}%-14s : ${RED_TEXT}%-45s ${MENU} %6s ${NORMAL}\n" 'MYSQL_DATADIR' $mdatadir '|';
	printf "${MENU}| ${NUMBER}4. ${NORMAL}%-14s : ${RED_TEXT}%-40s ${MENU} %6s ${NORMAL}\n" 'MYSQL_CONFIG' $mconfig '|';
	printf "${MENU}| %64s |${NORMAL}\n" " ";
	printf "${MENU}+------------------------------------------------------------------+${NORMAL}\n";
	return 0;
}

get_question(){
	ops=$1;
	err=$2;
	str="";
	case $ops in
		${SELECTDB} | ${DELETEDB} | ${EDITDB} )
			str="${ENTER_LINE}Please select a DB or ${RED_TEXT}[ enter ]${NORMAL} to exit. ${NORMAL}> "
		;;
		${STARTDB} | ${STOPDB} )
			str="${ENTER_LINE}Please select a DB [ ${RED_TEXT}'0'${NORMAL} for all or ${RED_TEXT}[enter] ${NORMAL}to exit.] ${NORMAL}> ";
		;;
		${CEKORPHAN} | ${CEKDEF} )
			str="${ENTER_LINE}Please select a DB to add to config file [ ${RED_TEXT}'0'${NORMAL} for all or ${RED_TEXT}[enter] ${NORMAL}to exit.] ${NORMAL}> ";
		;;
	esac
	if $err; then
		str=$(echo "${RED_TEXT}!!Invalid Option!!${NORMAL} " $str " ");
	fi
	
	printf "$str";	
	return 0;
}

confirm_dialog() {
	ops=$1;
	opt=$2;
	prm=$3;
	[ $opt -eq 0 ] && dbname="all db" || dbname=$(echo $prm | awk -F';' '{print $2":"$3}');
	case $ops in
		${EDITDB} )
			question="${ENTER_LINE}Are you sure want to edit the selected db ? ${RED_TEXT}[y|n|c]${NORMAL}> "
		;;
		${DELETEDB} )
			question="${ENTER_LINE}Are you sure want to delete the selected db ? ${RED_TEXT}[y|n|c]${NORMAL}> "
		;;
		${STARTDB} )
			question="${ENTER_LINE}Are you sure want to start ${dbname} ? ${RED_TEXT}[y|n|c]${NORMAL}> "
		;;
		${STOPDB} )
			question="${ENTER_LINE}Are you sure want to shutdown ${dbname} ? ${RED_TEXT}[y|n|c]${NORMAL}> "
		;;
		${CEKORPHAN} | ${CEKDEF} )
			question="${ENTER_LINE}Are you sure want to add ${dbname} to config file ? ${RED_TEXT}[y|n|c]${NORMAL}> "
		;;
	esac
	
	loop=true;
	retval=0;
	while $loop; 
	do
		printf "${question}";
		read answ;
		case $answ in
			'Y' | 'y' )
				loop=false; retval=0;
				;;
			'N' | 'n' )
				loop=false; retval=1;
				;;
			'C' | 'c' )
				loop=false; retval=2;
				;;
			* )
				return1line;
				;;
		esac
	done
	return $retval;
}

entriform() {
	local _ret=$1;
	local inputtype=$2;
	local ops=$3;
	local oldval=$4;
	local newval='';
	
	local format_frm="${ENTER_LINE}%-30s > ${NORMAL}%-10s\n";
	local format_frm_empt="${ENTER_LINE}%-15s > ${NORMAL}";
	local err_txt='';

	local loop=true;
	local first=true;
	while $loop; do
		if [[ $err_txt != '' ]]; then
			if $first; then
				return1line;
				first=false;
			else
				return2line;
			fi
			error_text "$err_txt";
			err_txt='';
		fi
		
		case $inputtype in
			${sid} )
				local txt=$([ $ops -eq ${EDITDB} ] && printf "DB SID ${RED_TEXT}[$oldsid]${NORMAL}" || echo "DB SID");
			;;
			${port} )
				local txt=$([ $ops -eq ${EDITDB} ] && printf "DB PORT ${RED_TEXT}[$oldport]${NORMAL}" || echo "DB PORT");
			;;
			${state} )
				local txt=$([ $ops -eq ${EDITDB} ] && printf "DB STATE ${RED_TEXT}[$oldstate]${NORMAL}" || echo "DB STATE");
			;;
			${default} )
				local txt=$([ $ops -eq ${EDITDB} ] && printf "DB Default File ${RED_TEXT}[$olddefault]${NORMAL}" || echo "DB Default File");
			;;
		esac
		
		if [[ $newval == '' ]]; then
			printf "${format_frm_empt}" "$txt";
			read newval;
			if [[ $newval == '' ]]; then
				if [ $ops -eq ${EDITDB} ]; then
					newval=$oldval;
				else
					case $inputtype in
						${sid} )
							err_txt="Please enter SID name";
						;;
						${port} )
							err_txt="Please enter DB port";
						;;
						${state} )
							err_txt="Please enter DB state";
						;;
						${default} )
							err_txt="Please enter DB default file";
						;;
					esac
				fi
			else
				case $inputtype in
					${sid} )
						local is_avail=$(probe_sid $newval; echo $?);
						if [ $is_avail -eq 0 ]; then
							err_txt="SID is used. Please enter other SID";
							newval='';
						fi
					;;
					${port} )
						if [[ "$newval" =~ $re ]]; then
							local is_avail=$(probe $newval; echo $?);
							if [ $is_avail -eq 0 ]; then
								err_txt="PORT already used. Please enter other port number";
								newval='';
							fi
						else
							err_txt="Port invalid. Please enter valid port number";
							newval='';
						fi
					;;
					${state} )
						case $newval in
							'M' | 'm' | 'S' | 's' )
								continue;
								;;
							*)
								err_txt="State invalid. Please enter valid db state";
								newval='';
								;;
						esac
					;;
					${default} )
						continue;
					;;
				esac
				
			fi
		else
			if $first; then 
				return1line; 
			else 
				return2line;
			fi
			printf "${format_frm}" "$txt" "$newval";
			loop=false;
		fi
	done
	eval $_ret="'$newval'"; 
	return 0;
}

show_form() {
	local _ret=$1;
	local ops=$2;
	local res=$3;
	local msg='';
	
	local corner="+";
	local lid="-";
	
	local termwidth=$([ $(tput cols) -ge 80 ] && tput cols || echo 80);
	local title=$([ $ops -eq ${EDITDB} ] && echo "Edit DB Parameter" || echo "Add New DB Parameter");	
	
	local newsid='';
	local newport='';
	local newstate='';
	local newdefault='';

	local oldsid=$([ $ops -eq ${EDITDB} ] && echo $res | awk -F';' '{print $2}' || echo '');
	local oldport=$([ $ops -eq ${EDITDB} ] && echo $res | awk -F';' '{print $3}' || echo '');
	local oldstate=$([ $ops -eq ${EDITDB} ] && echo $res | awk -F';' '{print $4}' || echo '');
	local olddefault=$([ $ops -eq ${EDITDB} ] && echo $res | awk -F';' '{print $5}' || echo '');
	
	local padding="$(printf '%0.1s' ${lid}{1..500})";
	local padding_empty="$(printf '%0.1s' ' '{1..500})";
	local format_hdr="${MENU}${corner}%*.*s ${NORMAL}%s ${MENU}%*.*s${corner}${NORMAL}\n";
	local format_txt="${NORMAL}%-40s\n";
	
	printf "${format_hdr}" 0 "$((((termwidth-4-${#title})/2)-1))" "$padding" "$title" 0 "$(((termwidth-2-${#title})/2))" "$padding";
	printf "${format_txt}" 'Please complete below information:';
	
	entriform newsid ${sid} $ops $oldsid;
	entriform newport ${port} $ops $oldport;
	entriform newstate ${state} $ops $oldstate;
	entriform newdefault ${default} $ops $olddefault;
	
	local retval=$(echo $newsid";"$newport";"$newstate";""$newdefault");
	
	eval $_ret="'$retval'"; 
	return 0;
}
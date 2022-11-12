#!/bin/ksh
#
# backup vnstat database in case of a crash
#        copy to /usr/local/bin/bu_vnstat.sh
# and add to root cron as
#    47 19 * * * -s /usr/local/bin/bu_vnstat.sh 
#

f_cpfile()
{
    l_cp_ifile="$1"
    l_cp_ofile="$2"

    if test ! -f "$l_cp_ifile"
    then
	return
    fi

    if test -f "$l_cp_ofile"
    then
	cmp "$l_cp_ofile" "$l_cp_ifile" > /dev/null 2>&1
	if test "$?" -eq "0"
	then
	    return
	fi
	if test ! -s "$l_cp_ifile"
	then
	    return
	fi
    fi

    logger "INFO vnstat b/u: Backing up $l_cp_ifile"
    cp "$l_cp_ifile" "$l_cp_ofile"
    chmod 640 "$l_cp_ofile"         > /dev/null 2>&1
    chown $g_owner:$g_group "$l_cp_ofile" > /dev/null 2>&1
    
} # END: f_cpfile()

f_bu_openbsd()
{
    if test "`id -u`" != "0"
    then
	return
    fi

    if test -d "$g_dir_vnstat" -a -d "$g_dir_bu"
    then
	f_cpfile "/etc/vnstat.conf"  "$g_dir_bu/vnstat.conf.$HOST"
	pgrep -u _vnstat vnstatd > /dev/null 2>&1
	l_rcvnstat="$?"
	if test "$l_rcvnstat" -eq "0"
	then
	    /usr/sbin/rcctl stop vnstatd > /dev/null 2>&1
	fi
	sleep 1
	f_cpfile "$g_dir_vnstat/vnstat.db" "$g_dir_bu/vnstat.db.$HOST"
	f_cpfile "$g_dir_vnstat/em0"       "$g_dir_bu/em0.$HOST"
	f_cpfile "$g_dir_vnstat/enc0"      "$g_dir_bu/enc0.$HOST"
	f_cpfile "$g_dir_vnstat/iwn0"      "$g_dir_bu/iwn0.$HOST"
	f_cpfile "$g_dir_vnstat/iwm0"      "$g_dir_bu/iwm0.$HOST"
	f_cpfile "$g_dir_vnstat/pflog0"    "$g_dir_bu/pflog0.$HOST"
	f_cpfile "$g_dir_vnstat/tun0"      "$g_dir_bu/tun0.$HOST"
	f_cpfile "$g_dir_vnstat/bge0"      "$g_dir_bu/bge0.$HOST"
	f_cpfile "$g_dir_vnstat/ath0"      "$g_dir_bu/ath0.$HOST"
	if test "$l_rcvnstat" -eq "0"
	then
	    /usr/sbin/rcctl start vnstatd > /dev/null 2>&1
	fi
    fi

} # END: f_bu_openbsd()

#
# main
#
OS=`uname -s`
HOST="`uname -n | awk -F '.' '{print $1}'`"
export OS HOST

g_dir_bhome=/u/BU
if test -d /home/jmccue
then
    g_owner="jmccue"
else
    g_owner="root"
fi

if test -d "/u1/BU"
then
    g_dir_bhome="/u1/BU"
else
    if test -d "/var/BU"
    then
	g_dir_bhome="/var/BU"
    fi
fi
g_dir_bu=$g_dir_bhome/$HOST/vnstat

case "$OS" in
    "OpenBSD")
	g_dir_vnstat=/var/db/vnstat
	g_group="wheel"
	f_bu_openbsd
	;;
    *)
	echo "E020: OS $OS not supported"
	;;
esac

exit 0

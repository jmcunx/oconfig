#!/bin/ksh
#
# restart OpenBSD Network, 7.2+ with wireguard use
# somethime this is needed at wifi hot spots
#

f_msg()
{
    l_m_msg="$1"
    l_m_msg_fmt=""
    l_m_tmsg="`echo "$l_m_msg" | cut -c 1-1`"
    l_m_now=`date '+%H:%M:%S'`
    l_m_ecode="0"
    
    case "$l_m_tmsg" in
	"W")
	    l_m_msg_fmt="WARN  $l_m_now $g_sname $l_m_msg"
	    ;;
	"S")
	    l_m_msg_fmt="SUCCESS  $l_m_now $g_sname $l_m_msg"
	    ;;
	"I")
	    l_m_msg_fmt="INFO  $l_m_now $g_sname $l_m_msg"
	    ;;
	"E")
	    l_m_msg_fmt="ERROR $l_m_now $g_sname $l_m_msg"
	    l_m_ecode="2"
	    ;;
	"X")
	    l_m_msg_fmt="INFO  $l_m_now $g_sname $l_m_msg"
	    echo "$l_m_msg_fmt"
	    return
	    ;;
	*)
	    l_m_msg_fmt="ABORT $l_m_now $g_sname $l_m_msg"
	    l_m_ecode="2"
	    ;;
    esac

    if test -c /dev/console
    then
	echo "$l_m_msg_fmt" >> /dev/console
    else
	if test "$l_m_ecode" -eq "0"
	then
	    echo "$l_m_msg_fmt"
	fi
    fi
    if test "$l_m_ecode" -ne "0"
    then
	echo "$l_m_msg_fmt"
	exit 2
    fi

} # END: f_msg()

g_sname="`basename $0`"
OS=`uname -s`
HOST="`uname -n | awk -F '.' '{print $1}'`"
export OS HOST

if test "`id -u`" = "0"
then
    g_doas=""
else
    g_doas="/usr/bin/doas -u root"
fi

if test "$OS" != "OpenBSD"
then
    f_msg "E001: $OS not supported"
fi

if test -x "/opt/jmc/bin/wg_openbsd.sh"
then
    /opt/jmc/bin/wg_openbsd.sh STATUS QUIET
    if test "$?" -eq "0"
    then
	f_msg "W010: Stopping wireguard"
	/opt/jmc/bin/wg_openbsd.sh STOP
	sleep 1
	/opt/jmc/bin/wg_openbsd.sh STATUS QUIET
	if test "$?" -eq "0"
	then
	    f_msg "E011: FAILED Stop of wireguard"
	fi
    fi
fi

if test "$g_doas" = ""
then
    f_msg "I030: restarting network"
else
    f_msg "X031: restarting network, doas access needed"
fi
$g_doas /bin/sh /etc/netstart
f_msg "I040: restart of network complete"

exit 0

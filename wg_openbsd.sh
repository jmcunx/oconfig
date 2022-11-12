#!/bin/ksh
#
# Start/stop wireguard on OpenBSD
#
# Note, config file MUST be named wg0.conf
#       and in dir /etc
#

f_msg()
{
    l_m_msg="$1"
    l_m_msg_fmt=""
    l_m_tmsg="`echo "$l_m_msg" | cut -c 1-1`"
    l_m_now=`date '+%H:%M:%S'`
    l_m_ecode="0"
    l_m_timeout="3"
    
    case "$l_m_tmsg" in
	"W")
	    l_m_msg_fmt="WARN  $l_m_msg"
	    ;;
	"S")
	    l_m_msg_fmt="SUCCESS  $l_m_msg"
	    ;;
	"I")
	    l_m_msg_fmt="INFO  $l_m_msg"
	    ;;
	"D")
	    l_m_msg_fmt="DEBUG $l_m_msg"
	    ;;
	"E")
	    l_m_msg_fmt="ERROR $l_m_msg"
	    l_m_ecode="2"
	    l_m_timeout="15"
	    ;;
	*)
	    l_m_msg_fmt="ABORT $l_m_msg"
	    l_m_ecode="2"
	    l_m_timeout="15"
	    ;;
    esac

    if test "$g_help" = "Y"
    then
	echo "$l_m_now - $l_m_msg_fmt"
	exit 2
    fi
    if test "$g_quiet" = "Y"
    then
	if test "$l_m_ecode" -ne "0"
	then
	    exit $l_m_ecode
	fi
	return
    fi

    if test "$g_use_logger" = "Y"
    then
	logger "$g_device $l_m_msg_fmt"
    fi
    if test "$g_use_xmessage" = "Y"
    then
	xmessage -timeout $l_m_timeout "$l_m_msg_fmt" &
    fi
    if test "$g_use_xconsole" = "Y"
    then
	echo "$l_m_msg_fmt" > /dev/console
    else
	echo "$l_m_now - $l_m_msg_fmt"
    fi

    if test "$l_m_ecode" -ne "0"
    then
	exit $l_m_ecode
    fi

} # END: f_msg()

f_help()
{
cat << EOF

$g_sname 'START|STOP|STATUS|LOGGER|QUIET|XCONSOLE|XMSG'

Will start or stop AirVPN wireguard on OpenBSD.
Options:
    START    - Start Wireguard
    STOP     - Stop  Wireguard
    STATUS   - Show  Wireguard Status
    LOGGER   - Log messages to /var/log/messages
    QUIET    - do not print any messages, only for Arg STATUS
    XCONSOLE - print messages to /dev/console
    XMSG     - Use xmessage
    --help  Show this help

doas access is needed to use this utility

EOF
} # END: f_help()

f_prog()
{
    l_pg_prog="$1"

    type "$l_pg_prog" > /dev/null 2>&1
    if test "$?" -ne "0"
    then
	f_msg "E100: cannot find program $l_pg_prog"
    fi

} # END: f_prog()

f_file()
{
    l_fl_file="$1"

    if test ! -f "$l_fl_file"
    then
	f_msg "E101: cannot find file $l_fl_file"
    fi
    if test ! -r "$l_fl_file"
    then
	f_msg "E102: cannot read file $l_fl_file"
    fi

} # END: f_file()

f_wgstat()
{
    ifconfig $g_device > /dev/null 2>&1
    if test "$?" -eq "0"
    then
	g_status="UP"
    else
	g_status="DOWN"
    fi

} # END: f_wgstat()

f_log()
{
    f_wgstat
    (
	echo "wireguard is $g_status"
	echo ""
	ifconfig wg0
	echo ""
	grep "$g_device" < /var/log/messages
    ) | xless &

} # END: f_log()

#
# main
#

if test "$OS" = ""
then
    OS=`uname -s`
    export OS
fi
if test "$USER" = ""
then
    USER=`id -un`
    export USER
fi

g_sname="$0"
g_arg=""
g_rmode=""
g_use_logger="N"
g_help="N"
g_use_xmessage="N"
g_use_xconsole="N"
g_quiet="N"
g_status="DOWN"
g_device="wg0"
g_wgcfg="/etc/wireguard/$g_device.conf"

if test "$OS" != "OpenBSD"
then
    f_msg "E001: $g_sname $OS not supported"
fi
if test ! -f "$g_wgcfg"
then
    f_msg "E001: $g_sname missing file $g_wgcfg"
fi
if test "$USER" = "root"
then
    g_doas=""
else
    g_doas="doas"
fi

for g_arg in $@
do
    case "$g_arg" in
	"XCONSOLE")
	    if test -w /dev/console
	    then
		g_use_xconsole="Y"
	    fi
	    ;;
	"XMSG")
	    g_use_xmessage="Y"
	    ;;
	"LOGGER")
	    g_use_logger="Y"
	    ;;
	"START"|"start"|"UP"|"up")
	    g_rmode="up"
	    ;;
	"STOP"|"stop"|"DOWN"|"down")
	    g_rmode="down"
	    ;;
	"STATUS"|"status"|"STAT"|"stat")
	    g_rmode="stat"
	    ;;
	"QUIET")
	    g_quiet="Y"
	    ;;
	"LOG"|"log")
	    f_log
	    exit 0
	    ;;
	"--help"|"-h"|"HELP"|"help"|"-help"|"-H")
	    g_help="Y"
	    f_help
	    exit 2
	    ;;
	*)
	    f_msg "E004: Arg $g_rmode invalid"
	    ;;
    esac
done

if test "$g_rmode" = "stat"
then
    f_wgstat
    f_msg "I002: wireguard is $g_status"
    if test "$g_status" = "UP"
    then
	exit 0
    else
	exit 2
    fi
fi
g_quiet="N"

f_prog "/usr/local/bin/wg-quick"
f_prog "rcctl"
f_prog "ifconfig"
f_prog "doas"
f_file "$g_wgcfg"

f_wgstat

case "$g_rmode" in
    "up")
	if test "$g_status" = "UP"
	then
	    f_msg "E010: wireguard is already active"
	fi
	f_msg "I011: activating wireguard"
	$g_doas /usr/local/bin/wg-quick up "$g_wgcfg"
	sleep 1
	;;
    "down")
	if test "$g_status" = "DOWN"
	then
	    f_msg "E020: wireguard is NOT active"
	fi
	f_msg "I021: deactivating wireguard"
	$g_doas /usr/local/bin/wg-quick down "$g_wgcfg"
	sleep 1
	;;
    *)
	f_msg "E030: Something went wrong"
	;;
esac

f_wgstat

case "$g_status" in
    "UP")
	f_msg "I040: wireguard is active"
	;;
    "DOWN")
	f_msg "I041: wireguard is DOWN"
	;;
    *)
	f_msg "I042: wireguard status Unknown"
	;;
esac

exit 0

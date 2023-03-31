#!/bin/sh
#
# attached to a wireless network
# and will create/update /opt/jmc/bin/jmccue-custom.*
# on reboots
# that can be sourced in on login
#
# Copy to /opt/jmc/bin/create_obsd.sh
#

f_make_login()
{
cat << EOF
#!/bin/csh
# Generated YYYYMMDD HHMMSS
# by $sname
#

if ( ! "\`id -u\`" == "0" ) then
    if ( ! \$?USER ) then
	setenv USER "\`id -un\`"
    endif
    if ( -d /mnt/tmpfs ) then
	setenv TMPDIR /mnt/tmpfs/\$USER
    else
	setenv TMPDIR /tmp/\$USER
    endif
    if ( ! -d \$TMPDIR ) then
	mkdir \$TMPDIR >& /dev/null && chmod 700 \$TMPDIR
    endif
    setenv DISTRO           OpenBSD
    setenv HOST             $HOST
    setenv DOMAIN           $DOMAIN
    setenv HOSTNAME         $HOST.$DOMAIN
    setenv IP               10.0.0.00
    setenv OS               OpenBSD
    setenv WORK_WORKSTATION NO
    setenv TMPDIR           \$TMPDIR
    setenv TMP              \$TMPDIR
    setenv TEMP             \$TMPDIR
    setenv TEMPDIR          \$TMPDIR
    setenv TMUX_TMPDIR      \$TMPDIR
endif
EOF

} # END: f_make_login()

f_make_profile()
{
cat << EOF
#!/bin/sh
# Generated YYYYMMDD HHMMSS
# by $sname
#

if test ! "\`id -u\`" = "0"
then
    case \$- in
        *i*)
            if test "\$USER" = ""
            then
                USER="\`id -un\`"
                export USER
            fi
            if test -d "/mnt/tmpfs"
            then
                TMPDIR="/mnt/tmpfs/\$USER"
            else
                TMPDIR="/tmp/\$USER"
            fi
            export TMPDIR
            if test ! -d "\$TMPDIR"
            then
                mkdir "\$TMPDIR" 2> /dev/null && chmod 700 "\$TMPDIR"
            fi
            DISTRO=OpenBSD
            DOMAIN=hsd1.ma.comcast.net
            HOST=$HOST
	    DOMAIN=$DOMAIN
            HOSTNAME=$HOST.$DOMAIN
            IP=10.0.0.00
            OS=OpenBSD
            WORK_WORKSTATION=NO
            TMPDIR=\$TMPDIR
            TMP=\$TMPDIR
            TEMP=\$TMPDIR
            TEMPDIR=\$TMPDIR
            TMUX_TMPDIR=\$TMPDIR
            export DISTRO DOMAIN HOST HOSTNAME IP OS WORK_WORKSTATION
            export TMPDIR TMP TEMP TEMPDIR TMUX_TMPDIR
            ;;
    esac
fi
EOF

} # END: f_make_profile()

f_generate()
{
    l_gen_wdev=""
    l_gen_wother=""
    l_gen_ip="UNKNOWN"
    l_gen_profile=""
    l_gen_login=""
    l_gen_now_fmt=`date '+%Y-%m-%d %H:%M:%S'`
    l_gen_ecode="0"

    case "$HOST" in
	"fuzzball")
	    l_gen_wdev="iwm0"
	    ;;
	"qball")
	    l_gen_wdev="iwn0"
	    ;;
	"hairball")
	    l_gen_wdev="urtwn0"
	    l_gen_wother="ath0"
	    ;;
	*)
	    echo "E003: $HOST not supported"
	    return
	    ;;
    esac

    if test "`id -u`" = "0"
    then
	l_gen_profile=/opt/jmc/bin/jmccue-custom.sh
	l_gen_login=/opt/jmc/bin/jmccue-custom.csh
    else
	if test -d "$TMPDIR"
	then
	    l_gen_profile=$TMPDIR/jmccue-custom.sh
	    l_gen_login=$TMPDIR/jmccue-custom.csh
	else
	    l_gen_profile=$HOME/jmccue-custom.sh
	    l_gen_login=$HOME/jmccue-custom.csh
	fi
    fi

    /sbin/ifconfig "$l_gen_wdev" > /dev/null 2>&1
    l_gen_ecode="$?"
    if test "$l_gen_ecode" -ne "0" -a "$l_gen_wother" != ""
    then
	l_gen_wdev="$l_gen_wother"
	/sbin/ifconfig "$l_gen_wdev" > /dev/null 2>&1
	l_gen_ecode="$?"
    fi
    if test "$l_gen_ecode" -eq "0"
    then
	l_gen_ip=`/sbin/ifconfig "$l_gen_wdev" | grep 'inet ' | head -n 1 | awk '{print $2}'`
    fi

    f_make_login \
	| sed "s/^ *setenv IP .*/    setenv IP               $l_gen_ip/;s/^# Generated .*/# Generated $l_gen_now_fmt/" \
	> $l_gen_login
    /bin/chmod 644 "$l_gen_login"

    f_make_profile \
	| sed "s/^ *IP.*/            IP=$l_gen_ip/;s/^# Generated .*/# Generated $l_gen_now_fmt/" \
	> $l_gen_profile
    /bin/chmod 644 "$l_gen_profile"

} # END: f_generate()

###############################################################################
# main
###############################################################################
sname="$0"

OS="`uname -s`"
HOST=`cat /etc/myname | awk -F '.' '{print $1}'`
DOMAIN=`cat /etc/myname | sed "s/$HOST\.//"`
export OS HOST DOMAIN

if test "$OS" = "OpenBSD"
then
    f_generate
else
    echo "E001: $OS not supported"
fi

### DONE, do not exit

############################################### - HISTORY LOGGING - #######################################################

## --------------------------------------------------------------
## Author: Chris Taylor & Kerry Miles
## Original Date: 05/05/2013
## Revisions: For revisions, please github: https://github.com/chtaylo2/cmd-history-monitor.git
##
## history-mon.sh is used for zsh, sh, ksh and bash shells
## --------------------------------------------------------------

if [ -t 0 ] && [ ! -e /etc/disable-history-logging ]; then
    export PATH=$PATH:/usr/ucb:/bin:/usr/bin
    export HISTMON_OS=`uname -s`

    ## Determine current user
    if [ "$HISTMON_OS" = "Linux" ]; then
        CUR_USER=`whoami`
    fi

    if [ -n "$CUR_USER" ]; then
        if [ -n "$LOGNAME" ]; then
            CUR_USER=$LOGNAME
        else
            CUR_USER=`id | cut -d'(' -f2 | cut -d')' -f1`
        fi
    fi

    ## Determine effective user
    REAL_USER=$SUDO_USER
    test -z "$REAL_USER" -o "$REAL_USER" = "$CUR_USER" && REAL_USER=`logname`
    test -z "$REAL_USER" -o "$REAL_USER" = "$CUR_USER" && {
        tty=`tty`
        set -- `ls -l $tty`
        REAL_USER=$3
	set --
    }
    test -z "$REAL_USER" && REAL_USER=$CUR_USER

    ## Determine current uid - we only log generics unless root becomes employee
    CUR_UID=`id $CUR_USER | cut -d '=' -f2 | cut -d '(' -f1`;
    REAL_UID=`id $REAL_USER | cut -d '=' -f2 | cut -d '(' -f1`;
    if [ $REAL_UID -eq 0 ] || [ $CUR_UID -lt 1000 ] || [ $CUR_UID -gt 900000 ]; then
        test -d $HOME/.histdir || mkdir $HOME/.histdir
        export HISTTIMEFORMAT='%F %T ~ '
        export HISTSIZE=4096
        export HISTFILE=$HOME/.histdir/.$REAL_USER
	desc="real_user=$REAL_USER ; curr_user=$CUR_USER"

	CMD_NUM=-1

        function history_mon
        {
           if [ -n "$BASH_VERSION" ]; then
               ## BASH PROMPT_COMMAND causes trap to be executed twice. fc also shows second-last command
               unset PROMPT_COMMAND; shopt -s extglob;
               cmd=$(history 1 | awk -F"~ " '{print $2}');
           elif [ -n "$ZSH_VERSION" ]; then
               ## Unable to get ZSH to reliably work at this time
               cmd='[Logged in w/zsh. Unable to monitor session]';
               CMD_NUM=$HISTCMD
           else 
               cmd=$(fc -ln -0 -0);
               cmd=${cmd#*[[:blank:]]}
               CMD_NUM=$HISTCMD
           fi
           if [ -n "$cmd" ]; then
               logger -p local2.info -t cmd_history -- "$desc ; pwd=$PWD ; command=$cmd" > /dev/null 2>&1
           fi
        }

	if [ "$HISTMON_OS" = "Linux" ]; then
	   if [ -n "$BASH_VERSION" ]; then
	       trap -- 'history_mon || trap - DEBUG;' DEBUG
	   else
	       trap -- '[[ $CMD_NUM -ne $HISTCMD ]] && history_mon || trap - DEBUG;' DEBUG
	   fi
	fi
    fi
fi
############################################################################################################################

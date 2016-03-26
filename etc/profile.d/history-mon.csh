############################################### - HISTORY LOGGING - #######################################################

## --------------------------------------------------------------
## Author: Chris Taylor & Kerry Miles
## Original Date: 05/05/2013
## Revisions: For revisions, please github: https://github.com/chtaylo2/cmd-history-monitor.git
##
## history-mon.csh is used for csh and tcsh shells
## --------------------------------------------------------------

if ( -t 0 && ! -e /etc/disable-history-logging ) then
    set path = ($path /usr/ucb /bin /usr/bin)
    set HISTMON_OS=`uname -s`

    ## Determine current user
    if ( "$HISTMON_OS" == "Linux" ) then
        set CUR_USER=`whoami`
    endif

    if (! $?CUR_USER ) then
	set CUR_USER='';
    endif

    if ( "$CUR_USER" == "" ) then
        set CUR_USER=`id | cut -d'(' -f2 | cut -d')' -f1`
    endif

    ## Determine effective user
    if (! $?SUDO_USER ) then
        set SUDO_USER='';
    endif
    set REAL_USER=$SUDO_USER
    test -z "$REAL_USER" -o "$REAL_USER" = "$CUR_USER" && set REAL_USER=`logname`
    test -z "$REAL_USER" -o "$REAL_USER" = "$CUR_USER" && set tty=`tty` && set REAL_USER=`ls -l $tty | awk '{print $3}'`
    test -z "$REAL_USER" && REAL_USER=$CUR_USER

    ## Determine current uid - we only log generics unless root becomes employee
    set CUR_UID=`id $CUR_USER | cut -d '=' -f2 | cut -d '(' -f1`;
    set REAL_UID=`id $REAL_USER | cut -d '=' -f2 | cut -d '(' -f1`;
    if ( $REAL_UID == 0 || $CUR_UID <= 1000 || $CUR_UID >= 900000 ) then
        test -d $HOME/.histdir || mkdir $HOME/.histdir
        set history=( 4096 "%h %Y-%D-%W %T ~ %R\n" )
	set histfile=$HOME/.histdir/.$REAL_USER
	set desc="real_user=$REAL_USER \; curr_user=$CUR_USER"

	if ( "$HISTMON_OS" == "Linux" ) then
		alias precmd "history 1 | awk -F'~ ' '{print "\$2"}' | /bin/logger -p local2.info -t 'cmd_history: real_user=$REAL_USER ; curr_user=$CUR_USER ; command='"
	endif
    endif 
endif
#############################################################################################################################

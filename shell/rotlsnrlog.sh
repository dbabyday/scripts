
 
# Look for all oracle homes in /var/opt/oracle/oratab
for CURRENT_HOME in `cat /var/opt/oracle/oratab | grep :/ | grep -v "#" | cut -d":" -f2 | sort | uniq`
do
    echo " "
    echo " "
    echo "USING $CURRENT_HOME as the current oracle home"
    echo "==========================================================================="
    ORACLE_HOME=$CURRENT_HOME

    # get all listeners associated with the current oracle home and are running
    for CURRENT_LSNR in `ps -ef | grep tnslsnr | grep $ORACLE_HOME | grep -v grep | awk '{ print $10 }' | sort`
    do
        echo "-------------------------------------------"
        echo "Current listener is $CURRENT_LSNR"
        echo "-------------------------------------------"
        
        # get the log file
        XML_FILE=`$ORACLE_HOME/bin/lsnrctl status $CURRENT_LSNR | grep "Listener Log File" | awk '{ print $4 }'`
        CURRENT_LSNR_LOWER=`echo "$CURRENT_LSNR" | tr '[:upper:]' '[:lower:]'`
        LOG_FILE=${XML_FILE%%/alert/*}/trace/${CURRENT_LSNR_LOWER}.log

        # new file name - set the initial values
        COUNT=1
        DATE=`date '+%Y%m%d_%H%M%S'`
        NEW_FILE_NAME=${LOG_FILE}.${DATE}
        
        # if NEW_FILE_NAME exists append an incrementing number
        [[ -f $NEW_FILE_NAME ]] && NEW_FILE_NAME_BASE=$NEW_FILE_NAME
        while [[ -f $NEW_FILE_NAME ]]
        do
            if (($COUNT < 10))
            then
                NEW_FILE_NAME=${NEW_FILE_NAME_BASE}_0${COUNT}
            else
                NEW_FILE_NAME=${NEW_FILE_NAME_BASE}_${COUNT}
            fi
        
            ((COUNT++))
        done

        # stop logging
        lsnrctl <<-EOF
        set current_listener $CURRENT_LSNR
        set log_status off
        EOF
        
#        # rename file
#        mv $LOG_FILE $NEW_FILE_NAME
#        zip $NEW_FILE_NAME.zip $NEW_FILE_NAME
        
        # start logging
        lsnrctl <<-EOF
        set current_listener $CURRENT_LSNR
        set log_status on
        EOF
    done
done
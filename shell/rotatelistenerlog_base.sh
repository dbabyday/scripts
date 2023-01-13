


############################
## ORACLE_HOMES           ##
############################

# save the current ORACLE_HOME, so we can set it back when finished
ORIG_ORACLE_HOME=$ORACLE_HOME

# get the oracle homes listed in oratab and store the unique ones on an array
ALL_ORACLE_HOMES=`cat /var/opt/oracle/oratab | grep -v "#" | grep ":" | awk -F':' '{ print $2 }'`
i=0
declare -a UNIQUE_ORACLE_HOMES
# loop through all the oracle home values from oratab
while read -r ONE_ORACLE_HOME
do
    match="n"
    # compare each oracle home value with the values we already stored in the array
    for uoh in "${UNIQUE_ORACLE_HOMES[@]}"
    do
        # if the oracle home is already in the array, flag it so we do not eneter it again
        [[ "$uoh" == $ONE_ORACLE_HOME ]] && match="y"
    done
    
    # if the oracle home is a new value, add it to the array
    if [[ "$match" == "n" ]]
    then
        UNIQUE_ORACLE_HOMES[$i]=$ONE_ORACLE_HOME
        ((i++))
    fi
done <<< $ALL_ORACLE_HOMES



############################
## LISTENERS              ##
############################



###########################################################################################################
# need to match oracle homes with listeners --> get this from ps -ef|grep lsnr
#     - export ORACLE_HOME=<value>
#     - loop through the unique oracle_homes, and filter the listener processes by the ones running at $ORACLE_HOME/bin/tnslsnr....awk '{ print $8 }
# 
###########################################################################################################



# get the listeners that are currently started
LISTENERS=`ps -ef | grep -v grep | grep lsnr | awk '{ print $9 }'`
while read -r LISTENER_NAME
do
    # get the listener log file for each listener
    LISTENER_LOG_FILES=`lsnrctl status $LISTENER_NAME | grep "Listener Log File" | awk '{ print $4 }'`
    while read -r LOG_FILE_NAME
    do
        # rotate each listener log file
        /orahome/oracle/james/rotatelistenerlog.sh $LISTENER_NAME $LOG_FILE_NAME
    done <<< $LISTENER_LOG_FILES
done <<< $LISTENERS

# re-set the ORACLE_HOME environment variable to what it was originally
export ORACLE_HOME=$ORIG_ORACLE_HOME





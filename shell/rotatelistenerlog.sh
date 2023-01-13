#####################################################################################################################
# 
# rotatelistenerlog.sh
# 
# Author: James Lutsey
# Date:   2018-12-28
# 
# Purpose: Rotate an oracle listener log file:
#              1. stops the logging for the listener
#              2. renames the log file by appending the date_time
#              3. starts the logging for the listener
# 
# Syntax:  rotatelistenerlog.sh <listener_name> <listener_log_file>
#              - find the listener names in $TNS_ADMIN/listener.ora
#              - find the listener log file by: lsnrctl status <listener_name>
# 
# Date        Name                  Description of change
# ----------  --------------------  ---------------------------------------------------------------------------------
# 
#####################################################################################################################



############################
## USER INPUT             ##
############################

# get the values
LISTENER_NAME=$1
LISTENER_LOG_FILE=$2

# verify user input
if [[ -z $LISTENER_NAME ]]
then
    echo "no LISTENER_NAME"
    exit
fi

if [[ -z $LISTENER_LOG_FILE ]]
then
    echo "no LISTENER_LOG_FILE"
    exit
fi

if ! grep -wsi "$LISTENER_NAME" $TNS_ADMIN/listener.ora
then
    echo "Listener $LISTENER_NAME does not exist"
    exit
fi

if ! [[ -e $LISTENER_LOG_FILE ]]
then
    echo "Listener log file $LISTENER_LOG_FILE does not exist"
    exit
fi



############################
## CREATE NEW FILE NAMES  ##
############################

# set the initial values
COUNT=1
DATE=`date '+%Y%m%d_%H%M%S'`
NEW_FILE_NAME=${LISTENER_LOG_FILE}.${DATE}

# if NEW_FILE_NAME exists append an incrementing number
if [[ -e $NEW_FILE_NAME ]]
then
    NEW_FILE_NAME_BASE=$NEW_FILE_NAME
fi

while [[ -e $NEW_FILE_NAME ]]
do
    if (($COUNT < 10))
    then
        NEW_FILE_NAME=${NEW_FILE_NAME_BASE}_0${COUNT}
    else
        NEW_FILE_NAME=${NEW_FILE_NAME_BASE}_${COUNT}
    fi

    ((COUNT++))
done



############################
## ROTATE THE LOG         ##
############################

# stop logging
lsnrctl <<-EOF
set current_listener $LISTENER_NAME
set log_status off
EOF

# rename file
mv $LISTENER_LOG_FILE $NEW_FILE_NAME

# start logging
lsnrctl <<-EOF
set current_listener $LISTENER_NAME
set log_status on
EOF

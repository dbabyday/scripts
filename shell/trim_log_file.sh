#!/bin/bash


# trim the log file
LOGFILE=$1

MATCH_DATE=$(gdate -d "-31 days" +%F)
MATCH_STRING="Checking for Failed Distributed Transactions"
i=0
while read -r line
do
	((i+=1))
	if [[ "${line}" =~ ${MATCH_DATE} ]] && [[ "${line}" =~ ${MATCH_STRING} ]]; then
		LINENUM=${i}
		break
	fi
done < ${LOGFILE}

((LINENUM-=3))

if (( LINENUM > 0 )); then
	echo ""
	echo `date +"%F %T"`" - Trimming ${LOGFILE} of entries before ${MATCH_DATE}"

	ed -s ${LOGFILE} <<-EOF
		1,${LINENUM}d
		w
	EOF
fi
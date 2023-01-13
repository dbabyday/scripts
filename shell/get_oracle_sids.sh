# list all the oracle sids
cat /var/opt/oracle/oratab | grep -v "#" | grep ":" | awk -F':' '{ print $1 }'


emailRecipients=james.lutsey@plexus.com

# write the head section
htmlFile=/tmp/tablespaces_full.html

echo '<html>'                                     >  ${htmlFile}
echo '<head>'                                     >> ${htmlFile}
echo '<style type="text/css">'                    >> ${htmlFile}
echo 'H3'                                         >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    font-family: verdana,arial,sans-serif;' >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable'                            >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    font-family: verdana,arial,sans-serif;' >> ${htmlFile}
echo '    font-size:11px;'                        >> ${htmlFile}
echo '    color:#333333;'                         >> ${htmlFile}
echo '    border-width: 1px;'                     >> ${htmlFile}
echo '    border-color: #000000;'                 >> ${htmlFile}
echo '    border-collapse: collapse;'             >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable th '                        >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    border-width: 1px;'                     >> ${htmlFile}
echo '    padding: 8px;'                          >> ${htmlFile}
echo '    border-style: solid;'                   >> ${htmlFile}
echo '    border-color: #000000;'                 >> ${htmlFile}
echo '    background-color: #dedede;'             >> ${htmlFile}
echo '    font-weight: bold;'                     >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable td '                        >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    border-width: 1px;'                     >> ${htmlFile}
echo '    padding: 8px;'                          >> ${htmlFile}
echo '    border-style: solid;'                   >> ${htmlFile}
echo '    border-color: #000000;'                 >> ${htmlFile}
echo '    background-color: #ffffff;'             >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable .red'                       >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    background-color:#ff0000;'              >> ${htmlFile}
echo '    color:#ffffff;'                         >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable .yellow'                    >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    background-color:#ffff00;'              >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo 'table.gridtable .white'                     >> ${htmlFile}
echo '{'                                          >> ${htmlFile}
echo '    background-color:#ffffff;'              >> ${htmlFile}
echo '}'                                          >> ${htmlFile}
echo '</style>'                                   >> ${htmlFile}
echo '</head>'                                    >> ${htmlFile}
echo ''                                           >> ${htmlFile}
echo '<body>'                                     >> ${htmlFile}
echo '<H3>Tablespace Sizes:</H3>'                 >> ${htmlFile}
echo '<table border="1" class="gridtable">'       >> ${htmlFile}
echo '    <tr>'                                   >> ${htmlFile}
echo '        <th>DATABASE</th>'                  >> ${htmlFile}
echo '        <th>TABLESPACE_NAME</th>'           >> ${htmlFile}
echo '        <th>SIZE_GB</th>'                   >> ${htmlFile}
echo '        <th>USED_GB</th>'                   >> ${htmlFile}
echo '        <th>FREE_GB</th>'                   >> ${htmlFile}
echo '        <th>%_USED</th>'                    >> ${htmlFile}
echo '        <th>MAXSIZE_GB</th>'                >> ${htmlFile}
echo '        <th>MAX_FREE</th>'                  >> ${htmlFile}
echo '        <th>%_MAX</th>'                     >> ${htmlFile}
echo '    </tr>'                                  >> ${htmlFile}


OracleSIDs=("AGLDEV01" "AMPD01" "ARCDV01")


# loop through the databases
for i in ${!OracleSIDs[@]}; do
	echo ""
	echo "--------------------------------------------------------------------------"
	echo ""
	echo `date "+%F %T"`" - Database: ${OracleSIDs[$i]}"
	echo ""

	# execute the query in the database
	# db_login and db_password are passed in from Applications Manager login that is set for the job
	${ORACLE_HOME}/bin/sqlplus -s /nolog <<-!EOSQL
		connect ${db_login}/${db_password}@${OracleSIDs[$i]}
		whenever oserror exit failure
		whenever sqlerror exit sql.sqlcode

		set linesize 1000
		set pagesize 0
		set serveroutput on format wrapped
		set trimspool on
		set echo off
		set feedback off

		spool ${htmlFile} append

		DECLARE
			dbName       varchar(128);
			classMaxFree varchar(20);
			classPctMax  varchar(20);
		BEGIN
			select name into dbName from v\$database;

			FOR t IN (  select    t.tablespace_name
			                    , round(df.total_bytes/1024/1024/1024,0) size_gb
			                    , case when e.used_bytes is null then 0
			                           else round(e.used_bytes/1024/1024/1024,0)
			                      end used_gb
			                    , case when f.free_bytes is null then 0
			                           else round(f.free_bytes/1024/1024/1024,0)
			                      end free_gb
			                    , case when e.used_bytes is null then 0
			                           else round(e.used_bytes/df.total_bytes*100,0)
			                      end pct_used
			                    , round(df.total_maxbytes/1024/1024/1024,0) maxsize_gb
			                    , round((df.total_maxbytes-e.used_bytes)/1024/1024/1024,1) max_free
			                    , case when e.used_bytes is null then 0
			                           else round(e.used_bytes/df.total_maxbytes*100,0)
			                      end pct_max
			            from      dba_tablespaces t
			            left join (  select   tablespace_name
			                                , sum(bytes) total_bytes
			                                , sum(  case when maxbytes=0 then bytes
			                                             else maxbytes
			                                        end  ) total_maxbytes
			                         from     dba_data_files
			                         group by tablespace_name  
			                      ) df on df.tablespace_name = t.tablespace_name
			            left join (  select   tablespace_name
			                                , sum(bytes) used_bytes
			                         from     dba_extents
			                         group by tablespace_name  
			                      ) e on e.tablespace_name = t.tablespace_name
			            left join (  select   sum(bytes) free_bytes
			                                , tablespace_name
			                         from     dba_free_space
			                         group by tablespace_name  
			                      ) f on f.tablespace_name = t.tablespace_name
			            where     e.used_bytes/df.total_maxbytes >= 0.8
			                      or (df.total_maxbytes-e.used_bytes)/1024/1024/1024 <= 10
			            order by  t.tablespace_name
			         )
			LOOP
				IF t.max_free<=5 THEN
				    classMaxFree := 'red';
				ELSIF t.max_free<=10 then
				    classMaxFree := 'yellow';
				ELSE
				    classMaxFree := 'white';
				END IF;

				IF t.pct_max>=90 THEN
				    classPctMax := 'red';
				ELSIF t.pct_max>=80 then
				    classPctMax := 'yellow';
				ELSE
				    classPctMax := 'white';
				END IF;

				dbms_output.put_line(  '    <tr>'                                                                             ||chr(10)||
				                       '        <td align="left"  class="white">'             ||dbName               ||'</td>'||chr(10)||
				                       '        <td align="left"  class="white">'             ||t.tablespace_name    ||'</td>'||chr(10)||
				                       '        <td align="right" class="white">'             ||to_char(t.size_gb)   ||'</td>'||chr(10)||
				                       '        <td align="right" class="white">'             ||to_char(t.used_gb)   ||'</td>'||chr(10)||
				                       '        <td align="right" class="white">'             ||to_char(t.free_gb)   ||'</td>'||chr(10)||
				                       '        <td align="right" class="white">'             ||to_char(t.pct_used)  ||'</td>'||chr(10)||
				                       '        <td align="right" class="white">'             ||to_char(t.maxsize_gb)||'</td>'||chr(10)||
				                       '        <td align="right" class="'||classMaxFree||'">'||to_char(t.max_free)  ||'</td>'||chr(10)||
				                       '        <td align="right" class="'||classPctMax ||'">'||to_char(t.pct_max)   ||'</td>'||chr(10)||
				                       '    <tr>'
				                    );
			END LOOP;
		END;
		/

		spool off
	!EOSQL
	ORAEXIT=$?
	if [[ ${ORAEXIT} -gt 0 ]]; then
		echo "ORAEXIT is ${ORAEXIT}"
		exit ${ORAEXIT}
	fi
done



echo "</body>" >> ${htmlFile}
echo "</html>" >> ${htmlFile}

# email the results
(
		echo "From: Applications_Manager"
		echo "To: ${emailRecipients}"
		echo "Subject: Full Tablespaces"
		echo "MIME-Version: 1.0"
		echo "Content-Type: text/html"
		echo "Content-Disposition: inline"
		cat ${htmlFile}
) | sendmail -t


# clean up
#[[ -f ${htmlFile} ]] && rm ${htmlFile}
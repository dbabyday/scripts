
##################################
## DECLARATIONS                 ##
##################################

# date and time we are running this to use in file name
DTNOW=$(date +%Y%m%d_%H%M%S)

# name of files we will use/create
LST1=y1_createusers.lst
SQL1=x1_profile_pwreset.sql
SQL2=x2_set_profiles_pwreset.sql
SQL3=x2_set_pws.sql
SQL4=x4_set_profiles_orig.sql
SQLFINAL=reset_pws_${ORACLE_SID}_${DTNOW}.sql
SQLFINALBASE=$(echo $SQLFINAL | cut -d'.' -f 1)


##################################
## PROFILE PWRESET              ##
##################################

# profile pwreset
[[ -e $SQL1 ]] && rm $SQL1
touch $SQL1
echo "set echo on feedback on timing on
spool $SQLFINALBASE

-- create profile PWRESET that will allow us to reuse passwords and does not have a verify function
declare
    qty  pls_integer;
    stmt varchar2(200);
begin
    select count(*) into qty
    from   sys.dba_profiles
    where  profile='PWRESET';

    if (qty=0)
    then
        stmt := 'create profile pwreset limit'||chr(10)||
                '    password_life_time unlimited'||chr(10)||
                '    password_reuse_time unlimited'||chr(10)||
                '    password_reuse_max unlimited'||chr(10)||
                '    password_verify_function null';
    else
        stmt := 'alter profile pwreset limit'||chr(10)||
                '    password_life_time unlimited'||chr(10)||
                '    password_reuse_time unlimited'||chr(10)||
                '    password_reuse_max unlimited'||chr(10)||
                '    password_verify_function null';
    end if;

    execute immediate stmt;
end;
/
" >> $SQL1



##################################
## GET USERS INFO FROM DATABASE ##
##################################

sqlplus -s "/ as sysdba" << EOF
set feedback off
set echo off
set trimspool on
set linesize 1000
set pagesize 50000
set long 10000
set head off
set termout off

col cr_user format a1000
col prfl    format a1000

-------------------------------------------------------------------------------------------------------------------

spool x2_set_profiles_pwreset.sql

select   'alter user "'||username||'" profile pwreset;' prfl
from     dba_users
where    username<>'XS\$NULL'
order by username;

select '' from dual;

spool off

-------------------------------------------------------------------------------------------------------------------

spool y1_createusers

select   dbms_metadata.get_ddl('USER',username) cr_user
from     dba_users
where    username<>'XS\$NULL'
order by username;

select '' from dual;

spool off

-------------------------------------------------------------------------------------------------------------------

spool x4_set_profiles_orig.sql

select   'alter user "'||username||'" profile '||profile||';' prfl
from     dba_users
where    username<>'XS\$NULL'
order by username;

select '' from dual;

spool off

-------------------------------------------------------------------------------------------------------------------
EOF



##################################
## PARSE CREATE USER STATEMENTS ##
##################################

# delete file if it exists
[[ -e $SQL3 ]] && rm $SQL3

# create empty file
touch $SQL3

# pull out only the lines that set the passwords and "/"
while read -r line
do
    # remove leading white spaces
    line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//')"

    # if line sets password, add it to the output file
    if [[ ${line:0:11} == "CREATE USER" ]]
    then
        len=${#line}
        len="$(($len-6))"
        line="ALTER ${line:6:$len};"
        echo $line >> $SQL3
    elif [[ ${line:0:10} == "ALTER USER" ]]
    then
        line="${line};"
        echo $line >> $SQL3
    fi
done < $LST1



#################################
## FINAL SQL FILE              ##
#################################

# combine the sql files
if [[ -e $SQL1 && -e $SQL2 && -e $SQL3 && -e $SQL4 ]]
then
    # combine
    cat $SQL1 $SQL2 $SQL3 $SQL4 > $SQLFINAL

    # remove the individual files
    [[ -e $SQL1 ]] && rm $SQL1
    [[ -e $SQL2 ]] && rm $SQL2
    [[ -e $SQL3 ]] && rm $SQL3
    [[ -e $SQL4 ]] && rm $SQL4
    [[ -e $LST1 ]] && rm $LST1
else
    echo "Not all the individual sql files exist, so we cannot combine them into one file"
fi

echo "drop profile pwreset;" >> $SQLFINAL
echo "" >> $SQLFINAL
echo "spool off" >> $SQLFINAL


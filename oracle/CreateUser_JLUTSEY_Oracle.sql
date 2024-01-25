/*
* log into Oracle server with your .admin
* 
* pick your database instance
* 
* 
* log in with sqlplus as the sysdba
* 
* sqlplus / as sysdba
* 
* you will get the command prompt
*/

--check if account exists
SELECT COUNT(1) FROM dba_users WHERE USERNAME = 'JLUTSEY' /*RITM237056*/;

-- creates your account with a dummy password and prompts you to change it.
CREATE USER JLUTSEY
	IDENTIFIED BY "ThisWi11BeChanged!"
	DEFAULT TABLESPACE USERS
	TEMPORARY TABLESPACE TEMP
	PROFILE DBA
	ACCOUNT UNLOCK /*RITM237056*/;
GRANT DBA TO JLUTSEY /*RITM237056*/;
ALTER USER JLUTSEY DEFAULT ROLE ALL /*RITM237056*/;
GRANT SELECT ANY DICTIONARY TO JLUTSEY /*RITM237056*/;
GRANT UNLIMITED TABLESPACE TO JLUTSEY /*RITM237056*/;
GRANT EXEMPT ACCESS POLICY TO JLUTSEY /*RITM237056*/;
PASSWORD JLUTSEY /*RITM237056*/;




--check if account exists
SELECT USERNAME FROM dba_users WHERE USERNAME = 'AccountName' /*TicketNumber*/;

-- creates your account with a dummy password and prompts you to change it.
CREATE USER "AccountName"
    IDENTIFIED BY "ThisWi11BeChanged!"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE PLEXUS_USER_PROFILE
    ACCOUNT UNLOCK /*TicketNumber*/;

-- grant permissions
GRANT CREATE SESSION TO "AccountName" /*TicketNumber*/;
GRANT PLXDEV TO "AccountName" /*TicketNumber*/;

-- change password
PASSWORD "AccountName" /*TicketNumber*/;
ALTER USER "AccountName" PASSWORD EXPIRE /*TicketNumber*/;






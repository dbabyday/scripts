/*

If a new JDE admin account gets requested, the JDE application admins will create the 
application account first, then pass the task on to us for creation of the Oracle account. 
These accounts are setup differently than most, example script is below. They have a 
different profile, and they all have the same password, which is in Cyber-Ark.

Remember to add this account in both JDEPD01 and JDEPD03.

REPLACE: <SID>
         RITM471640

*/



-- jdepd01

CREATE USER "PIHT_ADMIN"
  IDENTIFIED BY "ThisWi11BeChanged!"
  HTTP DIGEST DISABLE
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE JDE_ADMIN
  PASSWORD EXPIRE
  ACCOUNT UNLOCK /*RITM471640*/;

-- 1 Role for "PIHT_ADMIN" 
GRANT JDE_ADMIN TO "PIHT_ADMIN" /*RITM471640*/;
ALTER USER "PIHT_ADMIN" DEFAULT ROLE ALL /*RITM471640*/;

-- 1 System Privilege for "PIHT_ADMIN" 
GRANT CREATE SESSION TO "PIHT_ADMIN" /*RITM471640*/;

-- 1 Tablespace Quota for "PIHT_ADMIN" 
ALTER USER "PIHT_ADMIN" QUOTA UNLIMITED ON USERS /*RITM471640*/;

-- set password to value from CyberArk: JDE_User_Admin
PASSWORD "PIHT_ADMIN" /*RITM471640*/;



-- jdepd03

CREATE USER "PIHT_ADMIN"
  IDENTIFIED BY "ThisWi11BeChanged!"
  HTTP DIGEST DISABLE
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE JDE_ADMIN
  PASSWORD EXPIRE
  ACCOUNT UNLOCK /*RITM471640*/;

-- 1 Role for "PIHT_ADMIN" 
GRANT JDE_ADMIN TO "PIHT_ADMIN" /*RITM471640*/;
ALTER USER "PIHT_ADMIN" DEFAULT ROLE ALL /*RITM471640*/;

-- 1 System Privilege for "PIHT_ADMIN" 
GRANT CREATE SESSION TO "PIHT_ADMIN" /*RITM471640*/;

-- 4 Tablespace Quotas for "PIHT_ADMIN" 
ALTER USER "PIHT_ADMIN" QUOTA UNLIMITED ON SYS7333I /*RITM471640*/;
ALTER USER "PIHT_ADMIN" QUOTA UNLIMITED ON SYS7333T /*RITM471640*/;
ALTER USER "PIHT_ADMIN" QUOTA UNLIMITED ON USERS /*RITM471640*/;

-- set password to value from CyberArk: JDE_User_Admin
PASSWORD "PIHT_ADMIN" /*RITM471640*/;

-- /orahome/admin/jdepd01/adhoc/failedlogons
ka8u2uw4t#
ka8u2uw4t#
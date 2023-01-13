CREATE USER "AccountName" 
	IDENTIFIED BY "ThisWi11BeChanged!" 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP
	PROFILE PLEXUS_USER_PROFILE 
	QUOTA UNLIMITED ON USERS /* TicketNumber */;

PASSWORD "AccountName" /* TicketNumber */;

ALTER USER "AccountName" PASSWORD EXPIRE;

GRANT CREATE SESSION TO "AccountName" /* TicketNumber */;
GRANT PLXDEV TO "AccountName" /* TicketNumber */;

ALTER USER "AccountName" DEFAULT ROLE ALL /* TicketNumber */;









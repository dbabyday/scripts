https://www.sqlskills.com/blogs/paul/disaster-recovery-101-dealing-with-negative-spids-2-and-3/
http://www.eraofdata.com/sql-server/troubleshooting-sql-server/orphaned-msdtc-transactions-2-spids/





select req_transactionUoW as [UoW ID] from syslockinfo where req_spid = -2;

select request_owner_guid as [UoW ID] from sys.dm_tran_locks where request_session_id = -2;
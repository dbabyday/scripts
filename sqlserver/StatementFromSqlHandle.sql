----------------------------------------------------------------------------------------------
--                 GET SQL STATEMENT/SPROC FROM A SQL HANDLE
----------------------------------------------------------------------------------------------

-- http://msdn.microsoft.com/en-us/library/ms181929.aspx?PHPSESSID=ev0v34i8u80gkmn37sd8r65363

-- Note that the sqlhandle identifier is not passed as a literal



SELECT sql_handle AS Handle,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS Text

FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE sql_handle = --0x04000D00E3572A56542E4601CE9E00010100001000000000

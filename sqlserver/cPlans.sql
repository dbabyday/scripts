/*

	http://www.sommarskog.se/query-plan-mysteries.html#ssmsgettingplans

*/

DECLARE @dbname    nvarchar(256) = N'GSF2_AMER_PROD',
        @procname  nvarchar(256) = N'dbo.usp_RunningLicensePlatePostSMTByWorkOrderNumber_Select';

; WITH basedata AS   (  SELECT      qs.statement_start_offset/2 AS stmt_start
                                  , qs.statement_end_offset/2 AS stmt_end
                                  , est.encrypted AS isencrypted
								  , est.text AS sqltext
                                  , epa.value AS set_options
								  , qp.query_plan
                                  , charindex('<ParameterList>', qp.query_plan) + len('<ParameterList>')AS paramstart
                                  , charindex('</ParameterList>', qp.query_plan) AS paramend
                        FROM        sys.dm_exec_query_stats qs
                        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) est
                        CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle,qs.statement_start_offset,qs.statement_end_offset) qp
                        CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) epa
                        WHERE       est.objectid  = object_id (@procname)
                                    AND est.dbid      = db_id(@dbname)
                                    AND epa.attribute = 'set_options'
                     )
     , next_level AS (  SELECT stmt_start
     	                     , set_options
     	                     , query_plan
     	                     , CASE WHEN isencrypted = 1 THEN '-- ENCRYPTED'
                                    WHEN stmt_start >= 0 THEN substring(sqltext, stmt_start + 1, CASE stmt_end WHEN 0 THEN datalength(sqltext)
                                                                                                               ELSE stmt_end - stmt_start + 1
                                                                                                               END)
                               END AS Statement
                             , CASE WHEN paramend > paramstart THEN CAST (substring(query_plan, paramstart, paramend - paramstart) AS xml)
                               END AS params
                        FROM   basedata
                     )
SELECT set_options
     , n.stmt_start
	 , n.statement
     , (SELECT CR.c.value('@Column', 'nvarchar(128)') + ' = ' +
               CR.c.value('@ParameterCompiledValue', 'nvarchar(512)') + ', '
       FROM    n.params.nodes('ColumnReference') AS CR(c)
       FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)') AS sniffed_values
	 , CAST (query_plan AS xml) AS query_plan
FROM   next_level n
ORDER  BY n.set_options, n.stmt_start;


/*

-- select @@options;

DECLARE @setoptions1 INT = 249
      , @setoptions2 INT = 0;

/*************************************************************** 
Author: John Morehouse  
Summary: This script display what SET options are enabled for the current session.  
You may alter this code for your own purposes. You may republish altered code as long as you give due credit.  
THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
***************************************************************/  
SELECT 'DISABLE_DEF_CNST_CHK'    AS 'option', CASE @setoptions1 & 1     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 1     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 1)     - (@setoptions2 & 1)     WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'IMPLICIT_TRANSACTIONS'   AS 'option', CASE @setoptions1 & 2     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 2     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 2)     - (@setoptions2 & 2)     WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'CURSOR_CLOSE_ON_COMMIT'  AS 'option', CASE @setoptions1 & 4     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 4     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 4)     - (@setoptions2 & 4)     WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ANSI_WARNINGS'           AS 'option', CASE @setoptions1 & 8     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 8     WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 8)     - (@setoptions2 & 8)     WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ANSI_PADDING'            AS 'option', CASE @setoptions1 & 16    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 16    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 16)    - (@setoptions2 & 16)    WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ANSI_NULLS'              AS 'option', CASE @setoptions1 & 32    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 32    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 32)    - (@setoptions2 & 32)    WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ARITHABORT'              AS 'option', CASE @setoptions1 & 64    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 64    WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 64)    - (@setoptions2 & 64)    WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ARITHIGNORE'             AS 'option', CASE @setoptions1 & 128   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 128   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 128)   - (@setoptions2 & 128)   WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'QUOTED_IDENTIFIER'       AS 'option', CASE @setoptions1 & 256   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 256   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 256)   - (@setoptions2 & 256)   WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'NOCOUNT'                 AS 'option', CASE @setoptions1 & 512   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 512   WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 512)   - (@setoptions2 & 512)   WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ANSI_NULL_DFLT_ON'       AS 'option', CASE @setoptions1 & 1024  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 1024  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 1024)  - (@setoptions2 & 1024)  WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'ANSI_NULL_DFLT_OFF'      AS 'option', CASE @setoptions1 & 2048  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 2048  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 2048)  - (@setoptions2 & 2048)  WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'CONCAT_NULL_YIELDS_NULL' AS 'option', CASE @setoptions1 & 4096  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 4096  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 4096)  - (@setoptions2 & 4096)  WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'NUMERIC_ROUNDABORT'      AS 'option', CASE @setoptions1 & 8192  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 8192  WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 8192)  - (@setoptions2 & 8192)  WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different' UNION  
SELECT 'XACT_ABORT'              AS 'option', CASE @setoptions1 & 16384 WHEN 0 THEN 0 ELSE 1 END AS 'off/on 1', CASE @setoptions2 & 16384 WHEN 0 THEN 0 ELSE 1 END AS 'off/on 2', CASE (@setoptions1 & 16384) - (@setoptions2 & 16384) WHEN 0 THEN '' ELSE 'DIFFERENT' END AS 'different'  
ORDER BY 'option';

*/


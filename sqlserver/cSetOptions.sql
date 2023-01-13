-- select @@options;

DECLARE @setoptions1 INT = 0
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


/***********************************************************************************************
*
*  Author:  Lee Hart
*  Date:    06/04/2015
*  Purpose: Co-db-042 for review in central admin database for a general listing of 
*           all database servers.
*
***********************************************************************************************/

-- Run on CO-DB-042
SELECT  rs.server_name, sg.name AS groupname
       FROM    msdb.dbo.sysmanagement_shared_server_groups_internal sg
                     LEFT JOIN msdb.dbo.sysmanagement_shared_registered_servers_internal rs ON sg.server_group_id = rs.server_group_id
       WHERE   sg.server_type = 0 --only the Database Engine Server Group
                     AND rs.server_name IS NOT NULL
       GROUP BY rs.server_name, sg.name 
       ORDER BY 1

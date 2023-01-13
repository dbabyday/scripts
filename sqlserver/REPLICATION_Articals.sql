/*

    get list of articles and their columns along with their destinations

    run on pulication db

*/


--  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];

USE [GSFGlobal_PROD];

SELECT     pub.name AS [Publication], 
           art.name AS [Article], 
           STUFF( 
                    ( 
                        SELECT     ', ' + [syscolumns].[name] AS [text()] 
                        FROM       [sysarticlecolumns] 
                        INNER JOIN [syscolumns] ON [sysarticlecolumns].[colid] = [syscolumns].[colorder] 
                        WHERE      [sysarticlecolumns].[artid] = [art].[artid] 
                                   AND [art].[objid] = [syscolumns].[id] 
                        ORDER BY   [syscolumns].[colorder] 
                        FOR XML PATH('') 
                    ), 1, 2, '' 
                ) AS [Columns],
           [sub].[srvname] AS [DestinationServer],
           [sub].[dest_db] AS [DestinationDatabase],
           [art].[dest_table],
           CASE WHEN [sub].[subscription_type] = 1 THEN 'Pull' ELSE 'Push' END AS [SubscriptionType]
FROM       [dbo].[syspublications] AS [pub]
INNER JOIN [dbo].[sysarticles] AS [art] ON [art].[pubid] = [pub].[pubid]
INNER JOIN [dbo].[syssubscriptions] AS [sub] ON [art].[artid] = [sub].[artid]
ORDER BY   [pub].[name], 
           [art].[name],
           [sub].[dest_db];


CREATE EVENT SESSION [XE_Logons] ON SERVER 
ADD EVENT   sqlserver.login 
            (   
                SET collect_database_name = (1),
                    collect_options_text = (1)
                ACTION 
                (   
                    sqlserver.client_app_name,
                    sqlserver.client_connection_id,
                    sqlserver.client_hostname,
                    sqlserver.context_info,
                    sqlserver.server_instance_name,
                    sqlserver.server_principal_name
                )
                WHERE  
                (   
                    [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\srvcmsqldev.neen') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\srvcCV_SQL.neen') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\Srvcscomsql.plx') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NT AUTHORITY\SYSTEM') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\james.lutsey.admin')
                )
            ),
ADD EVENT   sqlserver.logout
            (
                ACTION 
                (   
                    sqlserver.client_app_name,
                    sqlserver.client_connection_id,
                    sqlserver.client_hostname,
                    sqlserver.context_info,
                    sqlserver.server_instance_name,
                    sqlserver.server_principal_name,
                    sqlserver.session_id
                )
                WHERE
                (   
                    [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\srvcmsqldev.neen') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\srvcCV_SQL.neen') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\Srvcscomsql.plx') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NT AUTHORITY\SYSTEM') 
                    AND [sqlserver].[not_equal_i_sql_unicode_string]([sqlserver].[server_principal_name],N'NA\james.lutsey.admin')
                )
            )
ADD TARGET package0.event_file
           (
               SET filename = N'F:\Traces\XE_Logons.xel'
           )
WITH       
           (   
               MAX_MEMORY            = 4096 KB,
               EVENT_RETENTION_MODE  = ALLOW_SINGLE_EVENT_LOSS,
               MAX_DISPATCH_LATENCY  = 30 SECONDS,
               MAX_EVENT_SIZE        = 0 KB,
               MEMORY_PARTITION_MODE = NONE,
               TRACK_CAUSALITY       = ON,
               STARTUP_STATE         = OFF
           );
GO



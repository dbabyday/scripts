SELECT          [s].[name],
N'
USE [master];
GO

IF NOT EXISTS(SELECT [name] FROM [sys].[servers] WHERE [server_id] != 0 AND [name] = N''' + [s].[name] + N''')
BEGIN
    EXECUTE [master].[dbo].[sp_addlinkedserver] @server     = N''' + [s].[name] + N''', 
                                                @srvproduct = N''' + [s].[product] + N''';
    
    EXECUTE [master].[dbo].[sp_addlinkedsrvlogin] @rmtsrvname  = N''' + [s].[name] + N''',
                                                  @useself     = '''  + CASE [l].[uses_self_credential] WHEN 1 THEN N'TRUE' ELSE N'FALSE' END + N''',
                                                  @locallogin  = '    + CASE [l].[uses_self_credential] WHEN 1 THEN N'NULL' ELSE COALESCE(N'''' + [p].[name] + '''',N'NULL') END + N',
                                                  @rmtuser     = '    + CASE WHEN [l].[remote_name] IS NULL THEN N'NULL' ELSE N'''' + [l].[remote_name] + '''' END + N',
                                                  @rmtpassword = '    + CASE WHEN [l].[remote_name] IS NULL THEN N'NULL;' ELSE N'''SuperSecretPassword;  --<---- Enter the password here''' END + N'
END

EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''collation compatible'',              @optvalue = ''' + CASE [s].[is_collation_compatible] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''collation name'',                    @optvalue = ' + COALESCE(N'''' + [s].[collation_name] + N'''',N'NULL') + N';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''connect timeout'',                   @optvalue = ''' + CAST([s].[connect_timeout] AS NVARCHAR(10)) + ''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''data access'',                       @optvalue = ''' + CASE [s].[is_data_access_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''dist'',                              @optvalue = ''' + CASE [s].[is_distributor] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''lazy schema validation'',            @optvalue = ''' + CASE [s].[lazy_schema_validation] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''pub'',                               @optvalue = ''' + CASE [s].[is_publisher] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''query timeout'',                     @optvalue = ''' + CAST([s].[query_timeout] AS NVARCHAR(10)) + ''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''rpc'',                               @optvalue = ''' + CASE [s].[is_remote_login_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''rpc out'',                           @optvalue = ''' + CASE [s].[is_rpc_out_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''sub'',                               @optvalue = ''' + CASE [s].[is_subscriber] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''use remote collation'',              @optvalue = ''' + CASE [s].[uses_remote_collation] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';
EXECUTE [master].[dbo].[sp_serveroption] @server = N''' + [s].[name] + N''', @optname = ''remote proc transaction promotion'', @optvalue = ''' + CASE [s].[is_remote_proc_transaction_promotion_enabled] WHEN 0 THEN N'FALSE' ELSE N'TRUE' END + N''';

GO
'
FROM            [sys].[servers] AS [s]
LEFT OUTER JOIN [sys].[linked_logins] AS [l] ON [l].[server_id] = [s].[server_id]
LEFT OUTER JOIN [sys].[server_principals] AS [p] ON [p].[principal_id] = [l].[local_principal_id]
ORDER BY        [s].[name];
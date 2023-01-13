-- rename default constraints

--  SELECT 'USE ' + QUOTENAME([name]) + ';' FROM [sys].[databases] ORDER BY [name];



SELECT   QUOTENAME(SCHEMA_NAME([d].[schema_id])) + N'.' + QUOTENAME(OBJECT_NAME([d].[parent_object_id])) + N'.' + QUOTENAME([c].[name]) AS [column_name],
         [d].[name] AS [current_name],
         N'DF_' + OBJECT_NAME([d].[parent_object_id]) + N'_' + [c].[name] AS [new_name],
         N'EXECUTE sp_rename @objname = N''' + QUOTENAME(SCHEMA_NAME([d].[schema_id])) + N'.' + QUOTENAME([d].[name]) + N''', ' + CHAR(13) + CHAR(10) + 
         N'                  @newname = N''DF_' + OBJECT_NAME([d].[parent_object_id]) + N'_' + [c].[name] + N''', ' + CHAR(13) + CHAR(10) +
         N'                  @objtype = N''OBJECT'';' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) AS [sql_command]
FROM     [sys].[default_constraints] AS [d]
JOIN     [sys].[columns] AS [c] ON  [d].[parent_object_id] = [c].[object_id]
                                AND [d].[parent_column_id] = [c].[column_id]
WHERE    [d].[name] != N'DF_' + OBJECT_NAME([d].[parent_object_id]) + N'_' + [c].[name]
         --AND QUOTENAME(SCHEMA_NAME([d].[schema_id])) + N'.' + QUOTENAME(OBJECT_NAME([d].[parent_object_id])) + N'.' + QUOTENAME([c].[name]) IN ('[dbo].[ACRDetail].[OriRequestQty]',
         --                                                                                                                                       '[dbo].[ItemMaster].[LastBinned]',
         --                                                                                                                                       '[dbo].[ItemMaster].[MinQty]',
         --                                                                                                                                       '[dbo].[ItemMaster].[SMI_LP_Splitting]',
         --                                                                                                                                       '[dbo].[JDELocationMaster].[ExternalWH]',
         --                                                                                                                                       '[dbo].[JDELocationMaster].[isNCM]',
         --                                                                                                                                       '[dbo].[JDELocationMaster].[IsRI]',
         --                                                                                                                                       '[dbo].[JDELocationMaster].[ISSMI]',
         --                                                                                                                                       '[dbo].[ManualKittingList].[PushToIIVS]',
         --                                                                                                                                       '[dbo].[StorageType].[IsSMI]',
         --                                                                                                                                       '[dbo].[tbl_BGMS_Interim_WMSProcess].[OperationSequence]',
         --                                                                                                                                       '[dbo].[tbl_BGMS_Interim_WMSProcess].[ProcessInProgress]',
         --                                                                                                                                       '[dbo].[tbl_BGMS_Interim_WMSSplitting].[ProcessInProgress]',
         --                                                                                                                                       '[dbo].[tbl_WMS_ExternalWH_ProcessDetails].[IsAdditional]',
         --                                                                                                                                       '[dbo].[WHInventory].[IA10]',
         --                                                                                                                                       '[dbo].[WHInventory].[LastBinned]')
ORDER BY 1,2;
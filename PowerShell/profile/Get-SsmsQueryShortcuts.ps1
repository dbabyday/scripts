Write-Host
Write-Host
Write-Host "Alt + F1 : sp_help"
Write-Host "Ctrl + F1 : select object_schema_name(object_id)+N'.'+name as tables from sys.tables order by 1;"
Write-Host "Ctrl + 1 : sp_who"
Write-Host "Ctrl + 2 : sp_lock"
Write-Host "Ctrl + 3 : select '/* my spid: ' + cast(@@spid as varchar(12)) + ' */' as my_spid"
Write-Host "Ctrl + 4 : sp_cColumns"
Write-Host "Ctrl + 5 : sp_cObject"
Write-Host
Write-Host

Write-Host
Write-Host
Write-Host "Alt + F1  : sp_help"
Write-Host "Ctrl + F1 : select object_schema_name(object_id)+N'.'+name as tables from sys.tables order by 1;"
Write-Host "Ctrl + 1  : sp_who"
Write-Host "Ctrl + 2  : sp_lock"
Write-Host "Ctrl + 3  : sp_WhoIsActive"
Write-Host "Ctrl + 4  : execute sp_BlitzFirst @ExpertMode=1, @Seconds=60;"
Write-Host "Ctrl + 5  : select top(100) * from"
Write-Host "Ctrl + 6  : select count(1) from"
Write-Host "Ctrl + 7  : sp_cColumns"
Write-Host "Ctrl + 8  : sp_cObject"
Write-Host "Ctrl + 9  : select '/* my spid: ' + cast(@@spid as varchar(12)) + ' */' as my_spid"
Write-Host "Ctrl + 0  : execute sp_whoisactive @filter = 'NA\james.lutsey.admin', @filter_type = 'login';"
Write-Host
Write-Host

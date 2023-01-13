/*********************************************************************************************************************
* 
* JOBS_UpdateBackupHomeDir.sql
* 
* Author: James Lutsey
* Date:   2019-01-03
* 
* Purpose: Updates the home directory in the DBA backup job steps' command and output_file_name parameters
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/



use msdb;



----------------------------------------------
--// USER INPUT                           //--
----------------------------------------------

declare @currentHomeDir   as nvarchar(128) = N'\\ap\xiamdata\Site\SQLBackup\'
      , @newHomeDir       as nvarchar(128) = N'\\ap\hangdata\Site\sqlbackup\pd\';



----------------------------------------------
--// DECLARATIONS                         //--
----------------------------------------------

declare @myJobName        as nvarchar(128)
      , @myStepId         as int
      , @myCommand        as nvarchar(max)
      , @myOutputFileName as nvarchar(200);

-- cursor to loop through all applicable job steps --> get the steps' commands and outputfiles as updated values with the new home directory
declare steps cursor local fast_forward for
    select   j.name
           , s.step_id
           , replace(s.command,@currentHomeDir,@newHomeDir)
           , replace(s.output_file_name,@currentHomeDir,@newHomeDir)
    from     dbo.sysjobs     as j
    join     dbo.sysjobsteps as s on s.job_id = j.job_id
    where    j.name in (   N'DBA - Backup SYSTEM_DATABASES - FULL'
                         , N'DBA - Backup USER_DATABASES - DIFF'
                         , N'DBA - Backup USER_DATABASES - FULL'
                         , N'DBA - Backup USER_DATABASES - LOG'  );



----------------------------------------------
--// EXECUTE THE UPDATES                  //--
----------------------------------------------

open steps;
    fetch next from steps into @myJobName, @myStepId, @myCommand, @myOutputFileName;

    while @@fetch_status = 0
    begin
        -- update the step with the new directory in the command and output_file_name
        execute dbo.sp_update_jobstep @job_name         = @myJobName
                                    , @step_id          = @myStepId
                                    , @command          = @myCommand
                                    , @output_file_name = @myOutputFileName;

        fetch next from steps into @myJobName, @myStepId, @myCommand, @myOutputFileName;
    end;
close steps;
deallocate steps;



----------------------------------------------
--// DISPLAY RESULTS                      //--
----------------------------------------------

-- display results for review
select   j.name
       , s.step_id
       , s.step_name
       , s.command
       , s.output_file_name
       , case when output_file_name is not null then N'execute dbo.sp_update_jobstep @job_name = N''' + j.name + N'''
                            , @step_id  = ' + cast(s.step_id as nvarchar(11)) + N'
                            , @command  = N''' + replace(s.command,N'''',N'''''') + N'''
                            , @output_file_name = N''' + replace(s.output_file_name,N'''',N'''''') + N''';'
              else N'execute dbo.sp_update_jobstep @job_name = N''' + j.name + N'''
                            , @step_id  = ' + cast(s.step_id as nvarchar(11)) + N'
                            , @command  = N''' + replace(s.command,N'''',N'''''') + N''';'
         end as update_cmd
from     dbo.sysjobs     as j
join     dbo.sysjobsteps as s on s.job_id = j.job_id
where    j.name in (   N'DBA - Backup SYSTEM_DATABASES - FULL'
                     , N'DBA - Backup USER_DATABASES - DIFF'
                     , N'DBA - Backup USER_DATABASES - FULL'
                     , N'DBA - Backup USER_DATABASES - LOG'  )
order by j.name
       , s.step_id;





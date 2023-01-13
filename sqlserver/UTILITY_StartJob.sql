/*

SELECT
    j.name,
    j.job_id,
    [enabled] = 
        CASE enabled
            WHEN 0 THEN 'disabled'
            WHEN 1 THEN 'yes'
        END,
    s.step_name,
    s.step_id
FROM 
    msdb..sysjobs AS j
JOIN
    msdb..sysjobsteps AS s
    ON j.job_id = s.job_id
    -- WHERE
    --     j.name = ''
ORDER BY
    j.name,
    s.step_id

*/

EXEC msdb.dbo.sp_start_job 
    @job_name = ''
   --, @step_name = ''



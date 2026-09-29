use GSF2_AMER_QA;

select 'target' which_one ,count(1) total_rows from Reference.TrainingProgram
union all
select 'source' which_one ,count(1) total_rows from [DCC-SQL-QA-010].GSF2_AMER_QA.Reference.TrainingProgram;


begin transaction;

set identity_insert Reference.TrainingProgram on;



-- updates
update
	t
set
	  t.Code=s.Code
	, t.Description=s.Description
	, t.ReferenceIdTrainingProgramCodeRegion=s.ReferenceIdTrainingProgramCodeRegion
	, t.IsActive=s.IsActive
	, t.Source=s.Source
	, t.SourceSystemID=s.SourceSystemID
	, t.DateEffectiveIn=s.DateEffectiveIn
	, t.DateEffectiveOut=s.DateEffectiveOut
from
	[DCC-SQL-QA-010].GSF2_AMER_QA.Reference.TrainingProgram s
join
	Reference.TrainingProgram t on t.TrainingProgramId=s.TrainingProgramId;




--inserts
insert into Reference.TrainingProgram (
	  TrainingProgramId
	, Code
	, Description
	, ReferenceIdTrainingProgramCodeRegion
	, IsActive
	, Source
	, SourceSystemID
	, DateEffectiveIn
	, DateEffectiveOut
)
select
	  s.TrainingProgramId
	, s.Code
	, s.Description
	, s.ReferenceIdTrainingProgramCodeRegion
	, s.IsActive
	, s.Source
	, s.SourceSystemID
	, s.DateEffectiveIn
	, s.DateEffectiveOut
from
	[DCC-SQL-QA-010].GSF2_AMER_QA.Reference.TrainingProgram s
where
	s.TrainingProgramId not in (select TrainingProgramId from Reference.TrainingProgram);

-- deletes
delete
	t
from
	Reference.TrainingProgram t
left join
	[DCC-SQL-QA-010].GSF2_AMER_QA.Reference.TrainingProgram s on t.TrainingProgramId=s.TrainingProgramId
where
	s.TrainingProgramId is null;



set identity_insert Reference.TrainingProgram off;


-- ROLLBACK TRANSACTION;
-- COMMIT TRANSACTION;
-- SELECT @@TRANCOUNT AS [TransactionCount];


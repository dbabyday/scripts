USE master;
GO
CREATE OR ALTER PROCEDURE dbo.sp_RaiserrorTime
	  @p_msg_str nvarchar(max)
	, @p_severity int = 10
	, @p_state int = 1
AS
	SET NOCOUNT ON;
	SET @p_msg_str = CONVERT(nvarchar(19),getdate(),120) + N' - ' + @p_msg_str;
	RAISERROR(@p_msg_str, @p_severity, @p_state) WITH NOWAIT;
GO
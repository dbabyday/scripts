---------------------------------------------------------------
--// usp_hexadecimal                                       //--
---------------------------------------------------------------

USE [CentralAdmin];
GO

IF OBJECT_ID (N'dbo.usp_hexadecimal',N'P') IS NULL
    EXECUTE(N'CREATE PROCEDURE [dbo].[usp_hexadecimal] AS ;');
GO

ALTER PROCEDURE [dbo].[usp_hexadecimal]
    @binvalue VARBINARY(256),
    @hexvalue NVARCHAR(514) OUTPUT
AS

SET NOCOUNT ON;

DECLARE @charvalue NVARCHAR(514) = N'0x',
        @i         INT          = 1,
        @length    INT,
        @hexstring CHAR(16),
        @tempint   INT,
        @firstint  INT,
        @secondint INT;

SET @length    = DATALENGTH(@binvalue);
SET @hexstring = N'0123456789ABCDEF';

WHILE (@i <= @length)
BEGIN
    SET @tempint   = CONVERT(int, SUBSTRING(@binvalue,@i,1));
    SET @firstint  = FLOOR(@tempint/16);
    SET @secondint = @tempint - (@firstint*16);
    SET @charvalue = @charvalue +
                     SUBSTRING(@hexstring, @firstint+1, 1) +
                     SUBSTRING(@hexstring, @secondint+1, 1);
    SET @i += 1;
END

SET @hexvalue = @charvalue;
GO
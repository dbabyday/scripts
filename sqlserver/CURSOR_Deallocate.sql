IF CURSOR_STATUS('global','myCursor') >= -1
BEGIN
	IF CURSOR_STATUS('global','myCursor') > -1
		CLOSE myCursor;

	DEALLOCATE myCursor;
END 
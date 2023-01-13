/*
       This will return the AD group or role from which the user is gaining permissions.
       This is useful when a user is a member of an AD group that is part of another
       AD group (etc) that has DB access.
*/

EXECUTE AS LOGIN = 'EU\Jiri.Ondrousek';
SELECT * FROM  [sys].[user_token];
REVERT;

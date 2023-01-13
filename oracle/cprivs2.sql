clear columns
undefine USER_NAME

col privilege format a
col obj_name format a40
col username format a30
col grant_sources format a50
col admin_or_grant_opt format a18
col hierarchy_opt format a13


SELECT   PRIVILEGE
       , OBJ_OWNER||'.'||OBJ_NAME AS OBJ_NAME
       , USERNAME
       , LISTAGG(GRANT_TARGET, ',') WITHIN GROUP (ORDER BY GRANT_TARGET) AS GRANT_SOURCES -- Lists the sources of the permission
       , MAX(ADMIN_OR_GRANT_OPT) AS ADMIN_OR_GRANT_OPT -- MAX acts as a Boolean OR by picking 'YES' over 'NO'
       , MAX(HIERARCHY_OPT) AS HIERARCHY_OPT -- MAX acts as a Boolean OR by picking 'YES' over 'NO'
FROM     (  -- Gets all roles a user has, even inherited ones
            WITH ALL_ROLES_FOR_USER AS (  SELECT DISTINCT CONNECT_BY_ROOT GRANTEE AS GRANTED_USER
                                                        , GRANTED_ROLE
                                          FROM            DBA_ROLE_PRIVS
                                          CONNECT BY      GRANTEE = PRIOR GRANTED_ROLE  
                                       )
            SELECT PRIVILEGE
                 , OBJ_OWNER
                 , OBJ_NAME
                 , USERNAME
                 , REPLACE(GRANT_TARGET, USERNAME, 'Direct to user') AS GRANT_TARGET
                 , ADMIN_OR_GRANT_OPT
                 , HIERARCHY_OPT
            FROM   (  -- System privileges granted directly to users
                      SELECT PRIVILEGE
                           , NULL         AS OBJ_OWNER
                           , NULL         AS OBJ_NAME
                           , GRANTEE      AS USERNAME
                           , GRANTEE      AS GRANT_TARGET
                           , ADMIN_OPTION AS ADMIN_OR_GRANT_OPT
                           , NULL         AS HIERARCHY_OPT
                      FROM   DBA_SYS_PRIVS
                      WHERE  GRANTEE IN (SELECT USERNAME FROM DBA_USERS)
                      UNION ALL
                      -- System privileges granted users through roles
                      SELECT PRIVILEGE
                           , NULL                            AS OBJ_OWNER
                           , NULL                            AS OBJ_NAME
                           , ALL_ROLES_FOR_USER.GRANTED_USER AS USERNAME
                           , GRANTEE                         AS GRANT_TARGET
                           , ADMIN_OPTION                    AS ADMIN_OR_GRANT_OPT
                           , NULL                            AS HIERARCHY_OPT
                      FROM   DBA_SYS_PRIVS
                      JOIN   ALL_ROLES_FOR_USER ON ALL_ROLES_FOR_USER.GRANTED_ROLE = DBA_SYS_PRIVS.GRANTEE
                      UNION ALL
                      -- Object privileges granted directly to users
                      SELECT PRIVILEGE
                           , OWNER AS OBJ_OWNER
                           , TABLE_NAME AS OBJ_NAME
                           , GRANTEE AS USERNAME
                           , GRANTEE AS GRANT_TARGET
                           , GRANTABLE
                           , HIERARCHY
                      FROM   DBA_TAB_PRIVS
                      WHERE  GRANTEE IN (SELECT USERNAME FROM DBA_USERS)
                      UNION ALL
                      -- Object privileges granted users through roles
                      SELECT PRIVILEGE
                           , OWNER AS OBJ_OWNER
                           , TABLE_NAME AS OBJ_NAME
                           , GRANTEE AS USERNAME
                           , ALL_ROLES_FOR_USER.GRANTED_ROLE AS GRANT_TARGET
                           , GRANTABLE
                           , HIERARCHY
                      FROM   DBA_TAB_PRIVS
                      JOIN   ALL_ROLES_FOR_USER ON ALL_ROLES_FOR_USER.GRANTED_ROLE = DBA_TAB_PRIVS.GRANTEE  
                   ) ALL_USER_PRIVS
            -- Adjust your filter here
            WHERE USERNAME = '&USER_NAME'
         ) DISTINCT_USER_PRIVS
GROUP BY PRIVILEGE
       , OBJ_OWNER
       , OBJ_NAME
       , USERNAME;

undefine USER_NAME

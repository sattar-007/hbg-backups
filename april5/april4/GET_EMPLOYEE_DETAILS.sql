--------------------------------------------------------
--  DDL for Procedure GET_EMPLOYEE_DETAILS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "HBG_INTEGRATION"."GET_EMPLOYEE_DETAILS" (
  p_empno     IN  varchar2,
  p_employee  OUT SYS_REFCURSOR
)
AS
BEGIN
  OPEN p_employee FOR
    SELECT *
    FROM   hz_cust_accounts
    WHERE  ACCOUNT_NUMBER = p_empno;
EXCEPTION
  WHEN OTHERS THEN
    p_employee := NULL;
END;


/

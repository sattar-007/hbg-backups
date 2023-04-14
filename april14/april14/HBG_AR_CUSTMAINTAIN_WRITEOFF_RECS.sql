--------------------------------------------------------
--  DDL for Type HBG_AR_CUSTMAINTAIN_WRITEOFF_RECS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_WRITEOFF_RECS" as object 
      (   group_id  NUMBER,
        p_jrnl_name   VARCHAR2(240),
        p_ledger_id   VARCHAR2(240),
        p_period_name  VARCHAR2(240),
        p_acct_prd     VARCHAR2(240),
        user_je_src     VARCHAR2(240),
        user_je_cat    VARCHAR2(240),
        code_comb_id  number,
        debit_amount number, 
        credit_amount number,
    CONSTRUCTOR FUNCTION "HBG_AR_CUSTMAINTAIN_WRITEOFF_RECS"
        RETURN  SELF AS  RESULT 
); 
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_WRITEOFF_RECS" 
AS
    CONSTRUCTOR FUNCTION "HBG_AR_CUSTMAINTAIN_WRITEOFF_RECS"
        RETURN  SELF AS  RESULT 
    AS
    BEGIN
        RETURN;
    END;
END;


/

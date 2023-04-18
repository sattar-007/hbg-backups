--------------------------------------------------------
--  DDL for Type HBG_AR_CUSTMAINTAIN_TRX_RT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_TRX_RT" is object ( 
    org_number varchar2(240),
    org_name varchar2(240),
    account_balance number,
    unapplied_amount number,
    invoice_total number,
    claim_total number,
    credit_total number,
    tier varchar2(30),
    tax_exempt varchar2(30),
    currency varchar2(30),
    transaction_details HBG_AR_CUSTMAINTAIN_TRX_DETAILS_TT,
    CONSTRUCTOR FUNCTION "HBG_AR_CUSTMAINTAIN_TRX_RT"   RETURN SELF AS RESULT )
	
	
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_TRX_RT" 
AS
    CONSTRUCTOR FUNCTION "HBG_AR_CUSTMAINTAIN_TRX_RT"
        RETURN  SELF AS  RESULT 
    AS
    BEGIN
        RETURN;
    END;
END;

/

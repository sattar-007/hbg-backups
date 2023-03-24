--------------------------------------------------------
--  DDL for Type HBG_AR_CUSTMAINTAIN_TRX_DETAILS_RT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_TRX_DETAILS_RT" as object (trx_key number,
    transaction_id number,
    cust_account_id number,
    party_id number,
    account_number varchar2(240),
    account_name varchar2(240), 
    org_nbr varchar2(240),
    trx_code varchar2(240),
    trx_type varchar2(240),
    flag_code varchar2(240),
    claim_number varchar2(240),
    invoice_ref_num varchar2(240),
    invoice_po_number varchar2(240),
    invoice_number varchar2(240),
    amount number,
    due_date varchar2(240),
    trx_date varchar2(240),
    aging_cat varchar2(240),
    status varchar2(240),
    payment_terms varchar2(240),
    edi_trans_date varchar2(240),
    edi_ack_date varchar2(240),
    edi_remit_date varchar2(240),
    trx_class varchar2(240),
    submitted_by varchar2(240)
)
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."HBG_AR_CUSTMAINTAIN_TRX_DETAILS_RT" 
AS
    CONSTRUCTOR FUNCTION "HBG_AR_CUSTMAINTAIN_TRX_DETAILS_RT"
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/

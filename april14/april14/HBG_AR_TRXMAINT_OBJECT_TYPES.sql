--------------------------------------------------------
--  DDL for Package HBG_AR_TRXMAINT_OBJECT_TYPES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_AR_TRXMAINT_OBJECT_TYPES" hbg_ar_trxmaint_object_types
as

type transaction_details_rt is record (trx_key number,
    transaction_id number,
    cust_account_id number,
    party_id number,
    account_number varchar2(240),
    account_name varchar2(240),
    party_number varchar2(240),
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
    edi_remit_date varchar2(240)
);
 TYPE transaction_details_tt IS TABLE OF transaction_details_rt;
type transactions_rt is record (trx_key number,
    org_number varchar2(240),
    org_name varchar2(240),
    account_balance number,
    unapplied_amount number,
    invoice_total number,
    claim_total number,
    credit_total number,
    trsnasaction_details transaction_details_tt);

 TYPE transactions_tt IS TABLE OF   transactions_rt ;
     
end;

/

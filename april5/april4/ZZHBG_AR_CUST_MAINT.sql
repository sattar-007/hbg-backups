--------------------------------------------------------
--  DDL for Package ZZHBG_AR_CUST_MAINT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."ZZHBG_AR_CUST_MAINT" AS
    PROCEDURE search_transactions (
        p_acct_nbr       IN VARCHAR2,
        p_org            IN VARCHAR2,
        p_trx_code       IN VARCHAR2,
        p_trxtype_reason IN VARCHAR2,
        p_flag_code      IN VARCHAR2,
        p_claim_nbr      IN VARCHAR2,
        p_shipment_nbr   IN VARCHAR2,
        p_inv_ref_nbr    IN VARCHAR2,
        p_inv_po_nbr     IN VARCHAR2,
        p_aging_cat      IN VARCHAR2,
        p_trx_from_date  IN VARCHAR2,
        p_trx_to_date    IN VARCHAR2,
        p_inv_num_from   IN VARCHAR2,
        p_inv_num_to     IN VARCHAR2,
        p_status         IN VARCHAR2,
        p_amt_from       IN VARCHAR2,
        p_amt_to         IN VARCHAR2,
        p_include_inv    IN VARCHAR2,
        p_include_cm     IN VARCHAR2,
        p_include_claim  IN VARCHAR2,
        x_transactions   OUT sys_refcursor
    );  
    end;

/

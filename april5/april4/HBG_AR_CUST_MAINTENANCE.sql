--------------------------------------------------------
--  DDL for Package HBG_AR_CUST_MAINTENANCE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_AR_CUST_MAINTENANCE" AS

    g_held_threshold_time number default 30;  -- 30 mins

    PROCEDURE search_transactions (
        p_acct_nbr               IN VARCHAR2,
        p_org                    IN VARCHAR2,
        p_trx_code               IN VARCHAR2,
        p_trxtype_reason         IN VARCHAR2,
        p_flag_code              IN VARCHAR2,
        p_claim_nbr              IN VARCHAR2,
        p_shipment_nbr           IN VARCHAR2,
        p_inv_ref_nbr            IN VARCHAR2,
        p_inv_po_nbr             IN VARCHAR2,
        p_aging_cat              IN VARCHAR2,
        p_trx_from_date          IN VARCHAR2,
        p_trx_to_date            IN VARCHAR2,
        p_inv_num_from           IN VARCHAR2,
        p_inv_num_to             IN VARCHAR2,
        p_status                 IN VARCHAR2,
        p_amt_from               IN VARCHAR2,
        p_amt_to                 IN VARCHAR2,
        p_include_inv            IN VARCHAR2,
        p_include_cm             IN VARCHAR2,
        p_include_claim          IN VARCHAR2,
        p_include_unapp_receipts IN VARCHAR2,
        p_loggedin_user          IN VARCHAR2,
        p_held_by_others         IN VARCHAR2,
        p_process_id             IN NUMBER,
        x_transactions           OUT nocopy clob,
        p_ret_status             OUT nocopy VARCHAR2,
        p_error_msg              OUT nocopy VARCHAR2
    );

    PROCEDURE create_trx_activity (
        p_data   IN BLOB,
        p_status OUT nocopy VARCHAR2,
        p_process_id out number
    );

    PROCEDURE store_selected_records (
        p_data   IN BLOB,
        p_status OUT nocopy VARCHAR2
    );

    PROCEDURE delete_unselected_records (
        p_data   IN BLOB,
        p_current_user in VARCHAR2,
        p_status OUT nocopy  VARCHAR2
    );

    PROCEDURE retrieve_selectedrecords (
        p_org           IN VARCHAR2,
        p_acct_nbr      IN VARCHAR2,
        p_loggedin_user IN VARCHAR2,
        x_transactions  OUT SYS_REFCURSOR,
        p_ret_status    OUT nocopy  VARCHAR2,
        p_error_msg     OUT nocopy VARCHAR2
    );
    
    PROCEDURE create_collapsed_transaction(
        p_process_id  in number,
        p_trx_number out nocopy varchar2,
        p_amount out nocopy varchar2,
        p_acct_number out nocopy varchar2,
        p_terms_name out nocopy varchar2
    );
 
END;

/

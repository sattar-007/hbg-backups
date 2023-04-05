--------------------------------------------------------
--  DDL for Package Body ZZHBG_AR_CUST_MAINT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."ZZHBG_AR_CUST_MAINT" AS

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
        x_transactions   OUT SYS_REFCURSOR
    ) IS
        p_ar_transaction_out HBG_AR_CUSTMAINTAIN_TRX_TT;
        l_idx                NUMBER;
        i                    NUMBER;
    BEGIN
        p_ar_transaction_out := HBG_AR_CUSTMAINTAIN_TRX_TT();
        i := 1;
        p_ar_transaction_out.extend;
        p_ar_transaction_out(i) := HBG_AR_CUSTMAINTAIN_TRX_RT( NULL, NULL, NULL, NULL,
                                                  NULL, NULL, NULL, HBG_AR_CUSTMAINTAIN_TRX_DETAILS_TT());

        p_ar_transaction_out(i).transaction_details := HBG_AR_CUSTMAINTAIN_TRX_DETAILS_TT();
        l_idx := 0;
        FOR rec IN (
            SELECT
                hbg_ar_trxmaint_trx_seq.NEXTVAL trx_key,
                a.*
            FROM
                (
                    WITH inv_amt AS (
                        SELECT
                            SUM(unit_selling_price) amount,
                            customer_trx_id
                        FROM
                            ra_customer_trx_lines_all
                        GROUP BY
                            customer_trx_id
                    )
                    SELECT
                        rct.customer_trx_id                              transaction_id,
                        hca.cust_account_id,
                        hp.party_id,
                        hca.account_number,
                        hca.account_name,
                        hp.party_number                                  org_nbr,
                        rct.attribute1                                   trx_code,
                        rct.attribute2                                   trx_type,
                        rct.attribute3                                   flag_code,
                        'claim_num'                                      claim_number,
                        'inv_ref_number'                                 invoice_ref_num,
                        rct.ct_reference                                 invoice_po_number,
                        rct.trx_number                                   invoice_number,
                        rctl.amount,
                        to_char(arps.due_date, 'YYYY-MM-DD')             due_date,
                        to_char(rct.trx_date, 'YYYY-MM-DD')              trx_date,
                        'aging_cat'                                      aging_cat,
                        decode(arps.status, 'OP', 'Open', 'CL', 'Close') status,
                        trm.name                                         payment_terms,
                        to_char(rct.attribute_date1, 'YYYY-MM-DD')       edi_trans_date,
                        to_char(rct.attribute_date2, 'YYYY-MM-DD')       edi_ack_date,
                        to_char(rct.attribute_date3, 'YYYY-MM-DD')       edi_remit_date
                    FROM
                        hz_cust_accounts         hca,
                        hz_parties               hp,
                        ra_customer_trx_all      rct,
                        inv_amt                  rctl,
                        ar_payment_schedules_all arps,
                        ra_terms_vl              trm
                    WHERE
                            hca.party_id = hp.party_id
                        AND hca.cust_account_id = rct.bill_to_customer_id
                        AND rct.customer_trx_id = rctl.customer_trx_id
                        AND arps.customer_trx_id = rct.customer_trx_id
                        AND rct.term_id = trm.term_id (+)
                        AND rct.trx_class IN ( 'INV', 'CM' )
                        AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
                        AND hp.party_number = nvl(p_org, hp.party_number)
                        AND nvl(rct.attribute1, 'X') = coalesce(p_trx_code, rct.attribute1, 'X')
                        AND nvl(rct.attribute2, 'X') = coalesce(p_trxtype_reason, rct.attribute2, 'X')
                        AND nvl(rct.attribute3, 'X') = coalesce(p_flag_code, rct.attribute3, 'X')
                        AND rct.trx_date >= TO_DATE(nvl(p_trx_from_date, rct.trx_date),
        'YYYY-MM-DD')
                        AND ROWNUM < 100
                    ORDER BY
                        rct.creation_date DESC
                ) a
        ) LOOP
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := HBG_AR_CUSTMAINTAIN_TRX_DETAILS_RT(NULL, NULL, NULL, NULL, NULL,
                                                                                         NULL, NULL, NULL, NULL, NULL,
                                                                                         NULL, NULL, NULL, NULL, NULL,
                                                                                         NULL, NULL, NULL, NULL, NULL,
                                                                                         NULL, NULL, NULL);

            p_ar_transaction_out(i).transaction_details(l_idx).trx_key := rec.trx_key;
            p_ar_transaction_out(i).transaction_details(l_idx).transaction_id := rec.transaction_id;
            p_ar_transaction_out(i).transaction_details(l_idx).cust_account_id := rec.cust_account_id;
            p_ar_transaction_out(i).transaction_details(l_idx).party_id := rec.party_id;
            p_ar_transaction_out(i).transaction_details(l_idx).account_number := rec.account_number;
            p_ar_transaction_out(i).transaction_details(l_idx).account_name := rec.account_name;
            p_ar_transaction_out(i).transaction_details(l_idx).org_nbr := rec.org_nbr;
            p_ar_transaction_out(i).transaction_details(l_idx).trx_code := rec.trx_code;
            p_ar_transaction_out(i).transaction_details(l_idx).trx_type := rec.trx_type;
            p_ar_transaction_out(i).transaction_details(l_idx).flag_code := rec.flag_code;
            p_ar_transaction_out(i).transaction_details(l_idx).claim_number := rec.claim_number;
            p_ar_transaction_out(i).transaction_details(l_idx).invoice_number := rec.invoice_number;
            p_ar_transaction_out(i).transaction_details(l_idx).invoice_po_number := rec.invoice_po_number;
            p_ar_transaction_out(i).transaction_details(l_idx).invoice_ref_num := rec.invoice_ref_num;
            p_ar_transaction_out(i).transaction_details(l_idx).amount := rec.amount;
            p_ar_transaction_out(i).transaction_details(l_idx).due_date := rec.due_date;
            p_ar_transaction_out(i).transaction_details(l_idx).trx_date := rec.trx_date;
            p_ar_transaction_out(i).transaction_details(l_idx).aging_cat := rec.aging_cat;
            p_ar_transaction_out(i).transaction_details(l_idx).status := rec.status;
            p_ar_transaction_out(i).transaction_details(l_idx).payment_terms := rec.payment_terms;
            p_ar_transaction_out(i).transaction_details(l_idx).edi_trans_date := rec.edi_trans_date;
            p_ar_transaction_out(i).transaction_details(l_idx).edi_ack_date := rec.edi_ack_date;
            p_ar_transaction_out(i).transaction_details(l_idx).edi_remit_date := rec.edi_remit_date;
        END LOOP;

        p_ar_transaction_out(i).org_number := 'XYZ';
        p_ar_transaction_out(i).org_name := 'XYZ124';
        p_ar_transaction_out(i).account_balance := 1000;
        p_ar_transaction_out(i).unapplied_amount := 0;
        OPEN x_transactions FOR SELECT
                                    *
                                FROM
                                    TABLE ( p_ar_transaction_out );

    EXCEPTION
        WHEN OTHERS THEN
            x_transactions := NULL;
            htp.print(sqlerrm);
    END;

END;

/

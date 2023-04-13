--------------------------------------------------------
--  DDL for Package Body XX_HBG_AR_CUST_MAINT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."XX_HBG_AR_CUST_MAINT" AS

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
        x_transactions           OUT NOCOPY CLOB,
        p_ret_status             OUT NOCOPY VARCHAR2,
        p_error_msg              OUT NOCOPY VARCHAR2
    ) IS

        p_ar_transaction_out     hbg_ar_custmaintain_trx_tt;
        l_idx                    NUMBER;
        i                        NUMBER DEFAULT 1;
        v_party_name             VARCHAR2(200);
        v_party_number           VARCHAR2(200);
        v_inv_amount             NUMBER DEFAULT 0;
        v_cm_amount              NUMBER DEFAULT 0;
        v_unapp_amount           NUMBER DEFAULT 0;
        v_claim_amount           NUMBER DEFAULT 0;
        v_include_inv            VARCHAR2(20);
        v_include_cm             VARCHAR2(20);
        v_include_claim          VARCHAR2(20);
        v_include_unapp_receipts VARCHAR2(20);
        too_many_orgs EXCEPTION;
        v_status                 VARCHAR2(20);
        v_error_msg              VARCHAR2(2000);
        v_tiers                  VARCHAR2(50);
        CURSOR c_getinvcm IS
        SELECT
            hbg_ar_trxmaint_trx_seq.NEXTVAL trx_key,
            a.*
        FROM
            (
                WITH inv_amt AS (
                    SELECT
                        SUM(extended_amount) amount,
                        customer_trx_id
                    FROM
                        ra_customer_trx_lines_all
                    GROUP BY
                        customer_trx_id
                )
                SELECT
                    rct.customer_trx_id                               transaction_id,
                    hca.cust_account_id,
                    hp.party_id,
                    hca.account_number,
                    hca.account_name,
                    hp.party_number                                   org_nbr,
                    rct.attribute1                                    trx_code,
                    rct.attribute2                                    trx_type,
                    rct.attribute3                                    flag_code,
                    NULL                                              claim_number,
                    NULL                                              invoice_ref_num,
                    rct.ct_reference                                  invoice_po_number,
                    rct.trx_number                                    invoice_number,
                    rctl.amount,
                    to_char(arps.due_date, 'YYYY-MM-DD')              due_date,
                    to_char(rct.trx_date, 'YYYY-MM-DD')               trx_date,
                    -- trunc(sysdate-50) - arps.due_date  aging_cat,
                    (
                        CASE
                            WHEN ( trunc(sysdate) - arps.due_date ) < - 30             THEN
                                'Future'
                            WHEN ( trunc(sysdate) - arps.due_date ) BETWEEN - 30 AND 0 THEN
                                'Current'
                            WHEN ( trunc(sysdate) - arps.due_date ) BETWEEN 0 AND 30   THEN
                                '1-30 Past Due'
                            WHEN ( trunc(sysdate) - arps.due_date ) BETWEEN 31 AND 60  THEN
                                '31-60 Past Due'
                            WHEN ( trunc(sysdate) - arps.due_date ) BETWEEN 61 AND 90  THEN
                                '61-90 Past Due'
                            WHEN ( trunc(sysdate) - arps.due_date ) BETWEEN 91 AND 120 THEN
                                '91-120 Past Due'
                        END
                    )                                                 aging_cat,
                    decode(arps.status, 'OP', 'Open', 'CL', 'Closed') status,
                    trm.name                                          payment_terms,
                    to_char(rct.attribute_date1, 'YYYY-MM-DD')        edi_trans_date,
                    to_char(rct.attribute_date2, 'YYYY-MM-DD')        edi_ack_date,
                    to_char(rct.attribute_date3, 'YYYY-MM-DD')        edi_remit_date,
                    rct.trx_class
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
                    AND rct.trx_class IN ( decode(v_include_inv, 'Y', 'INV', 'INV2'), decode(v_include_cm, 'Y', 'CM', 'CM2') )
                    AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
                    AND rct.trx_number BETWEEN nvl(p_inv_num_from, rct.trx_number) AND nvl(p_inv_num_to, rct.trx_number)
                    AND hp.party_number = nvl(p_org, hp.party_number)
                    AND nvl(rct.attribute1, 'X') = coalesce(p_trx_code, rct.attribute1, 'X')
                    AND nvl(rct.attribute2, 'X') = coalesce(p_trxtype_reason, rct.attribute2, 'X')
                    AND nvl(rct.attribute3, 'X') = coalesce(p_flag_code, rct.attribute3, 'X')
                    AND nvl(rct.ct_reference, 'X') = coalesce(p_inv_po_nbr, rct.ct_reference, 'X')
                    AND rct.trx_date BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                                 rct.trx_date) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'),
                                                                       rct.trx_date + 1)
                    AND rctl.amount BETWEEN nvl(p_amt_from, rctl.amount) AND nvl(p_amt_to, rctl.amount)
                    AND arps.status = decode(p_status, 'Open', 'OP', 'Closed', 'CL',
                                             'All', arps.status)
                    AND rct.customer_trx_id NOT IN (
                        SELECT
                            customer_trx_id
                        FROM
                            hbg_ar_trxmaint_store_selection
                    )
            ) a
        WHERE
            coalesce(p_aging_cat, aging_cat, 'X') = nvl(aging_cat, 'X'); --decode(aging_cat,'Future','FUTURE','Current','CURRENT','1-30 Past Due','30PASTDUE') ;

        CURSOR c_gethold_trxs IS
        SELECT
            trx_key,
            customer_trx_id transaction_id,
            cust_account_id,
            party_id,
            account_number,
            party_name      account_name,
            org_nbr,
            trx_code,
            trx_type,
            flag_code,
            claim_number,
            invoice_ref_num,
            invoice_po_number,
            invoice_number,
            amount,
            due_date,
            trx_date,
            aging_cat,
            status,
            payment_terms,
            edi_trans_date,
            edi_ack_date,
            edi_remit_date,
            trx_class,
            submitted_by
        FROM
            hbg_ar_trxmaint_store_selection
        WHERE
                submitted_by = CASE
                                   WHEN p_held_by_others = 'true' THEN
                                       submitted_by
                                   ELSE
                                       p_loggedin_user
                               END
            AND TO_DATE(trx_date, 'YYYY-MM-DD') BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                                            TO_DATE(trx_date, 'YYYY-MM-DD')) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'
                                                            ),
                                                                                                     TO_DATE(trx_date, 'YYYY-MM-DD') +
                                                                                                     1)
            AND status = decode(p_status, 'Hold', 'Hold', 'All', 'Hold')
            AND trx_class IN ( decode(v_include_inv, 'Y', 'INV', 'INV2'), decode(v_include_cm, 'Y', 'CM', 'CM2'), decode(v_include_inv
            , 'Y', 'RCPT', 'RCPT2'), decode(v_include_claim, 'Y', 'CLM', 'CLM2') )
            AND account_number = nvl(p_acct_nbr, account_number)
            AND nvl(invoice_number, 'X') BETWEEN coalesce(p_inv_num_from, invoice_number, 'X') AND coalesce(p_inv_num_to, invoice_number
            , 'X')
            AND org_nbr = nvl(p_org, org_nbr)
            AND nvl(trx_code, 'X') = coalesce(p_trx_code, trx_code, 'X')
            AND nvl(trx_type, 'X') = coalesce(p_trxtype_reason, trx_type, 'X')
            AND nvl(flag_code, 'X') = coalesce(p_flag_code, flag_code, 'X')
            AND nvl(invoice_ref_num, 'X') = coalesce(p_inv_po_nbr, invoice_ref_num, 'X')
            AND TO_DATE(trx_date, 'YYYY-MM-DD') BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                                            TO_DATE(trx_date, 'YYYY-MM-DD')) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'
                                                            ),
                                                                                                     TO_DATE(trx_date, 'YYYY-MM-DD') +
                                                                                                     1)
            AND amount BETWEEN nvl(p_amt_from, amount) AND nvl(p_amt_to, amount);

        CURSOR c_getrcpts IS
        SELECT
            hbg_ar_trxmaint_trx_seq.NEXTVAL                   trx_key,
            rct.cash_receipt_id                               transaction_id,
            hca.cust_account_id,
            hp.party_id,
            hca.account_number,
            hca.account_name,
            hp.party_number                                   org_nbr,
            rct.attribute1                                    trx_code,
            rct.attribute2                                    trx_type,
            rct.attribute3                                    flag_code,
            rct.receipt_number                                claim_number,
            NULL                                              invoice_ref_num,
            rct.logical_group_reference                       invoice_po_number,
            NULL                                              invoice_number,
            0 - arps.amount_due_remaining                     amount,
            to_char(arps.due_date, 'YYYY-MM-DD')              due_date,
            to_char(rct.receipt_date, 'YYYY-MM-DD')           trx_date,
            NULL                                              aging_cat,
            decode(arps.status, 'OP', 'Open', 'CL', 'Closed') status,
            'RCPT'                                            trx_class
        FROM
            hz_cust_accounts         hca,
            hz_parties               hp,
            ar_cash_receipts_all     rct,
            ar_payment_schedules_all arps
        WHERE
                hca.party_id = hp.party_id (+)
            AND hca.cust_account_id (+) = rct.pay_from_customer
            AND arps.cash_receipt_id = rct.cash_receipt_id
            AND 'RCPT' = decode(v_include_unapp_receipts, 'Y', 'RCPT', 'RCPT2')
            AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
            AND rct.receipt_number BETWEEN nvl(p_inv_num_from, rct.receipt_number) AND nvl(p_inv_num_to, rct.receipt_number)
            AND hp.party_number = nvl(p_org, hp.party_number)
            AND nvl(rct.attribute1, 'X') = coalesce(p_trx_code, rct.attribute1, 'X')
            AND nvl(rct.attribute2, 'X') = coalesce(p_trxtype_reason, rct.attribute2, 'X')
            AND nvl(rct.attribute3, 'X') = coalesce(p_flag_code, rct.attribute3, 'X')
            AND rct.receipt_date BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                             rct.receipt_date) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'),
                                                                       rct.receipt_date + 1)
            AND rct.amount BETWEEN nvl(p_amt_from, rct.amount) AND nvl(p_amt_to, rct.amount)     
                        -- AND ROWNUM < 100                        
            AND arps.status = decode(p_status, 'Open', 'OP', 'Closed', 'CL',
                                     'All', arps.status)
            AND rct.status = decode(p_status, 'Open', 'UNAPP', rct.status)
            AND rct.cash_receipt_id NOT IN (
                SELECT
                    customer_trx_id
                FROM
                    hbg_ar_trxmaint_store_selection
            );

        CURSOR c_getclaims IS
        SELECT
            hbg_ar_trxmaint_trx_seq.NEXTVAL                   trx_key,
            cca.claim_id                                      transaction_id,
            hca.cust_account_id,
            hp.party_id,
            hca.account_number,
            hca.account_name,
            hp.party_number                                   org_nbr,
            cca.attribute_char1                               trx_code,
            cca.attribute_char2                               trx_type,
            cca.attribute_char3                               flag_code,
            cca.claim_number                                  claim_number,
            cca.customer_ref_number                           invoice_ref_num,
            cca.source_object_number                          invoice_po_number,
            NULL                                              invoice_number,
            cca.amount                                        amount,
            NULL                                              due_date,
            to_char(cca.claim_date, 'YYYY-MM-DD')             trx_date,
            NULL                                              aging_cat,
            decode(cca.status_code, 'OPEN', 'Open', 'Closed') status,
            'CLM'                                             trx_class
        FROM
            hz_cust_accounts hca,
            hz_parties       hp,
            cjm_claims_all   cca
        WHERE
                hca.party_id = hp.party_id (+)
            AND hca.cust_account_id (+) = cca.bill_to_customer_id
            AND 'CLM' = decode(v_include_claim, 'Y', 'CLM', 'CLM2')
            AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
            AND cca.claim_number LIKE nvl(p_claim_nbr || '%', cca.claim_number)
            AND hp.party_number = nvl(p_org, hp.party_number)
            AND nvl(cca.attribute_char1, 'X') = coalesce(p_trx_code, cca.attribute_char1, 'X')
            AND nvl(cca.attribute_char2, 'X') = coalesce(p_trxtype_reason, cca.attribute_char2, 'X')
            AND nvl(cca.attribute_char3, 'X') = coalesce(p_flag_code, cca.attribute_char3, 'X')
            AND cca.claim_date BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                           cca.claim_date) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'),
                                                                   cca.claim_date + 1)
            AND cca.amount BETWEEN nvl(p_amt_from, cca.amount) AND nvl(p_amt_to, cca.amount)     
                        -- AND ROWNUM < 100                        
            AND cca.status_code = decode(p_status, 'Open', 'OPEN', 'Closed', 'SETTLED',
                                         'All', cca.status_code)
            AND cca.claim_id NOT IN (
                SELECT
                    customer_trx_id
                FROM
                    hbg_ar_trxmaint_store_selection
            );

    BEGIN

        -- delete any held transaction which are beyond threshold 

        DELETE FROM hbg_ar_trxmaint_store_selection
        WHERE
            submission_date < sysdate - ( g_held_threshold_time / 1440 );

    -- check if filters are enabled if not default all
        IF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
            AND ( p_inv_po_nbr IS NOT NULL )
        THEN
            v_include_inv := 'Y';
            v_include_cm := 'N';
            v_include_claim := 'N';
            v_include_unapp_receipts := 'N';
            -- insert into xxtest (msg) values('TEST 1 ');
        ELSIF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
            AND ( p_aging_cat IS NOT NULL )
        THEN
            v_include_inv := 'Y';
            v_include_cm := 'N';
            v_include_claim := 'N';
            v_include_unapp_receipts := 'N';
        ELSIF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
            AND ( p_inv_num_from IS NOT NULL OR p_inv_num_to IS NOT NULL )
        THEN
            v_include_inv := 'Y';
            v_include_cm := 'N';
            v_include_claim := 'N';
            v_include_unapp_receipts := 'N';
        ELSIF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
            AND ( p_claim_nbr IS NOT NULL )
        THEN
            v_include_inv := 'N';
            v_include_cm := 'N';
            v_include_claim := 'Y';
            v_include_unapp_receipts := 'N';
        ELSIF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
        THEN
            v_include_inv := 'Y';
            v_include_cm := 'Y';
            v_include_claim := 'Y';
            v_include_unapp_receipts := 'Y';
        ELSE
            v_include_inv := p_include_inv;
            v_include_cm := p_include_cm;
            v_include_claim := p_include_claim;
            v_include_unapp_receipts := p_include_unapp_receipts;
            -- insert into xxtest (msg) values('TEST 3 ');
        END IF;

      -- if the value for p_inv_po_nbr is not null then the search criteria should include invoices

        p_ar_transaction_out := hbg_ar_custmaintain_trx_tt();
        p_ar_transaction_out.extend;
        p_ar_transaction_out(i) := hbg_ar_custmaintain_trx_rt(NULL, NULL, NULL, NULL, NULL,
                                                             NULL, NULL, NULL, NULL, NULL,
                                                             hbg_ar_custmaintain_trx_details_tt());

        p_ar_transaction_out(i).transaction_details := hbg_ar_custmaintain_trx_details_tt();
        l_idx := 0;
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 11 ' );

        FOR rec IN c_gethold_trxs LOOP
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 3' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL);

            p_ar_transaction_out(i).transaction_details(l_idx).trx_key := rec.trx_key;
            p_ar_transaction_out(i).transaction_details(l_idx).submitted_by := rec.submitted_by;
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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
        END LOOP;

        FOR rec IN c_getinvcm LOOP
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 1 c_getinvcm' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL);

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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
        END LOOP;

        FOR rec IN c_getrcpts LOOP
        
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 2' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL);

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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
        END LOOP;

        FOR rec IN c_getclaims LOOP
        
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 2' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL);

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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
        END LOOP;


        -- FOR indx IN p_ar_transaction_out(1).transaction_details.first..p_ar_transaction_out(1).transaction_details.last LOOP
																															   

        --     INSERT INTO xxtest ( msg ) VALUES (  p_ar_transaction_out(1).transaction_details(indx).invoice_number );
        -- END LOOP;

        IF p_ar_transaction_out(1).transaction_details.count > 0 THEN
            FOR indx IN p_ar_transaction_out(1).transaction_details.first..p_ar_transaction_out(1).transaction_details.last LOOP
                IF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'INV' THEN
                    v_inv_amount := v_inv_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'CM' THEN
                    v_cm_amount := v_cm_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'RCPT' THEN
                    v_unapp_amount := v_unapp_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'CLM' THEN
                    v_claim_amount := v_claim_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                END IF;
            END LOOP;

--            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 4' );
		-- derive org_num and org_name
            BEGIN
                SELECT DISTINCT
                    hp.party_name,
                    hp.party_number
                INTO
                    v_party_name,
                    v_party_number
                FROM
                    hz_cust_accounts hca,
                    hz_parties       hp
                WHERE
                        hca.party_id = hp.party_id
                    AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
                    AND hp.party_number = nvl(p_org, hp.party_number);

            EXCEPTION
                WHEN too_many_rows THEN
                    RAISE too_many_orgs;
                WHEN OTHERS THEN
                    v_error_msg := sqlerrm;
                    RAISE;
            END;

            -- derive tiers
            BEGIN
                SELECT
                    hca.attribute1
                INTO v_tiers
                FROM
                    hz_cust_accounts hca,
                    hz_parties       hp
                WHERE
                        hca.party_id = hp.party_id
                    AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
                    AND hp.party_number = nvl(p_org, hp.party_number);

            EXCEPTION
                WHEN too_many_rows THEN
                    NULL;
                WHEN no_data_found THEN
                    NULL;
                WHEN OTHERS THEN
                    v_error_msg := sqlerrm;
                    RAISE;
            END;

--            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 5' );

            p_ar_transaction_out(i).org_number := v_party_number;
            p_ar_transaction_out(i).org_name := v_party_name;
            p_ar_transaction_out(i).account_balance := v_inv_amount + v_cm_amount + v_unapp_amount;
            p_ar_transaction_out(i).unapplied_amount := v_unapp_amount;
            p_ar_transaction_out(i).invoice_total := v_inv_amount;
            p_ar_transaction_out(i).claim_total := v_claim_amount;
            p_ar_transaction_out(i).credit_total := v_cm_amount;
            p_ar_transaction_out(i).tier := v_tiers;
            SELECT
                JSON_OBJECT(
                    'transactions' VALUE JSON_ARRAYAGG(
                        JSON_OBJECT(
                            'org_number' VALUE org_number,
                                    'org_name' VALUE org_name,
                                    'account_balance' VALUE a.account_balance,
                                    'unapplied_amount' VALUE a.unapplied_amount,
                                    'invoice_total' VALUE a.invoice_total,
                                    'claim_total' VALUE a.claim_total,
                                    'credit_total' VALUE a.credit_total,
                                    'tier' VALUE a.tier,
                                    'tax_exempt' VALUE a.tax_exempt,
                                    'currency' VALUE a.currency,
                                    'transaction_details' VALUE(
                                SELECT
                                    JSON_ARRAYAGG(
                                        JSON_OBJECT(
                                            'trx_key' VALUE b.trx_key,
                                            'transaction_id' VALUE b.transaction_id,
                                            'cust_account_id' VALUE b.cust_account_id,
                                            'party_id' VALUE b.party_id,
                                            'account_number' VALUE b.account_number,
                                                    'account_name' VALUE b.account_name,
                                            'org_nbr' VALUE b.org_nbr,
                                            'trx_code' VALUE b.trx_code,
                                            'trx_type' VALUE b.trx_type,
                                            'flag_code' VALUE b.flag_code,
                                                    'claim_number' VALUE b.claim_number,
                                            'invoice_ref_num' VALUE b.invoice_ref_num,
                                            'invoice_po_number' VALUE b.invoice_po_number,
                                            'invoice_number' VALUE b.invoice_number,
                                            'amount' VALUE b.amount,
                                                    'due_date' VALUE b.due_date,
                                            'trx_date' VALUE b.trx_date,
                                            'aging_cat' VALUE b.aging_cat,
                                            'status' VALUE b.status,
                                            'payment_terms' VALUE b.payment_terms,
                                                    'edi_trans_date' VALUE b.edi_trans_date,
                                            'edi_ack_date' VALUE b.edi_ack_date,
                                            'edi_remit_date' VALUE b.edi_remit_date,
                                            'trx_class' VALUE b.trx_class,
                                            'submitted_by' VALUE b.submitted_by
                                        RETURNING CLOB)
                                    RETURNING CLOB)
                                FROM
                                    TABLE(a.transaction_details) b
                            )
                        RETURNING CLOB)
                    RETURNING CLOB),
                            'ret_status' VALUE 'SUCCESS'
                RETURNING CLOB)
            INTO x_transactions
            FROM
                TABLE ( p_ar_transaction_out ) a;

            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 6' );

        END IF;

        IF p_ar_transaction_out(i).transaction_details.count > 0 THEN
            p_ret_status := 'SUCCESS';
            p_error_msg := '';
        ELSE
            p_ret_status := 'ERROR';
            p_error_msg := 'No data exists for given search criteria';
        END IF;

        INSERT INTO xxtest ( msg ) VALUES ( 'Inside 7 1' );

        COMMIT;
    EXCEPTION
        WHEN too_many_orgs THEN
            v_error_msg := 'the search criteria is retrieving multiple organizations. Please provide valid values';
            htp.print(v_error_msg);
            -- htp.status(500); 

            p_ret_status := 'ERROR';
            p_error_msg := v_error_msg;
            x_transactions := NULL;
            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 7 ' || v_error_msg );

        WHEN OTHERS THEN
            v_error_msg := 'ERROR ' || sqlerrm;
            x_transactions := NULL;
            htp.print(v_error_msg);
            owa_util.status_line(nstatus => 404, creason => 'Not Found', bclose_header => true);
            -- htp.status(500);
            p_ret_status := 'ERROR';
            p_error_msg := v_error_msg;
            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 7 ' || v_error_msg );

    END;


    PROCEDURE create_trx_activity (
        p_data   IN BLOB,
        p_status OUT VARCHAR2
    ) IS
        TYPE t_trxs_tab IS
            TABLE OF hbg_ar_cust_maintenance_activity%rowtype;
        l_trxs_tab t_trxs_tab := t_trxs_tab();
        l_top_obj  json_object_t;
        l_trxs_arr json_array_t;
        l_trx_obj  json_object_t;
        v_date      date;
    BEGIN
        l_top_obj := json_object_t(p_data);
        l_trxs_arr := l_top_obj.get_array('transactions');
        select sysdate into v_date from dual;
        FOR i IN 0..l_trxs_arr.get_size - 1 LOOP
            l_trxs_tab.extend;
            -- l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t).get_object('transaction');
            l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t);
        --    l_trxs_tab(l_trxs_tab.last).party_name := l_trx_obj.get_string('party_name.');
            l_trxs_tab(l_trxs_tab.last).account_number := l_trx_obj.get_string('account_number');
            l_trxs_tab(l_trxs_tab.last).aging_cat := l_trx_obj.get_string('aging_cat');
            l_trxs_tab(l_trxs_tab.last).amount := l_trx_obj.get_string('amount');
            l_trxs_tab(l_trxs_tab.last).amount_applied := l_trx_obj.get_string('amount_applied');
            l_trxs_tab(l_trxs_tab.last).action := l_trx_obj.get_string('action');
            l_trxs_tab(l_trxs_tab.last).balance := l_trx_obj.get_string('balance');
            l_trxs_tab(l_trxs_tab.last).claim_number := l_trx_obj.get_string('claim_number');
            l_trxs_tab(l_trxs_tab.last).cust_account_id := l_trx_obj.get_string('cust_account_id');
            l_trxs_tab(l_trxs_tab.last).due_date := l_trx_obj.get_string('due_date');
            l_trxs_tab(l_trxs_tab.last).edi_ack_date := l_trx_obj.get_string('edi_ack_date');
            l_trxs_tab(l_trxs_tab.last).edi_remit_date := l_trx_obj.get_string('edi_remit_date');
            l_trxs_tab(l_trxs_tab.last).edi_trans_date := l_trx_obj.get_string('edi_trans_date');
            l_trxs_tab(l_trxs_tab.last).flag_code := l_trx_obj.get_string('flag_code');
            l_trxs_tab(l_trxs_tab.last).invoice_number := l_trx_obj.get_string('invoice_number');
            l_trxs_tab(l_trxs_tab.last).invoice_po_number := l_trx_obj.get_string('invoice_po_number');
            l_trxs_tab(l_trxs_tab.last).invoice_ref_num := l_trx_obj.get_string('invoice_ref_num');
            l_trxs_tab(l_trxs_tab.last).org_nbr := l_trx_obj.get_string('org_nbr');
            l_trxs_tab(l_trxs_tab.last).party_id := l_trx_obj.get_string('party_id');
            l_trxs_tab(l_trxs_tab.last).payment_terms := l_trx_obj.get_string('payment_terms');
            l_trxs_tab(l_trxs_tab.last).trx_key := l_trx_obj.get_string('trx_key');
            l_trxs_tab(l_trxs_tab.last).customer_trx_id := l_trx_obj.get_string('transaction_id');
            l_trxs_tab(l_trxs_tab.last).new_trx_code := l_trx_obj.get_string('new_trx_code');
            l_trxs_tab(l_trxs_tab.last).NEW_TRX_NUMBER := l_trx_obj.get_string('new_trx_num');
            l_trxs_tab(l_trxs_tab.last).new_claim_number := l_trx_obj.get_string('new_claim_number');
            l_trxs_tab(l_trxs_tab.last).gl_account_number_new := l_trx_obj.get_string('new_gl_acct_num');
            l_trxs_tab(l_trxs_tab.last).gl_account_number := l_trx_obj.get_string('gl_account_num');
            l_trxs_tab(l_trxs_tab.last).trx_date := l_trx_obj.get_string('trx_date');
            l_trxs_tab(l_trxs_tab.last).trx_class := l_trx_obj.get_string('trx_class');
            l_trxs_tab(l_trxs_tab.last).session_id := l_trx_obj.get_string('session_id');
            l_trxs_tab(l_trxs_tab.last).submitted_by := l_trx_obj.get_string('submitted_by');
            l_trxs_tab(l_trxs_tab.last).submission_date := v_date;
            l_trxs_tab(l_trxs_tab.last).trx_code := l_trx_obj.get_string('trx_code');
            l_trxs_tab(l_trxs_tab.last).trx_type := l_trx_obj.get_string('trx_type');
            l_trxs_tab(l_trxs_tab.last).status := l_trx_obj.get_string('status');
            l_trxs_tab(l_trxs_tab.last).account_name := l_trx_obj.get_string('account_name');
            l_trxs_tab(l_trxs_tab.last).new_account_number := l_trx_obj.get_string('new_acct_num');
        END LOOP;
--   -- Populate the tables.
        FORALL i IN l_trxs_tab.first..l_trxs_tab.last
            INSERT INTO hbg_ar_cust_maintenance_activity VALUES l_trxs_tab ( i );
--   FORALL i IN l_emp_tab.first .. l_emp_tab.last
--     INSERT INTO emp VALUES l_emp_tab(i);
        COMMIT;
        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            p_status := 'ERROR '||SQLERRM;
    END;
END;

/

--------------------------------------------------------
--  DDL for Package Body HBG_AR_CUST_MAINTENANCE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_AR_CUST_MAINTENANCE" AS
 
--    FUNCTION to_json_object (
--        key_in   IN VARCHAR2,
--        value_in IN VARCHAR2 
--    ) RETURN json_object_t IS
--    BEGIN
--        RETURN json_object_t('{"' || key_in || '":"' || value_in || '"}');
--    END;

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
                ), trx_actvity AS (
                    SELECT
                        process_id,
                        customer_trx_id,
                        orcl_status,
                        TO_DATE(submission_date, 'DD-MON-YY') submission_date
                    FROM
                        hbg_ar_cust_maintenance_activity
                    WHERE
                            orcl_status = 'Success'
                        AND process_id > 1050
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
                    rct.trx_class,
                    nvl(rct.attribute_number1, maint.process_id)      process_id,
--                    maint.orcl_status,
                    to_char(maint.submission_date, 'YYYY-MM-DD')      closed_date,
                    rct.attribute5                                    comments
                FROM
                    hz_cust_accounts         hca,
                    hz_parties               hp,
                    ra_customer_trx_all      rct,
                    inv_amt                  rctl,
                    ar_payment_schedules_all arps,
                    ra_terms_vl              trm,
                    trx_actvity              maint
                WHERE
                        hca.party_id = hp.party_id
                    AND hca.cust_account_id = rct.bill_to_customer_id
                    AND rct.customer_trx_id = rctl.customer_trx_id
                    AND arps.customer_trx_id = rct.customer_trx_id
                    AND rct.term_id = trm.term_id (+)
                    AND TO_NUMBER(maint.customer_trx_id(+)) = rct.customer_trx_id 
--                    AND nvl(rct.attribute_number1,maint.process_id) = 1080

                    AND rct.trx_class IN ( decode(v_include_inv, 'Y', 'INV', 'INV2'), decode(v_include_cm, 'Y', 'CM', 'CM2'), decode(

                    v_include_cm, 'Y', 'ONACC', 'ONACC2') )
                    AND hca.account_number = nvl(p_acct_nbr, hca.account_number)
                    AND rct.trx_number BETWEEN nvl(p_inv_num_from, rct.trx_number) AND nvl(p_inv_num_to, rct.trx_number)
                    AND hp.party_number = nvl(p_org, hp.party_number)
                    AND ( p_trx_code IS NULL
                          OR ( rct.attribute1 IN (
                        SELECT
                            regexp_substr(p_trx_code, '[^,]+', 1, level)
                        FROM
                            dual
                        CONNECT BY
                            regexp_substr(p_trx_code, '[^,]+', 1, level) IS NOT NULL
                    ) ) )
--                    AND nvl(rct.attribute1, 'X') in p_trx_code --coalesce(p_trx_code, rct.attribute1, 'X')
                    AND nvl(rct.attribute2, 'X') = coalesce(p_trxtype_reason, rct.attribute2, 'X')
                    AND nvl(rct.attribute3, 'X') = coalesce(p_flag_code, rct.attribute3, 'X')
                    AND nvl(rct.ct_reference, 'X') = coalesce(p_inv_po_nbr, rct.ct_reference, 'X')
                    AND rct.trx_date BETWEEN nvl(TO_DATE(p_trx_from_date, 'YYYY-MM-DD'),
                                                 rct.trx_date) AND nvl(TO_DATE(p_trx_to_date, 'YYYY-MM-DD'),
                                                                       rct.trx_date + 1)
                    AND rctl.amount BETWEEN nvl(TO_NUMBER(p_amt_from),
                                                rctl.amount) AND nvl(TO_NUMBER(p_amt_to),
                                                                     rctl.amount)
                    AND arps.status = decode(p_status, 'Open', 'OP', 'Closed', 'CL',
                                             'All', arps.status)
                    AND coalesce(rct.attribute_number1, maint.process_id, 1) = coalesce(p_process_id, maint.process_id, rct.attribute_number1
                    , 1)
                    AND rct.customer_trx_id NOT IN (
                        SELECT
                            customer_trx_id
                        FROM
                            hbg_ar_trxmaint_store_selection
                    )
                ORDER BY
                    rct.customer_trx_id
            ) a
        WHERE
            coalesce(p_aging_cat, aging_cat, 'X') = nvl(aging_cat, 'X');

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
            AND trx_class IN ( decode(v_include_inv, 'Y', 'INV', 'INV2'), decode(v_include_cm, 'Y', 'CM', 'CM2'), decode(v_include_cm
            , 'Y', 'ONACC', 'ONACC2'), decode(v_include_inv, 'Y', 'RCPT', 'RCPT2'), decode(v_include_claim, 'Y', 'CLM', 'CLM2') )
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
        WITH trx_actvity AS (
            SELECT
                process_id,
                customer_trx_id,
                orcl_status,
                TO_DATE(submission_date, 'DD-MON-YY') submission_date
            FROM
                hbg_ar_cust_maintenance_activity
            WHERE
                    orcl_status = 'Success'
                AND process_id > 1050
        )
        SELECT
            hbg_ar_trxmaint_trx_seq.NEXTVAL                                        trx_key,
            rct.cash_receipt_id                                                    transaction_id,
            hca.cust_account_id,
            hp.party_id,
            hca.account_number,
            hca.account_name,
            hp.party_number                                                        org_nbr,
            rct.attribute1                                                         trx_code,
            rct.attribute2                                                         trx_type,
            rct.attribute3                                                         flag_code,
            rct.receipt_number                                                     claim_number,
            NULL                                                                   invoice_ref_num,
            rct.logical_group_reference                                            invoice_po_number,
            NULL                                                                   invoice_number,
            decode(arps.status, 'OP', arps.amount_due_remaining, 'CL', rct.amount) amount,
            to_char(arps.due_date, 'YYYY-MM-DD')                                   due_date,
            to_char(rct.receipt_date, 'YYYY-MM-DD')                                trx_date,
            NULL                                                                   aging_cat,
            decode(arps.status, 'OP', 'Open', 'CL', 'Closed')                      status,
            'RCPT'                                                                 trx_class,
            maint.process_id                                                       process_id,
--                    maint.orcl_status,
            to_char(maint.submission_date, 'YYYY-MM-DD')                           closed_date
        FROM
            hz_cust_accounts         hca,
            hz_parties               hp,
            ar_cash_receipts_all     rct,
            ar_payment_schedules_all arps,
            trx_actvity              maint
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
            AND arps.amount_due_remaining BETWEEN nvl(p_amt_from, arps.amount_due_remaining) AND nvl(p_amt_to, arps.amount_due_remaining
            )     
                        -- AND ROWNUM < 100                        
            AND arps.status = decode(p_status, 'Open', 'OP', 'Closed', 'CL',
                                     'All', arps.status)
            AND rct.status = decode(p_status, 'Open', 'UNAPP', rct.status)
            AND TO_NUMBER(maint.customer_trx_id(+)) = rct.cash_receipt_id
            AND nvl(maint.process_id, 1) = coalesce(p_process_id, maint.process_id, 1)
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
            AND 1 = nvl(p_process_id, 1)
            AND cca.claim_id NOT IN (
                SELECT
                    customer_trx_id
                FROM
                    hbg_ar_trxmaint_store_selection
            );

    BEGIN
        INSERT INTO xxtest VALUES ( p_aging_cat );

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
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 1 ' );

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
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 2 ' );

        ELSIF
            ( p_include_inv = 'N' )
            AND ( p_include_cm = 'N' )
            AND ( p_include_claim = 'N' )
            AND ( p_include_unapp_receipts = 'N' )
            AND ( p_inv_num_from IS NOT NULL OR p_inv_num_to IS NOT NULL )
        THEN
            v_include_inv := 'Y';
            v_include_cm := 'Y';
            v_include_claim := 'N';
            v_include_unapp_receipts := 'N';
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 3' );

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
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 4' );

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
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 5' );

        ELSE
            v_include_inv := p_include_inv;
            v_include_cm := p_include_cm;
            v_include_claim := p_include_claim;
            v_include_unapp_receipts := p_include_unapp_receipts;
            INSERT INTO xxtest ( msg ) VALUES ( 'TEST 6' );
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
                                                                                                    NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL);

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
            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 1 c_getinvcm ' || rec.invoice_number );

            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
            p_ar_transaction_out(i).transaction_details(l_idx).process_id := rec.process_id;
            p_ar_transaction_out(i).transaction_details(l_idx).closed_date := rec.closed_date;
            p_ar_transaction_out(i).transaction_details(l_idx).comments := rec.comments;
        END LOOP;

        FOR rec IN c_getrcpts LOOP
        
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 2' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
            p_ar_transaction_out(i).transaction_details(l_idx).process_id := rec.process_id;
            p_ar_transaction_out(i).transaction_details(l_idx).closed_date := rec.closed_date;
        END LOOP;

        FOR rec IN c_getclaims LOOP
        
            -- INSERT INTO xxtest ( msg ) VALUES ( 'Inside 2' );
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
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
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'ONACC' THEN
                    v_cm_amount := v_cm_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'RCPT' THEN
                    v_unapp_amount := v_unapp_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'CLM' THEN
                    v_claim_amount := v_claim_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                END IF;
            END LOOP;

            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 4' );
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

            INSERT INTO xxtest ( msg ) VALUES ( 'Inside 5' );

            p_ar_transaction_out(i).org_number := v_party_number;
            p_ar_transaction_out(i).org_name := v_party_name;
            p_ar_transaction_out(i).account_balance := v_inv_amount + v_cm_amount + v_unapp_amount + v_claim_amount;
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
                                            'submitted_by' VALUE b.submitted_by,
                                                    'closed_date' VALUE b.closed_date,
                                            'process_id' VALUE b.process_id,
                                            'comments' VALUE b.comments
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
        p_data       IN BLOB,
        p_status     OUT NOCOPY VARCHAR2,
        p_process_id OUT NUMBER
    ) IS

        TYPE t_trxs_tab IS
            TABLE OF hbg_ar_cust_maintenance_activity%rowtype;
        TYPE t_trxs_tab_1 IS
            TABLE OF hbg_ar_trxmaint_store_selection%rowtype;
        l_trxs_tab   t_trxs_tab := t_trxs_tab();
        l_trxs_tab_1 t_trxs_tab_1 := t_trxs_tab_1();
        l_top_obj    json_object_t;
        l_trxs_arr   json_array_t;
        l_trxs_arr_1 json_array_t;
        l_trx_obj    json_object_t;
--        l_trx_obj_1    json_object_t;
        v_date       DATE;
        v_process_id NUMBER;
        v_action     VARCHAR2(20);
    BEGIN
        l_top_obj := json_object_t(p_data);
        l_trxs_arr := l_top_obj.get_array('transactions');
        SELECT
            sysdate,
            hbg_artrx_seq.NEXTVAL
        INTO
            v_date,
            v_process_id
        FROM
            dual;
            
        --- hold transactions

        l_top_obj := json_object_t(p_data);
        -- l_trxs_arr := l_top_obj.get_array('transactions');
        l_trxs_arr_1 := l_top_obj.get_array('transactions');
        FOR i IN 0..l_trxs_arr_1.get_size - 1 LOOP
            -- l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t).get_object('transaction');
            l_trx_obj := TREAT(l_trxs_arr_1.get(i) AS json_object_t);
            IF l_trx_obj.get_string('status') = 'Open' THEN
                l_trxs_tab_1.extend;
                l_trxs_tab_1(l_trxs_tab_1.last).account_number := l_trx_obj.get_string('account_number');
                l_trxs_tab_1(l_trxs_tab_1.last).aging_cat := l_trx_obj.get_string('aging_cat');
                l_trxs_tab_1(l_trxs_tab_1.last).amount := l_trx_obj.get_string('amount');
                l_trxs_tab_1(l_trxs_tab_1.last).amount_applied := l_trx_obj.get_string('amount_applied');
                l_trxs_tab_1(l_trxs_tab_1.last).balance := l_trx_obj.get_string('balance');
                l_trxs_tab_1(l_trxs_tab_1.last).claim_number := l_trx_obj.get_string('claim_number');
                l_trxs_tab_1(l_trxs_tab_1.last).cust_account_id := l_trx_obj.get_string('cust_account_id');
                l_trxs_tab_1(l_trxs_tab_1.last).due_date := l_trx_obj.get_string('due_date');
                l_trxs_tab_1(l_trxs_tab_1.last).edi_ack_date := l_trx_obj.get_string('edi_ack_date');
                l_trxs_tab_1(l_trxs_tab_1.last).edi_remit_date := l_trx_obj.get_string('edi_remit_date');
                l_trxs_tab_1(l_trxs_tab_1.last).edi_trans_date := l_trx_obj.get_string('edi_trans_date');
                l_trxs_tab_1(l_trxs_tab_1.last).flag_code := l_trx_obj.get_string('flag_code');
                l_trxs_tab_1(l_trxs_tab_1.last).invoice_number := l_trx_obj.get_string('invoice_number');
                l_trxs_tab_1(l_trxs_tab_1.last).invoice_po_number := l_trx_obj.get_string('invoice_po_number');
                l_trxs_tab_1(l_trxs_tab_1.last).invoice_ref_num := l_trx_obj.get_string('invoice_ref_number');
                l_trxs_tab_1(l_trxs_tab_1.last).org_nbr := l_trx_obj.get_string('org_nbr');
                l_trxs_tab_1(l_trxs_tab_1.last).party_id := l_trx_obj.get_string('party_id');
                l_trxs_tab_1(l_trxs_tab_1.last).payment_terms := l_trx_obj.get_string('payment_terms');
                l_trxs_tab_1(l_trxs_tab_1.last).trx_key := l_trx_obj.get_string('trx_key');
                l_trxs_tab_1(l_trxs_tab_1.last).customer_trx_id := l_trx_obj.get_string('transaction_id');
                l_trxs_tab_1(l_trxs_tab_1.last).new_trx_code := l_trx_obj.get_string('new_trx_code');
                l_trxs_tab_1(l_trxs_tab_1.last).new_claim_number := l_trx_obj.get_string('new_claim_number');
                l_trxs_tab_1(l_trxs_tab_1.last).gl_account_number_new := l_trx_obj.get_string('gl_account_number_new');
                l_trxs_tab_1(l_trxs_tab_1.last).gl_account_number := l_trx_obj.get_string('gl_account_number');
                l_trxs_tab_1(l_trxs_tab_1.last).trx_date := l_trx_obj.get_string('trx_date');
                l_trxs_tab_1(l_trxs_tab_1.last).trx_class := l_trx_obj.get_string('trx_class');
                l_trxs_tab_1(l_trxs_tab_1.last).session_id := l_trx_obj.get_string('session_id');
                l_trxs_tab_1(l_trxs_tab_1.last).submitted_by := l_trx_obj.get_string('submitted_by');
                l_trxs_tab_1(l_trxs_tab_1.last).submission_date := v_date;
                l_trxs_tab_1(l_trxs_tab_1.last).trx_code := l_trx_obj.get_string('trx_code');
                l_trxs_tab_1(l_trxs_tab_1.last).trx_type := l_trx_obj.get_string('trx_type');
            -- l_trxs_tab_1(l_trxs_tab_1.last).status := l_trx_obj.get_string('status');
                l_trxs_tab_1(l_trxs_tab_1.last).status := 'Hold';
            END IF;

        END LOOP;        

--   -- Populate the tables.
        FORALL i IN l_trxs_tab.first..l_trxs_tab.last
            INSERT INTO hbg_ar_trxmaint_store_selection VALUES l_trxs_tab_1 ( i );

        COMMIT;
        
        
        -- collapse transactions

        FOR i IN 0..l_trxs_arr.get_size - 1 LOOP
            
            -- l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t).get_object('transaction');
            l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t);
            IF l_trx_obj.get_string('trx_class') != 'CLM' THEN
                l_trxs_tab.extend;
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
                l_trxs_tab(l_trxs_tab.last).new_trx_number := l_trx_obj.get_string('new_trx_num');
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
                l_trxs_tab(l_trxs_tab.last).process_id := v_process_id;
            END IF;

        END LOOP;

        v_action := l_trxs_tab(l_trxs_tab.last).action;
     
        -- create a record in the activity process table
        IF l_trxs_tab.count > 0 THEN
            INSERT INTO hbg_artrx_activity_process (
                process_id,
                activity_type,
                submitted_by,
                session_id,
                submission_date
            ) VALUES (
                v_process_id,
                v_action,
                l_trxs_tab(1).submitted_by,
                l_trxs_tab(1).session_id,
                sysdate
            );

--   -- Populate the tables.
            FORALL i IN l_trxs_tab.first..l_trxs_tab.last
                INSERT INTO hbg_ar_cust_maintenance_activity VALUES l_trxs_tab ( i );

        ELSE
            v_process_id := 0;
        END IF;

        COMMIT;
        p_status := 'SUCCESS';
        p_process_id := v_process_id;
    EXCEPTION
        WHEN OTHERS THEN
            p_status := 'ERROR ' || sqlerrm;
    END;

    PROCEDURE store_selected_records (
        p_data   IN BLOB,
        p_status OUT NOCOPY VARCHAR2
    ) IS

        TYPE t_trxs_tab IS
            TABLE OF hbg_ar_trxmaint_store_selection%rowtype;
        l_trxs_tab t_trxs_tab := t_trxs_tab();
        l_top_obj  json_object_t;
        l_trxs_arr json_array_t;
        l_trx_obj  json_object_t;
        v_date     DATE;
    BEGIN
        SELECT
            sysdate
        INTO v_date
        FROM
            dual;

        l_top_obj := json_object_t(p_data);
        -- l_trxs_arr := l_top_obj.get_array('transactions');
        l_trxs_arr := l_top_obj.get_array('transactions');
        FOR i IN 0..l_trxs_arr.get_size - 1 LOOP
            -- l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t).get_object('transaction');
            l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t);
            IF l_trx_obj.get_string('status') = 'Open' THEN
                l_trxs_tab.extend;
                l_trxs_tab(l_trxs_tab.last).party_name := l_trx_obj.get_string('account_name');
                l_trxs_tab(l_trxs_tab.last).account_number := l_trx_obj.get_string('account_number');
                l_trxs_tab(l_trxs_tab.last).aging_cat := l_trx_obj.get_string('aging_cat');
                l_trxs_tab(l_trxs_tab.last).amount := l_trx_obj.get_string('amount');
                l_trxs_tab(l_trxs_tab.last).amount_applied := l_trx_obj.get_string('amount_applied');
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
                l_trxs_tab(l_trxs_tab.last).invoice_ref_num := l_trx_obj.get_string('invoice_ref_number');
                l_trxs_tab(l_trxs_tab.last).org_nbr := l_trx_obj.get_string('org_nbr');
                l_trxs_tab(l_trxs_tab.last).party_id := l_trx_obj.get_string('party_id');
                l_trxs_tab(l_trxs_tab.last).payment_terms := l_trx_obj.get_string('payment_terms');
                l_trxs_tab(l_trxs_tab.last).trx_key := l_trx_obj.get_string('trx_key');
                l_trxs_tab(l_trxs_tab.last).customer_trx_id := l_trx_obj.get_string('transaction_id');
                l_trxs_tab(l_trxs_tab.last).new_trx_code := l_trx_obj.get_string('new_trx_code');
                l_trxs_tab(l_trxs_tab.last).new_claim_number := l_trx_obj.get_string('new_claim_number');
                l_trxs_tab(l_trxs_tab.last).gl_account_number_new := l_trx_obj.get_string('gl_account_number_new');
                l_trxs_tab(l_trxs_tab.last).gl_account_number := l_trx_obj.get_string('gl_account_number');
                l_trxs_tab(l_trxs_tab.last).trx_date := l_trx_obj.get_string('trx_date');
                l_trxs_tab(l_trxs_tab.last).trx_class := l_trx_obj.get_string('trx_class');
                l_trxs_tab(l_trxs_tab.last).session_id := l_trx_obj.get_string('session_id');
                l_trxs_tab(l_trxs_tab.last).submitted_by := l_trx_obj.get_string('submitted_by');
                l_trxs_tab(l_trxs_tab.last).submission_date := v_date;
                l_trxs_tab(l_trxs_tab.last).trx_code := l_trx_obj.get_string('trx_code');
                l_trxs_tab(l_trxs_tab.last).trx_type := l_trx_obj.get_string('trx_type');
            -- l_trxs_tab(l_trxs_tab.last).status := l_trx_obj.get_string('status');
                l_trxs_tab(l_trxs_tab.last).status := 'Hold';
            END IF;

        END LOOP;

--   -- Populate the tables.
        FORALL i IN l_trxs_tab.first..l_trxs_tab.last
            INSERT INTO hbg_ar_trxmaint_store_selection VALUES l_trxs_tab ( i );

        COMMIT;
        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            p_status := sqlerrm;
    END;

    PROCEDURE delete_unselected_records (
        p_data         IN BLOB,
        p_current_user IN VARCHAR2,
        p_status       OUT NOCOPY VARCHAR2
    ) IS

        TYPE t_trxs_tab IS
            TABLE OF hbg_ar_trxmaint_store_selection%rowtype;
        l_trxs_tab t_trxs_tab := t_trxs_tab();
        l_top_obj  json_object_t;
        l_trxs_arr json_array_t;
        l_trx_obj  json_object_t;
    BEGIN
        l_top_obj := json_object_t(p_data);
        l_trxs_arr := l_top_obj.get_array('transactions');
        FOR i IN 0..l_trxs_arr.get_size - 1 LOOP
            l_trxs_tab.extend;
            -- l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t).get_object('transaction');
            l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t);
            l_trxs_tab(l_trxs_tab.last).trx_key := l_trx_obj.get_string('trx_key');
            l_trxs_tab(l_trxs_tab.last).submitted_by := l_trx_obj.get_string('submitted_by');
        END LOOP;

--   -- Populate the tables.
        FORALL i IN l_trxs_tab.first..l_trxs_tab.last
            DELETE FROM hbg_ar_trxmaint_store_selection
            WHERE
                    trx_key = l_trxs_tab(i).trx_key
                AND submitted_by = p_current_user;

--   FORALL i IN l_emp_tab.first .. l_emp_tab.last
--     INSERT INTO emp VALUES l_emp_tab(i);

        COMMIT;
        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            p_status := 'ERROR';
    END;

    PROCEDURE retrieve_selectedrecords (
        p_org           IN VARCHAR2,
        p_acct_nbr      IN VARCHAR2,
        p_loggedin_user IN VARCHAR2,
        x_transactions  OUT SYS_REFCURSOR,
        p_ret_status    OUT NOCOPY VARCHAR2,
        p_error_msg     OUT NOCOPY VARCHAR2
    ) IS

        p_ar_transaction_out     hbg_ar_custmaintain_trx_tt;
        l_idx                    NUMBER;
        i                        NUMBER DEFAULT 1;
        v_party_name             VARCHAR2(200);
        v_party_number           VARCHAR2(200);
        v_inv_amount             NUMBER DEFAULT 0;
        v_cm_amount              NUMBER DEFAULT 0;
        v_include_inv            VARCHAR2(20);
        v_include_cm             VARCHAR2(20);
        v_include_claim          VARCHAR2(20);
        v_include_unapp_receipts VARCHAR2(20);
        too_many_orgs EXCEPTION;
        v_status                 VARCHAR2(20);
        v_error_msg              VARCHAR2(2000);
    BEGIN
        p_ar_transaction_out := hbg_ar_custmaintain_trx_tt();
        p_ar_transaction_out.extend;
        p_ar_transaction_out(i) := hbg_ar_custmaintain_trx_rt(NULL, NULL, NULL, NULL, NULL,
                                                             NULL, NULL, NULL, NULL, NULL,
                                                             hbg_ar_custmaintain_trx_details_tt());

        p_ar_transaction_out(i).transaction_details := hbg_ar_custmaintain_trx_details_tt();
        l_idx := 0;
        FOR rec IN (
            SELECT
                hbg_ar_trxmaint_trx_seq.NEXTVAL trx_key,
                a.*
            FROM
                (
                    SELECT
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
                        trx_class
                    FROM
                        hbg_ar_trxmaint_store_selection
                    WHERE
                        p_loggedin_user = submitted_by
                ) a
        ) LOOP
            p_ar_transaction_out(i).transaction_details.extend;
            l_idx := l_idx + 1;
            p_ar_transaction_out(i).transaction_details(l_idx) := hbg_ar_custmaintain_trx_details_rt(NULL, NULL, NULL, NULL, NULL,
                                                                                                    NULL, NULL, NULL, NULL, NULL,
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
            p_ar_transaction_out(i).transaction_details(l_idx).trx_class := rec.trx_class;
        END LOOP;

        IF p_ar_transaction_out(1).transaction_details.count > 0 THEN
            FOR indx IN p_ar_transaction_out(1).transaction_details.first..p_ar_transaction_out(1).transaction_details.last LOOP
                IF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'INV' THEN
                    v_inv_amount := v_inv_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                ELSIF p_ar_transaction_out(1).transaction_details(indx).trx_class = 'CM' THEN
                    v_cm_amount := v_cm_amount + p_ar_transaction_out(1).transaction_details(indx).amount;
                END IF;
            END LOOP;

		-- derive org_num and org_name
            BEGIN
                SELECT
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

            p_ar_transaction_out(i).org_number := v_party_number;
            p_ar_transaction_out(i).org_name := v_party_name;
            p_ar_transaction_out(i).account_balance := v_inv_amount + v_cm_amount;
            p_ar_transaction_out(i).unapplied_amount := 0;
            p_ar_transaction_out(i).invoice_total := v_inv_amount;
            p_ar_transaction_out(i).claim_total := 0;
            p_ar_transaction_out(i).credit_total := v_cm_amount;
            OPEN x_transactions FOR SELECT
                                        *
                                    FROM
                                        TABLE ( p_ar_transaction_out );

        END IF;

        IF p_ar_transaction_out(i).transaction_details.count > 0 THEN
            p_ret_status := 'SUCCESS';
            p_error_msg := '';
        ELSE
            p_ret_status := 'ERROR';
            p_error_msg := 'No data exists for given search criteria';
        END IF;

    EXCEPTION
        WHEN too_many_orgs THEN
            v_error_msg := 'the search criteria is retrieving multiple organizations. Please provide valid values';
            htp.print(v_error_msg);
            -- htp.status(500); 

            p_ret_status := 'ERROR';
            p_error_msg := v_error_msg;
            x_transactions := NULL;
        WHEN OTHERS THEN
            v_error_msg := sqlerrm;
            x_transactions := NULL;
            htp.print(v_error_msg);
            owa_util.status_line(nstatus => 404, creason => 'Not Found', bclose_header => true);
            -- htp.status(500);
            p_ret_status := 'ERROR';
            p_error_msg := v_error_msg;
    END;

    PROCEDURE create_collapsed_transaction (
        p_process_id  IN NUMBER,
        p_trx_number  OUT NOCOPY VARCHAR2,
        p_amount      OUT NOCOPY VARCHAR2,
        p_acct_number OUT NOCOPY VARCHAR2,
        p_terms_name  OUT NOCOPY VARCHAR2
    ) IS
    BEGIN
     
--     releasing transactions  which are collapsed successfully.

        DELETE FROM hbg_ar_trxmaint_store_selection
        WHERE
            customer_trx_id IN (
                SELECT
                    customer_trx_id
                FROM
                    hbg_ar_cust_maintenance_activity
                WHERE
                        process_id = p_process_id
                    AND orcl_status = 'Success'
            );

        COMMIT;
        
        -- select collapse record which needs to be created
        SELECT
            SUM(amount) amount,
            new_trx_number,
            account_number,
            terms_name
        INTO
            p_amount,
            p_trx_number,
            p_acct_number,
            p_terms_name
        FROM
            (
                WITH terms AS (
                    SELECT DISTINCT
                        trm.name,
                        prof.cust_account_id
                    FROM
                        hz_customer_profiles_f prof,
                        ra_terms_vl            trm
                    WHERE
                        prof.standard_terms = trm.term_id
                )
                SELECT
                    SUM(amount)                             amount,
                    new_trx_number,
                    nvl(new_account_number, account_number) account_number,
--            maint.cust_account_id,
                    trm.name                                terms_name
                FROM
                    hbg_ar_cust_maintenance_activity maint,
                    terms                            trm
                WHERE
                        1 = 1
                    AND process_id = p_process_id
                    AND trm.cust_account_id (+) = maint.cust_account_id
                GROUP BY
                    nvl(new_account_number, account_number),
                    new_trx_number,
                    maint.cust_account_id,
                    trm.name
            )
        GROUP BY
            new_trx_number,
            account_number,
            terms_name;

    END;

    PROCEDURE create_writeoff_records (
        p_data   IN BLOB,
        p_status OUT NOCOPY VARCHAR2
    ) IS

        TYPE t_trxs_tab IS
            TABLE OF hbg_artrx_writeoff_records%rowtype;
        l_trxs_tab t_trxs_tab := t_trxs_tab();
        l_top_obj  json_object_t;
        l_trxs_arr json_array_t;
        l_trx_obj  json_object_t; 
        /* v_date       DATE;  */
    BEGIN
        l_top_obj := json_object_t(p_data);
        l_trxs_arr := l_top_obj.get_array('transactions');
        FOR i IN 0..l_trxs_arr.get_size - 1 LOOP
            l_trx_obj := TREAT(l_trxs_arr.get(i) AS json_object_t);
            l_trxs_tab.extend;
            l_trxs_tab(l_trxs_tab.last).process_id := l_trx_obj.get_string('process_id');
            l_trxs_tab(l_trxs_tab.last).cust_account_id := l_trx_obj.get_string('cust_account_id');
            l_trxs_tab(l_trxs_tab.last).account_number := l_trx_obj.get_string('account_number');
            l_trxs_tab(l_trxs_tab.last).party_id := l_trx_obj.get_string('party_id');
            l_trxs_tab(l_trxs_tab.last).org_nbr := l_trx_obj.get_string('org_nbr');
            l_trxs_tab(l_trxs_tab.last).amount := l_trx_obj.get_string('amount');
            l_trxs_tab(l_trxs_tab.last).gl_acc_number := l_trx_obj.get_string('gl_acc_number');
            l_trxs_tab(l_trxs_tab.last).gl_acc_name := l_trx_obj.get_string('gl_acc_name');
            l_trxs_tab(l_trxs_tab.last).je_reason := l_trx_obj.get_string('je_reason');
            l_trxs_tab(l_trxs_tab.last).je_batch_name := l_trx_obj.get_string('je_batch_name');
            l_trxs_tab(l_trxs_tab.last).je_header_name := l_trx_obj.get_string('je_header_name');
            l_trxs_tab(l_trxs_tab.last).trx_date := l_trx_obj.get_string('trx_date');
            l_trxs_tab(l_trxs_tab.last).action := l_trx_obj.get_string('action');
            l_trxs_tab(l_trxs_tab.last).submitted_by := l_trx_obj.get_string('submitted_by');
            l_trxs_tab(l_trxs_tab.last).submission_date := l_trx_obj.get_string('submission_date');
            l_trxs_tab(l_trxs_tab.last).session_id := l_trx_obj.get_string('session_id');
        END LOOP;

        FORALL i IN l_trxs_tab.first..l_trxs_tab.last
            INSERT INTO hbg_artrx_writeoff_records VALUES l_trxs_tab ( i );

        COMMIT;
        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            p_status := 'ERROR ' || sqlerrm;
    END;

    PROCEDURE create_writeoff_journals (
        p_process_id                    IN NUMBER,
        p_ar_custmaintain_writeoff_recs OUT NOCOPY hbg_ar_custmaintain_writeoff_rec_tt
    ) IS

        CURSOR c1 IS
        SELECT
            'WriteOff with process Id ' || woff.process_id journal_name,
            300000001918096                                ledger_id,
            to_char(sysdate, 'Mon-yy')                     period_name,
            to_char(sysdate, 'yyyy-mm-dd')                 acct_date,
            'Manual'                                       user_je_src,
            'Manual'                                       user_je_cat,
            woff.process_id                                group_id,
            rec_act.code_combination_id,
            woff.amount
        FROM
            hbg_artrx_writeoff_records woff,
            ar_receivables_activity    rec_act
        WHERE
                woff.gl_acc_number = rec_act.seg_name
            AND woff.process_id = p_process_id;

        p_clearing_amt NUMBER DEFAULT 0;
        i              NUMBER DEFAULT 1;
    BEGIN
        p_ar_custmaintain_writeoff_recs := hbg_ar_custmaintain_writeoff_rec_tt();
        FOR rec IN c1 LOOP
            p_ar_custmaintain_writeoff_recs.extend;
            p_ar_custmaintain_writeoff_recs(i) := hbg_ar_custmaintain_writeoff_recs(NULL, NULL, NULL, NULL, NULL,
                                                                                   NULL, NULL, NULL, NULL, NULL);

            p_ar_custmaintain_writeoff_recs(i).p_jrnl_name := rec.journal_name;
            p_ar_custmaintain_writeoff_recs(i).p_ledger_id := rec.ledger_id;
            p_ar_custmaintain_writeoff_recs(i).p_period_name := rec.period_name;
            p_ar_custmaintain_writeoff_recs(i).p_acct_prd := rec.acct_date;
            p_ar_custmaintain_writeoff_recs(i).user_je_src := rec.user_je_src;
            p_ar_custmaintain_writeoff_recs(i).user_je_cat := rec.user_je_cat;
            p_ar_custmaintain_writeoff_recs(i).code_comb_id := rec.code_combination_id;
            p_ar_custmaintain_writeoff_recs(i).debit_amount := rec.amount;
            p_ar_custmaintain_writeoff_recs(i).group_id := p_process_id;
            p_clearing_amt := p_clearing_amt + rec.amount;
            i := i + 1;
        END LOOP;

        p_ar_custmaintain_writeoff_recs.extend;
        p_ar_custmaintain_writeoff_recs(i) := hbg_ar_custmaintain_writeoff_recs(NULL, NULL, NULL, NULL, NULL,
                                                                               NULL, NULL, NULL, NULL, NULL);

        p_ar_custmaintain_writeoff_recs(i).p_jrnl_name := p_ar_custmaintain_writeoff_recs(1).p_jrnl_name;
        p_ar_custmaintain_writeoff_recs(i).p_ledger_id := p_ar_custmaintain_writeoff_recs(1).p_ledger_id;
        p_ar_custmaintain_writeoff_recs(i).p_period_name := p_ar_custmaintain_writeoff_recs(1).p_period_name;
        p_ar_custmaintain_writeoff_recs(i).p_acct_prd := p_ar_custmaintain_writeoff_recs(1).p_acct_prd;
        p_ar_custmaintain_writeoff_recs(i).user_je_src := p_ar_custmaintain_writeoff_recs(1).user_je_src;
        p_ar_custmaintain_writeoff_recs(i).user_je_cat := p_ar_custmaintain_writeoff_recs(1).user_je_cat;
        p_ar_custmaintain_writeoff_recs(i).code_comb_id := '11042';
        p_ar_custmaintain_writeoff_recs(i).credit_amount := p_clearing_amt;
        p_ar_custmaintain_writeoff_recs(i).group_id := p_process_id;
    END;

END;

/

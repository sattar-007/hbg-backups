--------------------------------------------------------
--  DDL for Package Body HBG_SO_AUTO_HOLDS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_SO_AUTO_HOLDS_PKG" IS

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Amount Exceeds Validation                        
-- |Description      : This Program is used to validate Sales Order with Payment Type as Credit Card to place them on Amount Exceed Hold  					    
-- +===================================================================+

    PROCEDURE hbg_so_amount_excds_val (
        p_source_line_id     IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

      /*  CURSOR c_exclusion IS
        SELECT DISTINCT
            source_order_id
        FROM
            hbg_auto_hold_so_info_ext hahsie
        WHERE
                1 = 1
            AND EXISTS (
                SELECT
                    1
                FROM
                    hbg_auto_hold_so_holds_ext
                WHERE
                        source_order_id = hahsie.source_order_id
                   -- AND release_code <> 'HBG_AUTO_RELEASE'
                    AND hold_code = 'HBG_Amt_Exceeds'
            );*/
	-- Below cursor is used to release the Amount Exceeds Hold if they pass the VALIDATION
        CURSOR c_release IS
        SELECT DISTINCT
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON') month,
            dha.ordered_date,
--            dha.order_amount,
            dfla.status_code,
            dha.amt_excd_hold_flag
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND ( ( upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
          --  AND account_number IN ( '12006009-TJ MAXX', '4' )
                    AND dfla.status_code = 'CANCELED'
                    AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_headers_all
                WHERE
                        header_id = dha.header_id
                    AND dfla.status_code <> 'CANCELED'
            ) )
                  OR ( upper(dha.order_type_code) <> 'HBG_CREDIT_CARD'
                       AND EXISTS (
                SELECT
                    1
                FROM
                    doo_headers_all
                WHERE
                        header_id = dha.header_id
                    AND dfla.status_code <> 'CANCELED'
            ) ) )
            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND p_batch_id IS NULL
        UNION
        SELECT DISTINCT
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON') month,
            dha.ordered_date,
--            dha.order_amount,
            dfla.status_code,
            dha.amt_excd_hold_flag
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            doo_headers_eff_b     dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'EDI General'
            AND dheb.attribute_char18 = p_batch_id
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND ( ( upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
          --  AND account_number IN ( '12006009-TJ MAXX', '4' )
                    AND dfla.status_code = 'CANCELED'
                    AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_headers_all
                WHERE
                        header_id = dha.header_id
                    AND dfla.status_code <> 'CANCELED'
            ) )
                  OR ( upper(dha.order_type_code) <> 'HBG_CREDIT_CARD'
                       AND EXISTS (
                SELECT
                    1
                FROM
                    doo_headers_all
                WHERE
                        header_id = dha.header_id
                    AND dfla.status_code <> 'CANCELED'
            ) ) )
            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id);

        CURSOR c1 IS
        SELECT
            *
        FROM
            (
                SELECT
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON') month,
                    dha.ordered_date,
                    SUM(dla.extended_amount)         order_amount,
                    dha.amt_excd_hold_flag
                FROM
                    doo_headers_all       dha,
                    doo_lines_all         dla,
                    doo_fulfill_lines_all dfla,
                    hz_cust_accounts      hca
                WHERE
                        1 = 1
                    AND dha.header_id = dla.header_id
                    AND dla.line_id = dfla.line_id
                    AND dfla.bill_to_customer_id = hca.cust_account_id
                    AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
                    AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                                  'SHIPPED' )
                    AND dha.object_version_number = (
                        SELECT
                            MAX(object_version_number)
                        FROM
                            doo_headers_all
                        WHERE
                                dha.source_order_id = source_order_id
                            AND dha.source_order_system = source_order_system
                            AND status_code <> 'DOO_REFERENCE'
                    )
                    AND upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
                GROUP BY
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON'),
                    dha.ordered_date,
            --SUM(DLA.EXTENDED_AMOUNT) order_amount,
                    dha.amt_excd_hold_flag
                UNION
                SELECT
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON') month,
                    dha.ordered_date,
                    SUM(dla.extended_amount)         order_amount,
                    dha.amt_excd_hold_flag
                FROM
                    doo_headers_all       dha,
                    doo_lines_all         dla,
                    doo_fulfill_lines_all dfla,
                    hz_cust_accounts      hca
                WHERE
                        1 = 1
                    AND dha.header_id = dla.header_id
                    AND dla.line_id = dfla.line_id
                    AND dfla.bill_to_customer_id = hca.cust_account_id
                    AND dha.status_code IN ( 'DOO_DRAFT' )
                    AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
                    AND dha.object_version_number = (
                        SELECT
                            MAX(object_version_number)
                        FROM
                            doo_headers_all
                        WHERE
                                dha.source_order_id = source_order_id
                            AND dha.source_order_system = source_order_system
                    )
                    AND upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
                GROUP BY
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON'),
                    dha.ordered_date,
            --SUM(DLA.EXTENDED_AMOUNT) order_amount,
                    dha.amt_excd_hold_flag
            )
        ORDER BY
            account_number,
            ordered_date;

        CURSOR c2 (
            acc_number VARCHAR2,
            order_date DATE
        ) IS
        SELECT
            *
        FROM
            (
                SELECT
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON') month,
                    dha.ordered_date,
                    SUM(dla.extended_amount)         order_amount,
                    dha.amt_excd_hold_flag
                FROM
                    doo_headers_all       dha,
                    doo_lines_all         dla,
                    doo_fulfill_lines_all dfla,
                    hz_cust_accounts      hca
                WHERE
                        1 = 1
                    AND dha.header_id = dla.header_id
                    AND dla.line_id = dfla.line_id
                    AND dfla.bill_to_customer_id = hca.cust_account_id
                    AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
                    AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                                  'SHIPPED' )
                    AND dha.object_version_number = (
                        SELECT
                            MAX(object_version_number)
                        FROM
                            doo_headers_all
                        WHERE
                                dha.source_order_id = source_order_id
                            AND dha.source_order_system = source_order_system
                            AND status_code <> 'DOO_REFERENCE'
                    )
                    AND upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
                    AND nvl(amt_excd_hold_flag, 'N') IN ( 'H', 'Y' )
                    AND account_number = acc_number
                    AND trunc(ordered_date) <= trunc(last_day(add_months(order_date, - 1)))
                GROUP BY
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON'),
                    dha.ordered_date,
                    dha.amt_excd_hold_flag
                UNION
                SELECT
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON') month,
                    dha.ordered_date,
                    SUM(dla.extended_amount)         order_amount,
                    dha.amt_excd_hold_flag
                FROM
                    doo_headers_all       dha,
                    doo_lines_all         dla,
                    doo_fulfill_lines_all dfla,
                    hz_cust_accounts      hca
                WHERE
                        1 = 1
                    AND dha.header_id = dla.header_id
                    AND dla.line_id = dfla.line_id
                    AND dfla.bill_to_customer_id = hca.cust_account_id
                    AND dha.status_code IN ( 'DOO_DRAFT' )
                    AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
                    AND dha.object_version_number = (
                        SELECT
                            MAX(object_version_number)
                        FROM
                            doo_headers_all
                        WHERE
                                dha.source_order_id = source_order_id
                            AND dha.source_order_system = source_order_system
                    )
                    AND upper(dha.order_type_code) = 'HBG_CREDIT_CARD'
                    AND nvl(amt_excd_hold_flag, 'N') IN ( 'H', 'Y' )
                    AND account_number = acc_number
                    AND trunc(ordered_date) <= trunc(last_day(add_months(order_date, - 1)))
                GROUP BY
                    dha.source_order_id,
                    hca.account_number,
                    dha.order_number,
                    to_char(dha.ordered_date, 'MON'),
                    dha.ordered_date,
                    dha.amt_excd_hold_flag
            )
        ORDER BY
            account_number,
            ordered_date;

        CURSOR get_valid_lines (
            profile_limit NUMBER,
            markup_limit  NUMBER
        ) IS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON')                        month,
            dha.ordered_date,
            SUM(dla.extended_amount)                                order_amount,
            dha.amt_excd_hold_flag,
            'HBG_Amt_Exceeds'                                       hold_name,
            'Order amount $'
            || TRIM(to_char(SUM(dla.extended_amount), '999,999,999,999.00'))
            || ' plus markup $'
            || TRIM(to_char(round((markup_limit * SUM(dla.extended_amount)) / 100), '999,999,999,999.00'))
            || ' does not fit within the monthly 
							threshold $'
            || profile_limit
            || ' 
							since '
            || to_char(dha.ordered_date, 'Mon')
            || concat('''', 's open CC orders are currently 
							$')
            || TRIM(to_char(dha.open_cc_amt, '999,999,999,999.00')) hold_comments,
            'HBG_AUTO_RELEASE'                                      release_code,
            'Automatically released because Order amount $'
            || TRIM(to_char(SUM(dla.extended_amount), '999,999,999,999.00'))
            || ' plus markup $'
            || TRIM(to_char(round((markup_limit * SUM(dla.extended_amount)) / 100), '999,999,999,999.00'))
            || ' does fit within the monthly 
							threshold $'
            || profile_limit
            || ' 
							since '
            || to_char(dha.ordered_date, 'Mon')
            || concat('''', 's open CC orders are  
							$')
            || TRIM(to_char(dha.open_cc_amt, '999,999,999,999.00')) release_comments
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')) = 'N'
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND p_batch_id IS NULL
            --AND order_type = 'HBG_CREDIT_CARD'
            AND nvl(dha.amt_excd_hold_flag, 'N') IN ( 'Y', 'R' )
            AND dha.header_id IN (
                SELECT
                    header_id
                FROM
                    doo_lines_all
                WHERE
                    source_line_id = nvl(p_source_line_id, dla.source_line_id)
            )
            AND ( EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dha.source_order_id
                    AND dhi.transaction_entity_name1 = 'DOO_ORDER_HEADERS_V'
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Amt_Exceeds'
                    AND dhi.hold_release_reason_code IS NULL
                    AND dha.amt_excd_hold_flag IN ( 'R' )
            )
                  OR NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dha.source_order_id
                    AND dhi.transaction_entity_name1 = 'DOO_ORDER_HEADERS_V'
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Amt_Exceeds'
                    --AND release_code IS NULL
                    AND dha.amt_excd_hold_flag = 'Y'
            ) )
        GROUP BY
            dha.source_order_system,
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON'),
            dha.ordered_date,
            dha.amt_excd_hold_flag,
            dha.open_cc_amt
        UNION
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON')                        month,
            dha.ordered_date,
            SUM(dla.extended_amount)                                order_amount,
            dha.amt_excd_hold_flag,
            'HBG_Amt_Exceeds'                                       hold_name,
            'Order amount $'
            || TRIM(to_char(SUM(dla.extended_amount), '999,999,999,999.00'))
            || ' plus markup $'
            || TRIM(to_char(round((markup_limit * SUM(dla.extended_amount)) / 100), '999,999,999,999.00'))
            || ' does not fit within the monthly 
							threshold $'
            || profile_limit
            || ' 
							since '
            || to_char(dha.ordered_date, 'Mon')
            || concat('''', 's open CC orders are currently 
							$')
            || TRIM(to_char(dha.open_cc_amt, '999,999,999,999.00')) hold_comments,
            'HBG_AUTO_RELEASE'                                      release_code,
            'Automatically released because Order amount $'
            || TRIM(to_char(SUM(dla.extended_amount), '999,999,999,999.00'))
            || ' plus markup $'
            || TRIM(to_char(round((markup_limit * SUM(dla.extended_amount)) / 100), '999,999,999,999.00'))
            || ' does fit within the monthly 
							threshold $'
            || profile_limit
            || ' 
							since '
            || to_char(dha.ordered_date, 'Mon')
            || concat('''', 's open CC orders are  
							$')
            || TRIM(to_char(dha.open_cc_amt, '999,999,999,999.00')) release_comments
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb,
            doo_headers_eff_b       dheb_batch
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND dha.header_id = dheb_batch.header_id (+)
            AND dheb_batch.context_code (+) = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')) = 'N'
            --AND order_type = 'HBG_CREDIT_CARD'
            AND nvl(dha.amt_excd_hold_flag, 'N') IN ( 'Y', 'R' )
            AND dha.header_id IN (
                SELECT
                    header_id
                FROM
                    doo_lines_all
                WHERE
                    source_line_id = nvl(p_source_line_id, dla.source_line_id)
            )
            AND ( EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dha.source_order_id
                    AND dhi.transaction_entity_name1 = 'DOO_ORDER_HEADERS_V'
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Amt_Exceeds'
                    AND dhi.hold_release_reason_code IS NULL
                    AND dha.amt_excd_hold_flag IN ( 'R' )
            )
                  OR NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dha.source_order_id
                    AND dhi.transaction_entity_name1 = 'DOO_ORDER_HEADERS_V'
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Amt_Exceeds'
                    --AND release_code IS NULL
                    AND dha.amt_excd_hold_flag = 'Y'
            ) )
        GROUP BY
            dha.source_order_system,
            dha.source_order_id,
            hca.account_number,
            dha.order_number,
            to_char(dha.ordered_date, 'MON'),
            dha.ordered_date,
            dha.amt_excd_hold_flag,
            dha.open_cc_amt;

        l_threshold_amount   NUMBER;
        l_threshold_perc     NUMBER;
        l_order_amount       NUMBER;
        l_previous_month     VARCHAR2(100);
        l_threshold_cal      NUMBER;
        l_previous_acct      VARCHAR2(255);
        l_return_status      VARCHAR2(200);
        loop_index           NUMBER := 1;
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        BEGIN
            SELECT
                fpov.profile_option_value
            INTO l_threshold_amount
            FROM
                fnd_profile_option_values fpov,
                fnd_profile_options_vl    fpo
            WHERE
                    1 = 1
                AND fpov.profile_option_id = fpo.profile_option_id
                AND fpo.profile_option_name = 'HBG_AMT_EXCD_MON_LMT'; -- SQL Statement to get the Threshold Amount set at Amount Exceeds PROFILE

        EXCEPTION
            WHEN OTHERS THEN
                l_threshold_amount := 0;
        END;

        BEGIN
            SELECT
                fpov.profile_option_value
            INTO l_threshold_perc
            FROM
                fnd_profile_option_values fpov,
                fnd_profile_options_vl    fpo
            WHERE
                    1 = 1
                AND fpov.profile_option_id = fpo.profile_option_id
                AND fpo.profile_option_name = 'HBG_AMT_EXCD_MARKUP';-- SQL Statement to get the Threshold Markup set at Amount Exceeds PROFILE

        EXCEPTION
            WHEN OTHERS THEN
                l_threshold_perc := 0;
        END;

     /*   FOR c_exclusion_list IN c_exclusion LOOP
            UPDATE hbg_auto_hold_so_info_ext
            SET
                amt_excd_hold_flag = 'E'
            WHERE
                source_order_id = c_exclusion_list.source_order_id;

            COMMIT;
        END LOOP;
	*/
	-- Update the lines flag to Release if validation is success and falls under threshold LIMIT
        FOR c_rel IN c_release LOOP
            UPDATE doo_headers_all
            SET
                amt_excd_hold_flag =
                    CASE
                        WHEN c_rel.amt_excd_hold_flag = 'H' THEN
                            'R'
                        ELSE
                            'N'
                    END
            WHERE
                source_order_id = c_rel.source_order_id;

            COMMIT;
        END LOOP;

	-- Update the lines flag to Hold if validation is fails and does not fall under threshold LIMIT
        FOR c IN c1 LOOP
            IF ( c.month <> nvl(l_previous_month, '999999999') OR c.account_number <> nvl(l_previous_acct, 0) ) THEN
                l_threshold_cal := 0;
                FOR c2_open IN c2(c.account_number, c.ordered_date) LOOP -- Inside loop to get the previous months orders placed on Hold to validate if they fall under threshold limit
                    l_order_amount := c2_open.order_amount + ( c2_open.order_amount * l_threshold_perc ) / 100;
                    IF ( l_threshold_cal + l_order_amount <= l_threshold_amount ) THEN
                        l_threshold_cal := l_threshold_cal + l_order_amount;
                        UPDATE doo_headers_all
                        SET
                            amt_excd_hold_flag =
                                CASE
                                    WHEN c2_open.amt_excd_hold_flag = 'H' THEN
                                        'R'
                                    ELSE
                                        'R'
                                END,
                            open_cc_amt = l_threshold_cal
                        WHERE
                            order_number = c2_open.order_number;

                    ELSE
                        l_threshold_cal := l_threshold_cal + l_order_amount;
                        UPDATE doo_headers_all
                        SET
                            amt_excd_hold_flag =
                                CASE
                                    WHEN c2_open.amt_excd_hold_flag = 'H' THEN
                                        'H'
                                    ELSE
                                        'Y'
                                END,
                            open_cc_amt =
                                CASE
                                    WHEN l_threshold_cal <= 0 THEN
                                        0
                                    ELSE
                                        l_threshold_cal
                                END
                        WHERE
                            order_number = c2_open.order_number;

                    END IF;

                    COMMIT;
                END LOOP;

            END IF;

            l_order_amount := c.order_amount + ( c.order_amount * l_threshold_perc ) / 100;
			--dbms_output.put_line(l_threshold_cal||' '||c.order_number||' '||l_order_amount);
            IF ( l_order_amount = 0 ) THEN
                l_threshold_cal := l_threshold_cal + l_order_amount;
                UPDATE doo_headers_all
                SET
                    amt_excd_hold_flag =
                        CASE
                            WHEN c.amt_excd_hold_flag = 'H' THEN
                                'R'
                            ELSE
                                'R'
                        END,
                    open_cc_amt = l_threshold_cal
                WHERE
                    order_number = c.order_number;

                l_previous_month := c.month;
                l_previous_acct := c.account_number;
            ELSIF ( l_threshold_cal + l_order_amount <= l_threshold_amount ) THEN
                l_threshold_cal := l_threshold_cal + l_order_amount;
                UPDATE doo_headers_all
                SET
                    amt_excd_hold_flag =
                        CASE
                            WHEN c.amt_excd_hold_flag = 'H' THEN
                                'R'
                            ELSE
                                'R'
                        END,
                    open_cc_amt = l_threshold_cal
                WHERE
                    order_number = c.order_number;

                l_previous_month := c.month;
                l_previous_acct := c.account_number;
				--dbms_output.put_line(l_threshold_cal||' '||c.order_number||' '||'N');
            ELSE
                l_threshold_cal := l_threshold_cal + l_order_amount;
                UPDATE doo_headers_all
                SET
                    amt_excd_hold_flag =
                        CASE
                            WHEN c.amt_excd_hold_flag = 'H' THEN
                                'H'
                            ELSE
                                'Y'
                        END,
                    open_cc_amt = l_threshold_cal
                WHERE
                    order_number = c.order_number;

                l_previous_month := c.month;
                l_previous_acct := c.account_number;
				--dbms_output.put_line(l_threshold_cal||' '||c.order_number||' '||'C3');
            END IF;

            COMMIT;
            --dbms_output.put_line(l_order_amount);
        END LOOP;

        COMMIT;
        FOR c_lines IN get_valid_lines(l_threshold_amount, l_threshold_perc) LOOP
            v_so_hold_array_disp.extend;
            v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_lines.source_order_system, c_lines.source_order_id, NULL, c_lines.
            hold_name, c_lines.hold_comments,
                                                                      c_lines.release_code, c_lines.release_comments, c_lines.amt_excd_hold_flag,
                                                                      c_lines.account_number, c_lines.order_number);

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_so_amount_excds_val;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Gift Reveiw Validation                        
-- |Description      : This Program is used to validate Sales Order with Order Type as Gifting to place them on Gift Review Hold  					    
-- +===================================================================+

    PROCEDURE hbg_so_gift_reveiw_val (
        p_order_line_id      IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

        loop_index           NUMBER := 1;
        CURSOR get_valid_lines (
            l_gift_threshold NUMBER
        ) IS
        SELECT DISTINCT
            dha.source_order_system,
            dha.source_order_id,
            dla.source_line_id,
            dla.unit_list_price,
            'HBG_Gift_Review' hold_name,
            'Gifting Order with list price >= $'
            || l_gift_threshold
            || ' USD'         hold_comments,
            hca.account_number,
            dha.order_number
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.source_line_id = nvl(p_order_line_id, dla.source_line_id)
--    AND dha.order_number = '123'
            AND dla.unit_list_price >= l_gift_threshold
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')))) = 'N'
            AND upper(dha.order_type_code) = 'HBG_GIFTING'
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND p_batch_id IS NULL
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
                    AND status_code <> 'DOO_REFERENCE'
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Gift_Review'
--            AND dhi.hold_release_reason_code is not null
            )
        UNION
        SELECT DISTINCT
            dha.source_order_system,
            dha.source_order_id,
            dla.source_line_id,
            dla.unit_list_price,
            'HBG_Gift_Review' hold_name,
            'Gifting Order with list price >= $'
            || l_gift_threshold
            || ' USD'         hold_comments,
            hca.account_number,
            dha.order_number
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb,
            doo_headers_eff_b       dheb_batch
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.source_line_id = nvl(p_order_line_id, dla.source_line_id)
--    AND dha.order_number = '123'
            AND dla.unit_list_price >= l_gift_threshold
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')))) = 'N'
            AND upper(dha.order_type_code) = 'HBG_GIFTING'
            AND dha.header_id = dheb_batch.header_id
            AND dheb_batch.context_code = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Gift_Review'
--            AND dhi.hold_release_reason_code is not null
            );

        l_gift_threshold     NUMBER;
        l_return_status      VARCHAR2(200);
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        BEGIN
            SELECT
                fpov.profile_option_value
            INTO l_gift_threshold
            FROM
                fnd_profile_option_values fpov,
                fnd_profile_options_vl    fpo
            WHERE
                    1 = 1
                AND fpov.profile_option_id = fpo.profile_option_id
                AND fpo.profile_option_name = 'HBG_GIFT_REVIEW_THRESHOLD'; -- SQL Statement to get threshold quantity set for Gifting Orders

        EXCEPTION
            WHEN OTHERS THEN
                l_gift_threshold := 0;
        END;

        FOR c_get_valid_lines IN get_valid_lines(l_gift_threshold) LOOP
            v_so_hold_array_disp.extend;
            v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      NULL, NULL, NULL, c_get_valid_lines.account_number, c_get_valid_lines.
                                                                      order_number);

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_so_gift_reveiw_val;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Prepaid Validation                        
-- |Description      : This Program is used to validate Sales Order having Customer Account Status on 'Loss' to place them on Prepaid Hold  					    
-- +===================================================================+

    PROCEDURE hbg_so_prepaid_val (
        p_order_line_id      IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

        loop_index           NUMBER := 1;
        CURSOR get_valid_lines IS
        SELECT DISTINCT
            dha.source_order_system,
            dha.source_order_id,
            dla.source_line_id,
            'HBG_Prepaid'                   hold_name,
            'Account has Credit Status = L' hold_comments,
            hca.account_number,
            dha.order_number
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_customer_profiles_f  hcpf,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.order_number NOT IN ( '1580' )
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dfla.bill_to_customer_id = hcpf.cust_account_id
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')))) = 'N'
            AND dla.source_line_id = nvl(p_order_line_id, dla.source_line_id)
            AND hcpf.account_status = 'LOSS'
            AND p_batch_id IS NULL
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
                    AND status_code <> 'DOO_REFERENCE'
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Prepaid'
--            AND dhi.hold_release_reason_code is not null
            )
        UNION
        SELECT DISTINCT
            dha.source_order_system,
            dha.source_order_id,
            dla.source_line_id,
            'HBG_Prepaid'                   hold_name,
            'Account has Credit Status = L' hold_comments,
            hca.account_number,
            dha.order_number
        FROM
            doo_headers_all         dha,
            doo_lines_all           dla,
            doo_fulfill_lines_all   dfla,
            hz_customer_profiles_f  hcpf,
            hz_cust_accounts        hca,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb,
            doo_headers_eff_b       dheb_batch
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
--    AND dha.order_number = '123'
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dfla.bill_to_customer_id = hcpf.cust_account_id
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char5, nvl(dheb.attribute_char7, 'N')))) = 'N'
            AND dla.source_line_id = nvl(p_order_line_id, dla.source_line_id)
            AND hcpf.account_status = 'LOSS'
            AND dha.header_id = dheb_batch.header_id
            AND dheb_batch.context_code = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Prepaid'
--            AND dhi.hold_release_reason_code is not null
            );

        l_return_status      VARCHAR2(200);
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        FOR c_get_valid_lines IN get_valid_lines LOOP
            v_so_hold_array_disp.extend;
            v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      NULL, NULL, NULL, c_get_valid_lines.account_number, c_get_valid_lines.
                                                                      order_number);

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_so_prepaid_val;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : SO Custom Rules Extract                        
-- |Description      : This Program is used to Extract all the Valid Validation Rules Created in VBCS Application 					    
-- +===================================================================+	

    PROCEDURE hbg_so_custom_rules (
        p_owner                            IN VARCHAR2,
        p_reporting_group                  IN VARCHAR2,
        p_category1                        IN VARCHAR2,
        p_category2                        IN VARCHAR2,
        p_item_number                      IN VARCHAR2,
        p_short_title                      IN VARCHAR2,
        p_short_author                     IN VARCHAR2,
        p_organization                     IN VARCHAR2,
        p_organization_name                IN VARCHAR2,
        p_account_number                   IN VARCHAR2,
        p_account_name                     IN VARCHAR2,
        p_shipto                           IN VARCHAR2,
        p_shipto_name                      IN VARCHAR2,
        p_country                          IN VARCHAR2,
        p_state                            IN VARCHAR2,
        p_holdname                         IN VARCHAR2,
        p_autoreleaseflag                  IN VARCHAR2,
        p_hbg_auto_hold_custom_rules_array OUT hbg_auto_hold_custom_rules_type_array
    ) IS

        CURSOR get_valid_lines IS
        SELECT
            hahcre.owner_name                                         owner_name,
            hahvse_owner.description                                  owner_name_desc,
            hahvse_reporting.description                              reporting_group,
            hahvse_reporting.meaning                                  reporting_group_desc,
            hahvse_catgeory1.description                              category_1,
            hahvse_catgeory1.meaning                                  category_1_desc,
            hahvse_catgeory2.description                              category_2,
            hahvse_catgeory2.meaning                                  category_2_desc,
            hahcre.item_number,
            hahie.author,
            hahie.short_title,
            hahcre.organization,
            (
                SELECT DISTINCT
                    organization_name
                FROM
                    hbg_auto_hold_customer_ext
                WHERE
                        organization_number = hahcre.organization
                    AND ROWNUM = 1
            )                                                         organization_name,
            hahcre.account_number,
            hahce.account_name,
            hahcre.ship_to_site,
            hahce.party_site_name,
            hahcre.country,
            hahcre.state,
            hahce.hold_name,
            hahcre.hold_comments,
            to_char(hahcre.start_date, 'MM-DD-YYYY')                  start_date,
            to_char(hahcre.end_date, 'MM-DD-YYYY')                    end_date,
            hahcre.auto_release_flag,
            hahcre.rule_id,
            hahcre.comments,
            to_char(hahcre.creation_date, 'MM-DD-YYYY HH24:MI:ss')    creation_date,
            hahcre.created_by,
            to_char(hahcre.last_update_date, 'MM-DD-YYYY HH24:MI:ss') last_update_date,
            hahcre.last_updated_by
        FROM
            hbg_auto_hold_custom_rules_ext hahcre,
            hbg_auto_hold_items_ext        hahie,
            hbg_auto_hold_customer_ext     hahce,
            hbg_auto_hold_value_sets_ext   hahvse_owner,
            hbg_auto_hold_lookups_ext      hahvse_reporting,
            hbg_auto_hold_lookups_ext      hahvse_catgeory1,
            hbg_auto_hold_lookups_ext      hahvse_catgeory2,
            hbg_auto_hold_codes_ext        hahce
        WHERE
                1 = 1
            AND hahcre.item_number = hahie.item_number (+)
            AND hahie.organization_code (+) = 'ITEM_MASTER'
            AND hahcre.organization = hahce.organization_number (+)
            AND hahcre.account_number = hahce.account_number (+)
            AND hahcre.ship_to_site = hahce.party_site_number (+)
            AND hahce.site_use_code (+) = 'SHIP_TO'
            AND hahcre.owner_name = hahvse_owner.flex_value (+)
            AND hahvse_owner.value_set_name (+) = 'HBG_Owner'
            AND hahcre.reporting_group = hahvse_reporting.lookup_code (+)
            AND hahvse_reporting.lookup_type (+) = 'HBG_REPORTING_GROUP'
            AND hahcre.category_1 = hahvse_catgeory1.lookup_code (+)
            AND hahvse_catgeory1.lookup_type (+) = 'HBG_CATEGORY_1'
            AND hahcre.category_2 = hahvse_catgeory2.lookup_code (+)
            AND hahvse_catgeory2.lookup_type (+) = 'HBG_CATEGORY_2'
            AND hahcre.hold_name = hahce.hold_code (+)
            AND nvl(hahcre.owner_name, '999999999') LIKE nvl(p_owner, nvl(hahcre.owner_name, '999999999'))
            AND nvl(hahvse_reporting.description, '999999999') LIKE nvl(p_reporting_group, nvl(hahvse_reporting.description, '999999999'))
            AND nvl(hahvse_catgeory1.description, '999999999') LIKE nvl(p_category1, nvl(hahvse_catgeory1.description, '999999999'))
            AND nvl(hahvse_catgeory2.description, '999999999') LIKE nvl(p_category2, nvl(hahvse_catgeory2.description, '999999999'))
            AND nvl(hahcre.item_number, '999999999') LIKE nvl(p_item_number, nvl(hahcre.item_number, '999999999'))
            AND nvl(hahie.short_title, '999999999') LIKE nvl(p_short_title, nvl(hahie.short_title, '999999999'))
            AND nvl(hahie.author, '999999999') LIKE nvl(p_short_author, nvl(hahie.author, '999999999'))
            AND nvl(hahcre.organization, '999999999') LIKE nvl(p_organization, nvl(hahcre.organization, '999999999'))
            AND nvl(hahce.organization_name, '999999999') LIKE nvl(p_organization_name, nvl(hahce.organization_name, '999999999'))
            AND nvl(hahcre.ship_to_site, '999999999') LIKE nvl(p_shipto, nvl(hahcre.ship_to_site, '999999999'))
            AND nvl(hahce.party_site_name, '999999999') LIKE nvl(p_shipto_name, nvl(hahce.party_site_name, '999999999'))
            AND nvl(hahcre.account_number, '999999999') LIKE nvl(p_account_number, nvl(hahcre.account_number, '999999999'))
            AND nvl(hahce.account_name, '999999999') LIKE nvl(p_account_name, nvl(hahce.account_name, '999999999'))
            AND nvl(hahcre.country, '999999999') LIKE nvl(p_country, nvl(hahcre.country, '999999999'))
            AND nvl(hahcre.state, '999999999') LIKE nvl(p_state, nvl(hahcre.state, '999999999'))
            AND nvl(hahce.hold_name, '999999999') LIKE nvl(p_holdname, nvl(hahce.hold_name, '999999999'))
            AND nvl(hahcre.auto_release_flag, '999999999') LIKE nvl(p_autoreleaseflag, nvl(hahcre.auto_release_flag, '999999999'))
        ORDER BY
            hahcre.rule_id,
            hahcre.start_date;

        loop_index                        NUMBER := 1;
        v_hbg_auto_hold_custom_rules_disp hbg_auto_hold_custom_rules_type_array := hbg_auto_hold_custom_rules_type_array();
    BEGIN
        FOR c_get_valid_lines IN get_valid_lines LOOP
            v_hbg_auto_hold_custom_rules_disp.extend;
            v_hbg_auto_hold_custom_rules_disp(loop_index) := hbg_auto_hold_custom_rules_type(c_get_valid_lines.owner_name, c_get_valid_lines.
            reporting_group, c_get_valid_lines.category_1, c_get_valid_lines.category_2, c_get_valid_lines.item_number,
                                                                                            c_get_valid_lines.author, c_get_valid_lines.
                                                                                            short_title, c_get_valid_lines.organization,
                                                                                            c_get_valid_lines.organization_name, c_get_valid_lines.
                                                                                            account_number,
                                                                                            c_get_valid_lines.account_name, c_get_valid_lines.
                                                                                            ship_to_site, c_get_valid_lines.party_site_name,
                                                                                            c_get_valid_lines.country, c_get_valid_lines.
                                                                                            state,
                                                                                            c_get_valid_lines.hold_name, c_get_valid_lines.
                                                                                            hold_comments, c_get_valid_lines.start_date,
                                                                                            c_get_valid_lines.end_date, c_get_valid_lines.
                                                                                            auto_release_flag,
                                                                                            c_get_valid_lines.rule_id, c_get_valid_lines.
                                                                                            comments);

            loop_index := loop_index + 1;
        END LOOP;

        p_hbg_auto_hold_custom_rules_array := v_hbg_auto_hold_custom_rules_disp;
    EXCEPTION
        WHEN OTHERS THEN
            p_hbg_auto_hold_custom_rules_array := v_hbg_auto_hold_custom_rules_disp;
    END hbg_so_custom_rules;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : SO Custom Rules UPDATE                        
-- |Description      : This Program is used to Updated Validation Rules Created in VBCS Application 					    
-- +===================================================================+	

    PROCEDURE hbg_so_custom_rule_update (
        p_comments        IN VARCHAR2,
        p_autoreleaseflag IN VARCHAR2,
        p_end_date        IN DATE,
        p_rule_id         IN NUMBER,
        p_last_updated_by IN VARCHAR2,
        p_hold_comments   IN VARCHAR2,
        p_department      IN VARCHAR2,
        p_return_status   OUT VARCHAR2
    ) IS
        l_return_status VARCHAR2(200) := NULL;
    BEGIN
        UPDATE hbg_auto_hold_custom_rules_ext
        SET
            end_date = p_end_date,
            comments = p_comments,
            hold_comments = p_hold_comments,
            auto_release_flag = p_autoreleaseflag,
            last_updated_by = p_last_updated_by,
            last_update_date = sysdate,
            department = p_department
        WHERE
            rule_id = p_rule_id;

        COMMIT;
        l_return_status := 'SUCCESS';
        p_return_status := l_return_status;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'FAILURE';
            p_return_status := l_return_status;
    END hbg_so_custom_rule_update;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : SO Custom Rules Creation                        
-- |Description      : This Program is used to Insert Validation Rules Created in VBCS Application 					    
-- +===================================================================+	

    PROCEDURE hbg_so_custom_rule_create (
        p_owner           IN VARCHAR2,
        p_reporting_group IN VARCHAR2,
        p_category1       IN VARCHAR2,
        p_category2       IN VARCHAR2,
        p_item_number     IN VARCHAR2,
        p_organization    IN VARCHAR2,
        p_account_number  IN VARCHAR2,
        p_shipto          IN VARCHAR2,
        p_country         IN VARCHAR2,
        p_state           IN VARCHAR2,
        p_holdname        IN VARCHAR2,
        p_hold_comments   IN VARCHAR2,
        p_start_date      IN DATE,
        p_comments        IN VARCHAR2,
        p_autoreleaseflag IN VARCHAR2,
        p_end_date        IN DATE,
        p_created_by      IN VARCHAR2,
        p_last_updated_by IN VARCHAR2,
        p_department      IN VARCHAR2,
        p_zipcode         IN VARCHAR2,
        p_return_status   OUT VARCHAR2
    ) IS
        l_count          NUMBER := 0;
        l_existing_count NUMBER;
        l_zip_code       VARCHAR2(2000);
    BEGIN
        BEGIN
            SELECT
                COUNT(1)
            INTO l_count
            FROM
                egp_system_items_b
            WHERE
                item_number = p_item_number;

        EXCEPTION
            WHEN OTHERS THEN
                l_count := 0;
        END;

        BEGIN
            SELECT
                LISTAGG(zip_code, ';') WITHIN GROUP(
                ORDER BY
                    key
                )
            INTO l_zip_code
            FROM
                (
                    SELECT
                        regexp_substr(p_zipcode, '[^,]+', 1, level) zip_code,
                        1                                           key
                    FROM
                        dual
                    CONNECT BY
                        regexp_substr(p_zipcode, '[^,]+', 1, level) IS NOT NULL
                ) a
            WHERE
                    1 = 1
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        hz_geographies
                    WHERE
                        geography_name = a.zip_code
                )
            GROUP BY
                key;

        EXCEPTION
            WHEN OTHERS THEN
                l_zip_code := NULL;
        END;

        BEGIN
            SELECT
                COUNT(1)
            INTO l_existing_count
            FROM
                hbg_auto_hold_custom_rules_ext
            WHERE
                    1 = 1
                AND nvl(owner_name, '#NULL') = nvl(p_owner, '#NULL')
                AND nvl(reporting_group, '#NULL') = nvl(p_reporting_group, '#NULL')
                AND nvl(category_1, '#NULL') = nvl(p_category1, '#NULL')
                AND nvl(category_2, '#NULL') = nvl(p_category2, '#NULL')
                AND nvl(organization, '#NULL') = nvl(p_organization, '#NULL')
                AND nvl(account_number, '#NULL') = nvl(p_account_number, '#NULL')
                AND nvl(ship_to_site, '#NULL') = nvl(p_shipto, '#NULL')
                AND nvl(item_number, '#NULL') = nvl(p_item_number, '#NULL')
                AND nvl(country, '#NULL') = nvl(p_country, '#NULL')
                AND nvl(state, '#NULL') = nvl(p_state, '#NULL')
                AND hold_name = p_holdname
                AND nvl(zip_code, '#NULL') = nvl(p_zipcode, '#NULL')
                AND ( nvl(p_start_date, sysdate) BETWEEN start_date AND nvl(end_date, TO_DATE('4812-12-31', 'YYYY-MM-DD'))
                      OR nvl(p_end_date, TO_DATE('4812-12-31', 'YYYY-MM-DD')) BETWEEN start_date AND nvl(end_date, TO_DATE('4812-12-31',
                      'YYYY-MM-DD')) );

        EXCEPTION
            WHEN OTHERS THEN
                l_existing_count := 0;
        END;

        IF (
            p_owner IS NULL
            AND p_item_number IS NULL
            AND p_organization IS NULL
            AND p_country IS NULL
            AND p_state IS NULL
        ) THEN
            p_return_status := 'Rule must populate one of the field like Owner, Item, Organization, Country or State';
        ELSIF ( p_holdname IS NULL ) THEN
            p_return_status := 'Hold Name cannot be null';
        ELSIF (
            l_count = 0
            AND p_item_number IS NOT NULL
        ) THEN
            p_return_status := 'Item does not exists, please enter the valid item number ';
        ELSIF ( l_existing_count > 0 ) THEN
            p_return_status := 'Rule with this combination already exists';
        ELSIF ( l_zip_code IS NOT NULL ) THEN
            p_return_status := 'Invalid Zip Codes exists '
                               || l_zip_code
                               || ' , Please Select the valid Zip Codes';
        ELSE
            INSERT INTO hbg_auto_hold_custom_rules_ext (
                owner_name,
                reporting_group,
                category_1,
                category_2,
                item_number,
                organization,
                account_number,
                ship_to_site,
                country,
                state,
                hold_name,
                hold_comments,
                start_date,
                end_date,
                auto_release_flag,
                comments,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                department,
                zip_code
            ) VALUES (
                p_owner,
                p_reporting_group,
                p_category1,
                p_category2,
                p_item_number,
                p_organization,
                p_account_number,
                p_shipto,
                p_country,
                p_state,
                p_holdname,
                p_hold_comments,
                p_start_date,
                p_end_date,
                p_autoreleaseflag,
                p_comments,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate,
                p_department,
                p_zipcode
            );

            p_return_status := 'SUCCESS';
        END IF;
   /* EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'FAILURE';*/
    END;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : SO Custom Rules VALIDATION                        
-- |Description      : This Program is used to Validate SO Information and place the orders on Holds 					    
-- +===================================================================+	

    PROCEDURE hbg_so_custom_rule_hold (
        p_source_line_id     IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

        l_return_status      VARCHAR2(255);
        CURSOR c_val IS
        SELECT DISTINCT
            source_order_system,
            source_order_id,
            source_line_id,
            hold_name,
            hold_comments
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.order_number, a.source_line_id, a.hold_name -- We will assign the rank to each record by considering order, line and hold name as group with start date as ordering
                         ORDER BY
                             substr(a.hold_level, - 2), a.start_date
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_system,
                            dha.source_order_id,
                            dla.source_line_id,
                            dfla.fulfill_line_id,
                            dha.order_number,
                            hahcre.owner_name,
                            hahcre.reporting_group,
                            hahcre.category_1,
                            hahcre.category_2,
                            hahcre.item_number,
                            hahcre.organization,
                            hahcre.account_number,
                            hahcre.ship_to_site,
                            hahcre.country,
                            hahcre.state,
                            hahcre.hold_name,
                            hahcre.rule_id
                            || ' - '
                            || hahcre.department
                            || ' - '
                            || hahcre.hold_comments hold_comments,
                            hahcre.start_date,
                            hahcre.end_date,
                            hahcre.auto_release_flag,
                            CASE -- This is assign precedence to the hold rule based on the combination provided in functional spec
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 1'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 2'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 3'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 4'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 5'
                                WHEN hahcre.item_number IS NOT NULL THEN
                                    'PRECEDENCE - 6'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 7'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 8'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 9'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 10'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 11'
                                WHEN hahcre.category_2 IS NOT NULL THEN
                                    'PRECEDENCE - 12'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 13'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 14'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 15'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 16'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 17'
                                WHEN hahcre.category_1 IS NOT NULL THEN
                                    'PRECEDENCE - 18'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 19'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 20'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 21'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 22'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 23'
                                WHEN hahcre.reporting_group IS NOT NULL THEN
                                    'PRECEDENCE - 24'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 25'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 26'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 27'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 28'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 29'
                                WHEN hahcre.owner_name IS NOT NULL THEN
                                    'PRECEDENCE - 30'
                                WHEN hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 31'
                                WHEN hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 32'
                                WHEN hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 33'
                                WHEN hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 34'
                                WHEN hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 35'
                                ELSE
                                    'PRECEDENCE -36'
                            END                     hold_level
                        FROM
                            doo_headers_all                dha,
                            doo_headers_eff_b              dheb,
                            doo_lines_all                  dla,
                            doo_fulfill_lines_all          dfla,
                            hz_cust_accounts               hca,
                            hz_parties                     hp,
                            hz_party_sites                 hps,
                            hz_cust_acct_sites_all         hcasa,
                            egp_system_items_b             esib,
                            ego_item_eff_b                 eieb,
                            inv_org_parameters             iop,
                            hz_locations                   hl,
                            fnd_common_lookups             hahvse_reporting,
                            fnd_common_lookups             hahvse_catgeory1,
                            fnd_common_lookups             hahvse_catgeory2,
                            hbg_auto_hold_custom_rules_ext hahcre,
                            doo_fulfill_lines_eff_b        dfleb,
                            doo_headers_eff_b              dheb_override
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.header_id = dla.header_id
                            AND dla.line_id = dfla.line_id
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND hca.party_id = hp.party_id
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'One Time Address'
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Override'
                            AND dha.header_id = dheb_override.header_id (+)
                            AND dheb_override.context_code (+) = 'Override'
                            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char5, nvl(dheb_override.
                            attribute_char7, 'N')))) = 'N'
                            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
                            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                                          'SHIPPED' )
                            AND dha.object_version_number = (
                                SELECT
                                    MAX(object_version_number)
                                FROM
                                    doo_headers_all
                                WHERE
                                        dha.source_order_id = source_order_id
                                    AND dha.source_order_system = source_order_system
                                    AND status_code <> 'DOO_REFERENCE'
                            )
                            AND dha.creation_date BETWEEN hahcre.start_date AND nvl(hahcre.end_date, sysdate)
                            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
                            AND hps.party_site_id = hcasa.party_site_id (+)
                            AND hps.location_id = hl.location_id (+)
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND hahcre.reporting_group = hahvse_reporting.lookup_code (+)
                            AND hahvse_reporting.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hahcre.category_1 = hahvse_catgeory1.lookup_code (+)
                            AND hahvse_catgeory1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hahcre.category_2 = hahvse_catgeory2.lookup_code (+)
                            AND hahvse_catgeory2.lookup_type (+) = 'HBG_CATEGORY_2'
                            AND nvl(eieb.attribute_char1, 'A') = nvl(hahcre.owner_name, nvl(eieb.attribute_char1, 'A'))
                            AND nvl(eieb.attribute_char2, 'A') = nvl(hahvse_reporting.description, nvl(eieb.attribute_char2, 'A'))
                            AND nvl(eieb.attribute_char3, 'A') = nvl(hahvse_catgeory1.description, nvl(eieb.attribute_char3, 'A'))
                            AND nvl(eieb.attribute_char4, 'A') = nvl(hahvse_catgeory2.description, nvl(eieb.attribute_char4, 'A'))
                            AND nvl(esib.item_number, 'A') = nvl(hahcre.item_number, nvl(esib.item_number, 'A'))
                            AND nvl(hp.party_number, 'A') = nvl(hahcre.organization, nvl(hp.party_number, 'A'))
                            AND nvl(hca.account_number, 'A') = nvl(hahcre.account_number, nvl(hca.account_number, 'A'))
                            AND nvl(hps.party_site_number, 'A') = nvl(hahcre.ship_to_site, nvl(hps.party_site_number, 'A'))
                            AND nvl(dheb.attribute_char1, nvl(hcasa.attribute3, hl.country)) = nvl(hahcre.country, nvl(dheb.attribute_char1,
                            nvl(hcasa.attribute3, hl.country)))
                            AND nvl(dheb.attribute_char8, nvl(hl.state, '#NULL')) = nvl(hahcre.state, nvl(dheb.attribute_char8, nvl(hl.
                            state, '#NULL')))
                            AND nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL')) IN (
                                SELECT
                                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level)
                                FROM
                                    dual
                                CONNECT BY
                                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level) IS NOT NULL
                                UNION
                                SELECT
                                    nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL'))
                                FROM
                                    dual
                                WHERE
                                    hahcre.zip_code IS NULL
                            )
                            AND p_batch_id IS NULL
                            AND NOT EXISTS (   -- Exclude the orders if there is same hold name is already applied and not yet released
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.source_line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
					--and hah.hold_comments like  hahcre.rule_id||'%'
                                    AND dhi.hold_release_reason_code IS NULL
                                UNION
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
					--and hah.hold_comments like  hahcre.rule_id||'%'
                                    AND dhi.hold_release_reason_code IS NULL
                            )
                            AND NOT EXISTS ( -- Exclude the order Hold if there is it is already applied and released
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.source_line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
                                    AND dhi.hold_comments = hahcre.rule_id
                                                            || ' - '
                                                            || hahcre.created_by
                                                            || ' - '
                                                            || hahcre.hold_comments
                                    AND dhi.hold_release_reason_code IS NOT NULL
                                UNION
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
                                    AND dhi.hold_comments = hahcre.rule_id
                                                            || ' - '
                                                            || hahcre.created_by
                                                            || ' - '
                                                            || hahcre.hold_comments
                                    AND dhi.hold_release_reason_code IS NOT NULL
                            )
                        ORDER BY
                            dha.source_order_id,
                            dla.source_line_id,
                            dfla.fulfill_line_id,
                            hahcre.rule_id
                    ) a
                UNION
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.order_number, a.source_line_id, a.hold_name -- We will assign the rank to each record by considering order, line and hold name as group with start date as ordering
                         ORDER BY
                             substr(a.hold_level, - 2), a.start_date
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_system,
                            dha.source_order_id,
                            dla.source_line_id,
                            dfla.fulfill_line_id,
                            dha.order_number,
                            hahcre.owner_name,
                            hahcre.reporting_group,
                            hahcre.category_1,
                            hahcre.category_2,
                            hahcre.item_number,
                            hahcre.organization,
                            hahcre.account_number,
                            hahcre.ship_to_site,
                            hahcre.country,
                            hahcre.state,
                            hahcre.hold_name,
                            hahcre.rule_id
                            || ' - '
                            || hahcre.department
                            || ' - '
                            || hahcre.hold_comments hold_comments,
                            hahcre.start_date,
                            hahcre.end_date,
                            hahcre.auto_release_flag,
                            CASE -- This is assign precedence to the hold rule based on the combination provided in functional spec
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 1'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 2'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 3'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 4'
                                WHEN hahcre.item_number IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 5'
                                WHEN hahcre.item_number IS NOT NULL THEN
                                    'PRECEDENCE - 6'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 7'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 8'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 9'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 10'
                                WHEN hahcre.category_2 IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 11'
                                WHEN hahcre.category_2 IS NOT NULL THEN
                                    'PRECEDENCE - 12'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 13'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 14'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 15'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 16'
                                WHEN hahcre.category_1 IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 17'
                                WHEN hahcre.category_1 IS NOT NULL THEN
                                    'PRECEDENCE - 18'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 19'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 20'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 21'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 22'
                                WHEN hahcre.reporting_group IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 23'
                                WHEN hahcre.reporting_group IS NOT NULL THEN
                                    'PRECEDENCE - 24'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 25'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 26'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 27'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 28'
                                WHEN hahcre.owner_name IS NOT NULL
                                     AND hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 29'
                                WHEN hahcre.owner_name IS NOT NULL THEN
                                    'PRECEDENCE - 30'
                                WHEN hahcre.ship_to_site IS NOT NULL THEN
                                    'PRECEDENCE - 31'
                                WHEN hahcre.account_number IS NOT NULL THEN
                                    'PRECEDENCE - 32'
                                WHEN hahcre.organization IS NOT NULL THEN
                                    'PRECEDENCE - 33'
                                WHEN hahcre.state IS NOT NULL THEN
                                    'PRECEDENCE - 34'
                                WHEN hahcre.country IS NOT NULL THEN
                                    'PRECEDENCE - 35'
                                ELSE
                                    'PRECEDENCE -36'
                            END                     hold_level
                        FROM
                            doo_headers_all                dha,
                            doo_headers_eff_b              dheb,
                            doo_lines_all                  dla,
                            doo_fulfill_lines_all          dfla,
                            hz_cust_accounts               hca,
                            hz_parties                     hp,
                            hz_party_sites                 hps,
                            hz_cust_acct_sites_all         hcasa,
                            egp_system_items_b             esib,
                            ego_item_eff_b                 eieb,
                            inv_org_parameters             iop,
                            hz_locations                   hl,
                            fnd_common_lookups             hahvse_reporting,
                            fnd_common_lookups             hahvse_catgeory1,
                            fnd_common_lookups             hahvse_catgeory2,
                            hbg_auto_hold_custom_rules_ext hahcre,
                            doo_fulfill_lines_eff_b        dfleb,
                            doo_headers_eff_b              dheb_override,
                            doo_headers_eff_b              dheb_batch
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.header_id = dla.header_id
                            AND dla.line_id = dfla.line_id
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND hca.party_id = hp.party_id
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'One Time Address'
                            AND dha.status_code IN ( 'DOO_DRAFT' )
                            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Override'
                            AND dha.header_id = dheb_override.header_id (+)
                            AND dheb_override.context_code (+) = 'Override'
                            AND dha.header_id = dheb_batch.header_id
                            AND dheb_batch.context_code = 'EDI General'
                            AND dheb_batch.attribute_char18 = p_batch_id
                            AND nvl(dfleb.attribute_char5, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char5, nvl(dheb_override.
                            attribute_char7, 'N')))) = 'N'
                            AND dha.object_version_number = (
                                SELECT
                                    MAX(object_version_number)
                                FROM
                                    doo_headers_all
                                WHERE
                                        dha.source_order_id = source_order_id
                                    AND dha.source_order_system = source_order_system
                            )
                            AND dha.creation_date BETWEEN hahcre.start_date AND nvl(hahcre.end_date, sysdate)
                            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
                            AND hps.party_site_id = hcasa.party_site_id (+)
                            AND hps.location_id = hl.location_id (+)
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND hahcre.reporting_group = hahvse_reporting.lookup_code (+)
                            AND hahvse_reporting.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hahcre.category_1 = hahvse_catgeory1.lookup_code (+)
                            AND hahvse_catgeory1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hahcre.category_2 = hahvse_catgeory2.lookup_code (+)
                            AND hahvse_catgeory2.lookup_type (+) = 'HBG_CATEGORY_2'
                            AND nvl(eieb.attribute_char1, 'A') = nvl(hahcre.owner_name, nvl(eieb.attribute_char1, 'A'))
                            AND nvl(eieb.attribute_char2, 'A') = nvl(hahvse_reporting.description, nvl(eieb.attribute_char2, 'A'))
                            AND nvl(eieb.attribute_char3, 'A') = nvl(hahvse_catgeory1.description, nvl(eieb.attribute_char3, 'A'))
                            AND nvl(eieb.attribute_char4, 'A') = nvl(hahvse_catgeory2.description, nvl(eieb.attribute_char4, 'A'))
                            AND nvl(esib.item_number, 'A') = nvl(hahcre.item_number, nvl(esib.item_number, 'A'))
                            AND nvl(hp.party_number, 'A') = nvl(hahcre.organization, nvl(hp.party_number, 'A'))
                            AND nvl(hca.account_number, 'A') = nvl(hahcre.account_number, nvl(hca.account_number, 'A'))
                            AND nvl(hps.party_site_number, 'A') = nvl(hahcre.ship_to_site, nvl(hps.party_site_number, 'A'))
                            AND nvl(dheb.attribute_char1, nvl(hcasa.attribute3, hl.country)) = nvl(hahcre.country, nvl(dheb.attribute_char1,
                            nvl(hcasa.attribute3, hl.country)))
                            AND nvl(dheb.attribute_char8, nvl(hl.state, '#NULL')) = nvl(hahcre.state, nvl(dheb.attribute_char8, nvl(hl.
                            state, '#NULL')))
                            AND nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL')) IN (
                                SELECT
                                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level)
                                FROM
                                    dual
                                CONNECT BY
                                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level) IS NOT NULL
                                UNION
                                SELECT
                                    nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL'))
                                FROM
                                    dual
                                WHERE
                                    hahcre.zip_code IS NULL
                            )
                            AND NOT EXISTS (   -- Exclude the orders if there is same hold name is already applied and not yet released
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.source_line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
					--and hah.hold_comments like  hahcre.rule_id||'%'
                                    AND dhi.hold_release_reason_code IS NULL
                                UNION
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
					--and hah.hold_comments like  hahcre.rule_id||'%'
                                    AND dhi.hold_release_reason_code IS NULL
                            )
                            AND NOT EXISTS ( -- Exclude the order Hold if there is it is already applied and released
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.source_line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
                                    AND dhi.hold_comments = hahcre.rule_id
                                                            || ' - '
                                                            || hahcre.created_by
                                                            || ' - '
                                                            || hahcre.hold_comments
                                    AND dhi.hold_release_reason_code IS NOT NULL
                                UNION
                                SELECT
                                    1
                                FROM
                                    doo_hold_instances dhi,
                                    doo_hold_codes_vl  dhcv
                                WHERE
                                        1 = 1
                                    AND dhi.transaction_entity_id1 = dla.line_id
                                    AND dhi.hold_code_id = dhcv.hold_code_id
                                    AND dhcv.hold_code = hahcre.hold_name
                                    AND dhi.hold_comments = hahcre.rule_id
                                                            || ' - '
                                                            || hahcre.created_by
                                                            || ' - '
                                                            || hahcre.hold_comments
                                    AND dhi.hold_release_reason_code IS NOT NULL
                            )
                        ORDER BY
                            dha.source_order_id,
                            dla.source_line_id,
                            dfla.fulfill_line_id,
                            hahcre.rule_id
                    ) a
            )
        WHERE
            rank = 1;
       /* ORDER BY
            source_order_id,
            source_line_id,
            fulfill_line_id;*/ -- Consider only records having rank as 1 incase of multiple records with same hold name

        loop_index           NUMBER := 1;
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        FOR c_get_valid_lines IN c_val LOOP
            v_so_hold_array_disp.extend;
            v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      NULL, NULL, 'Y', NULL, NULL /* c_get_valid_lines.account_number, c_get_valid_lines.
                                                                      order_number*/);

			/*INSERT INTO hbg_so_custom_rule_hold_ext VALUES (c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      NULL, NULL, 'Y', c_get_valid_lines.account_number, c_get_valid_lines.
                                                                      order_number,p_oic_run_id,p_created_by,sysdate,p_last_updated_by,sysdate,null);*/

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := sqlerrm;
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_so_custom_rule_hold;

    PROCEDURE hbg_so_custom_rule_release (
        p_source_line_id     IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

        l_return_status      VARCHAR2(255);
        CURSOR c_val IS  -- Program to release hold if rule is inactivated in VBCS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dla.source_line_id,
            dfla.fulfill_line_id,
            dha.order_number,
            hahcre.owner_name,
            hahvse_reporting.description reporting_group,
            hahvse_catgeory1.description category_1,
            hahvse_catgeory2.description category_2,
            hahcre.item_number,
            hahcre.organization,
            hahcre.account_number,
            hahcre.ship_to_site,
            hahcre.country,
            hahcre.state,
            hahcre.hold_name,
            hahcre.rule_id
            || ' - '
            || hahcre.department
            || ' - '
            || hahcre.hold_comments      hold_comments,
            hahcre.start_date,
            hahcre.end_date,
            hahcre.auto_release_flag,
            'HBG_AUTO_RELEASE'           release_code,
            'Automatically released because Rule ID '
            || hahcre.rule_id
            || ' is now inactive.'       release_comments
        FROM
            doo_headers_all                dha,
            doo_headers_eff_b              dheb,
            doo_lines_all                  dla,
            doo_fulfill_lines_all          dfla,
            hz_cust_accounts               hca,
            hz_parties                     hp,
            hz_party_sites                 hps,
            hz_cust_acct_sites_all         hcasa,
            egp_system_items_b             esib,
            ego_item_eff_b                 eieb,
            inv_org_parameters             iop,
            hz_locations                   hl,
            fnd_common_lookups             hahvse_reporting,
            fnd_common_lookups             hahvse_catgeory1,
            fnd_common_lookups             hahvse_catgeory2,
            hbg_auto_hold_custom_rules_ext hahcre
        WHERE
                1 = 1
            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
--           AND DHA.ORDER_NUMBER NOT IN ('402')
--           and hahcre.rule_id like '1068%'
            AND sysdate > nvl(hahcre.end_date, sysdate)
            AND hahcre.auto_release_flag = 'Y'
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'One Time Address'
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
                    AND status_code <> 'DOO_REFERENCE'
            )
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND hps.party_site_id = hcasa.party_site_id (+)
            AND hps.location_id = hl.location_id (+)
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND esib.inventory_item_id = eieb.inventory_item_id (+)
            AND eieb.organization_id = iop.organization_id (+)
            AND iop.organization_code (+) = 'ITEM_MASTER'
            AND eieb.context_code (+) = 'Family Code'
            AND hahcre.reporting_group = hahvse_reporting.lookup_code (+)
            AND hahvse_reporting.lookup_type (+) = 'HBG_REPORTING_GROUP'
            AND hahcre.category_1 = hahvse_catgeory1.lookup_code (+)
            AND hahvse_catgeory1.lookup_type (+) = 'HBG_CATEGORY_1'
            AND hahcre.category_2 = hahvse_catgeory2.lookup_code (+)
            AND hahvse_catgeory2.lookup_type (+) = 'HBG_CATEGORY_2'
            AND nvl(eieb.attribute_char1, 'A') = nvl(hahcre.owner_name, nvl(eieb.attribute_char1, 'A'))
            AND nvl(eieb.attribute_char2, 'A') = nvl(hahvse_reporting.description, nvl(eieb.attribute_char2, 'A'))
            AND nvl(eieb.attribute_char3, 'A') = nvl(hahvse_catgeory1.description, nvl(eieb.attribute_char3, 'A'))
            AND nvl(eieb.attribute_char4, 'A') = nvl(hahvse_catgeory2.description, nvl(eieb.attribute_char4, 'A'))
            AND nvl(esib.item_number, 'A') = nvl(hahcre.item_number, nvl(esib.item_number, 'A'))
            AND nvl(hp.party_number, 'A') = nvl(hahcre.organization, nvl(hp.party_number, 'A'))
            AND nvl(hca.account_number, 'A') = nvl(hahcre.account_number, nvl(hca.account_number, 'A'))
            AND nvl(hps.party_site_number, 'A') = nvl(hahcre.ship_to_site, nvl(hps.party_site_number, 'A'))
            AND nvl(dheb.attribute_char1, nvl(hcasa.attribute3, hl.country)) = nvl(hahcre.country, nvl(dheb.attribute_char1, nvl(hcasa.
            attribute3, hl.country)))
            AND nvl(dheb.attribute_char8, hl.state) = nvl(hahcre.state, nvl(dheb.attribute_char8, hl.state))
            AND nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL')) IN (
                SELECT
                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level)
                FROM
                    dual
                CONNECT BY
                    regexp_substr(hahcre.zip_code, '[^,]+', 1, level) IS NOT NULL
                UNION
                SELECT
                    nvl(dheb.attribute_char12, nvl(hl.postal_code, '#NULL'))
                FROM
                    dual
                WHERE
                    hahcre.zip_code IS NULL
            )
            AND EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = hahcre.hold_name
                    AND dhi.hold_comments = hahcre.rule_id
                                            || ' - '
                                            || hahcre.created_by
                                            || ' - '
                                            || hahcre.hold_comments
                    AND dhi.hold_release_reason_code IS NULL
            )
        ORDER BY
            dha.source_order_id,
            dla.source_line_id,
            dfla.fulfill_line_id,
            hahcre.rule_id;

        loop_index           NUMBER := 1;
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        FOR c_get_valid_lines IN c_val LOOP
            v_so_hold_array_disp.extend;
            v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      c_get_valid_lines.release_code, c_get_valid_lines.release_comments,
                                                                      'Y', c_get_valid_lines.account_number, c_get_valid_lines.order_number);

			/*INSERT INTO hbg_so_custom_rule_hold_ext VALUES (c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
            c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                      NULL, NULL, 'Y', c_get_valid_lines.account_number, c_get_valid_lines.
                                                                      order_number,p_oic_run_id,p_created_by,sysdate,p_last_updated_by,sysdate,null);*/

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_so_custom_rule_release;

END hbg_so_auto_holds_pkg;

/

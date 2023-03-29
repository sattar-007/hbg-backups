--------------------------------------------------------
--  DDL for Package Body HBG_ITEM_HOT_TITLES_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_ITEM_HOT_TITLES_PKG" AS
    PROCEDURE validate_hold_items (
        p_source_order_line_id IN VARCHAR2,
        p_batch_name           IN VARCHAR2,
        x_status_code          OUT VARCHAR2,
        p_so_auto_hold_array   OUT hbg_so_auto_holds_type_array
    ) AS

        CURSOR order_cur IS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name                 account_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            SUM(nvl(dfla.ordered_qty, 0)) quantity,
            hps.party_site_number         ship_to
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND dha.order_number NOT IN (872)
            AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED', 'CANCEL_PENDING' )
            AND p_batch_name IS NULL
			AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char2, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char2, nvl(dheb.attribute_char7, 'N')))) = 'N'
            	--AND DFLA.LAST_UPDATE_DATE > :p_last_run_date
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
            )
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
            AND dha.source_order_id IN (
                SELECT
                    source_order_id
                FROM
                    doo_lines_all
                WHERE
                    source_line_id = nvl(p_source_order_line_id, source_line_id)
            )
        GROUP BY
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            hps.party_site_number
        UNION
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name                 account_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            SUM(nvl(dfla.ordered_qty, 0)) quantity,
            hps.party_site_number         ship_to
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps,
            doo_headers_eff_b     dheb_batch,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') IN ( 'DOO_DRAFT' )
            AND dfla.status_code NOT IN ( 'CREATED' )
            AND dha.order_number NOT IN (872)
            AND dha.header_id = dheb_batch.header_id
            AND dheb_batch.context_code = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_name 
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char2, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char2, nvl(dheb.attribute_char7, 'N')))) = 'N'
				--AND DFLA.LAST_UPDATE_DATE > :p_last_run_date
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
            )
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
        GROUP BY
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            hps.party_site_number;

        CURSOR ord_ln_cur (
            p_source_order_system VARCHAR2,
            p_source_order_id     VARCHAR2,
            p_item_number         VARCHAR2,
            p_party_site_number   VARCHAR2
        ) IS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            dla.source_line_id,
            dla.line_number          source_order_line_num,
            dfla.fulfill_line_number fulfillment_line_num,
            dfla.fulfill_line_id,
            hca.account_number,
            hp.party_name            account_name,
            esib.item_number,
            nvl(dfla.ordered_qty, 0) quantity,
            hps.party_site_number    ship_to,
            dha.object_version_number,
            dla.status_code          so_line_status,
            dfla.status_code         fulfill_line_status
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps,
			doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb
        WHERE
                1 = 1
            AND dha.source_order_id = p_source_order_id
            AND dha.source_order_system = p_source_order_system
            AND esib.item_number = p_item_number
            AND hps.party_site_number = p_party_site_number
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dha.order_number NOT IN (872)
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED','CANCEL_PENDING' )
			AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char2, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char2, nvl(dheb.attribute_char7, 'N')))) = 'N'							  
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
            AND p_batch_name IS NULL
            --AND dha.order_number not in ('541')
            AND dla.source_line_id = nvl(p_source_order_line_id, dla.source_line_id)
			
		
				--AND DFLA.LAST_UPDATE_DATE > :p_last_run_date
        UNION
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            dla.source_line_id,
            dla.line_number          source_order_line_num,
            dfla.fulfill_line_number fulfillment_line_num,
            dfla.fulfill_line_id,
            hca.account_number,
            hp.party_name            account_name,
            esib.item_number,
            nvl(dfla.ordered_qty, 0) quantity,
            hps.party_site_number    ship_to,
            dha.object_version_number,
            dla.status_code          so_line_status,
            dfla.status_code         fulfill_line_status
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps,
            doo_fulfill_lines_eff_b dfleb,
            doo_headers_eff_b       dheb,
			doo_headers_eff_b     dheb_batch
        WHERE
                1 = 1
            AND dha.source_order_id = p_source_order_id
            AND dha.source_order_system = p_source_order_system
            AND esib.item_number = p_item_number
            AND hps.party_site_number = p_party_site_number
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') IN ( 'DOO_DRAFT' )
            AND dfla.status_code NOT IN ( 'CREATED' )
            AND dha.order_number NOT IN (872)
			AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char2, nvl(dfleb.attribute_char6, nvl(dheb.attribute_char2, nvl(dheb.attribute_char7, 'N')))) = 'N'
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
            AND dha.header_id = dheb_batch.header_id
            AND dheb_batch.context_code = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_name;
		
		
		
		--------------------------------------------------------------------------------------
        l_hot_tile           VARCHAR2(20);
        l_apply_hold         VARCHAR2(20);
        l_over_ride_ind      VARCHAR2(20);
        l_order_qty          NUMBER;
        l_threshold_qty      NUMBER;
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
        loop_index           NUMBER := 1;
    BEGIN
        FOR order_rec IN order_cur LOOP
            l_hot_tile := 'N';
            BEGIN
                SELECT
                    nvl(attribute_char1,'N')
                INTO l_hot_tile
                FROM
                    ego_item_eff_b
                WHERE
                        inventory_item_id = order_rec.inventory_item_id
                    AND organization_id = order_rec.organization_id
                    AND context_code = 'Hot Title Indicator'
                    AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            
            IF l_hot_tile = 'Y' THEN
            
            BEGIN
                SELECT
                    threshold_quantity,
                    override_indicator
                INTO
                    l_threshold_qty,
                    l_over_ride_ind
                FROM
                    (
                        SELECT
                            nvl(attribute_number1, 0) threshold_quantity,
                            nvl(attribute_char2, 'N') override_indicator
                        FROM
                            ego_item_eff_b
                        WHERE
                                inventory_item_id = order_rec.inventory_item_id
                            AND organization_id = order_rec.organization_id
                            AND context_code = 'Hot Title Thresholds Table'
                            AND attribute_char1 = order_rec.account_number
                        UNION
                        SELECT
                            nvl(attribute_number1, 0) threshold_quantity,
                            nvl(attribute_char2, 'N') override_indicator
                        FROM
                            ego_item_eff_b
                        WHERE
                                inventory_item_id = order_rec.inventory_item_id
                            AND organization_id = order_rec.organization_id
                            AND context_code = 'Hot Title Indicator'
                            --AND attribute_char1 IS NULL
                            AND NOT EXISTS (
                                SELECT
                                    1
                                FROM
                                    ego_item_eff_b
                                WHERE
                                        inventory_item_id = order_rec.inventory_item_id
                                    AND organization_id = order_rec.organization_id
                                    AND context_code = 'Hot Title Thresholds Table'
                                    AND attribute_char1 = order_rec.account_number
                            )
                    );

            EXCEPTION
                WHEN no_data_found THEN
                    l_threshold_qty :=0;
                    l_over_ride_ind :='N';
                    NULL;
            END;

                IF order_rec.account_number LIKE '%12224132-BARNES%' THEN
                    FOR ord_ln_rec IN ord_ln_cur(order_rec.source_order_system, order_rec.source_order_id, order_rec.item_number, order_rec.
                    ship_to) LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                                  NULL, NULL, NULL, ord_ln_rec.account_number, ord_ln_rec.
                                                                                  order_number);

                        loop_index := loop_index + 1;
                    END LOOP;

                ELSIF
                    l_over_ride_ind = 'N'
                    AND order_rec.quantity >= l_threshold_qty
                THEN
                    FOR ord_ln_rec IN ord_ln_cur(order_rec.source_order_system, order_rec.source_order_id, order_rec.item_number, order_rec.
                    ship_to) LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Ordered Quantity '
                                                                                                                                             ||
                                                                                                                                             order_rec.
                                                                                                                                             quantity
                                                                                                                                             ||
                                                                                                                                             ' equals or exceeds the Hot Title Threshold of '
                                                                                                                                             ||
                                                                                                                                             l_threshold_qty,
                                                                                  NULL, NULL, NULL, ord_ln_rec.account_number, ord_ln_rec.
                                                                                  order_number);

                        loop_index := loop_index + 1;
                    END LOOP;
                END IF;
            END IF;

        END LOOP;

        x_status_code := 'SUCCESS';
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            x_status_code := 'FAILURE';
            p_so_auto_hold_array := v_so_hold_array_disp;
    END validate_hold_items;

    PROCEDURE validate_release_items (
        p_source_order_line_id IN VARCHAR2,
        x_status_code          OUT VARCHAR2,
        p_so_auto_hold_array   OUT hbg_so_auto_holds_type_array
    ) AS

        CURSOR order_cur IS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name                 account_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            SUM(nvl(dfla.ordered_qty, 0)) quantity,
            hps.party_site_number         ship_to
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dha.order_number NOT IN (872)
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED','CANCEL_PENDING' )
            AND hca.account_number NOT LIKE '%12224132-BARNES%'
				--AND DFLA.LAST_UPDATE_DATE > :p_last_run_date
            AND EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                    AND dhi.hold_release_reason_code IS NULL
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                    AND dhi.hold_release_reason_code IS NULL
            )
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
            AND dha.source_order_id IN (
                SELECT
                    source_order_id
                FROM
                    doo_lines_all
                WHERE
                    source_line_id = nvl(p_source_order_line_id, source_line_id)
            )
        GROUP BY
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            hca.account_number,
            hp.party_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            hps.party_site_number
        ORDER BY
            dha.source_order_id;

        CURSOR ord_ln_cur (
            p_source_order_system VARCHAR2,
            p_source_order_id     VARCHAR2,
            p_item_number         VARCHAR2,
            p_party_site_number   VARCHAR2,
			p_creation_date 		  DATE
        ) IS
        SELECT
            dha.source_order_system,
            dha.source_order_id,
            dha.order_number,
            dla.source_line_id,
            dla.line_number          source_order_line_num,
            dfla.fulfill_line_number fulfillment_line_num,
            dfla.fulfill_line_id,
            hca.account_number,
            hp.party_name            account_name,
            esib.item_number,
            nvl(dfla.ordered_qty, 0) quantity,
            hps.party_site_number    ship_to,
            dha.object_version_number,
            dla.status_code          so_line_status,
            dfla.status_code         fulfill_line_status
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps
        WHERE
                1 = 1
            AND dha.source_order_id = nvl(p_source_order_id,dha.source_order_id)
            AND dha.source_order_system = nvl(p_source_order_system,dha.source_order_system)
            AND esib.item_number = p_item_number
            AND hps.party_site_number = p_party_site_number
			AND trunc(dha.creation_date) = nvl(p_creation_date,trunc(dha.creation_date))
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dha.order_number NOT IN (872)
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED','CANCEL_PENDING' )
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
            AND dla.source_line_id = nvl(p_source_order_line_id, dla.source_line_id);

        CURSOR bn_order_cur IS
        SELECT
           
            hca.account_number,
            hp.party_name                 account_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            SUM(nvl(dfla.ordered_qty, 0)) quantity,
            hps.party_site_number         ship_to,
			trunc(dha.creation_date) creation_date
        FROM
            doo_headers_all       dha,
            doo_lines_all         dla,
            doo_fulfill_lines_all dfla,
            hz_cust_accounts      hca,
            hz_parties            hp,
            egp_system_items_b    esib,
            hz_party_sites        hps
        WHERE
                1 = 1
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dla.header_id = dfla.header_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND hca.party_id = hp.party_id
            AND dla.inventory_item_id = esib.inventory_item_id
            AND dla.inventory_organization_id = esib.organization_id
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dha.order_number NOT IN (872)
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED','CANCEL_PENDING' )
            AND hca.account_number  LIKE '%12224132-BARNES%'
				--AND DFLA.LAST_UPDATE_DATE > :p_last_run_date
            AND EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                    AND dhi.hold_release_reason_code IS NULL
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code = 'HBG_Hot_Title'
                    AND dhi.hold_release_reason_code IS NULL
            )
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
            AND dha.source_order_id IN (
                SELECT
                    source_order_id
                FROM
                    doo_lines_all
                WHERE
                    source_line_id = nvl(p_source_order_line_id, source_line_id)
            )
        GROUP BY
            hca.account_number,
            hp.party_name,
            esib.item_number,
            esib.inventory_item_id,
            esib.organization_id,
            hps.party_site_number,
			trunc(dha.creation_date);

        l_hot_tile           VARCHAR2(20);
        l_rel_hold           VARCHAR2(20);
        l_over_ride_ind      VARCHAR2(20);
        l_order_qty          NUMBER;
        l_threshold_qty      NUMBER;
        v_so_hold_array_disp hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
        loop_index
    number := 1;
    BEGIN
        FOR bn_order_rec IN bn_order_cur LOOP
            BEGIN
                SELECT
                    attribute_char1
                INTO l_hot_tile
                FROM
                    ego_item_eff_b
                WHERE
                        inventory_item_id = bn_order_rec.inventory_item_id
                    AND organization_id = bn_order_rec.organization_id
                        AND context_code = 'Hot Title Indicator'
                            AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    l_hot_tile := 'N';
            END;

            IF l_hot_tile = 'Y' THEN
                BEGIN
                    SELECT
                        threshold_quantity,
                        override_indicator
                    INTO
                        l_threshold_qty,
                        l_over_ride_ind
                    FROM
                        (
                            SELECT
                                nvl(attribute_number1, 0) threshold_quantity,
                                nvl(attribute_char2, 'N') override_indicator
                            FROM
                                ego_item_eff_b
                            WHERE
                                    inventory_item_id = bn_order_rec.inventory_item_id
                                AND organization_id = bn_order_rec.organization_id
                                    AND context_code = 'Hot Title Thresholds Table'
                                        AND attribute_char1 = bn_order_rec.account_number
                            UNION
                            SELECT
                                nvl(attribute_number1, 0) threshold_quantity,
                                nvl(attribute_char2, 'N') override_indicator
                            FROM
                                ego_item_eff_b
                            WHERE
                                    inventory_item_id = bn_order_rec.inventory_item_id
                                AND organization_id = bn_order_rec.organization_id
                                    AND context_code = 'Hot Title Indicator'
                                        --AND attribute_char1 IS NULL
                                            AND NOT EXISTS (
                                    SELECT
                                        1
                                    FROM
                                        ego_item_eff_b
                                    WHERE
                                            inventory_item_id = bn_order_rec.inventory_item_id
                                        AND organization_id = bn_order_rec.organization_id
                                            AND context_code = 'Hot Title Thresholds'
                                                AND attribute_char1 = bn_order_rec.account_number
                                )
                        );

                EXCEPTION
                    WHEN no_data_found THEN
                        l_threshold_qty :=0;
                        l_over_ride_ind :='N';
                        NULL;
                END;

                IF l_over_ride_ind = 'Y' THEN
                    FOR ord_ln_rec IN ord_ln_cur(NULL, NULL, bn_order_rec.item_number, bn_order_rec.ship_to, bn_order_rec.creation_date)
                    LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                                  'HBG_MANUAL_RELEASE', 'Releasing B and N Hot Title Hold',
                                                                                  NULL, ord_ln_rec.account_number, ord_ln_rec.order_number);

                        loop_index := loop_index + 1;
                    END LOOP;

                ELSIF
                    l_over_ride_ind = 'N'
                    AND bn_order_rec.quantity < l_threshold_qty
                THEN
                    FOR ord_ln_rec IN ord_ln_cur(NULL, NULL, bn_order_rec.item_number, bn_order_rec.ship_to, bn_order_rec.creation_date)
                    LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                                  'HBG_MANUAL_RELEASE', 'Releasing B and N Hot Title Hold',
                                                                                  NULL, ord_ln_rec.account_number, ord_ln_rec.order_number);

                        loop_index := loop_index + 1;
                    END LOOP;
                END IF;

            ELSE
                FOR ord_ln_rec IN ord_ln_cur(NULL, NULL, bn_order_rec.item_number, bn_order_rec.ship_to, bn_order_rec.creation_date) LOOP
                    v_so_hold_array_disp.extend;
                    v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                    ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                              'HBG_MANUAL_RELEASE', 'Releasing B and N Hot Title Hold',
                                                                              NULL, ord_ln_rec.account_number, ord_ln_rec.order_number);

                    loop_index := loop_index + 1;
                END LOOP;
            END IF;

        END LOOP;

        FOR order_rec IN order_cur LOOP
            BEGIN
                SELECT
                    nvl(attribute_char1,'N')
                INTO l_hot_tile
                FROM
                    ego_item_eff_b
                WHERE
                        inventory_item_id = order_rec.inventory_item_id
                    AND organization_id = order_rec.organization_id
                        AND context_code = 'Hot Title Indicator'
                            AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    l_hot_tile := 'N';
            END;

            IF l_hot_tile = 'Y' THEN
                BEGIN
                    SELECT
                        threshold_quantity,
                        override_indicator
                    INTO
                        l_threshold_qty,
                        l_over_ride_ind
                    FROM
                        (
                            SELECT
                                nvl(attribute_number1, 0) threshold_quantity,
                                nvl(attribute_char2, 'N') override_indicator
                            FROM
                                ego_item_eff_b
                            WHERE
                                    inventory_item_id = order_rec.inventory_item_id
                                AND organization_id = order_rec.organization_id
                                    AND context_code = 'Hot Title Thresholds Table'
                                        AND attribute_char1 = order_rec.account_number
                            UNION
                            SELECT
                                nvl(attribute_number1, 0) threshold_quantity,
                                nvl(attribute_char2, 'N') override_indicator
                            FROM
                                ego_item_eff_b
                            WHERE
                                    inventory_item_id = order_rec.inventory_item_id
                                AND organization_id = order_rec.organization_id
                                    AND context_code = 'Hot Title Indicator'
                                        --AND attribute_char1 IS NULL
                                            AND NOT EXISTS (
                                    SELECT
                                        1
                                    FROM
                                        ego_item_eff_b
                                    WHERE
                                            inventory_item_id = order_rec.inventory_item_id
                                        AND organization_id = order_rec.organization_id
                                            AND context_code = 'Hot Title Thresholds Table'
                                                AND attribute_char1 = order_rec.account_number
                                )
                        );

                EXCEPTION
                    WHEN no_data_found THEN
                    l_threshold_qty :=0;
                    l_over_ride_ind :='N';
                        NULL;
                END;

                IF l_over_ride_ind = 'Y' THEN
                    FOR ord_ln_rec IN ord_ln_cur(order_rec.source_order_system, order_rec.source_order_id, order_rec.item_number, order_rec.
                    ship_to, NULL) LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                                  'HBG_MANUAL_RELEASE', 'Releasing Hot Title Hold', NULL,
                                                                                  ord_ln_rec.account_number, ord_ln_rec.order_number);

                        loop_index := loop_index + 1;
                    END LOOP;

                ELSIF
                    l_over_ride_ind = 'N'
                    AND order_rec.quantity < l_threshold_qty
                THEN
                    FOR ord_ln_rec IN ord_ln_cur(order_rec.source_order_system, order_rec.source_order_id, order_rec.item_number, order_rec.
                    ship_to, NULL) LOOP
                        v_so_hold_array_disp.extend;
                        v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                        ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                                  'HBG_MANUAL_RELEASE', 'Releasing Hot Title Hold', NULL,
                                                                                  ord_ln_rec.account_number, ord_ln_rec.order_number);

                        loop_index := loop_index + 1;
                    END LOOP;
                END IF;

            ELSIF l_hot_tile = 'N' THEN
                FOR ord_ln_rec IN ord_ln_cur(order_rec.source_order_system, order_rec.source_order_id, order_rec.item_number, order_rec.
                ship_to, NULL) LOOP
                    v_so_hold_array_disp.extend;
                    v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(ord_ln_rec.source_order_system, ord_ln_rec.source_order_id,
                    ord_ln_rec.source_line_id, 'HBG_Hot_Title', 'Hold for B & N Hot Title',
                                                                              'HBG_MANUAL_RELEASE', 'Releasing Hot Title Hold', NULL,
                                                                              ord_ln_rec.account_number, ord_ln_rec.order_number);

                    loop_index := loop_index + 1;
                END LOOP;
            END IF;

        END LOOP;
        
        x_status_code := 'SUCCESS';
        p_so_auto_hold_array := v_so_hold_array_disp;
        EXCEPTION
        WHEN OTHERS THEN
            x_status_code := 'FAILURE';
            p_so_auto_hold_array := v_so_hold_array_disp;

    END validate_release_items;

END hbg_item_hot_titles_pkg;

/

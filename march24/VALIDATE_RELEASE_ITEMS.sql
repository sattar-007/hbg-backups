--------------------------------------------------------
--  DDL for Procedure VALIDATE_RELEASE_ITEMS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "HBG_INTEGRATION"."VALIDATE_RELEASE_ITEMS" (
        p_oic_run_id    NUMBER,
        x_staus_code    OUT VARCHAR2,
        x_staus_message OUT VARCHAR2
    ) AS

        CURSOR order_cur IS
        SELECT
            source_order_id,
            order_number,
            account_name,
			account_number,
            item_number,
            quantity,
            source_order_line_id,
            ship_to,
            oic_run_id,
            object_version_number,
            stage_id
        FROM
            hbg_so_hot_titles_release_ext so
        WHERE
                oic_run_id = p_oic_run_id
            AND status = 'N'
            AND account_name NOT LIKE 'BARNES%'
            --AND source_order_id = '300000048670731'
        GROUP BY
            source_order_id,
            order_number,
            account_name,
			account_number,
            quantity,
            source_order_line_id,
            ship_to,
            item_number,
            oic_run_id,
            object_version_number,
            stage_id
        ORDER BY
            source_order_id;

        CURSOR bn_order_cur IS
        SELECT
            item_number,
            SUM(quantity)        quantity,
            oic_run_id,
            trunc(creation_date) creation_date
        FROM
            hbg_so_hot_titles_release_ext so
        WHERE
                oic_run_id = p_oic_run_id
            AND account_name LIKE 'BARNES%'
            AND status = 'N'
        GROUP BY
            item_number,
            trunc(creation_date),
			oic_run_id
            
        ORDER BY
            item_number,
            trunc(creation_date),
			oic_run_id;

        l_hot_tile      VARCHAR2(20);
        l_rel_hold      VARCHAR2(20);
        l_over_ride_ind VARCHAR2(20);
        l_order_qty     NUMBER;
        l_threshold_qty NUMBER;
    BEGIN
        FOR bn_order_rec IN bn_order_cur LOOP
            BEGIN
                SELECT
                    hot_title_indicator
                INTO l_hot_tile
                FROM
                    hbg_item_hot_titles_ext
                WHERE
                        item_number = bn_order_rec.item_number
                    AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    l_hot_tile := 'N';
            END;

            IF l_hot_tile = 'Y' THEN
                BEGIN
                    SELECT
                        threshold_quantity,
                        nvl(override_indicator, 'N') override_indicator
                    INTO
                        l_threshold_qty,
                        l_over_ride_ind
                    FROM
                        hbg_item_hot_titles_ext
                    WHERE
                            item_number = bn_order_rec.item_number
                        AND customer_account (+) LIKE 'BARNES%';--NEED TO CHECK

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                IF l_over_ride_ind = 'Y' THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'Y',
                        hold_code = 'HBG_Hot_Title',
                        release_code = 'HBG_MANUAL_RELEASE',
                        release_comments = 'Releasing B and N Hot Title Hold',
                        status = 'V'
                    WHERE
                            item_number = bn_order_rec.item_number
                        AND trunc(creation_date) = bn_order_rec.creation_date
                        AND oic_run_id = bn_order_rec.oic_run_id;

                    COMMIT;
                ELSIF
                    l_over_ride_ind = 'N'
                    AND bn_order_rec.quantity >= l_threshold_qty
                THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'N',
                        status = 'V'
                    WHERE
                            item_number = bn_order_rec.item_number
                        AND trunc(creation_date) = bn_order_rec.creation_date
                        AND oic_run_id = bn_order_rec.oic_run_id;
					COMMIT;

                ELSIF
                    l_over_ride_ind = 'N'
                    AND bn_order_rec.quantity < l_threshold_qty
                THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'Y',
                        hold_code = 'HBG_Hot_Title',
                        release_code = 'HBG_MANUAL_RELEASE',
                        release_comments = 'Releasing B and N Hot Title Hold',
                        status = 'V'
                    WHERE
                            item_number = bn_order_rec.item_number
                        AND trunc(creation_date) = bn_order_rec.creation_date
                        AND oic_run_id = bn_order_rec.oic_run_id;

                    COMMIT;
                END IF;

            ELSE
                UPDATE hbg_so_hot_titles_release_ext
                SET
                   release_hold_flag = 'Y',
                   hold_code = 'HBG_Hot_Title',
                   release_code = 'HBG_MANUAL_RELEASE',
                   release_comments = 'Releasing B and N Hot Title Hold',
                   status = 'V'
                WHERE
                        item_number = bn_order_rec.item_number
                    AND trunc(creation_date) = bn_order_rec.creation_date
                    AND oic_run_id = bn_order_rec.oic_run_id;
            COMMIT;
            END IF;

        END LOOP;

        FOR order_rec IN order_cur LOOP
            BEGIN
                SELECT
                    hot_title_indicator
                INTO l_hot_tile
                FROM
                    hbg_item_hot_titles_ext
                WHERE
                        item_number = order_rec.item_number
                    AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    l_hot_tile := 'N';
            END;

            IF l_hot_tile = 'Y' THEN
                BEGIN
                    SELECT
                        threshold_quantity,
                        nvl(override_indicator, 'N') override_indicator
                    INTO
                        l_threshold_qty,
                        l_over_ride_ind
                    FROM
                        hbg_item_hot_titles_ext
                    WHERE
                            item_number = order_rec.item_number
                        AND customer_account (+) = order_rec.account_number;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                IF l_over_ride_ind = 'Y' THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'Y',
                        hold_code = 'HBG_Hot_Title',
                        release_code = 'HBG_MANUAL_RELEASE',
                        release_comments = 'Releasing Hot Title Hold',
                        status = 'V'
                    WHERE
                            oic_run_id = order_rec.oic_run_id
                    AND item_number = order_rec.item_number
                    AND stage_id = order_rec.stage_id
                    AND source_order_id = order_rec.source_order_id;

                    COMMIT;
                ELSIF
                    l_over_ride_ind = 'N'
                    AND order_rec.quantity >= l_threshold_qty
                THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'N',
                        status = 'V'
                    WHERE
                            oic_run_id = order_rec.oic_run_id
                    AND item_number = order_rec.item_number
                    AND stage_id = order_rec.stage_id
                    AND source_order_id = order_rec.source_order_id;

                ELSIF
                    l_over_ride_ind = 'N'
                    AND order_rec.quantity < l_threshold_qty
                THEN
                    UPDATE hbg_so_hot_titles_release_ext
                    SET
                        release_hold_flag = 'Y',
                        hold_code = 'HBG_Hot_Title',
                        release_code = 'HBG_MANUAL_RELEASE',
                        release_comments = 'Releasing Hot Title Hold',
                        status = 'V'
                    WHERE
                            oic_run_id = p_oic_run_id
                    AND item_number = order_rec.item_number
                    AND stage_id = order_rec.stage_id
                    AND source_order_id = order_rec.source_order_id;

                    COMMIT;
                END IF;

            ELSIF l_hot_tile = 'N' THEN
                UPDATE hbg_so_hot_titles_release_ext
                SET
                    release_hold_flag = 'Y',
                    hold_code = 'HBG_Hot_Title',
                    release_code = 'HBG_MANUAL_RELEASE',
                    release_comments = 'Releasing Hot Title Hold',
                    status = 'V'
                WHERE
                        oic_run_id = p_oic_run_id
                    AND item_number = order_rec.item_number
                    AND stage_id = order_rec.stage_id
                    AND source_order_id = order_rec.source_order_id;
            COMMIT;
            END IF;

        END LOOP;

    END validate_release_items;				 
				

/

--------------------------------------------------------
--  DDL for Package Body HBG_LIFE_PLANNER_ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_LIFE_PLANNER_ITEM_PKG" AS

    PROCEDURE validate_items (
        p_oic_run_id     NUMBER,
        x_staus_code     OUT  VARCHAR2,
        x_staus_message  OUT  VARCHAR2
    ) AS
        CURSOR item_cur IS
        SELECT
            *
        FROM
            xxhbg_life_planner_item_cate_stg
        WHERE
            oic_run_id = p_oic_run_id
            order by stage_id;
            

        l_item_category VARCHAR2(200);
    BEGIN
        FOR item_rec IN item_cur LOOP

            -- CREATE scenario
            IF item_rec.category_code IS NULL AND item_rec.new_category_code IS NOT NULL THEN

                INSERT INTO xxhbg_egp_item_categories_interface (
                        interface_stage_id,
                        transaction_type,
                        batch_id,
                        batch_number,
                        item_number,
                        organization_code,
                        catalog_category_name,
                        category_code,
                        old_category_name,
                        old_category_code,
                        source_system_code,
                        source_system_reference,
                        start_date,
                        end_date,
                        oic_run_id,
                        stage_id,
                        status,
                        status_message,
                        creation_date,
                        created_by,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        hbg_life_planner_id_s.NEXTVAL,
                        'CREATE',
                        p_oic_run_id,
                        NULL,
                        item_rec.item_number,
                        item_rec.organization_code,
                        item_rec.category_set_name,
                        item_rec.new_category_code,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_oic_run_id,
                        item_rec.stage_id,
                        'V',
                        NULL,
                        sysdate,
                        item_rec.created_by,
                        item_rec.last_updated_by,
                        sysdate
                    );

             -- DELETE scenario
             ELSIF item_rec.new_category_code IS NULL AND item_rec.category_code IS NOT NULL then
             
                INSERT INTO xxhbg_egp_item_categories_interface (
                        interface_stage_id,
                        transaction_type,
                        batch_id,
                        batch_number,
                        item_number,
                        organization_code,
                        catalog_category_name,
                        category_code,
                        old_category_name,
                        old_category_code,
                        source_system_code,
                        source_system_reference,
                        start_date,
                        end_date,
                        oic_run_id,
                        stage_id,
                        status,
                        status_message,
                        creation_date,
                        created_by,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        hbg_life_planner_id_s.NEXTVAL,
                        'DELETE',
                        p_oic_run_id,
                        NULL,
                        item_rec.item_number,
                        item_rec.organization_code,
                        item_rec.category_set_name,
                        item_rec.category_code,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_oic_run_id,
                        item_rec.stage_id,
                        'V',
                        NULL,
                        sysdate,
                        item_rec.created_by,
                        item_rec.last_updated_by,
                        sysdate
                    );
          -- UPDATE scenario
          ELSE
          ----Inser Delete records---
                    INSERT INTO xxhbg_egp_item_categories_interface (
                        interface_stage_id,
                        transaction_type,
                        batch_id,
                        batch_number,
                        item_number,
                        organization_code,
                        catalog_category_name,
                        category_code,
                        old_category_name,
                        old_category_code,
                        source_system_code,
                        source_system_reference,
                        start_date,
                        end_date,
                        oic_run_id,
                        stage_id,
                        status,
                        status_message,
                        creation_date,
                        created_by,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        hbg_life_planner_id_s.NEXTVAL,
                        'DELETE',
                        p_oic_run_id,
                        NULL,
                        item_rec.item_number,
                        item_rec.organization_code,
                        item_rec.category_set_name,
                        item_rec.category_code,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_oic_run_id,
                        item_rec.stage_id,
                        'V',
                        NULL,
                        sysdate,
                        item_rec.created_by,
                        item_rec.last_updated_by,
                        sysdate
                    );

            -----------Create Records-------------------

                    INSERT INTO xxhbg_egp_item_categories_interface (
                        interface_stage_id,
                        transaction_type,
                        batch_id,
                        batch_number,
                        item_number,
                        organization_code,
                        catalog_category_name,
                        category_code,
                        old_category_name,
                        old_category_code,
                        source_system_code,
                        source_system_reference,
                        start_date,
                        end_date,
                        oic_run_id,
                        stage_id,
                        status,
                        status_message,
                        creation_date,
                        created_by,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        hbg_life_planner_id_s.NEXTVAL,
                        'CREATE',
                        p_oic_run_id,
                        NULL,
                        item_rec.item_number,
                        item_rec.organization_code,
                        item_rec.category_set_name,
                        item_rec.new_category_code,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_oic_run_id,
                        item_rec.stage_id,
                        'V',
                        NULL,
                        sysdate,
                        item_rec.created_by,
                        item_rec.last_updated_by,
                        sysdate
                    );

                END IF;

           COMMIT;

        END LOOP;

        COMMIT;
        x_staus_code := 'SUCCESS';
        x_staus_message := 'Item category date validated successfully';
    EXCEPTION
        WHEN OTHERS THEN
            x_staus_code := sqlcode;
            x_staus_message := 'Unhandled exception while validating item category data ' || sqlerrm;
    END validate_items;
PROCEDURE update_status (
        p_oic_run_id      NUMBER,
        p_ess_request_id  NUMBER,
        x_staus_code      OUT  VARCHAR2,
        x_staus_message   OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_ess_request_id IS NOT NULL THEN
            UPDATE xxhbg_egp_item_categories_interface
            SET
                import_request_id = p_ess_request_id,
                status = 'SUCCESS',
                status_message = 'Item Category import submitted successfully'
            WHERE
                oic_run_id = p_oic_run_id;
            COMMIT;
            UPDATE xxhbg_life_planner_item_cate_stg
            SET
                status = 'SUCCESS',
                status_message = 'Item Category import submitted successfully'
            WHERE
                oic_run_id = p_oic_run_id
                AND status <> 'ERROR';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            x_staus_code := sqlcode;
            x_staus_message := 'Unhandled exception while updating item category import status' || sqlerrm;
    END;
END hbg_life_planner_item_pkg;

/

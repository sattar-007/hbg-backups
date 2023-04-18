--------------------------------------------------------
--  DDL for Package Body HBG_SHIPPING_SCHEDULES_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_SHIPPING_SCHEDULES_PKG" AS

    PROCEDURE hbg_ss_create_ship_sch_type_template (
        p_shipping_schedule_type                 IN VARCHAR2,
        p_add_items_automatically                IN VARCHAR2,
        p_remove_items_automatically             IN VARCHAR2,
        p_on_sale_date_editable                  IN VARCHAR2,
        p_on_sale_date_required                  IN VARCHAR2,
        p_release_date_editable                  IN VARCHAR2,
        p_release_date_required                  IN VARCHAR2,
        p_release_date_subtract_from_osd         IN NUMBER,
        p_cutoff_date_editable                   IN VARCHAR2,
        p_cutoff_date_required                   IN VARCHAR2,
        p_cutoff_date_subtract_from_release_date IN NUMBER,
        p_cleanup_release_date_editable          IN VARCHAR2,
        p_cleanup_release_date_required          IN VARCHAR2,
        p_cleanup_release_date_subtract_from_osd IN NUMBER,
        p_created_by                             IN VARCHAR2,
        p_created_date                           IN DATE,
        p_last_updated_by                        IN VARCHAR2,
        p_last_updated_date                      IN DATE,
        p_return_status                         OUT VARCHAR2
    ) IS
        l_count NUMBER := 0;
    BEGIN
        SELECT
            COUNT(1)
        INTO l_count
        FROM
            xxhbg_ss_shipping_schedule_type_template
        WHERE
            shipping_schedule_type = p_shipping_schedule_type;
            

        IF l_count > 0 THEN
            UPDATE xxhbg_ss_shipping_schedule_type_template
            SET
                add_items_automatically = p_add_items_automatically,
                remove_items_automatically = p_remove_items_automatically,
                on_sale_date_editable = p_on_sale_date_editable,
                on_sale_date_required = p_on_sale_date_required,
                release_date_editable = p_release_date_editable,
                release_date_required = p_release_date_required,
                release_date_subtract_from_osd = p_release_date_subtract_from_osd,
                cutoff_date_editable = p_cutoff_date_editable,
                cutoff_date_required = p_cutoff_date_required,
                cutoff_date_subtract_from_release_date = p_cutoff_date_subtract_from_release_date,
                cleanup_release_date_editable = p_cleanup_release_date_editable,
                cleanup_release_date_required = p_cleanup_release_date_required,
                cleanup_release_date_subtract_from_osd = p_cleanup_release_date_subtract_from_osd,
                last_updated_by = p_last_updated_by,
                last_updated_date = sysdate
            WHERE
                shipping_schedule_type = p_shipping_schedule_type;

        ELSE
            INSERT INTO xxhbg_ss_shipping_schedule_type_template (
                shipping_schedule_type,
                add_items_automatically,
                remove_items_automatically,
                on_sale_date_editable,
                on_sale_date_required,
                release_date_editable,
                release_date_required,
                release_date_subtract_from_osd,
                cutoff_date_editable,
                cutoff_date_required,
                cutoff_date_subtract_from_release_date,
                cleanup_release_date_editable,
                cleanup_release_date_required,
                cleanup_release_date_subtract_from_osd,
                created_by,
                created_date,
                last_updated_by,
                last_updated_date
            ) VALUES (
                p_shipping_schedule_type,
                p_add_items_automatically,
                p_remove_items_automatically,
                p_on_sale_date_editable,
                p_on_sale_date_required,
                p_release_date_editable,
                p_release_date_required,
                p_release_date_subtract_from_osd,
                p_cutoff_date_editable,
                p_cutoff_date_required,
                p_cutoff_date_subtract_from_release_date,
                p_cleanup_release_date_editable,
                p_cleanup_release_date_required,
                p_cleanup_release_date_subtract_from_osd,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate
            );

        END IF;
        p_return_status := 'SUCCESS';
      
    END hbg_ss_create_ship_sch_type_template;

    PROCEDURE hbg_ss_create_ship_release_type_template (
        p_release_type                                                   IN VARCHAR2,
        p_res_immediately_or_according_to_delivery_profile_release_dates IN VARCHAR2,
        p_make_ip_on_release                                             IN VARCHAR2,
        p_override_small_pack                                            IN VARCHAR2,
        p_rush                                                           IN VARCHAR2,
        p_category_0_release_date_subtract_from_osd                      IN NUMBER,
        p_category_0_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_1_release_date_subtract_from_osd                      IN NUMBER,
        p_category_1_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_2_release_date_subtract_from_osd                      IN NUMBER,
        p_category_2_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_3_release_date_subtract_from_osd                      IN NUMBER,
        p_category_3_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_4_release_date_subtract_from_osd                      IN NUMBER,
        p_category_4_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_5_release_date_subtract_from_osd                      IN NUMBER,
        p_category_5_mab_date_subtract_from_osd                          IN NUMBER,
        p_category_6_release_date_subtract_from_osd                      IN NUMBER,
        p_category_6_mab_date_subtract_from_osd                          IN NUMBER,
        p_created_by                                                     IN VARCHAR2,
        p_created_date                                                   IN DATE,
        p_last_updated_by                                                IN VARCHAR2,
        p_last_updated_date                                              IN DATE,
        p_return_status                                                 OUT VARCHAR2
    ) IS
        l_count NUMBER := 0;
    BEGIN
        SELECT
            COUNT(1)
        INTO l_count
        FROM
            xxhbg_ss_release_type_template
        WHERE
            release_type = p_release_type;

        IF l_count > 0 THEN
            UPDATE xxhbg_ss_release_type_template
            SET
                res_immediately_or_according_to_delivery_profile_release_dates = p_res_immediately_or_according_to_delivery_profile_release_dates,
                make_ip_on_release = p_make_ip_on_release,
                override_small_pack = p_override_small_pack,
                rush = p_rush,
                category_0_release_date_subtract_from_osd = p_category_0_release_date_subtract_from_osd,
                category_0_mab_date_subtract_from_osd = p_category_0_mab_date_subtract_from_osd,
                category_1_release_date_subtract_from_osd = p_category_1_release_date_subtract_from_osd,
                category_1_mab_date_subtract_from_osd = p_category_1_mab_date_subtract_from_osd,
                category_2_release_date_subtract_from_osd = p_category_2_release_date_subtract_from_osd,
                category_2_mab_date_subtract_from_osd = p_category_2_mab_date_subtract_from_osd,
                category_3_release_date_subtract_from_osd = p_category_3_release_date_subtract_from_osd,
                category_3_mab_date_subtract_from_osd = p_category_3_mab_date_subtract_from_osd,
                category_4_release_date_subtract_from_osd = p_category_4_release_date_subtract_from_osd,
                category_4_mab_date_subtract_from_osd = p_category_4_mab_date_subtract_from_osd,
                category_5_release_date_subtract_from_osd = p_category_5_release_date_subtract_from_osd,
                category_5_mab_date_subtract_from_osd = p_category_5_mab_date_subtract_from_osd,
                category_6_release_date_subtract_from_osd = p_category_6_release_date_subtract_from_osd,
                category_6_mab_date_subtract_from_osd = p_category_6_mab_date_subtract_from_osd,
                last_updated_by = p_last_updated_by,
                last_updated_date = sysdate
            WHERE
                release_type = p_release_type;

        ELSE
            INSERT INTO xxhbg_ss_release_type_template (
                release_type,
                res_immediately_or_according_to_delivery_profile_release_dates,
                make_ip_on_release,
                override_small_pack,
                rush,
                category_0_release_date_subtract_from_osd,
                category_0_mab_date_subtract_from_osd,
                category_1_release_date_subtract_from_osd,
                category_1_mab_date_subtract_from_osd,
                category_2_release_date_subtract_from_osd,
                category_2_mab_date_subtract_from_osd,
                category_3_release_date_subtract_from_osd,
                category_3_mab_date_subtract_from_osd,
                category_4_release_date_subtract_from_osd,
                category_4_mab_date_subtract_from_osd,
                category_5_release_date_subtract_from_osd,
                category_5_mab_date_subtract_from_osd,
                category_6_release_date_subtract_from_osd,
                category_6_mab_date_subtract_from_osd,
                created_by,
                created_date,
                last_updated_by,
                last_updated_date
            ) VALUES (
                p_release_type,
                p_res_immediately_or_according_to_delivery_profile_release_dates,
                p_make_ip_on_release,
                p_override_small_pack,
                p_rush,
                p_category_0_release_date_subtract_from_osd,
                p_category_0_mab_date_subtract_from_osd,
                p_category_1_release_date_subtract_from_osd,
                p_category_1_mab_date_subtract_from_osd,
                p_category_2_release_date_subtract_from_osd,
                p_category_2_mab_date_subtract_from_osd,
                p_category_3_release_date_subtract_from_osd,
                p_category_3_mab_date_subtract_from_osd,
                p_category_4_release_date_subtract_from_osd,
                p_category_4_mab_date_subtract_from_osd,
                p_category_5_release_date_subtract_from_osd,
                p_category_5_mab_date_subtract_from_osd,
                p_category_6_release_date_subtract_from_osd,
                p_category_6_mab_date_subtract_from_osd,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate
            );

        END IF;
        p_return_status := 'SUCCESS';
    END hbg_ss_create_ship_release_type_template;

END hbg_shipping_schedules_pkg;

/

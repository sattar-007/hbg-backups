--------------------------------------------------------
--  DDL for Package HBG_SHIPPING_SCHEDULES_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_SHIPPING_SCHEDULES_PKG" AS
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
    );

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
    );

END hbg_shipping_schedules_pkg;

/

--------------------------------------------------------
--  DDL for Package HBG_FAMILY_CODE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_FAMILY_CODE_PKG" IS
    PROCEDURE hbg_family_code_owner_create (
        p_owner_code        IN VARCHAR2,
        p_owner_name        IN VARCHAR2,
        p_owner_abbr        IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_in_pubtracker_ind IN VARCHAR2,
        p_distributee_ind   IN VARCHAR2,
        p_creation_date     IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_owner_update (
        p_owner_id          IN NUMBER,
        p_owner_code        IN VARCHAR2,
        p_owner_name        IN VARCHAR2,
        p_owner_abbr        IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_in_pubtracker_ind IN VARCHAR2,
        p_distributee_ind   IN VARCHAR2,
         p_creation_date     IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_group_create (
        p_reporting_grp_code IN VARCHAR2,
        p_reporting_grp_name IN VARCHAR2,
        p_reporting_grp_abbr IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_owner_id           IN NUMBER,
        p_status             IN VARCHAR2,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_return_status      OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_group_update (
        p_reporting_group_id IN NUMBER,
        p_reporting_grp_code IN VARCHAR2,
        p_reporting_grp_name IN VARCHAR2,
        p_reporting_grp_abbr IN VARCHAR2,
        p_creation_date      IN DATE,
        p_created_by         IN VARCHAR2,
        p_last_updated_date  IN DATE,
        p_last_updated_by    IN VARCHAR2,
        p_owner_id           IN NUMBER,
        p_status             IN VARCHAR2,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_return_status      OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_category1_create (
        p_category1_code         IN VARCHAR2,
        p_category1_name         IN VARCHAR2,
        p_category1_abbr         IN VARCHAR2,
        p_start_date             IN DATE,
        p_end_date               IN DATE,
        p_status                 IN VARCHAR2,
        p_returnable_grace_days  IN NUMBER,
        p_creation_date          IN DATE,
        p_created_by             IN VARCHAR2,
        p_last_updated_date      IN DATE,
        p_last_updated_by        IN VARCHAR2,
        p_reporting_group_id     IN NUMBER,
        p_pub_id                 IN NUMBER,
        p_company_code           IN VARCHAR2,
        p_osd_ind                IN VARCHAR2,
        p_partial_ship_ind       IN VARCHAR2,
        p_partial_ship_threshold IN NUMBER,
        p_return_status          OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_category1_update (
        p_category1_id           IN NUMBER,
        p_category1_code         IN VARCHAR2,
        p_category1_name         IN VARCHAR2,
        p_category1_abbr         IN VARCHAR2,
        p_start_date             IN DATE,
        p_end_date               IN DATE,
        p_status                 IN VARCHAR2,
        p_returnable_grace_days  IN NUMBER,
        p_creation_date          IN DATE,
        p_created_by             IN VARCHAR2,
        p_last_updated_date      IN DATE,
        p_last_updated_by        IN VARCHAR2,
        p_reporting_group_id     IN NUMBER,
        p_pub_id                 IN NUMBER,
        p_company_code           IN VARCHAR2,
        p_osd_ind                IN VARCHAR2,
        p_partial_ship_ind       IN VARCHAR2,
        p_partial_ship_threshold IN NUMBER,
        p_return_status          OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_category2_create (
        p_category2_code    IN VARCHAR2,
        p_category2_name    IN VARCHAR2,
        p_category2_abbr    IN VARCHAR2,
        p_impr_id           IN  NUMBER,
        p_created_by      IN VARCHAR2,
        p_last_updated_by IN VARCHAR2,
        p_category1_id    IN NUMBER,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_status          IN VARCHAR2,
        p_return_status   OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_reporting_category2_update (
       p_category2_id      IN NUMBER,
        p_category2_code    IN VARCHAR2,
        p_category2_name    IN VARCHAR2,
        p_category2_abbr    IN VARCHAR2,
        p_impr_id           IN  NUMBER,
        p_creation_date         IN DATE,
        p_created_by            IN VARCHAR2,
        p_last_updated_date     IN DATE,
        p_last_updated_by       IN VARCHAR2,
        p_category1_id          IN NUMBER,
        p_start_date            IN DATE,
        p_end_date              IN DATE,
        p_status                IN VARCHAR2,
        p_return_status         OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_external_publisher_create (
        p_external_pub_code IN VARCHAR2,
        p_external_pub_name IN VARCHAR2,
        p_external_pub_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_category1_id      IN NUMBER,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_external_publisher_update (
        p_pub_id            IN NUMBER,
        p_external_pub_code IN VARCHAR2,
        p_external_pub_name IN VARCHAR2,
        p_external_pub_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_category1_id      IN NUMBER,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_external_imprint_create (
        p_external_imp_code IN VARCHAR2,
        p_external_imp_name IN VARCHAR2,
        p_external_imp_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_category2_id      IN NUMBER,
        p_pub_id            IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_external_imprint_update (
        p_impr_id           IN NUMBER,
        p_external_imp_code IN VARCHAR2,
        p_external_imp_name IN VARCHAR2,
        p_external_imp_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_category2_id      IN NUMBER,
        p_pub_id            IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_format_create (
        p_format_code         IN VARCHAR2,
        p_format_name         IN VARCHAR2,
        p_format_abbr         IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_ebook_ind           IN VARCHAR2,
        p_nonpub_item_ind     IN VARCHAR2,
        p_audio_ind           IN VARCHAR2,
        p_inc_sale_ind        IN VARCHAR2,
        p_cal_ind             IN VARCHAR2,
        p_commodity_code      IN VARCHAR2,
        p_require_sub_fmt_ind IN VARCHAR2,
        p_creation_date       IN DATE,
        p_created_by          IN VARCHAR2,
        p_last_updated_date   IN DATE,
        p_last_updated_by     IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_format_update (
        p_format_id           IN NUMBER,
        p_format_code         IN VARCHAR2,
        p_format_name         IN VARCHAR2,
        p_format_abbr         IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_ebook_ind           IN VARCHAR2,
        p_nonpub_item_ind     IN VARCHAR2,
        p_audio_ind           IN VARCHAR2,
        p_inc_sale_ind        IN VARCHAR2,
        p_cal_ind             IN VARCHAR2,
        p_commodity_code      IN VARCHAR2,
        p_require_sub_fmt_ind IN VARCHAR2,
        p_creation_date       IN DATE,
        p_created_by          IN VARCHAR2,
        p_last_updated_date   IN DATE,
        p_last_updated_by     IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_sub_format_create (
        p_sub_format_code   IN VARCHAR2,
        p_sub_format_name   IN VARCHAR2,
        p_sub_format_abbr   IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_commodity_code    IN VARCHAR2,
        p_default_rpt_ind   IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_family_code_sub_format_update (
        p_sub_format_id     IN NUMBER,
        p_sub_format_code   IN VARCHAR2,
        p_sub_format_name   IN VARCHAR2,
        p_sub_format_abbr   IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_commodity_code    IN VARCHAR2,      
        p_default_rpt_ind   IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

END hbg_family_code_pkg;

/

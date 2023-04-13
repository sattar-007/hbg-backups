--------------------------------------------------------
--  DDL for Package HBG_CUSTOMER_MASTER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_CUSTOMER_MASTER_PKG" IS
    PROCEDURE hbg_client_info_create (
        cust_owner                  IN VARCHAR2,
        owner_description           IN VARCHAR2,
        account_type                IN VARCHAR2,
        account_type_description    IN VARCHAR2,
        created_by                  IN VARCHAR2,
        last_updated_by             IN VARCHAR2,
        default_account_type        IN VARCHAR2,
        default_account_type_owners IN VARCHAR2,
        operation_account_type      IN VARCHAR2,
        reporting_group             IN VARCHAR2,
        reporting_group_description IN VARCHAR2,
        category1                   IN VARCHAR2,
        category1_description       IN VARCHAR2,
        category2                   IN VARCHAR2,
        category2_description       IN VARCHAR2,
        cust_format                 IN VARCHAR2,
        format_description          IN VARCHAR2,
        sub_format                  IN VARCHAR2,
        sub_format_description      IN VARCHAR2,
        customer_account            IN VARCHAR2,
        cust_account_id             IN NUMBER,
        p_return_status             OUT VARCHAR2
    );

    PROCEDURE hbg_client_info_upd (
        p_client_info_id              IN NUMBER,
        p_cust_owner                  IN VARCHAR2,
        p_owner_description           IN VARCHAR2,
        p_account_type                IN VARCHAR2,
        p_account_type_description    IN VARCHAR2,
        p_last_updated_by             IN VARCHAR2,
        p_default_account_type        IN VARCHAR2,
        p_default_account_type_owners IN VARCHAR2,
        p_operation_account_type      IN VARCHAR2,
        p_reporting_group             IN VARCHAR2,
        p_reporting_group_description IN VARCHAR2,
        p_category1                   IN VARCHAR2,
        p_category1_description       IN VARCHAR2,
        p_category2                   IN VARCHAR2,
        p_category2_description       IN VARCHAR2,
        p_cust_format                 IN VARCHAR2,
        p_format_description          IN VARCHAR2,
        p_sub_format                  IN VARCHAR2,
        p_sub_format_description      IN VARCHAR2,
        p_customer_account            IN VARCHAR2,
        p_cust_account_id             IN NUMBER,
        p_return_status               OUT VARCHAR2
    );

    PROCEDURE hbg_cust_account_type_create (
      
        p_customer_name        IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_name         IN VARCHAR2,
        p_cust_accnt_id        IN NUMBER,
        p_party_id             IN VARCHAR2,
        p_default_account_type IN VARCHAR2,
        p_account_type_desc    IN VARCHAR2,
        p_entered_by           IN VARCHAR2,
        p_entered_date         IN DATE,
        p_updated_by           IN VARCHAR2,
        p_updated_date         IN DATE,
        p_registry_id          IN NUMBER,
        p_organization_name    IN VARCHAR2,
        p_site_number          IN VARCHAR2,
        p_site_name            IN VARCHAR2,
        p_country              IN VARCHAR2,
        p_address              IN VARCHAR2,
        p_city                 IN VARCHAR2,
        p_state             IN VARCHAR2,
        p_postal_code          IN VARCHAR2,
        p_san                  IN VARCHAR2,
        p_lookup               IN Varchar2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_cust_account_type_update (
        p_acc_typ_id           IN NUMBER,
        p_customer_name        IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_name         IN VARCHAR2,
        p_cust_accnt_id        IN NUMBER,
        p_party_id             IN VARCHAR2,
        p_default_account_type IN VARCHAR2,
        p_account_type_desc    IN VARCHAR2,
        p_entered_by           IN VARCHAR2,
        p_entered_date         IN DATE,
        p_updated_by           IN VARCHAR2,
        p_updated_date         IN DATE,
        p_registry_id          IN NUMBER,
        p_organization_name    IN VARCHAR2,
        p_site_number          IN VARCHAR2,
        p_site_name            IN VARCHAR2,
        p_country              IN VARCHAR2,
        p_address              IN VARCHAR2,
        p_city                 IN VARCHAR2,
        p_state             IN VARCHAR2,
        p_postal_code          IN VARCHAR2,
        p_san                  IN VARCHAR2,
        p_lookup               IN Varchar2,
        p_return_status     OUT VARCHAR2
    );

END hbg_customer_master_pkg;

/

--------------------------------------------------------
--  DDL for Package HBG_SO_DIST_TITLE_RIGHTS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_SO_DIST_TITLE_RIGHTS_PKG" IS

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group & Associations Deletion                        
-- |Description      : This Program is used to delete the country associations available under particular group 					    
-- +===================================================================+

    PROCEDURE hbg_country_assoc_deletion (
        p_country_id       IN VARCHAR2,
        p_country_group_id IN NUMBER,
        p_return_status    OUT VARCHAR2
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Update                        
-- |Description      : This Program is used to Update the country group information  					    
-- +===================================================================+

    PROCEDURE hbg_country_group_update (
        p_country_group_id   IN NUMBER,
        p_comments           IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_return_status      OUT VARCHAR2
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Update                        
-- |Description      : This Program is used to create the association with the country group  					    
-- +===================================================================+

    PROCEDURE hbg_add_country_assocation (
        p_country_group_id IN NUMBER,
        p_country_id       IN NUMBER,
        p_created_by       IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_return_status    OUT VARCHAR2
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group create                        
-- |Description      : This Program is used to create  the country group  					    
-- +===================================================================+

    PROCEDURE hbg_create_country_group (
        p_country_group_code IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_comments           IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_return_status      OUT VARCHAR2,
        p_country_group_id   OUT NUMBER
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Copy & Edit                        
-- |Description      : This Program is used to create using the copy & Edit of existing country group  					    
-- +===================================================================+

    PROCEDURE hbg_copyedit_country_group (
        p_country_group      IN NUMBER,
        p_country_group_code IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_comments           IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_return_status      OUT VARCHAR2,
        p_country_group_id   OUT NUMBER
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Creation                        
-- |Description      : This Program is used to create distribution rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_creation (
        p_owner             IN VARCHAR2,
        p_reporting_group   IN VARCHAR2,
        p_category_1        IN VARCHAR2,
        p_category_2        IN VARCHAR2,
        p_format            IN VARCHAR2,
        p_subformat         IN VARCHAR2,
        p_from_pubdate      IN DATE,
        p_to_pubdate        IN DATE,
        p_country_group     IN NUMBER,
        p_country_code      IN NUMBER,
        p_edition           IN VARCHAR2,
        p_item_number       IN VARCHAR2,
        p_account_number    IN NUMBER,
        p_account_type      IN VARCHAR2,
        p_default_acct_type IN VARCHAR2,
        p_outcome           IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_group_rule        IN VARCHAR2,
        p_comments          IN VARCHAR2,
        p_created_by        IN VARCHAR2,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Updation                        
-- |Description      : This Program is used to update distribution rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_update (
        p_distribution_right_id IN NUMBER,
        p_end_date              IN DATE,
        p_group_rule            IN VARCHAR2,
        p_comments              IN VARCHAR2,
        p_last_updated_by       IN VARCHAR2,
        p_return_status         OUT VARCHAR2
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Validation                        
-- |Description      : This Program is used to Validate distribution & title rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_title_rights_val (
        p_source_line_id     IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    );
	
-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Groups Conversion                        
-- |Description      : This Program is used to Load the Country Groups				    
-- +===================================================================+

    PROCEDURE hbg_country_group_load ;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Conversion                        
-- |Description      : This Program is used to Load the Distribution Rights				    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_load ;
    
-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Conversion                        
-- |Description      : This Program is used to Load the Title Rights				    
-- +===================================================================+

    PROCEDURE hbg_title_rights_load ;

END hbg_so_dist_title_rights_pkg;

/

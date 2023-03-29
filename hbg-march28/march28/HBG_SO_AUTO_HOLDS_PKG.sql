--------------------------------------------------------
--  DDL for Package HBG_SO_AUTO_HOLDS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_SO_AUTO_HOLDS_PKG" IS

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

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
    );

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : SO Custom Rules VALIDATION                        
-- |Description      : This Program is used to Validate SO Information and release the Holds Placed on orders				    
-- +===================================================================+	
    PROCEDURE hbg_so_custom_rule_release (
        p_source_line_id     IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    );

END hbg_so_auto_holds_pkg;

/

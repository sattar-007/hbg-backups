--------------------------------------------------------
--  DDL for Package HBG_ITEM_HOT_TITLES_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_ITEM_HOT_TITLES_PKG" AS
    PROCEDURE validate_hold_items (
        p_source_order_line_id IN VARCHAR2,
        p_batch_name           IN VARCHAR2,
        x_status_code          OUT VARCHAR2,
        p_so_auto_hold_array   OUT hbg_so_auto_holds_type_array
    );

    PROCEDURE validate_release_items (
        p_source_order_line_id IN VARCHAR2,
        x_status_code          OUT VARCHAR2,
        p_so_auto_hold_array   OUT hbg_so_auto_holds_type_array
    );

END;

/

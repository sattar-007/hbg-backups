--------------------------------------------------------
--  DDL for Type XXHBG_PRE_RESERVATION_LINE_CRT_REC
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."XXHBG_PRE_RESERVATION_LINE_CRT_REC" force AS OBJECT (
          p_item_code               NUMBER,
        p_isbn_on_book            NUMBER,
        p_short_title             VARCHAR2(200),
        p_status                  VARCHAR2(200),
        p_reservation_type        VARCHAR2(200),
        p_print_number            NUMBER,
        p_inventory_organization  VARCHAR2(200),
        p_lot_number              NUMBER,
        p_subinventory            VARCHAR2(200),
        p_requested_quantity      NUMBER,
        p_reserved_quantity       NUMBER,
        p_released_via_cuid       NUMBER,
        p_available_reserved      NUMBER,
        p_ip_only                 VARCHAR2(200),
        p_pre_reserved_balance    NUMBER,
        p_usable_balance          NUMBER,
        p_end_balance             NUMBER,
        p_created_by              VARCHAR2(200),
        p_last_updated_by         VARCHAR2(200),
        p_reservation_number      NUMBER,
    CONSTRUCTOR FUNCTION XXHBG_PRE_RESERVATION_LINE_CRT_REC
        RETURN SELF AS RESULT
);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."XXHBG_PRE_RESERVATION_LINE_CRT_REC" AS
 CONSTRUCTOR FUNCTION XXHBG_PRE_RESERVATION_LINE_CRT_REC
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/

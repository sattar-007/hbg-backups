--------------------------------------------------------
--  DDL for Type XXHBG_PRE_RESERVATION_HDR_CRT_REC
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."XXHBG_PRE_RESERVATION_HDR_CRT_REC" force AS OBJECT (
        p_pre_reservation_number  NUMBER,
        p_inventory_organization  VARCHAR2(200),
        p_requester               VARCHAR2(200),
        p_approver                VARCHAR2(200),
        p_reason_code             VARCHAR2(200),
        p_reservation_type        VARCHAR2(200),
        p_print_number            NUMBER,
        p_expiration_date         DATE,
        p_comments                VARCHAR2(200),
        p_status                  VARCHAR2(200),
        p_criteria_uid            VARCHAR2(200),
        p_created_by              VARCHAR2(200),
        p_last_updated_by         VARCHAR2(200),
        reservation_lines        XXHBG_PRE_RESERVATION_LINE_CRT_TBL,
    CONSTRUCTOR FUNCTION XXHBG_PRE_RESERVATION_HDR_CRT_REC
        RETURN SELF AS RESULT
);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."XXHBG_PRE_RESERVATION_HDR_CRT_REC" AS
 CONSTRUCTOR FUNCTION XXHBG_PRE_RESERVATION_HDR_CRT_REC
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/

--------------------------------------------------------
--  DDL for Trigger XXHBG_SALES_FORCE_DIV_TBL_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_SALES_FORCE_DIV_TBL_TRG" BEFORE
    INSERT ON "XXHBG_SALES_FORCE_DIV_TBL"
    FOR EACH ROW
BEGIN
    IF :new.SF_DIV_ID IS NULL THEN
        SELECT
            XXHBG_SALES_FORCE_DIV_TBL_SEQ.NEXTVAL
        INTO :new.SF_DIV_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_SALES_FORCE_DIV_TBL_TRG" ENABLE;

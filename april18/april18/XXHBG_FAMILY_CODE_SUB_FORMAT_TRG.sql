--------------------------------------------------------
--  DDL for Trigger XXHBG_FAMILY_CODE_SUB_FORMAT_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_SUB_FORMAT_TRG" BEFORE
    INSERT ON "XXHBG_FAMILY_CODE_SUB_FORMAT"
    FOR EACH ROW
BEGIN
    IF :new.SUB_FORMAT_ID IS NULL THEN
        SELECT
            XXHBG_FAMILY_CODE_SUB_FORMAT_SEQ.NEXTVAL
        INTO :new.SUB_FORMAT_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_SUB_FORMAT_TRG" ENABLE;

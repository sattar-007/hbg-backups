--------------------------------------------------------
--  DDL for Trigger XXHBG_FAMILY_CODE_REPORTING_CATEGORY2_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_REPORTING_CATEGORY2_TRG" BEFORE
    INSERT ON "XXHBG_FAMILY_CODE_REPORTING_CATEGORY2"
    FOR EACH ROW
BEGIN
    IF :new.CATEGORY2_ID IS NULL THEN
        SELECT
            XXHBG_FAMILY_CODE_REPORTING_CATEGORY2_SEQ.NEXTVAL
        INTO :new.CATEGORY2_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_REPORTING_CATEGORY2_TRG" ENABLE;
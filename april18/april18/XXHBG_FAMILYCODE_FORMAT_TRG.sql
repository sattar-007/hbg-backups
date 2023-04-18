--------------------------------------------------------
--  DDL for Trigger XXHBG_FAMILYCODE_FORMAT_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILYCODE_FORMAT_TRG" BEFORE
    INSERT ON "XXHBG_FAMILYCODE_FORMAT"
    FOR EACH ROW
BEGIN
    IF :new.FORMAT_ID IS NULL THEN
        SELECT
            XXHBG_FAMILYCODE_FORMAT_SEQ.NEXTVAL
        INTO :new.FORMAT_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILYCODE_FORMAT_TRG" ENABLE;

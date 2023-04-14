--------------------------------------------------------
--  DDL for Trigger XXHBG_FAMILY_CODE_OWNER_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_OWNER_TRG" BEFORE
    INSERT ON "XXHBG_FAMILY_CODE_OWNER"
    FOR EACH ROW
BEGIN
    IF :new.OWNER_ID IS NULL THEN
        SELECT
            XXHBG_FAMILY_CODE_OWNER_SEQ.NEXTVAL
        INTO :new.OWNER_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_FAMILY_CODE_OWNER_TRG" ENABLE;

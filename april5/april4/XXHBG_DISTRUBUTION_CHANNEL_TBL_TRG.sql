--------------------------------------------------------
--  DDL for Trigger XXHBG_DISTRUBUTION_CHANNEL_TBL_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_DISTRUBUTION_CHANNEL_TBL_TRG" BEFORE
    INSERT ON "XXHBG_DISTRUBUTION_CHANNEL_TBL"
    FOR EACH ROW
BEGIN
    IF :new.DIST_CHANNEL_ID IS NULL THEN
        SELECT
            XXHBG_DISTRUBUTION_CHANNEL_TBL_SEQ.NEXTVAL
        INTO :new.DIST_CHANNEL_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_DISTRUBUTION_CHANNEL_TBL_TRG" ENABLE;

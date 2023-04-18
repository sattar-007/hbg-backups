--------------------------------------------------------
--  DDL for Trigger HBG_SO_HOT_TITLE_HOLD_ID_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_HOLD_ID_TRG" BEFORE
    INSERT ON "HBG_SO_HOT_TITLES_HOLD_EXT"
    FOR EACH ROW
BEGIN
    IF :new.stage_id IS NULL THEN
        SELECT
            hbg_so_hot_title_hold_id.NEXTVAL
        INTO :new.stage_id
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_HOLD_ID_TRG" ENABLE;

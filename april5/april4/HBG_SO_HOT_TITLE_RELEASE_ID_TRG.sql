--------------------------------------------------------
--  DDL for Trigger HBG_SO_HOT_TITLE_RELEASE_ID_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_RELEASE_ID_TRG" BEFORE
    INSERT ON hbg_so_hot_titles_release_ext
    FOR EACH ROW
BEGIN
    IF :new.stage_id IS NULL THEN
        SELECT
            hbg_so_hot_title_release_id.NEXTVAL
        INTO :new.stage_id
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_RELEASE_ID_TRG" ENABLE;

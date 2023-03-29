--------------------------------------------------------
--  DDL for Trigger XXHBG_RES_PRE_RES_RECORD_ID_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_RES_PRE_RES_RECORD_ID_TRG" BEFORE
    INSERT ON xxhbg_res_pre_reservation_lines
    FOR EACH ROW
	 WHEN (new.record_id IS NULL) BEGIN
        SELECT
            XXHBG_RES_PRE_RES_RECORD_ID_SEQ.NEXTVAL
        INTO :new.record_id
        FROM
            dual;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_RES_PRE_RES_RECORD_ID_TRG" ENABLE;

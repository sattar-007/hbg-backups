--------------------------------------------------------
--  DDL for Trigger XXHBG_SF_ACCT_TYPE_TBL_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."XXHBG_SF_ACCT_TYPE_TBL_TRG" BEFORE
    INSERT ON "XXHBG_SF_ACCT_TYPE_TBL"
    FOR EACH ROW
BEGIN
    IF :new.SF_ACCT_TYPE_ID IS NULL THEN
        SELECT
            XXHBG_SF_ACCT_TYPE_TBL_SEQ.NEXTVAL
        INTO :new.SF_ACCT_TYPE_ID
        FROM
            sys.dual;

    END IF;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."XXHBG_SF_ACCT_TYPE_TBL_TRG" ENABLE;

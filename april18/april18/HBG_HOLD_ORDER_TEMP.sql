--------------------------------------------------------
--  DDL for Trigger HBG_HOLD_ORDER_TEMP
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_HOLD_ORDER_TEMP" 
BEFORE INSERT
   ON hbg_cx_order_header
   FOR EACH ROW

DECLARE

BEGIN

if (:new.account_id is null) then
   :new.integration_status := 'SENT';
   :new.state := 'HOLD_' || :new.state;
end if;

EXCEPTION
   WHEN OTHERS THEN
   null;
END;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_HOLD_ORDER_TEMP" ENABLE;

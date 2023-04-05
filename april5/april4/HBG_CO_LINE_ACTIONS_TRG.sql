--------------------------------------------------------
--  DDL for Trigger HBG_CO_LINE_ACTIONS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_CO_LINE_ACTIONS_TRG" 
              before insert on HBG_CO_LINE_ACTIONS
              for each row
              begin
                  if :new.LINE_ACTION_ID is null then
                      select HBG_CO_LINE_ACTIONS_SEQ .nextval into :new.LINE_ACTION_ID from sys.dual;
                 end if;
              end;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_CO_LINE_ACTIONS_TRG" ENABLE;

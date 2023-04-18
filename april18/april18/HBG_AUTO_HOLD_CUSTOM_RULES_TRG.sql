--------------------------------------------------------
--  DDL for Trigger HBG_AUTO_HOLD_CUSTOM_RULES_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_AUTO_HOLD_CUSTOM_RULES_TRG" 
              before insert on HBG_AUTO_HOLD_CUSTOM_RULES_EXT
              for each row
              begin
                  if :new.RULE_ID is null then
                      select HBG_AUTO_HOLD_CUSTOM_RULES_SEQ .nextval into :new.RULE_ID from sys.dual;
                 end if;
              end;

/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_AUTO_HOLD_CUSTOM_RULES_TRG" ENABLE;

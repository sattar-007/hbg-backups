--------------------------------------------------------
--  DDL for Trigger HBG_CO_RULES_LINES_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_CO_RULES_LINES_TRG" 
              before insert on HBG_CO_RULES_LINES
              for each row
              begin
                  if :new.RULE_LINE_ID is null then
                      select HBG_CO_RULES_LINES_SEQ .nextval into :new.RULE_LINE_ID from sys.dual;
                 end if;
              end;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_CO_RULES_LINES_TRG" ENABLE;

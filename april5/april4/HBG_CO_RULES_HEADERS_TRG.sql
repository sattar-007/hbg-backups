--------------------------------------------------------
--  DDL for Trigger HBG_CO_RULES_HEADERS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_CO_RULES_HEADERS_TRG" 
              before insert on HBG_CO_RULES_HEADERS
              for each row
              begin
                  if :new.RULE_ID is null then
                      select HBG_CO_RULES_HEADERS_SEQ .nextval into :new.RULE_ID from sys.dual;
                 end if;
              end;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_CO_RULES_HEADERS_TRG" ENABLE;

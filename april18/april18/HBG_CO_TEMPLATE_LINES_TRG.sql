--------------------------------------------------------
--  DDL for Trigger HBG_CO_TEMPLATE_LINES_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_CO_TEMPLATE_LINES_TRG" 
              before insert on HBG_CO_TEMPLATE_LINES
              for each row
              begin
                  if :new.LINE_ID is null then
                      select HBG_CO_TEMPLATE_LINES_SEQ .nextval into :new.LINE_ID from sys.dual;
                 end if;
              end;
/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_CO_TEMPLATE_LINES_TRG" ENABLE;

--------------------------------------------------------
--  DDL for Trigger HBG_TITLE_RIGHTS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_TITLE_RIGHTS_TRG" 
              before insert on HBG_TITLE_RIGHTS_EXT
              for each row
              begin
                  if :new.TITLE_RIGHT_ID is null then
                      select HBG_TITLE_RIGHTS_SEQ.nextval into :new.TITLE_RIGHT_ID from sys.dual;
                 end if;
              end;

/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_TITLE_RIGHTS_TRG" ENABLE;

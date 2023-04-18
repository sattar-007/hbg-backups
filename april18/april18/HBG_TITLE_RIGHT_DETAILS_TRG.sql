--------------------------------------------------------
--  DDL for Trigger HBG_TITLE_RIGHT_DETAILS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_TITLE_RIGHT_DETAILS_TRG" 
              before insert on HBG_TITLE_RIGHT_DETAILS_EXT
              for each row
              begin
                  if :new.TITLE_RIGHT_DETAIL_ID is null then
                      select HBG_TITLE_RIGHT_DETAILS_SEQ.nextval into :new.TITLE_RIGHT_DETAIL_ID from sys.dual;
                 end if;
              end;

/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_TITLE_RIGHT_DETAILS_TRG" ENABLE;

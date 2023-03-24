--------------------------------------------------------
--  DDL for Trigger HBG_COUNTRY_GROUPS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_COUNTRY_GROUPS_TRG" 
              before insert on HBG_COUNTRY_GROUPS_EXT
              for each row
              begin
                  if :new.COUNTRY_GROUP_ID is null then
                      select HBG_COUNTRY_GROUPS_SEQ .nextval into :new.COUNTRY_GROUP_ID from sys.dual;
                 end if;
              end;


/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_COUNTRY_GROUPS_TRG" ENABLE;

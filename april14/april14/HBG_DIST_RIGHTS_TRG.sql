--------------------------------------------------------
--  DDL for Trigger HBG_DIST_RIGHTS_TRG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "HBG_INTEGRATION"."HBG_DIST_RIGHTS_TRG" 
              before insert on HBG_DIST_RIGHTS_EXT
              for each row
              begin
                  if :new.DISTRIBUTION_RIGHT_ID is null then
                      select HBG_DIST_RIGHTS_SEQ.nextval into :new.DISTRIBUTION_RIGHT_ID from sys.dual;
                 end if;
              end;

/
ALTER TRIGGER "HBG_INTEGRATION"."HBG_DIST_RIGHTS_TRG" ENABLE;

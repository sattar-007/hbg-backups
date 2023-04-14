--------------------------------------------------------
--  Constraints for Table HBG_COUNTRY_GROUPS_EXT
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_COUNTRY_GROUPS_EXT" ADD CONSTRAINT "HBG_COUNTRY_GROUPS_EXT_PK1" PRIMARY KEY ("COUNTRY_GROUP_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;

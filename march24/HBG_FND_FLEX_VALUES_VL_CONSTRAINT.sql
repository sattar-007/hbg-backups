--------------------------------------------------------
--  Constraints for Table HBG_FND_FLEX_VALUES_VL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_FND_FLEX_VALUES_VL" ADD CONSTRAINT "HBG_FND_FLEX_VALUES_VL_PK" PRIMARY KEY ("FLEX_VALUE_ID", "FLEX_VALUE_SET_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;
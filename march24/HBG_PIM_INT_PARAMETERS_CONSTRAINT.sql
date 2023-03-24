--------------------------------------------------------
--  Constraints for Table HBG_PIM_INT_PARAMETERS
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_PIM_INT_PARAMETERS" MODIFY ("PARAM_ID" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."HBG_PIM_INT_PARAMETERS" ADD CONSTRAINT "HBG_PIM_INT_PARAMETERS" PRIMARY KEY ("PARAM_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;

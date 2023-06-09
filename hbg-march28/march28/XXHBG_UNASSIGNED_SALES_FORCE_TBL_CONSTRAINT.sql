--------------------------------------------------------
--  Constraints for Table XXHBG_UNASSIGNED_SALES_FORCE_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."XXHBG_UNASSIGNED_SALES_FORCE_TBL" MODIFY ("ENTERED_BY" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."XXHBG_UNASSIGNED_SALES_FORCE_TBL" MODIFY ("START_DATE" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."XXHBG_UNASSIGNED_SALES_FORCE_TBL" ADD PRIMARY KEY ("SF_UNASSIGNED_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;

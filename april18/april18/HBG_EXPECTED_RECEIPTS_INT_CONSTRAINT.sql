--------------------------------------------------------
--  Constraints for Table HBG_EXPECTED_RECEIPTS_INT
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_EXPECTED_RECEIPTS_INT" MODIFY ("REFERENCE_NBR" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."HBG_EXPECTED_RECEIPTS_INT" MODIFY ("RECEIPT_LINE" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."HBG_EXPECTED_RECEIPTS_INT" ADD CONSTRAINT "HBG_EXPECTED_RECEIPTS_INT_PK" PRIMARY KEY ("REFERENCE_NBR", "RECEIPT_LINE")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;

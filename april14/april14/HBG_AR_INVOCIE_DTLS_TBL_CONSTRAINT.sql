--------------------------------------------------------
--  Constraints for Table HBG_AR_INVOCIE_DTLS_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_AR_INVOCIE_DTLS_TBL" MODIFY ("CUSTOMER_TRX_ID" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."HBG_AR_INVOCIE_DTLS_TBL" MODIFY ("PAYMENT_SCHEDULE_ID" NOT NULL ENABLE);
  ALTER TABLE "HBG_INTEGRATION"."HBG_AR_INVOCIE_DTLS_TBL" ADD PRIMARY KEY ("CUSTOMER_TRX_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;
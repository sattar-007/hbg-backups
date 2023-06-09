--------------------------------------------------------
--  DDL for Index IND_HBG_AR_PAYM_SCHE_002
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IND_HBG_AR_PAYM_SCHE_002" ON "HBG_INTEGRATION"."HBG_AR_PAYMENTS_SCHEDULE" ("BATCH_ID", "OIC_INTEGRATION_ID", "SEQUENCE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

--------------------------------------------------------
--  DDL for Index IND_HBG_AR_PAYM_ARCH_001
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IND_HBG_AR_PAYM_ARCH_001" ON "HBG_INTEGRATION"."HBG_AR_PAYMENTS_ARCHIVE" ("BATCH_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

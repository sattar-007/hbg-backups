--------------------------------------------------------
--  DDL for Index HBG_STERLING_SHIPTO_SAN_IDX_3
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."HBG_STERLING_SHIPTO_SAN_IDX_3" ON "HBG_INTEGRATION"."HBG_STERLING_SHIPTO_SAN" ("ACCOUNT_NUMBER") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

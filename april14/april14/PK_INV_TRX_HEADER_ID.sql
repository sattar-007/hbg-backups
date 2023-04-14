--------------------------------------------------------
--  DDL for Index PK_INV_TRX_HEADER_ID
--------------------------------------------------------

  CREATE UNIQUE INDEX "HBG_INTEGRATION"."PK_INV_TRX_HEADER_ID" ON "HBG_INTEGRATION"."HBG_WMS_INV_TRX_HEADER" ("INV_TRX_HEADER_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
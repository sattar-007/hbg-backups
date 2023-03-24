--------------------------------------------------------
--  DDL for Index HBG_PROCESS_ORDERS_ADDRESSES_FBDI_IDX_5
--------------------------------------------------------

  CREATE BITMAP INDEX "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_ADDRESSES_FBDI_IDX_5" ON "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_ADDRESSES_FBDI" ("SOURCE_SHIP_NO", "SOURCE_SHIPTO_SAN", "SOURCE_EDI_SHIP_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

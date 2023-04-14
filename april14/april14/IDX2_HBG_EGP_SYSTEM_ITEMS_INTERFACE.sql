--------------------------------------------------------
--  DDL for Index IDX2_HBG_EGP_SYSTEM_ITEMS_INTERFACE
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX2_HBG_EGP_SYSTEM_ITEMS_INTERFACE" ON "HBG_INTEGRATION"."HBG_EGP_SYSTEM_ITEMS_INTERFACE" ("ORGANIZATION_CODE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

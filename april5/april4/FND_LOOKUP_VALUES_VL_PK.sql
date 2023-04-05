--------------------------------------------------------
--  DDL for Index FND_LOOKUP_VALUES_VL_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "HBG_INTEGRATION"."FND_LOOKUP_VALUES_VL_PK" ON "HBG_INTEGRATION"."FND_LOOKUP_VALUES_VL" ("LOOKUP_TYPE", "LOOKUP_CODE", "VIEW_APPLICATION_ID", "SET_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

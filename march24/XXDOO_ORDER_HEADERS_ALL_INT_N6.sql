--------------------------------------------------------
--  DDL for Index XXDOO_ORDER_HEADERS_ALL_INT_N6
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."XXDOO_ORDER_HEADERS_ALL_INT_N6" ON "HBG_INTEGRATION"."XXDOO_ORDER_HEADERS_ALL_INT" ("SUB_BATCH_NAME") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE( INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;
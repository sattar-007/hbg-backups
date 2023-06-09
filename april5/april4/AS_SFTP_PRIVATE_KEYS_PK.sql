--------------------------------------------------------
--  DDL for Index AS_SFTP_PRIVATE_KEYS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "HBG_INTEGRATION"."AS_SFTP_PRIVATE_KEYS_PK" ON "HBG_INTEGRATION"."AS_SFTP_PRIVATE_KEYS" ("HOST", "ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;

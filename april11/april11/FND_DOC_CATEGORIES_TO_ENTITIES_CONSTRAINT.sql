--------------------------------------------------------
--  Constraints for Table FND_DOC_CATEGORIES_TO_ENTITIES
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."FND_DOC_CATEGORIES_TO_ENTITIES" ADD CONSTRAINT "FND_DOC_CATEGORIES_TO_ENTITIES_PK" PRIMARY KEY ("CATEGORY_ID", "DOCUMENT_ENTITY_ID", "ENTERPRISE_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;

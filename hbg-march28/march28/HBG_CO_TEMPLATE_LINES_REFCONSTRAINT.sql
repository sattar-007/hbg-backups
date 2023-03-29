--------------------------------------------------------
--  Ref Constraints for Table HBG_CO_TEMPLATE_LINES
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CO_TEMPLATE_LINES" ADD CONSTRAINT "HBG_CO_TEMPLATE_LINES_FK1" FOREIGN KEY ("TEMPLATE_ID")
	  REFERENCES "HBG_INTEGRATION"."HBG_CO_TEMPLATE_HEADERS" ("TEMPLATE_ID") ENABLE;

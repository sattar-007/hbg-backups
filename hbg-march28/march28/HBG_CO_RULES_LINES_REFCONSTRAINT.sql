--------------------------------------------------------
--  Ref Constraints for Table HBG_CO_RULES_LINES
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CO_RULES_LINES" ADD CONSTRAINT "HBG_CO_RULES_LINES_FK1" FOREIGN KEY ("RULE_ID")
	  REFERENCES "HBG_INTEGRATION"."HBG_CO_RULES_HEADERS" ("RULE_ID") ENABLE;

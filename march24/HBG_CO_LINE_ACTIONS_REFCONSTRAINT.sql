--------------------------------------------------------
--  Ref Constraints for Table HBG_CO_LINE_ACTIONS
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CO_LINE_ACTIONS" ADD CONSTRAINT "HBG_CO_LINE_ACTIONS_FK1" FOREIGN KEY ("RULE_LINE_ID")
	  REFERENCES "HBG_INTEGRATION"."HBG_CO_RULES_LINES" ("RULE_LINE_ID") ENABLE;

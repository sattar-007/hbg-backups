--------------------------------------------------------
--  DDL for Package HBG_LIFE_PLANNER_ITEM_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_LIFE_PLANNER_ITEM_PKG" AS
    PROCEDURE VALIDATE_ITEMS (
        P_OIC_RUN_ID NUMBER,
        X_STAUS_CODE OUT VARCHAR2,
        X_STAUS_MESSAGE OUT VARCHAR2); 
PROCEDURE update_status (
        p_oic_run_id     NUMBER,
        p_ess_request_id number,
        x_staus_code     OUT  VARCHAR2,
        x_staus_message  OUT  VARCHAR2
    );
END;

/

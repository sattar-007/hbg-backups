--------------------------------------------------------
--  DDL for Package XXHBG_PRE_RESERVATIONS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."XXHBG_PRE_RESERVATIONS_PKG" IS
    PROCEDURE hbg_pre_res_header_create (
        p_resevation_dtls       in XXHBG_PRE_RESERVATION_HDR_CRT_TBL,
        p_return_status          OUT VARCHAR2
    );
END xxhbg_pre_reservations_pkg;

/

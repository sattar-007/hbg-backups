--------------------------------------------------------
--  DDL for Package Body HBG_INVENTORY_TRANSACTIONS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_INVENTORY_TRANSACTIONS_PKG" IS
/*
--
-- $Header: HBG_INVENTORY_TRANSACTIONS_PKG.sql
--
-- Copyright (c) 2022, by Peloton Consulting Group, All Rights Reserved
--
-- Author          : Emanuel Reis - Peloton Consulting Group
-- Component Id    : HBG_INVENTORY_TRANSACTIONS_PKG
-- Script Location : 
-- Description     :
-- Package Usage   : Package responsible for transforming and loading data for the Inventory Transactions Integration.
--
-- Name                               Type        Purpose
-- --------------------------------   ----------  ----------------------------------------------------
-- MAIN                               Procedure   Procedure to start the data validation, transforming and loading.
--
-- History:
-- Name                 Date          Version    Description
-- ------------------   ------------  --------   ------------------------------------------------------------------------
-- Emanuel Reis         25-JAN-2022   1.0        Original Version
--
*/  
   /*Global Variables*/
   G_ZIP_FILE_NAME VARCHAR2(255)         := 'InvTransactionsInterface';
   G_SFTP_DIR      VARCHAR2(255)         := '/OIC_IB/SCM_Inv_Transaction';
   G_DIR           VARCHAR2(255)         := 'HBG_JSON_IMPORT'; -- Change to INV DIR
   G_USER          VARCHAR2(255)         := 'peloton_integrations';
   G_HOST          VARCHAR2(255)         := '130.35.103.243';
   G_PORT          NUMBER                := 5013;
   G_TRUST_SERVER  BOOLEAN               := TRUE;
   G_SEPARATOR     VARCHAR2(3)           := ',';
   G_DELIMITER     VARCHAR2(3)           := '';
   G_TRANSACTIONS_FILENAME VARCHAR2(255) := 'InvTransactionsInterface';
   G_LOTS_FILENAME VARCHAR2(255)         := 'InvTransactionLotsInterface';
   G_TRANSACTIONS_FILEEXT VARCHAR2(255)  := '.csv';
   G_LOTS_FILEEXT VARCHAR2(255)          := '.csv';

   FUNCTION FILE_TO_BLOB_F (P_FILENAME VARCHAR2) RETURN BLOB AS

        X_BLOB_FILE BLOB;
        L_FILE      BFILE := BFILENAME(G_DIR, P_FILENAME);
        L_BLOB      BLOB;
        SRC_OFFSET  NUMBER := 1;
        DST_OFFSET  NUMBER := 1;
        SRC_OSIN    NUMBER;
        DST_OSIN    NUMBER;
        BYTES_WT    NUMBER;

    BEGIN
        DBMS_LOB.CREATETEMPORARY(L_BLOB, FALSE, 2);
        DBMS_LOB.FILEOPEN(L_FILE, DBMS_LOB.FILE_READONLY);
        DBMS_LOB.OPEN(L_BLOB, DBMS_LOB.LOB_READWRITE);
        SRC_OSIN := SRC_OFFSET;
        DST_OSIN := DST_OFFSET;
        DBMS_LOB.LOADBLOBFROMFILE(L_BLOB, L_FILE, DBMS_LOB.LOBMAXSIZE, SRC_OFFSET, DST_OFFSET);
        DBMS_LOB.CLOSE(L_BLOB);
        DBMS_LOB.FILECLOSEALL();
        RETURN L_BLOB;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END FILE_TO_BLOB_F;

   PROCEDURE GENERATE_LINE_P (P_LINE_RECORDS IN INV_TRANS_LINES_TYPE
                             ,P_SEPARATOR IN VARCHAR2
                             ,P_DELIMITER IN VARCHAR2 DEFAULT NULL
                             ,P_TRANSACTIONS_LINE OUT VARCHAR2
                             ,P_LOTS_LINE OUT VARCHAR2) IS 

   L_TRANSACTIONS_LINE VARCHAR2(32767);
   L_LOTS_LINE VARCHAR2(32767);

   L_INV_TRANSACTIONS_TAB G_INV_TRANSACTIONS_TYPE;
   L_INV_LOTS_TAB G_INV_LOTS_TYPE;

   BEGIN

        L_TRANSACTIONS_LINE       := NULL;
        L_LOTS_LINE               := NULL;
        L_INV_TRANSACTIONS_TAB(0) := NULL;
        L_INV_LOTS_TAB(0)         := NULL;

        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_DATE       := P_LINE_RECORDS.TRANSACTION_DATE;
        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_TYPE_NAME  := CASE WHEN P_LINE_RECORDS.TRANSACTION_TYPE = 'RETURN'
                                                                    AND P_LINE_RECORDS.TRANSACTION_QUANTITY >= 0
                                                                 THEN 'WMS Return'

                                                                 WHEN P_LINE_RECORDS.TRANSACTION_TYPE = 'RETURN'
                                                                    AND P_LINE_RECORDS.TRANSACTION_QUANTITY < 0
                                                                 THEN 'WMS Returns Corrections'

                                                                 WHEN P_LINE_RECORDS.TRANSACTION_TYPE = 'SI-TRANSFER'
                                                                 THEN 'Subinventory Transfer'

                                                                 WHEN P_LINE_RECORDS.TRANSACTION_TYPE IN ('CYCLE-COUNT','ADJUSTMENT')
                                                                  AND P_LINE_RECORDS.TRANSACTION_QUANTITY < 0
                                                                 THEN 'WMS Dec Adjustment'

                                                                 WHEN P_LINE_RECORDS.TRANSACTION_TYPE IN ('CYCLE-COUNT','ADJUSTMENT')
                                                                  AND P_LINE_RECORDS.TRANSACTION_QUANTITY >= 0
                                                                 THEN 'WMS Inc Adjustment'

                                                                 ELSE P_LINE_RECORDS.TRANSACTION_TYPE
                                                                  END;

        L_INV_TRANSACTIONS_TAB(0).ITEM_NUMBER            := P_LINE_RECORDS.ISBN;
        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_QUANTITY   := P_LINE_RECORDS.TRANSACTION_QUANTITY;
        L_INV_TRANSACTIONS_TAB(0).PRIMARY_QUANTITY       := P_LINE_RECORDS.TRANSACTION_QUANTITY;
        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_UOM        := P_LINE_RECORDS.TRANSACTION_UOM;
        L_INV_TRANSACTIONS_TAB(0).SUBINVENTORY_CODE      := P_LINE_RECORDS.SUBINVENTORY;

        IF P_LINE_RECORDS.TRANSFER_SUBINVENTORY IS NOT NULL THEN
            L_INV_TRANSACTIONS_TAB(0).TRANSFER_SUBINVENTORY       := P_LINE_RECORDS.TRANSFER_SUBINVENTORY;
            L_INV_TRANSACTIONS_TAB(0).TRANSFER_ORGANIZATION_NAME  := 'Indianapolis Fulfillment';
        END IF;

        L_INV_TRANSACTIONS_TAB(0).SOURCE_HEADER_ID       := P_LINE_RECORDS.SOURCE_HEADER_ID;
        L_INV_TRANSACTIONS_TAB(0).SOURCE_LINE_ID         := P_LINE_RECORDS.SOURCE_LINE_ID;
        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_REFERENCE  := P_LINE_RECORDS.TRANSACTION_REFERENCE;
        L_INV_TRANSACTIONS_TAB(0).REASON_NAME            := P_LINE_RECORDS.TRANSACTION_TYPE || ' - ' || P_LINE_RECORDS.REASON_NAME;
        L_INV_TRANSACTIONS_TAB(0).ORGANIZATION_NAME      := 'Indianapolis Fulfillment';
        L_INV_TRANSACTIONS_TAB(0).SOURCE_CODE            := 'WMS';
        L_INV_TRANSACTIONS_TAB(0).PROCESS_FLAG           := '1';
        L_INV_TRANSACTIONS_TAB(0).TRANSACTION_MODE       := '3';
        L_INV_TRANSACTIONS_TAB(0).LOCK_FLAG              := '2';
        L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT1           := 'HBG WMS';

        IF P_LINE_RECORDS.LOT_NUMBER IS NOT NULL THEN

            L_INV_LOTS_TAB(0).INVENTORY_LOT_INTERFACE_NUMBER      := TO_CHAR(SQ_LOT_NUMBER.NEXTVAL);
            L_INV_LOTS_TAB(0).LOT_NUMBER                          := P_LINE_RECORDS.LOT_NUMBER;
            L_INV_LOTS_TAB(0).TRANSACTION_QUANTITY                := P_LINE_RECORDS.TRANSACTION_QUANTITY;
            L_INV_LOTS_TAB(0).PRIMARY_QUANTITY                    := P_LINE_RECORDS.TRANSACTION_QUANTITY;

            L_INV_TRANSACTIONS_TAB(0).INV_LOTSERIAL_INTERFACE_NUM := L_INV_LOTS_TAB(0).INVENTORY_LOT_INTERFACE_NUMBER;

            L_LOTS_LINE :=  P_DELIMITER || L_INV_LOTS_TAB(0).INVENTORY_LOT_INTERFACE_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).INVENTORY_SERIAL_INTERFACE_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).SOURCE_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).SOURCE_LINE_ID || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).DESCRIPTION || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_EXPIRATION_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).TRANSACTION_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PRIMARY_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ORIGINATION_TYPE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ORIGINATION_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).STATUS_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).RETEST_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).EXPIRATION_ACTION_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).EXPIRATION_ACTION_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).EXPIRATION_ACTION_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).HOLD_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).MATURITY_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).DATE_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).GRADE_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).CHANGE_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).AGE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).REASON_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).REASON_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PROCESS_FLAG || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).SUPPLIER_LOT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).TERRITORY_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).TERRITORY_SHORT_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ITEM_SIZE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).COLOR || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_VOLUME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).VOLUME_UOM_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).VOLUME_UOM || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PLACE_OF_ORIGIN || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).BEST_BY_DATE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_LENGTH || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LENGTH_UOM || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LENGTH_UOM_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).RECYCLED_CONTENT || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_THICKNESS || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).THICKNESS_UOM || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_WIDTH || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).WIDTH_UOM || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).WIDTH_UOM_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).CURL_WRINKLE_FOLD || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).VENDOR_NAME || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PRODUCT_CODE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PRODUCT_TRANSACTION_ID || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).SECONDARY_TRANSACTION_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).SUBLOT_NUM || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PARENT_LOT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PARENT_OBJECT_TYPE || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PARENT_OBJECT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PARENT_OBJECT_TYPE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).PARENT_OBJECT_NUMBER2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).LOT_ATTRIBUTE_CATEGORY || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE6 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE7 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE8 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE9 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE10 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE11 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE12 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE13 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE14 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE15 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE16 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE17 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE18 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE19 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).C_ATTRIBUTE20 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE6 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE7 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE8 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE9 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).D_ATTRIBUTE10 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE6 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE7 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE8 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE9 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).N_ATTRIBUTE10 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).T_ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).T_ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).T_ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).T_ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).T_ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_CATEGORY || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE6 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE7 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE8 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE9 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE10 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE11 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE12 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE13 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE14 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE15 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE16 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE17 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE18 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE19 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE20 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER6 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER7 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER8 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER9 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_NUMBER10 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_DATE1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_DATE2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_DATE3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_DATE4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_DATE5 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_TIMESTAMP1 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_TIMESTAMP2 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_TIMESTAMP3 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_TIMESTAMP4 || P_DELIMITER || P_SEPARATOR || 
                            P_DELIMITER || L_INV_LOTS_TAB(0).ATTRIBUTE_TIMESTAMP5 || P_DELIMITER || P_SEPARATOR || 'END';
            P_LOTS_LINE  := L_LOTS_LINE;                        
        ELSE 
            P_LOTS_LINE  := NULL;
        END IF;

        L_TRANSACTIONS_LINE :=  P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ORGANIZATION_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_GROUP_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_GROUP_SEQ || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_BATCH_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_BATCH_SEQ || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PROCESS_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).INVENTORY_ITEM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ITEM_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REVISION || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).INV_LOTSERIAL_INTERFACE_NUM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SUBINVENTORY_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOCATOR_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT11 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT12 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT13 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT14 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT15 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT16 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT17 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT18 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT19 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOC_SEGMENT20 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_UOM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_UNIT_OF_MEASURE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).RESERVATION_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || TO_CHAR(L_INV_TRANSACTIONS_TAB(0).TRANSACTION_DATE, 'YYYY/MM/DD HH24:MI:SS') || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_SOURCE_TYPE_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_TYPE_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_ORGANIZATION_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_ORGANIZATION_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_SUBINVENTORY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT11 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT12 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT13 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT14 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT15 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT16 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT17 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT18 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT19 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFER_LOC_SEGMENT20 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PRIMARY_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SECONDARY_TRANSACTION_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SECONDARY_UOM_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SECONDARY_UNIT_OF_MEASURE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SOURCE_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SOURCE_HEADER_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SOURCE_LINE_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_SOURCE_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT11 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT12 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT13 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT14 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT15 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT16 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT17 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT18 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT19 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT20 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT21 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT22 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT23 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT24 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT25 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT26 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT27 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT28 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT29 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DSP_SEGMENT30 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_ACTION_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_MODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOCK_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_REFERENCE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REASON_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CURRENCY_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CURRENCY_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CURRENCY_CONVERSION_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CURRENCY_CONVERSION_RATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CURRENCY_CONVERSION_DATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_COST || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_COST || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).NEW_AVERAGE_COST || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).VALUE_CHANGE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PERCENTAGE_CHANGE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT11 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT12 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT13 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT14 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT15 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT16 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT17 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT18 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT19 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT20 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT21 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT22 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT23 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT24 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT25 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT26 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT27 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT28 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT29 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DST_SEGMENT30 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOCATION_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EMPLOYEE_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).RECEIVING_DOCUMENT || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LINE_ITEM_NUM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SHIPMENT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSPORTATION_COST || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CONTAINERS || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).WAYBILL_AIRBILL || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EXPECTED_ARRIVAL_DATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REQUIRED_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SHIPPABLE_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SHIPPED_QUANTITY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).VALIDATION_REQUIRED || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).NEGATIVE_REQ_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).OWNING_TP_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_OWNING_TP_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).OWNING_ORGANIZATION_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFR_OWNING_ORGANIZATION_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_PERCENTAGE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PLANNING_TP_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_PLANNING_TP_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ROUTING_REVISION || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ROUTING_REVISION_DATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ALTERNATE_BOM_DESIGNATOR || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ALTERNATE_ROUTING_DESIGNATOR || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ORGANIZATION_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).USSGL_TRANSACTION_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).WIP_ENTITY_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SCHEDULE_UPDATE_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SETUP_TEARDOWN_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PRIMARY_SWITCH || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).MRP_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).OPERATION_SEQ_NUM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).WIP_SUPPLY_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).RELIEVE_RESERVATIONS_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).RELIEVE_HIGH_LEVEL_RSV_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_PRICE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).BUILD_BREAK_TO_UOM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).BUILD_BREAK_TO_UNIT_OF_MEASURE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_CATEGORY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE11 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE12 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE13 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE14 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE15 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE16 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE17 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE18 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE19 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE20 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER6 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER7 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER8 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER9 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_NUMBER10 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_DATE1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_DATE2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_DATE3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_DATE4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_DATE5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_TIMESTAMP1 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_TIMESTAMP2 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_TIMESTAMP3 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_TIMESTAMP4 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ATTRIBUTE_TIMESTAMP5 || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSACTION_COST_IDENTIFIER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DEFAULT_TAXATION_COUNTRY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).DOCUMENT_SUB_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRX_BUSINESS_CATEGORY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).USER_DEFINED_FISC_CLASS || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TAX_INVOICE_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TAX_INVOICE_DATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PRODUCT_CATEGORY || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PRODUCT_TYPE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).ASSESSABLE_VALUE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TAX_CLASSIFICATION_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EXEMPT_CERTIFICATE_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EXEMPT_REASON_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).INTENDED_USE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).FIRST_PTY_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).THIRD_PTY_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).FINAL_DISCHARGE_LOC_CODE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CATEGORY_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).OWNING_ORGANIZATION_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).XFR_OWNING_ORGANIZATION_ID || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PRC_BU_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).VENDOR_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).VENDOR_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).CONSIGNMENT_AGREEMENT_NUM || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).USE_CURRENT_COST || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EXTERNAL_SYSTEM_PACKING_UNIT || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_LOCATOR_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).INV_PROJECT || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).INV_TASK || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).COUNTRY_OF_ORIGIN_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_INV_PROJECT || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).TRANSFER_INV_TASK || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_PROJECT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_TASK_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_EXPENDITURE_TYPE_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_EXPENDITURE_ITEM_DATE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_EXPENDITURE_ORG_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_CONTRACT_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).PJC_FUNDING_SOURCE_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REQUESTER_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REQUESTER_NUMBER || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).EXTERNAL_SYS_TXN_REFERENCE || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).SOURCE_LOT_FLAG || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).LOT_TXN_GROUP_NAME || P_DELIMITER || P_SEPARATOR || 
                                P_DELIMITER || L_INV_TRANSACTIONS_TAB(0).REPRESENTATIVE_LOT_NUMBER || P_DELIMITER || P_SEPARATOR || 'END';

   P_TRANSACTIONS_LINE := L_TRANSACTIONS_LINE; 

   EXCEPTION
    WHEN OTHERS THEN
        P_TRANSACTIONS_LINE := NULL;
        P_LOTS_LINE         := NULL;
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
   END GENERATE_LINE_P;

   PROCEDURE LOAD_ARCHIVE_TABLES_P (P_LINE_RECORDS IN INV_TRANS_LINES_TYPE) IS

        LV_STATUS VARCHAR2(30);
        LV_MESSAGE VARCHAR2(2000);
        R_ARCHIVE HBG_INV_TRANSACTIONS_ARCHIVE%ROWTYPE;

   BEGIN

        LV_STATUS  := 'S';
        LV_MESSAGE := NULL;

        R_ARCHIVE := NULL;

        R_ARCHIVE.OIC_INSTANCE_ID       := P_LINE_RECORDS.OIC_INSTANCE_ID;
        R_ARCHIVE.WMS_PROCESS_ID        := P_LINE_RECORDS.WMS_PROCESS_ID;
        R_ARCHIVE.START_DATE            := P_LINE_RECORDS.START_DATE;
        R_ARCHIVE.END_DATE              := P_LINE_RECORDS.END_DATE;
        R_ARCHIVE.SOURCE_HEADER_ID      := P_LINE_RECORDS.SOURCE_HEADER_ID;
        R_ARCHIVE.TRANSACTION_TYPE      := P_LINE_RECORDS.TRANSACTION_TYPE;
        R_ARCHIVE.SOURCE_LINE_ID        := P_LINE_RECORDS.SOURCE_LINE_ID;
        R_ARCHIVE.ISBN                  := P_LINE_RECORDS.ISBN;
        R_ARCHIVE.TRANSACTION_QUANTITY  := P_LINE_RECORDS.TRANSACTION_QUANTITY;
        R_ARCHIVE.TRANSACTION_UOM       := P_LINE_RECORDS.TRANSACTION_UOM;
        R_ARCHIVE.TRANSACTION_REFERENCE := P_LINE_RECORDS.TRANSACTION_REFERENCE;
        R_ARCHIVE.SUBINVENTORY          := P_LINE_RECORDS.SUBINVENTORY;
        R_ARCHIVE.TRANSFER_SUBINVENTORY := P_LINE_RECORDS.TRANSFER_SUBINVENTORY;
        R_ARCHIVE.REASON_NAME           := P_LINE_RECORDS.REASON_NAME;
        R_ARCHIVE.LOT_NUMBER            := P_LINE_RECORDS.LOT_NUMBER;
        R_ARCHIVE.STATUS                := 'PROCESSING';
        R_ARCHIVE.RETURN_MESSAGE        := NULL;
        R_ARCHIVE.CREATION_DATE         := SYSDATE;
        R_ARCHIVE.LAST_UPDATE_DATE      := SYSDATE;
        R_ARCHIVE.CREATED_BY            := -1;
        R_ARCHIVE.LAST_UPDATED_BY       := -1;

        INSERT /*+  APPEND PARALLEL  */  
          INTO HBG_INV_TRANSACTIONS_ARCHIVE
        VALUES R_ARCHIVE;

   EXCEPTION
   WHEN OTHERS THEN
        LV_STATUS  := 'E';
        LV_MESSAGE := SQLERRM;
   END LOAD_ARCHIVE_TABLES_P;

   PROCEDURE MAIN (P_OIC_INSTANCE_ID VARCHAR2) IS

    EXP_CREATE_FILE EXCEPTION;
    EXP_LOAD_LINE EXCEPTION;
    EXP_LOAD_FILE EXCEPTION;
    EXP_ARCHIVE_DATA EXCEPTION;

    L_INV_TRANS_LINES_TAB G_INV_TRANS_LINES_TYPE;

    L_TRANSACTIONS_FILE UTL_FILE.FILE_TYPE;
    L_LOTS_FILE UTL_FILE.FILE_TYPE;

    TRANSACTIONS_LINE VARCHAR2(32767);
    LOTS_LINE VARCHAR2(32767);

    L_INV_TRANSACTION_BLOB BLOB;
    L_INV_LOTS_BLOB BLOB;
    L_ZIP_FILES BLOB;

    CURSOR C_INV_TRANSACTIONS_INFO IS   
        SELECT HBG_INV_TRANSACTIONS_HEADER.WMS_PROCESS_ID
              ,HBG_INV_TRANSACTIONS_HEADER.START_DATE
              ,HBG_INV_TRANSACTIONS_HEADER.END_DATE
              ,HBG_INV_TRANSACTIONS_HEADER.SOURCE_HEADER_ID
              ,HBG_INV_TRANSACTIONS_HEADER.TRANSACTION_TYPE
              ,HBG_INV_TRANSACTIONS_LINES.SOURCE_LINE_ID
              ,HBG_INV_TRANSACTIONS_LINES.ISBN
              ,HBG_INV_TRANSACTIONS_LINES.TRANSACTION_QUANTITY
              ,HBG_INV_TRANSACTIONS_LINES.TRANSACTION_UOM
              ,HBG_INV_TRANSACTIONS_LINES.TRANSACTION_DATE
              ,HBG_INV_TRANSACTIONS_LINES.TRANSACTION_REFERENCE
              ,HBG_INV_TRANSACTIONS_LINES.SUBINVENTORY
              ,HBG_INV_TRANSACTIONS_LINES.TRANSFER_SUBINVENTORY
              ,HBG_INV_TRANSACTIONS_LINES.REASON_NAME
              ,HBG_INV_TRANSACTIONS_LINES.LOT_NUMBER 
              ,P_OIC_INSTANCE_ID OIC_INSTANCE_ID
          FROM HBG_INV_TRANSACTIONS_HEADER
             , HBG_INV_TRANSACTIONS_LINES
         WHERE HBG_INV_TRANSACTIONS_HEADER.SOURCE_HEADER_ID = HBG_INV_TRANSACTIONS_LINES.SOURCE_HEADER_ID;

   BEGIN

       BEGIN

        OPEN C_INV_TRANSACTIONS_INFO;
       FETCH C_INV_TRANSACTIONS_INFO BULK COLLECT INTO L_INV_TRANS_LINES_TAB;
       CLOSE C_INV_TRANSACTIONS_INFO;

       IF L_INV_TRANS_LINES_TAB.COUNT > 0 THEN

        BEGIN
            L_TRANSACTIONS_FILE := UTL_FILE.FOPEN (G_DIR, G_TRANSACTIONS_FILENAME || G_TRANSACTIONS_FILEEXT, 'W', 32767);
            L_LOTS_FILE := UTL_FILE.FOPEN (G_DIR, G_LOTS_FILENAME || G_LOTS_FILEEXT, 'W', 32767);
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                RAISE_APPLICATION_ERROR(-20001, SQLERRM);
        END;

        FOR L_INV_LINE IN L_INV_TRANS_LINES_TAB.FIRST .. L_INV_TRANS_LINES_TAB.LAST LOOP

            BEGIN

                TRANSACTIONS_LINE := NULL;
                LOTS_LINE         := NULL;

                GENERATE_LINE_P(P_LINE_RECORDS      => L_INV_TRANS_LINES_TAB(L_INV_LINE)
                               ,P_SEPARATOR         => G_SEPARATOR
                               ,P_DELIMITER         => G_DELIMITER
                               ,P_TRANSACTIONS_LINE => TRANSACTIONS_LINE
                               ,P_LOTS_LINE         => LOTS_LINE);

                UTL_FILE.PUT_LINE(L_TRANSACTIONS_FILE, TRANSACTIONS_LINE);

                IF LOTS_LINE IS NOT NULL THEN 
                    UTL_FILE.PUT_LINE (L_LOTS_FILE, LOTS_LINE);
                END IF;

            EXCEPTION 
                WHEN OTHERS THEN
                    RAISE EXP_LOAD_LINE;
            END;

            BEGIN
                BEGIN
                 LOAD_ARCHIVE_TABLES_P (P_LINE_RECORDS    => L_INV_TRANS_LINES_TAB(L_INV_LINE)); 
            EXCEPTION 
              WHEN OTHERS THEN
                   RAISE EXP_ARCHIVE_DATA;
            END;

        EXCEPTION 
        WHEN EXP_ARCHIVE_DATA THEN
             CONTINUE;
        WHEN EXP_LOAD_LINE THEN
             CONTINUE;
        END;

        END LOOP;

        COMMIT;

        UTL_FILE.FCLOSE (L_TRANSACTIONS_FILE);
        UTL_FILE.FCLOSE (L_LOTS_FILE);

        BEGIN
            L_INV_TRANSACTION_BLOB := FILE_TO_BLOB_F(G_TRANSACTIONS_FILENAME || G_TRANSACTIONS_FILEEXT);
            L_INV_LOTS_BLOB := FILE_TO_BLOB_F(G_LOTS_FILENAME || G_LOTS_FILEEXT);
        EXCEPTION
             WHEN OTHERS THEN
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR(-20001, 'ERROR TRYING TO CONVERT FILE TO BLOB: '||SQLERRM);
        END; 

        BEGIN
            APEX_ZIP.ADD_FILE(P_ZIPPED_BLOB => L_ZIP_FILES, P_FILE_NAME => (G_TRANSACTIONS_FILENAME || G_TRANSACTIONS_FILEEXT), P_CONTENT => L_INV_TRANSACTION_BLOB);
            APEX_ZIP.ADD_FILE(P_ZIPPED_BLOB => L_ZIP_FILES, P_FILE_NAME => (G_LOTS_FILENAME || G_LOTS_FILEEXT), P_CONTENT => L_INV_LOTS_BLOB);
            APEX_ZIP.FINISH(P_ZIPPED_BLOB => L_ZIP_FILES);
        EXCEPTION
             WHEN OTHERS THEN
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR(-20001, 'ERROR TRYING TO ZIP BLOB FILE: '||SQLERRM);
        END;

        BEGIN

            AS_SFTP_KEYMGMT.LOGIN( I_USER => G_USER,
                                   I_HOST => G_HOST,
                                   I_PORT => G_PORT,
                                   I_TRUST_SERVER => G_TRUST_SERVER);

            AS_SFTP.PUT_FILE(G_SFTP_DIR || '/' || G_ZIP_FILE_NAME ||'.zip' , L_ZIP_FILES);
        EXCEPTION
             WHEN OTHERS THEN
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR(-20001, 'ERROR TRYING TO MOVE ZIP FILE TO SFTP LOCATION: '||SQLERRM);
        END;

       END IF;


       EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
       END;

   COMMIT;

   EXCEPTION 
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
   END MAIN;

END HBG_INVENTORY_TRANSACTIONS_PKG;

/

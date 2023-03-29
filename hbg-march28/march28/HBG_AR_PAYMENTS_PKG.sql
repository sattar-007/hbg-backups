--------------------------------------------------------
--  DDL for Package HBG_AR_PAYMENTS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_AR_PAYMENTS_PKG" IS
/*
--
-- $Header: HBG_AR_PAYMENTS_PKG.sql
--
-- Copyright (c) 2022, by Peloton Consulting Group, All Rights Reserved
--
-- Author          : Emanuel Reis - Peloton Consulting Group
-- Component Id    : HBG_AR_PAYMENTS_PKG
-- Script Location : 
-- Description     :
-- Package Usage   : Package responsible for transforming and loading data for the AR Payments Integration.
--
-- Name                               Type        Purpose
-- --------------------------------   ----------  ----------------------------------------------------
-- MAIN                               Procedure   Procedure to start the data validation, transforming and loading.
-- GET_LIST_OF_ACCOUNTS_F             Function    Function to generate the list of accounts
-- UPDATE_PAYMENT_LINE_STATUS_P       Procedure   Procedure to update return status and message in payment lines
--
-- History:
-- Name                 Date          Version    Description
-- ------------------   ------------  --------   ------------------------------------------------------------------------
-- Emanuel Reis         25-JAN-2022   1.0        Original Version
--
*/ 

        TYPE LIST_OF_ACCOUNT_REC IS RECORD 
        (LIST_OF_ACCOUNTS VARCHAR2(32767)
        ,BATCH_ID HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
        ,OIC_INSTANCE_ID VARCHAR2(1000));

        TYPE LIST_OF_ACCOUNT_TYPE IS TABLE OF LIST_OF_ACCOUNT_REC;

   PROCEDURE MAIN(P_OIC_INSTANCE_ID VARCHAR2
                , P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE);

   FUNCTION GET_LIST_OF_ACCOUNTS_F(P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE) 
                                  RETURN LIST_OF_ACCOUNT_TYPE PIPELINED;

   PROCEDURE UPDATE_PAYMENT_LINE_STATUS_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                                         , P_ACCOUNT_NUMBER IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE
                                         , P_RETURN_STATUS  IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE
                                         , P_RETURN_MESSAGE IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE);

   PROCEDURE VALIDATE_CUSTOMER_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                                 ,P_USER IN VARCHAR2);

   PROCEDURE HBG_PAYMENT_EXTENSION_CREATE ( P_BATCH_ID         IN HBG_AR_PAYMENTS_LINES.BATCH_ID%TYPE
                                          ,P_BUSINESS_UNIT    IN HBG_AR_PAYMENTS_LINES.BUSINESS_UNIT%TYPE
                                          ,P_PAYMENT_TYPE     IN HBG_AR_PAYMENTS_LINES.PAYMENT_TYPE%TYPE
                                          ,P_PAYMENT_DATE     IN HBG_AR_PAYMENTS_LINES.PAYMENT_DATE%TYPE
                                          ,P_ACCOUNT_NUMBER   IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE
                                          ,P_ACCOUNT_NAME     IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NAME%TYPE
                                          ,P_RECEIPT_NUMBER   IN HBG_AR_PAYMENTS_LINES.RECEIPT_NUMBER%TYPE
                                          ,P_AMOUNT           IN HBG_AR_PAYMENTS_LINES.AMOUNT%TYPE
                                          ,P_PAYMENT_METHOD   IN HBG_AR_PAYMENTS_LINES.PAYMENT_METHOD%TYPE
                                          ,P_CURRENCY         IN HBG_AR_PAYMENTS_LINES.CURRENCY%TYPE
                                          ,P_GL_ACCOUNT       IN HBG_AR_PAYMENTS_LINES.GL_ACCOUNT%TYPE
                                          ,P_CREATED_BY       IN HBG_AR_PAYMENTS_LINES.CREATED_BY%TYPE
                                          ,P_LAST_UPDATED_BY  IN HBG_AR_PAYMENTS_LINES.LAST_UPDATED_BY%TYPE
                                          ,P_CREATE_STATUS    OUT VARCHAR2
                                          ,P_LINE_ID_OUT OUT NUMBER);

    PROCEDURE MERGE_HEADER_P (P_BATCH_ID IN HBG_AR_PAYMENTS_HEADER.BATCH_ID%TYPE
                             ,P_STATUS IN HBG_AR_PAYMENTS_HEADER.STATUS%TYPE
                             ,P_CREATED_BY IN HBG_AR_PAYMENTS_HEADER.CREATED_BY%TYPE
                             ,P_CREATION_DATE IN HBG_AR_PAYMENTS_HEADER.CREATION_DATE%TYPE
                             ,P_LAST_UPDATED_BY IN HBG_AR_PAYMENTS_HEADER.LAST_UPDATED_BY%TYPE
                             ,P_LAST_UPDATE_DATE IN HBG_AR_PAYMENTS_HEADER.LAST_UPDATE_DATE%TYPE
                             ,P_CREATE_STATUS OUT VARCHAR2); 

    PROCEDURE MERGE_LINE_P (P_LINE_ID IN HBG_AR_PAYMENTS_LINES.LINE_ID%TYPE,
                            P_BATCH_ID IN HBG_AR_PAYMENTS_LINES.LINE_ID%TYPE,
                            P_BUSINESS_UNIT IN HBG_AR_PAYMENTS_LINES.BUSINESS_UNIT%TYPE,
                            P_PROCESS_TYPE  IN HBG_AR_PAYMENTS_LINES.PROCESS_TYPE%TYPE,
                            P_PAYMENT_TYPE  IN HBG_AR_PAYMENTS_LINES.PAYMENT_TYPE%TYPE,
                            P_PAYMENT_DATE  IN HBG_AR_PAYMENTS_LINES.PAYMENT_DATE%TYPE,
                            P_ACCOUNT_NUMBER  IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NUMBER%TYPE,
                            P_ACCOUNT_NAME  IN HBG_AR_PAYMENTS_LINES.ACCOUNT_NAME%TYPE,
                            P_RECEIPT_NUMBER IN HBG_AR_PAYMENTS_LINES.RECEIPT_NUMBER%TYPE,
                            P_INVOICE_NUMBER  IN HBG_AR_PAYMENTS_LINES.INVOICE_NUMBER%TYPE,
                            P_CLAIM_NUMBER IN HBG_AR_PAYMENTS_LINES.CLAIM_NUMBER%TYPE,
                            P_TRANSACTION_CODE IN HBG_AR_PAYMENTS_LINES.TRANSACTION_CODE%TYPE,
                            P_AMOUNT  IN HBG_AR_PAYMENTS_LINES.AMOUNT%TYPE,
                            P_PAYMENT_METHOD IN HBG_AR_PAYMENTS_LINES.PAYMENT_METHOD%TYPE,
                            P_CURRENCY  IN HBG_AR_PAYMENTS_LINES.CURRENCY%TYPE,
                            P_GL_ACCOUNT  IN HBG_AR_PAYMENTS_LINES.GL_ACCOUNT%TYPE,
                            P_RECEIPT_ID  IN HBG_AR_PAYMENTS_LINES.RECEIPT_ID%TYPE,
                            P_PAYMENT_ID  IN HBG_AR_PAYMENTS_LINES.PAYMENT_ID%TYPE,
                            P_CLAIM_ID  IN HBG_AR_PAYMENTS_LINES.CLAIM_ID%TYPE,
                            P_CREATION_DATE  IN HBG_AR_PAYMENTS_LINES.CREATION_DATE%TYPE,
                            P_CREATED_BY  IN HBG_AR_PAYMENTS_LINES.CREATED_BY%TYPE,
                            P_LAST_UPDATE_DATE   IN HBG_AR_PAYMENTS_LINES.LAST_UPDATE_DATE%TYPE,
                            P_LAST_UPDATED_BY  IN HBG_AR_PAYMENTS_LINES.LAST_UPDATED_BY%TYPE,
                            P_RETURN_STATUS  IN HBG_AR_PAYMENTS_LINES.RETURN_STATUS%TYPE,
                            P_RETURN_MESSAGE  IN HBG_AR_PAYMENTS_LINES.RETURN_MESSAGE%TYPE,
                            P_CREATE_STATUS    OUT VARCHAR2,
                            P_LINE_ID_OUT OUT NUMBER);

    PROCEDURE CREATE_SCHEDULE_P (P_BATCH_ID IN HBG_AR_PAYMENTS_SCHEDULE.BATCH_ID%TYPE
                                ,P_OIC_INTEGRATION_ID IN HBG_AR_PAYMENTS_SCHEDULE.OIC_INTEGRATION_ID%TYPE
                                ,P_NUMBER_OF_PARALLEL IN NUMBER
                                ,P_PROCESS_TYPE IN HBG_AR_PAYMENTS_SCHEDULE.PROCESS_TYPE%TYPE
                                ,P_PAYMENT_TYPE IN HBG_AR_PAYMENTS_SCHEDULE.PAYMENT_TYPE%TYPE
                                ,P_STATUS OUT VARCHAR2
                                ,P_MESSAGE OUT VARCHAR2);

    PROCEDURE VALIDATE_PAYMENTS_P (P_BATCH_ID IN HBG_AR_PAYMENTS_SCHEDULE.BATCH_ID%TYPE
                                  ,P_STATUS OUT VARCHAR2
                                  ,P_MESSAGE OUT VARCHAR2);

END HBG_AR_PAYMENTS_PKG;

/

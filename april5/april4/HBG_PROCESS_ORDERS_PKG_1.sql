--------------------------------------------------------
--  DDL for Package Body HBG_PROCESS_ORDERS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_PKG" IS
  /*************************************************************************
  *
  * Description:   HBG Process Orders Integration
  *
  * Modifications:
  *
  * DATE         AUTHOR           	DESCRIPTION
  * ----------   -----------      	------------------------------------------
  * 11/25/2022   Mariana Teixeira   INITIAL VERSION
  * 12/26/2022   Mariana Teixeira   Debug
  * 01/06/2023   Mariana Teixeira   Table Names/ EFFs tables and files
  * 03/29/2023   Mariana Teixeira   CX Procedures
  *
  ************************************************************************/

----------------------------------------------------------------------------------------------------------------------------------------
/*								GENERATE FBDI																				*/
----------------------------------------------------------------------------------------------------------------------------------------

	 PROCEDURE generate_fbdi (
        p_SBI_UUID 	  IN VARCHAR2,
        p_operation   IN VARCHAR2,
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER,
        ftp_filename  OUT VARCHAR2 

    )  AS

        x_zip_header             	BLOB;
        l_header_file         	 	utl_file.file_type;
        l_header_file_name			VARCHAR2(100) := 'DooOrderHeadersAllInt.csv';
        l_header_blob           	BLOB;
        l_lines_file      			utl_file.file_type;
        l_lines_file_name 			VARCHAR2(100) := 'DooOrderLinesAllInt.csv';
        l_lines_blob        		BLOB;
        l_address_file          	utl_file.file_type;
        l_address_file_name     	VARCHAR2(100) := 'DooOrderAddressesInt.csv';
        l_address_blob              BLOB;
        l_header_eff_file         	utl_file.file_type;
        l_header_eff_file_name		VARCHAR2(100) := 'DooOrderHdrsAllEffBInt.csv';
        l_header_eff_blob           BLOB;
        l_lines_eff_file         	utl_file.file_type;
        l_lines_eff_file_name		VARCHAR2(100) := 'DooOrderLinesAllEffBInt.csv';
        l_lines_eff_blob           BLOB;
        I_USER VARCHAR2(200);
        I_HOST VARCHAR2(200);
        I_PORT NUMBER;
        I_TRUST_SERVER BOOLEAN;
        l_report_flag VARCHAR2(5);
        l_put_file NUMBER := 0;
        l_retry    number := 0;
        l_ftp_folder    VARCHAR2(30);
    BEGIN

        IF p_operation = 'CREATE' THEN
          ftp_filename := 'HBG_Sterling_Orders_' ||p_SBI_UUID||'.zip';
        ELSIF   p_operation = 'SUBMIT' THEN
          ftp_filename := 'HBG_Sterling_Submit_Orders_' ||p_SBI_UUID||'.zip'; 
        END IF;
	 /*-----------------------------------------------------------------------------------------------------
			FTP CONNECTION AND CREDENTIALS
	------------------------------------------------------------------------------------------------------*/	
        SELECT  LOOKUP_VALUE,
                LOOKUP_VALUE1,
                TO_NUMBER(LOOKUP_VALUE2)
        INTO    I_USER,
                I_HOST,
                I_PORT
        FROM HBG_PROCESS_ORDERS_LOOKUP
        WHERE LOOKUP_CODE = 'FTP_CONNECTION';

        I_TRUST_SERVER := TRUE;

    /*-----------------------------------------------------------------------------------------------------
			FTP FOLDER
	------------------------------------------------------------------------------------------------------*/	
        SELECT LOOKUP_VALUE
        INTO   l_ftp_folder
        FROM HBG_PROCESS_ORDERS_LOOKUP
        WHERE LOOKUP_CODE = 'FTP_FOLDER';
	/*-----------------------------------------------------------------------------------------------------
			OUTPUT VALUES INITIAL ASSIGNMENT
	------------------------------------------------------------------------------------------------------*/		

		errbuf := null;
		retcode := 0;

	/*-----------------------------------------------------------------------------------------------------
			GENERATE FBDI HEADER CSV FILE
	------------------------------------------------------------------------------------------------------*/

		/*----------------------------------------------------------------------
				FOR EACH RECORD IN HBG_PROCESS_ORDERS_HEADERS_FBDI TABLE
		------------------------------------------------------------------------*/
        l_header_file := utl_file.fopen(g_directory, l_header_file_name, 'W', 32767);
        FOR l_rec IN (
            SELECT
                *
            FROM
                HBG_PROCESS_ORDERS_HEADERS_FBDI
            WHERE
                SBI_UUID = p_SBI_UUID
			and status = 'VALIDATED'
        ) LOOP

			/*----------------------------------------------------------------------
					WRITE HEADER ROW IN CSV FILE
			------------------------------------------------------------------------*/
            utl_file.put_line(l_header_file,'"'|| l_rec.SOURCE_TRANSACTION_ID           || '","' || 
												  l_rec.SOURCE_TRANSACTION_SYSTEM       || '","' ||
												  l_rec.SOURCE_TRANSACTION_NUMBER       || '","' ||
												  l_rec.SOURCE_TRANSACTION_REVISION_NO  || '","' ||
												  l_rec.BUYING_PARTY_ID                 || '","' ||
												  l_rec.BUYING_PARTY_NAME               || '","' ||
												  l_rec.BUYING_PARTY_FIRST_NAME	  	  	|| '","' ||
												  l_rec.BUYING_PARTY_LAST_NAME          || '","' ||
												  l_rec.BUYING_PARTY_MIDDLE_NAME	  	|| '","' ||
												  l_rec.BUYING_PARTY_NAME_SUFFIX	  	|| '","' ||
												  l_rec.BUYING_PARTY_TITLE		  	  	|| '","' ||
												  l_rec.BUYING_PARTY_NUMBER             || '","' ||
												  l_rec.BUYING_PARTY_ORIG_SYS_REF       || '","' ||
												  l_rec.BUYING_PARTY_CONTACT_ID         || '","' ||
												  l_rec.BUYING_PARTY_CONTACT_NAME       || '","' ||
												  l_rec.BUYING_CONTACT_FIRST_NAME	    || '","' ||
												  l_rec.BUYING_CONTACT_LAST_NAME	    || '","' ||
												  l_rec.BUYING_CONTACT_MIDDLE_NAME	  	|| '","' ||
												  l_rec.BUYING_CONTACT_NAME_SUFFIX	  	|| '","' ||
												  l_rec.BUYING_CONTACT_TITLE		    || '","' ||
												  l_rec.BUYING_PARTY_TYPE		        || '","' ||
												  l_rec.BUYING_PARTY_CONTACT_NUMBER     || '","' ||
												  l_rec.BUYING_PARTY_CONT_ORIG_SYS_REF  || '","' ||
												  l_rec.PREF_SOLD_TO_CONTACT_POINT_ID	|| '","' ||
												  l_rec.PREF_SOLD_CONT_PT_ORIG_SYS_REF  || '","' ||
												  l_rec.CUSTOMER_PO_NUMBER              || '","' ||
												  l_rec.TRANSACTIONAL_CURRENCY_CODE     || '","' ||
												  l_rec.TRANSACTIONAL_CURRENCY_NAME     || '","' ||
												  l_rec.CURRENCY_CONVERSION_TYPE        || '","' ||
												  l_rec.CURRENCY_CONVERSION_RATE        || '","' ||
												  l_rec.CURRENCY_CONVERSION_DATE        || '","' ||
												  l_rec.TRANSACTION_ON                  || '","' ||
												  l_rec.REQUESTING_BUSINESS_UNIT_ID     || '","' ||
												  l_rec.REQUESTING_BUSINESS_UNIT        || '","' ||
												  l_rec.TRANSACTION_TYPE_CODE           || '","' ||
												  l_rec.TRANSACTION_DOCUMENT_TYPE_CODE  || '","' ||
												  l_rec.REQUEST_CANCEL_DATE             || '","' ||
												  l_rec.COMMENTS                        || '","' ||
												  l_rec.BATCH_NAME                      || '","' ||
												  l_rec.REQUESTING_LEGAL_UNIT_ID        || '","' ||
												  l_rec.REQUESTING_LEGAL_UNIT           || '","' ||
												  l_rec.ORIG_SYS_DOCUMENT_REFERENCE     || '","' ||
												  l_rec.PARTIAL_SHIP_ALLOWED_FLAG       || '","' ||
												  l_rec.CANCEL_REASON_CODE              || '","' ||
												  l_rec.CANCEL_REASON                   || '","' ||
												  l_rec.PRICED_ON                       || '","' ||
												  l_rec.FREEZE_PRICING                  || '","' ||
												  l_rec.FREEZE_SHIPPING_CHARGE          || '","' ||
												  l_rec.FREEZE_TAX                      || '","' ||
												  l_rec.OPERATION_MODE                  || '","' ||
												  l_rec.CREATE_CUSTOMER_INFO_FLAG       || '","' ||
												  l_rec.REVISION_SOURCE_TXN_SYSTEM      || '","' ||
												  l_rec.BUYING_PARTY_PERSON_EMAIL       || '","' ||
												  l_rec.BUYING_PARTY_ORG_EMAIL          || '","' ||
												  l_rec.BUYING_PARTY_CONTACT_EMAIL      || '","' ||
												  l_rec.SUBMIT_FLAG       			  	|| '","' ||
												  l_rec.PRE_CREDIT_CHECKED_FLAG         || '","' ||
												  l_rec.SALES_CHANNEL_CODE		      	|| '","' ||
												  l_rec.SALES_CHANNEL			        || '","' ||
												  l_rec.SALESPERSON_ID		  		  	|| '","' ||
												  l_rec.SALESPERSON			  		  	|| '","' ||
												  l_rec.AGREEMENT_HEADER_ID             || '","' ||
												  l_rec.AGREEMENT_NUMBER ||'"');                


        END LOOP;

		/*----------------------------------------------------------------------
					CLOSE AND ADD HEADER FILE TO ZIP 
		------------------------------------------------------------------------*/
        utl_file.fclose(l_header_file);
        l_header_blob := file_to_blob(l_header_file_name);
        apex_zip.add_file(p_zipped_blob => x_zip_header, p_file_name => l_header_file_name, p_content => l_header_blob);

	/*-----------------------------------------------------------------------------------------------------
			GENERATE FBDI LINES CSV FILE
	------------------------------------------------------------------------------------------------------*/
        l_lines_file := utl_file.fopen(g_directory, l_lines_file_name, 'W', 32767);

		/*----------------------------------------------------------------------
				FOR EACH RECORD IN HBG_PROCESS_ORDERS_LINES_FBDI TABLE
		------------------------------------------------------------------------*/
        FOR l_rec IN (
            SELECT
                *
            FROM
                HBG_PROCESS_ORDERS_LINES_FBDI
            WHERE
                SBI_UUID = p_SBI_UUID
			and status = 'VALIDATED'
        ) LOOP

			/*----------------------------------------------------------------------------
					WRITE LINES ROW IN CSV FILE
			------------------------------------------------------------------------------*/
            utl_file.put_line(l_lines_file, 
                                   '"'||l_rec.SOURCE_TRANSACTION_ID 			|| '","' ||
										l_rec.SOURCE_TRANSACTION_SYSTEM         || '","' ||
										l_rec.SOURCE_TRANSACTION_LINE_ID        || '","' ||
										l_rec.SOURCE_TRANSACTION_SCHEDULE_ID    || '","' ||
										l_rec.SOURCE_TRANSACTION_SCHEDULE_NO    || '","' ||
										l_rec.SOURCE_TRANSACTION_LINE_NO        || '","' ||
										l_rec.PRODUCT_ID                        || '","' ||
										l_rec.PRODUCT_NUMBER                    || '","' ||
										l_rec.PRODUCT_DESCRIPTION               || '","' ||
										l_rec.SOURCE_SYS_PRODUCT_REFERENCE      || '","' ||
										l_rec.ORDERED_QUANTITY                  || '","' ||
										l_rec.ORDERED_UOM_CODE                  || '","' ||
										l_rec.ORDERED_UOM                       || '","' ||
										l_rec.REQUESTED_FULFILLMENT_ORG_ID      || '","' ||
										l_rec.REQUESTED_FULFILLMENT_ORG_CODE    || '","' ||
										l_rec.REQUESTED_FULFILLMENT_ORG_NAME    || '","' ||
										l_rec.BUSINESS_UNIT_ID                  || '","' ||
										l_rec.BUSINESS_UNIT_NAME                || '","' ||
										l_rec.REQUESTING_BUSINESS_UNIT_ID       || '","' ||
										l_rec.REQUESTING_BUSINESS_UNIT_NAME     || '","' ||
										l_rec.SUBSTITUTION_ALLOWED_FLAG         || '","' ||
										l_rec.CUSTOMER_PO_NUMBER                || '","' ||
										l_rec.CUSTOMER_PO_LINE_NUMBER           || '","' ||
										l_rec.CUSTOMER_PO_SCHEDULE_NUMBER       || '","' ||
										l_rec.CUSTOMER_PRODUCT_ID               || '","' ||
										l_rec.CUSTOMER_PRODUCT_NUMBER           || '","' ||
										l_rec.CUSTOMER_PRODUCT_DESCRIPTION      || '","' ||
										l_rec.TRANSACTION_LINE_TYPE_CODE        || '","' ||
										l_rec.TRANSACTION_LINE_TYPE             || '","' ||
										l_rec.PARENT_LINE_REFERENCE             || '","' ||
										l_rec.ROOT_PARENT_LINE_REFERENCE        || '","' ||
										l_rec.SHIPPING_INSTRUCTIONS             || '","' ||
										l_rec.PACKING_INSTRUCTIONS              || '","' ||
										l_rec.INVOICING_RULE_CODE               || '","' ||
										l_rec.INVOICING_RULE                    || '","' ||
										l_rec.ACCOUNTING_RULE_CODE              || '","' ||
										l_rec.ACCOUNTING_RULE                   || '","' ||
										l_rec.REQUESTED_SHIP_DATE               || '","' ||
										l_rec.REQUESTED_ARRIVAL_DATE            || '","' ||
										l_rec.SCHEDULE_SHIP_DATE                || '","' ||
										l_rec.SCHEDULE_ARRIVAL_DATE             || '","' ||
										l_rec.DEMAND_CLASS_CODE                 || '","' ||
										l_rec.DEMAND_CLASS                      || '","' ||
										l_rec.SHIPPING_CARRIER_CODE             || '","' ||
										l_rec.SHIPPING_CARRIER                  || '","' ||
										l_rec.PAYMENT_TERM_CODE                 || '","' ||
										l_rec.PAYMENT_TERM                      || '","' ||
										l_rec.TRANSACTION_CATEGORY_CODE         || '","' ||
										l_rec.SHIPPING_SERVICE_LEVEL_CODE       || '","' ||
										l_rec.SHIPPING_SERVICE_LEVEL            || '","' ||
										l_rec.SHIPPING_MODE_CODE                || '","' ||
										l_rec.SHIPPING_MODE                     || '","' ||
										l_rec.SHIPMENT_PRIORITY_CODE            || '","' ||
										l_rec.SHIPMENT_PRIORITY                 || '","' ||
										l_rec.INVENTORY_ORGANIZATION_ID         || '","' ||
										l_rec.INVENTORY_ORGANIZATION_CODE       || '","' ||
										l_rec.INVENTORY_ORGANIZATION_NAME       || '","' ||
										l_rec.FREIGHT_TERMS_CODE                || '","' ||
										l_rec.FREIGHT_TERMS                     || '","' ||
										l_rec.REQUEST_CANCEL_DATE               || '","' ||
										l_rec.ORIGINAL_PRODUCT_ID               || '","' ||
										l_rec.ORIGINAL_PRODUCT_NUMBER           || '","' ||
										l_rec.ORIGINAL_PRODUCT_DESCRIPTION      || '","' ||
										l_rec.PARTIAL_SHIP_ALLOWED_FLAG         || '","' ||
										l_rec.FULFILLMENT_LINE_ID               || '","' ||
										l_rec.COMMENTS                          || '","' ||
										l_rec.UNIT_LIST_PRICE                   || '","' ||
										l_rec.UNIT_SELLING_PRICE                || '","' ||
										l_rec.EXTENDED_AMOUNT                   || '","' ||
										l_rec.EARLIEST_ACCEPTABLE_SHIP_DATE     || '","' ||
										l_rec.LATEST_ACCEPTABLE_SHIP_DATE       || '","' ||
										l_rec.EARLIEST_ACCEPTABLE_ARR_DATE      || '","' ||
										l_rec.LATEST_ACCEPTABLE_ARRIVAL_DATE    || '","' ||
										l_rec.PROMISE_SHIP_DATE                 || '","' ||
										l_rec.PROMISE_ARRIVAL_DATE              || '","' ||
										l_rec.SUBINVENTORY_CODE                 || '","' ||
										l_rec.SUBINVENTORY                      || '","' ||
										l_rec.SHIP_SET_NAME                     || '","' ||
										l_rec.TAX_EXEMPT_FLAG                   || '","' ||
										l_rec.TAX_CLASSIFICATION_CODE           || '","' ||
										l_rec.TAX_CLASSIFICATION                || '","' ||
										l_rec.TAX_EXEMPTION_CERTIFICATE_NO      || '","' ||
										l_rec.TAX_EXEMPT_REASON_CODE            || '","' ||
										l_rec.TAX_EXEMPT_REASON                 || '","' ||
										l_rec.DEFAULT_TAXATION_COUNTRY          || '","' ||
										l_rec.DEFAULT_TAX_COUNTRY_SHORT_NAME    || '","' ||
										l_rec.FIRST_PARTY_TAX_REGISTRATION      || '","' ||
										l_rec.FIRST_PARTY_TAX_REG_NUMBER	    || '","' ||
										l_rec.THIRD_PARTY_TAX_REGISTRATION      || '","' ||
										l_rec.THIRD_PARTY_TAX_REG_NUMBER	    || '","' ||
										l_rec.DOCUMENT_SUBTYPE                  || '","' ||
										l_rec.DOCUMENT_SUBTYPE_NAME	     		|| '","' ||
										l_rec.PRODUCT_FISCAL_CATEGORY_ID        || '","' ||
										l_rec.PRODUCT_FISCAL_CATEGORY_NAME	    || '","' ||
										l_rec.PRODUCT_TYPE                      || '","' ||
										l_rec.PRODUCT_TYPE_NAME		     		|| '","' ||
										l_rec.PRODUCT_CATEGORY                  || '","' ||
										l_rec.PRODUCT_CATEGORY_NAME	     		|| '","' ||
										l_rec.TRANSACTION_BUSINESS_CATEGORY     || '","' ||
										l_rec.TXN_BUSINESS_CATEGORY_NAME	    || '","' ||
										l_rec.ASSESSABLE_VALUE                  || '","' ||
										l_rec.USER_DEFINED_FISCAL_CLASS         || '","' ||
										l_rec.USER_DEFINED_FISC_CLASS_NAME	    || '","' ||
										l_rec.INTENDED_USE_CLASSIFICATION_ID    || '","' ||
										l_rec.INTENDED_USE_CLASS_NAME	     	|| '","' ||
										l_rec.FOB_POINT_CODE                    || '","' ||
										l_rec.FOB_POINT                         || '","' ||
										l_rec.ORIG_SYS_DOCUMENT_REFERENCE       || '","' ||
										l_rec.ORIG_SYS_DOC_LINE_REFERENCE       || '","' ||
										l_rec.CANCEL_REASON_CODE                || '","' ||
										l_rec.CANCEL_REASON                     || '","' ||
										l_rec.SUBSTITUTION_REASON_CODE          || '","' ||
										l_rec.SUBSTITUTION_REASON               || '","' ||
										l_rec.RETURN_REASON_CODE                || '","' ||
										l_rec.RETURN_REASON                     || '","' ||
										l_rec.QUANTITY_PER_MODEL                || '","' ||
										l_rec.UNIT_QUANTITY		     			|| '","' ||
										l_rec.SORT_LINE_NUMBER		     		|| '","' ||
										l_rec.CONTRACT_START_DATE		     	|| '","' ||
										l_rec.CONTRACT_END_DATE		     		|| '","' ||
										l_rec.TOTAL_CONTRACT_QUANTITY	     	|| '","' ||
										l_rec.TOTAL_CONTRACT_AMOUNT	     		|| '","' ||
										l_rec.REQUIRED_FULFILLMENT_DATE   	    || '","' ||
										l_rec.COMPONENT_ID_PATH                 || '","' ||
										l_rec.IS_VALID_CONFIGURATION            || '","' ||
										l_rec.CONFIGURATOR_PATH                 || '","' ||
										l_rec.CONFIG_HEADER_ID                  || '","' ||
										l_rec.CONFIG_REVISION_NUMBER            || '","' ||
										l_rec.OPERATION_MODE                    || '","' ||
										l_rec.CREDIT_CHK_AUTH_NUM               || '","' ||
										l_rec.CREDIT_CHK_AUTH_EXP_DATE          || '","' ||
										l_rec.SERVICE_DURATION		     		|| '","' ||
										l_rec.SERVICE_DURATION_PERIOD_CODE      || '","' ||
										l_rec.SERVICE_DURATION_PERIOD_NAME      || '","' ||
										l_rec.SALESPERSON_ID		     		|| '","' ||
										l_rec.SALESPERSON			     		|| '","' ||
										l_rec.ASSET_GROUP_NUMBER 		     	|| '","' ||
										l_rec.SERVICE_CANCEL_DATE               || '","' ||
										l_rec.AGREEMENT_HEADER_ID               || '","' ||
										l_rec.AGREEMENT_NUMBER                  || '","' ||
										l_rec.COVERED_PRODUCT_IDENTIFIER        || '","' ||
										l_rec.COVERED_PRODUCT_NUMBER            || '","' ||
										l_rec.COVERED_PRODUCT_DESCRIPTION       || '","' ||
										l_rec.COVERED_PRODUCT_SRCSYS_REF        || '","' ||
										l_rec.COVERED_CUSTOMER_PRODUCT_ID       || '","' ||
										l_rec.COVERED_CUSTOMER_PRODUCT_NUM      || '","' ||
										l_rec.COVERED_CUSTOMER_PRODUCT_DESC     || '","' ||
										l_rec.INVENTORY_TRANSACTION_FLAG        || '","' ||
										l_rec.FULFILL_LINE_ID                   || '","' ||
										l_rec.SUBSCRIPTION_PROFILE_ID           || '","' ||
										l_rec.SUBSCRIPTION_PROFILE_NAME         || '","' ||
										l_rec.EXTERNAL_PRICE_BOOK_NAME          || '","' ||
										l_rec.ACTION_TYPE_CODE                  || '","' ||
										l_rec.ACTION_TYPE                       || '","' ||
										l_rec.END_REASON_CODE                   || '","' ||
										l_rec.END_REASON                        || '","' ||
										l_rec.END_CREDIT_METHOD_CODE            || '","' ||
										l_rec.END_CREDIT_METHOD                 || '","' ||
										l_rec.END_DATE                          || '","' ||
                                        'DOO_OrderFulfillmentGenericProcess'    ||'"'
                                        --l_rec.PROCESS_NAME                      ||'"'

			);
        END LOOP;

		/*----------------------------------------------------------------------
					CLOSE AND ADD LINES FILE TO ZIP 
		------------------------------------------------------------------------*/

        utl_file.fclose(l_lines_file);
        l_lines_blob := file_to_blob(l_lines_file_name);
        apex_zip.add_file(p_zipped_blob => x_zip_header, p_file_name => l_lines_file_name, p_content => l_lines_blob);

	/*-----------------------------------------------------------------------------------------------------
			GENERATE FBDI ADRESSES CSV FILE
	------------------------------------------------------------------------------------------------------*/
        l_address_file := utl_file.fopen(g_directory, l_address_file_name, 'W', 32767);

		/*----------------------------------------------------------------------
				FOR EACH RECORD IN HBG_PROCESS_ORDERS_ADDRESSES_FBDI TABLE
		------------------------------------------------------------------------*/

        FOR l_rec IN (
            SELECT
                *
            FROM
                HBG_PROCESS_ORDERS_ADDRESSES_FBDI
            WHERE
                SBI_UUID = p_SBI_UUID
			and status = 'VALIDATED'
        ) LOOP

			/*----------------------------------------------------------------------------
					WRITE ADRESSES ROW IN CSV FILE
			------------------------------------------------------------------------------*/
            utl_file.put_line(l_address_file, '"'||

                                        l_rec.SOURCE_TRANSACTION_ID           		|| '","' ||								
                                        l_rec.SOURCE_TRANSACTION_SYSTEM       		|| '","' ||								
                                        l_rec.SOURCE_TRANSACTION_LINE_ID      		|| '","' ||								
                                        l_rec.SOURCE_TRANSACTION_SCHEDULE_ID  		|| '","' ||								
                                        l_rec.ADDRESS_USE_TYPE                		|| '","' ||								
                                        l_rec.PARTY_ID                        		|| '","' ||								
                                        l_rec.PARTY_NUMBER                    		|| '","' ||								
                                        l_rec.PARTY_NAME                      		|| '","' ||								
                                        l_rec.CUSTOMER_ID                     		|| '","' ||								
                                        l_rec.CUSTOMER_NUMBER                 		|| '","' ||								
                                        l_rec.CUSTOMER_NAME                   		|| '","' ||								
                                        l_rec.REQUESTED_SUPPLIER_CODE         		|| '","' ||								
                                        l_rec.REQUESTED_SUPPLIER_NUMBER       		|| '","' ||								
                                        l_rec.REQUESTED_SUPPLIER_NAME         		|| '","' ||								
                                        l_rec.PARTY_SITE_ID                   		|| '","' ||								
                                        l_rec.ACCOUNT_SITE_USE_ID             		|| '","' ||								
                                        l_rec.REQUESTED_SUPPLIER_SITE_ID      		|| '","' ||								
                                        l_rec.ADDRESS_ORIG_SYS_REFERENCE      		|| '","' ||								
                                        l_rec.ADDRESS_LINE1                  		|| '","' ||								
                                        l_rec.ADDRESS_LINE2                  		|| '","' ||								
                                        l_rec.ADDRESS_LINE3                  		|| '","' ||								
                                        l_rec.ADDRESS_LINE4                  		|| '","' ||								
                                        l_rec.CITY                            		|| '","' ||								
                                        l_rec.POSTAL_CODE                     		|| '","' ||								
                                        l_rec.STATE                           		|| '","' ||								
                                        l_rec.PROVINCE                        		|| '","' ||								
                                        l_rec.COUNTY                          		|| '","' ||								
                                        l_rec.COUNTRY                         		|| '","' ||								
                                        l_rec.SHIP_TO_REQUEST_REGION          		|| '","' ||								
                                        l_rec.PARTY_CONTACT_ID                		|| '","' ||								
                                        l_rec.PARTY_CONTACT_NUMBER            		|| '","' ||								
                                        l_rec.PARTY_CONTACT_NAME              		|| '","' ||								
                                        l_rec.ACCOUNT_CONTACT_ID              		|| '","' ||								
                                        l_rec.ACCOUNT_CONTACT_NUMBER          		|| '","' ||	
                                        l_rec.ACCOUNT_CONTACT_NAME            	    || '","' ||
                                        l_rec.CONTACT_ORIG_SYS_REFERENCE      	    || '","' ||
                                        l_rec.LOCATION_ID			   			    || '","' ||
                                        l_rec.PREF_CONTACT_POINT_ID	   		        || '","' ||
                                        l_rec.PREF_CONT_POINT_ORIG_SYS_REF	   	    || '","' ||
                                        l_rec.FIRST_NAME			   			    || '","' ||
                                        l_rec.LAST_NAME			   			        || '","' ||
                                        l_rec.MIDDLE_NAME			   			    || '","' ||
                                        l_rec.NAME_SUFFIX			   			    || '","' ||
                                        l_rec.TITLE			   				        || '","' ||
                                        l_rec.CONTACT_FIRST_NAME		   		    || '","' ||
                                        l_rec.CONTACT_LAST_NAME		   		        || '","' ||
                                        l_rec.CONTACT_MIDDLE_NAME		   		    || '","' ||
                                        l_rec.CONTACT_NAME_SUFFIX		   		    || '","' ||
                                        l_rec.CONTACT_TITLE		   			        || '","' ||
                                        l_rec.PARTY_TYPE			   			    || '","' ||
                                        l_rec.DESTINATION_SHIPPING_ORG_ID     	    || '","' ||
                                        l_rec.DESTINATION_SHIPPING_ORG_CODE   	    || '","' ||
                                        l_rec.DESTINATION_SHIPPING_ORG_NAME   	    || '","' ||
                                        l_rec.PARTY_PERSON_EMAIL              	    || '","' ||
                                        l_rec.PARTY_ORGANIZATION_EMAIL        	    || '","' ||
                                        l_rec.PARTY_CONTACT_EMAIL || '"' );

        END LOOP;

		/*----------------------------------------------------------------------
					CLOSE AND ADD ADRESSES FILE TO ZIP 
		------------------------------------------------------------------------*/

        utl_file.fclose(l_address_file);
        l_address_blob := file_to_blob(l_address_file_name);
        apex_zip.add_file(p_zipped_blob => x_zip_header, p_file_name => l_address_file_name, p_content => l_address_blob);

	/*-----------------------------------------------------------------------------------------------------
			GENERATE FBDI HEADERS ALL EFF CSV FILE
	------------------------------------------------------------------------------------------------------*/
        l_header_eff_file := utl_file.fopen(g_directory, l_header_eff_file_name, 'W', 32767);

		/*----------------------------------------------------------------------
				FOR EACH RECORD IN HBG_PROCESS_ORDERS_HDRS_EFF_FBDI TABLE
		------------------------------------------------------------------------*/

        FOR l_rec IN (
            SELECT
                *
            FROM
                HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
            WHERE
                SBI_UUID = p_SBI_UUID
			and status = 'VALIDATED'
        ) LOOP

			/*----------------------------------------------------------------------------
					WRITE HEADERS EFF ROW IN CSV FILE
			------------------------------------------------------------------------------*/
                utl_file.put_line(l_header_eff_file, 
                '"'||
                                            l_rec.SOURCE_TRANSACTION_ID      	|| '","' ||
                                            l_rec.SOURCE_TRANSACTION_SYSTEM  	|| '","' ||
                                            l_rec.CONTEXT_CODE         			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR1      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR2      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR3      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR4      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR5      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR6      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR7      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR8      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR9      			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR10     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR11     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR12     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR13     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR14     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR15     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR16     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR17     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR18     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR19     			|| '","' ||
                                            l_rec.ATTRIBUTE_CHAR20     			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER1    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER2    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER3    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER4    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER5    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER6    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER7    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER8    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER9    			|| '","' ||
                                            l_rec.ATTRIBUTE_NUMBER10   			|| '","' ||
                                            l_rec.ATTRIBUTE_DATE1      			|| '","' ||
                                            l_rec.ATTRIBUTE_DATE2      			|| '","' ||
                                            l_rec.ATTRIBUTE_DATE3      			|| '","' ||
                                            l_rec.ATTRIBUTE_DATE4      			|| '","' ||
                                            l_rec.ATTRIBUTE_DATE5      			|| '","' ||
             to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP1),'YYYY/MM/DD HH24:MI:SS') || '","' ||
             to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP2),'YYYY/MM/DD HH24:MI:SS') || '","' ||
             to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP3),'YYYY/MM/DD HH24:MI:SS') || '","' ||
             to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP4),'YYYY/MM/DD HH24:MI:SS') || '","' ||
             to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP5),'YYYY/MM/DD HH24:MI:SS') || '"');

        END LOOP;

		/*----------------------------------------------------------------------
					CLOSE AND ADD HEADERS EFF FILE TO ZIP 
		------------------------------------------------------------------------*/

        utl_file.fclose(l_header_eff_file);
        l_header_eff_blob := file_to_blob(l_header_eff_file_name);
        apex_zip.add_file(p_zipped_blob => x_zip_header, p_file_name => l_header_eff_file_name, p_content => l_header_eff_blob);

  	/*-----------------------------------------------------------------------------------------------------
			GENERATE FBDI LINES ALL EFF CSV FILE
	------------------------------------------------------------------------------------------------------*/
        l_lines_eff_file := utl_file.fopen(g_directory, l_lines_eff_file_name, 'W', 32767);

		/*----------------------------------------------------------------------
				FOR EACH RECORD IN HBG_PROCESS_ORDERS_LINES_EFF_FBDI TABLE
		------------------------------------------------------------------------*/

        FOR l_rec IN (
            SELECT
                *
            FROM
                HBG_PROCESS_ORDERS_LINES_EFF_FBDI
            WHERE
                SBI_UUID = p_SBI_UUID
			and status = 'VALIDATED'
        ) LOOP

			/*----------------------------------------------------------------------------
					WRITE LINES EFF ROW IN CSV FILE
			------------------------------------------------------------------------------*/
                utl_file.put_line(l_lines_eff_file, '"' ||
                    l_rec.SOURCE_TRANSACTION_ID      		|| '","' ||
                    l_rec.SOURCE_TRANSACTION_SYSTEM  		|| '","' ||
                    l_rec.SOURCE_TRANSACTION_LINE_ID     	|| '","' ||
                    l_rec.SOURCE_TRANSACTION_SCHEDULE_ID	|| '","' ||
                    l_rec.CONTEXT_CODE         				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR1      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR2      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR3      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR4      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR5      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR6      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR7      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR8      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR9      				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR10     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR11     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR12     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR13     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR14     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR15     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR16     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR17     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR18     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR19     				|| '","' ||
                    l_rec.ATTRIBUTE_CHAR20     				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER1    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER2    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER3    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER4    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER5    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER6    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER7    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER8    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER9    				|| '","' ||
                    l_rec.ATTRIBUTE_NUMBER10   				|| '","' ||
                    l_rec.ATTRIBUTE_DATE1      				|| '","' ||
                    l_rec.ATTRIBUTE_DATE2      				|| '","' ||
                    l_rec.ATTRIBUTE_DATE3      				|| '","' ||
                    l_rec.ATTRIBUTE_DATE4      				|| '","' ||
                    l_rec.ATTRIBUTE_DATE5      				|| '","' ||
                     to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP1),'YYYY/MM/DD HH24:MI:SS') || '","' ||
                     to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP2),'YYYY/MM/DD HH24:MI:SS') || '","' ||
                     to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP3),'YYYY/MM/DD HH24:MI:SS') || '","' ||
                     to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP4),'YYYY/MM/DD HH24:MI:SS') || '","' ||
                     to_char(to_date(l_rec.ATTRIBUTE_TIMESTAMP5),'YYYY/MM/DD HH24:MI:SS') || '"');				

        END LOOP;

		/*----------------------------------------------------------------------
					CLOSE AND ADD LINES EFF FILE TO ZIP 
		------------------------------------------------------------------------*/

        utl_file.fclose(l_lines_eff_file);
        l_lines_eff_blob := file_to_blob(l_lines_eff_file_name);
        apex_zip.add_file(p_zipped_blob => x_zip_header, p_file_name => l_lines_eff_file_name, p_content => l_lines_eff_blob);      

       	/*----------------------------------------------------------------------
					GENERATE ZIP FILE
		------------------------------------------------------------------------*/    
        apex_zip.finish(p_zipped_blob => x_zip_header);

       	/*----------------------------------------------------------------------
					LOG IN FTP SERVER
		------------------------------------------------------------------------*/  

        WHILE l_put_file = 0 and l_retry < 6 
        LOOP 

        BEGIN
         AS_SFTP_KEYMGMT.LOGIN(
            I_USER => I_USER,
            I_HOST => I_HOST,
            I_PORT => I_PORT,
            I_TRUST_SERVER => I_TRUST_SERVER
  );

        /*----------------------------------------------------------------------
					WRITE ZIP FILE IN FTP SERVER
		------------------------------------------------------------------------*/  
        AS_SFTP.put_file('/OIC_IB/'||l_ftp_folder||'/'||ftp_filename , x_zip_header );
        l_report_flag := 'true';
        l_put_file := 1;

        EXCEPTION WHEN OTHERS THEN
            l_retry := l_retry + 1;
            dbms_session.sleep(l_retry*60);
            dbms_output.put_line('retry: ' || l_retry ||' date: '|| systimestamp ); 
            l_put_file := 0;

            if l_retry = 6 then
                errbuf := sqlerrm;
                retcode := 1;
                dbms_output.put_line(sqlerrm); 
            end if;

        END;
    END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            errbuf := sqlerrm;
			retcode := 1;

    END generate_fbdi;

----------------------------------------------------------------------------------------------------------------------------------------
/*								FILE TO BLOB																				*/
----------------------------------------------------------------------------------------------------------------------------------------
	FUNCTION file_to_blob (
			p_filename VARCHAR2
		) RETURN BLOB AS

			x_blob_file BLOB;
			l_file      BFILE := bfilename(g_directory, p_filename);
			l_blob      BLOB;
			src_offset  NUMBER := 1;
			dst_offset  NUMBER := 1;
			src_osin    NUMBER;
			dst_osin    NUMBER;
			bytes_wt    NUMBER;
		BEGIN
			dbms_lob.createtemporary(l_blob, false, 2);
			dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
			dbms_lob.open(l_blob, dbms_lob.lob_readwrite);
			src_osin := src_offset;
			dst_osin := dst_offset;
			dbms_lob.loadblobfromfile(l_blob, l_file, dbms_lob.lobmaxsize, src_offset, dst_offset);
			dbms_lob.close(l_blob);
			dbms_lob.filecloseall();
			RETURN l_blob;
		EXCEPTION
			WHEN OTHERS THEN
				RETURN NULL;
    END file_to_blob;

-----------------------------------------------------------------------------------------------------------------------------------------------
/*																																*/
-----------------------------------------------------------------------------------------------------------------------------------------------
	PROCEDURE PROCESS_SBI_UUID_DATA (
        p_debug       		IN VARCHAR2 DEFAULT 'false',
		p_debug_filename	IN VARCHAR2 DEFAULT NULL,
		p_sbi_uuid	  		IN VARCHAR2,
		p_gid_id			IN NUMBER,
		p_headers_count		IN NUMBER,
        p_line_seq_count    IN NUMBER,
		p_line_count		IN NUMBER,
		errbuf				OUT VARCHAR2,
		retcode				OUT VARCHAR2
	) AS


	/*-----------------------------------------------------------------------------------------------------
		CURSORS FOR EACH FBDI FILE
	------------------------------------------------------------------------------------------------------*/
	--DATA FOR SALES ORDER HEADER FBDI
	CURSOR c_doo_header_all_interface IS
		SELECT 
				LPAD(GIS_HEADER_UID,p_headers_count,'0') AS GIS_HEADER_UID,
				hdr.PURCHASE_ORDER_NO,
				TO_CHAR(hdr.ORDER_DATE, 'YYYY/MM/DD HH24:MI:SS') as ORDER_DATE,
				hdr.STAGE_ACCOUNT_NO
		FROM 	HBG_STERLING_HEADER hdr
		WHERE 	hdr.SBI_UUID = p_sbi_uuid
			AND hdr.IMPORT_STATUS = 'NEW';


	--DATA FOR SALES ORDER HEADER EFFS FBDI
	CURSOR c_doo_hdr_effs_all_interface IS
		SELECT 
				--Header id
				LPAD(hdr.GIS_HEADER_UID,p_headers_count,'0') AS GIS_HEADER_UID,
                hdr.STAGE_ACCOUNT_NO,
                hdr.PURCHASE_ORDER_NO,
				--EDI General CONTEXT
				hdr.CANCEL_DATE,
				hdr.ORDER_STATUS,
				hdr.DEPARTMENT_NO,
				hdr.VENDOR_NO,
				hdr.BATCH_ID,
				hdr.DESTINATION_ACCOUNT_NO,
				hdr.FREIGHT_CHARGE_IND,
				hdr.GIFT_MESSAGE,
				hdr.POA_FLAG,
				hdr.AGENCY_NAME,
				hdr.ACCOUNT_CODE,
				hdr.BUYER_NAME,
				hdr.COST_CENTER_CODE,
				hdr.EDI_DATES,
				hdr.EDI_PO_TYPE_CODE,
				ship.EDI_DC_ID,
				hdr.BACKORDER_CODE,
				hdr.SALES_TYPE,
				--EDI Customer CONTEXT
				hdr.CUSTOMER_SPECIFIC_DATA,
				hdr.CUSTOMER_EMAIL,
				hdr.CUSTOMER_TELEPHONE_NO,
				hdr.COMPANY_CODE,
				hdr.BUYER_PHONE,
				ship.SHIPTO_SAN,
				ship.SHIPTO_NO,
				ship.EDI_SHIP_ID,
				--GS1 Data CONTEXT
				hdr.GS1_LABEL_TAG10,
				hdr.GS1_LABEL_DATA1,
				hdr.GS1_LABEL_DATA2,
				hdr.GS1_LABEL_DATA3,
				hdr.GS1_LABEL_DATA4,
				hdr.GS1_LABEL_DATA5,
				hdr.GS1_LABEL_DATA6,
				hdr.GS1_LABEL_DATA7,
				hdr.GS1_LABEL_DATA8,
				hdr.GS1_LABEL_DATA9,
				hdr.GS1_LABEL_DATA10,
				hdr.GS1_LABEL_TAG1,
				hdr.GS1_LABEL_TAG2,
				hdr.GS1_LABEL_TAG3,
				hdr.GS1_LABEL_TAG4,
				hdr.GS1_LABEL_TAG5,
				hdr.GS1_LABEL_TAG6,
				hdr.GS1_LABEL_TAG7,
				hdr.GS1_LABEL_TAG8,
				hdr.GS1_LABEL_TAG9,
				--GS1_Data CONTEXT
				hdr.GS1_DATA,
				--HDR Date CONTEXT
				hdr.HDR_DATE_1,
				hdr.HDR_DATE_2,
				hdr.HDR_DATE_3,
				hdr.HDR_DATE_4,
				hdr.HDR_DATE_5,
				hdr.HDR_DATE_Q1,
				hdr.HDR_DATE_Q2,
				hdr.HDR_DATE_Q3,
				hdr.HDR_DATE_Q4,
				hdr.HDR_DATE_Q5,
				--HDR_2 Date CONTEXT
				hdr.HDR_DATE_6,
				hdr.HDR_DATE_7,
				hdr.HDR_DATE_8,
				hdr.HDR_DATE_9,
				hdr.HDR_DATE_10,
				hdr.HDR_DATE_Q6,
				hdr.HDR_DATE_Q7,
				hdr.HDR_DATE_Q8,
				hdr.HDR_DATE_Q9,
				hdr.HDR_DATE_Q10,
				--General CONTEXT
				--hdr.DESTINATION_ACCOUNT_NO,
				--hdr.AGENCY_NAME,
				--EDI Promo Code CONTEXT
				hdr.PROMO_CODE1,
				hdr.PROMO_CODE2,
				hdr.PROMO_CODE3,
				hdr.PROMO_CODE4,
				hdr.PROMO_CODE5,
				--Ref Q CONTEXT
				hdr.REF_Q1,
				hdr.REF_Q2,
				hdr.REF_Q3,
				hdr.REF_Q4,
				hdr.REF_Q5,
				hdr.REF_DATA1,
				hdr.REF_DATA2,
				hdr.REF_DATA3,
				hdr.REF_DATA4,
				hdr.REF_DATA5,
				--EDI Address/One Time Address CONTEXT
				ship.SHIPTO_NAME,
				ship.SHIPTO_ADDR1,
				ship.SHIPTO_ADDR2,
				ship.SHIPTO_ADDR3,
				ship.SHIPTO_ADDR4,
				ship.SHIPTO_CITY,
				ship.SHIPTO_STATE,
				ship.SHIPTO_POSTAL_CODE,
				ship.SHIPTO_COUNTRY,
				ship.SHIPTO_ATTENTION

		FROM 	HBG_STERLING_HEADER hdr,
				HBG_STERLING_SHIP ship

		WHERE 	hdr.SBI_UUID = p_sbi_uuid
			AND hdr.IMPORT_STATUS = 'NEW'
			AND ship.SBI_UUID = hdr.SBI_UUID
			AND hdr.PURCHASE_ORDER_NO = ship.PURCHASE_ORDER_NO
			AND hdr.STAGE_ACCOUNT_NO = ship.STAGE_ACCOUNT_NO;


	--DATA FOR SALES ORDER LINES FBDI
	CURSOR c_doo_lines_all_interface IS

	SELECT  

		LPAD(GIS_HEADER_UID,p_headers_count,'0') AS GIS_HEADER_UID,
		CASE WHEN LINE_SEQUENCE IS NULL OR LINE_SEQUENCE = 0 THEN LPAD(LINE_SEQUENCE2,p_line_seq_count,'0')
             ELSE LPAD(LINE_SEQUENCE,p_line_seq_count,'0') END AS LINE_SEQUENCE,
		LPAD(row_number() over( partition by LINE_SEQUENCE,
                                            LINE_SEQUENCE2,
											purchase_order_no,
											stage_account_no 
								order by stage_account_no, 
											purchase_order_no, 
											LINE_SEQUENCE,
                                            LINE_SEQUENCE2),p_line_count,'0')  as ROW_NO,
		EAN,
		NVL(ORDER_QTY,0) AS ORDER_QTY,
		PURCHASE_ORDER_NO,
		STAGE_ACCOUNT_NO
		FROM HBG_STERLING_DETAIL line
		WHERE SBI_UUID = p_sbi_uuid
		AND IMPORT_STATUS = 'NEW'
		ORDER BY line.stage_account_no, 
				line.purchase_order_no, 
				line.LINE_SEQUENCE,
                row_no,
				line.SHIPTO_NO, 
				line.SHIPTO_SAN;


	--DATA FOR SALES ORDER LINES EFF FBDI
	CURSOR c_doo_lines_effs_all_interface IS
	SELECT 
		--HEADER/LINE ID
		LPAD(line.GIS_HEADER_UID,p_headers_count,'0') AS GIS_HEADER_UID,
		CASE WHEN LINE_SEQUENCE IS NULL OR LINE_SEQUENCE = 0 THEN LPAD(LINE_SEQUENCE2,p_line_seq_count,'0')
             ELSE LPAD(LINE_SEQUENCE,p_line_seq_count,'0') END AS LINE_SEQUENCE,
		LPAD(row_number() over( partition by LINE_SEQUENCE,
                                            LINE_SEQUENCE2,
											line.purchase_order_no,
											line.stage_account_no 
								order by line.stage_account_no, 
											line.purchase_order_no, 
											LINE_SEQUENCE,
                                            LINE_SEQUENCE2),p_line_count,'0')  as ROW_NO,
        line.STAGE_ACCOUNT_NO,
        line.PURCHASE_ORDER_NO,
		--EDI Customer CONTEXT
		line.CUSTOMER_RETAIL_PRICE,	
		line.CUSTOMER_UNIT_NET_PRICE,	
		line.CUSTOMER_PACK_QTY,	
		line.CUSTOMER_DISCOUNT,	
		line.CUSTOMER_SPECIFIC_DATA,
		--EDI General CONTEXT
		line.PRODUCT_DESCRIPTION,	
		line.ITEM_UOM,	
		line.SALES_CHANNEL,	
		line.TICKET_TYPE,	
		line.COLOR,	
		line.PRODUCT_SIZE,	
		line.CLASS_ID,	
		--line.LINE_SEQUENCE,	
		line.EAN,	
		line.ISBN,	
		line.SKU,	
		line.UPC,	
		line.SHIPTO_NO,	
		line.SHIPTO_SAN,	
		line.EDI_SHIP_ID,	
		line.EXTENDED_NET_COST,	
		line.MASTER_PACK,    
		line.INNER_PACK,
		--DTL Q Date CONTEXT
		line.DTL_DATE_Q1,
		line.DTL_DATE_Q2,
		line.DTL_DATE_Q3,
		line.DTL_DATE_Q4,
		line.DTL_DATE_Q5,
		line.DTL_DATE_1,
		line.DTL_DATE_2,
		line.DTL_DATE_5,
		line.DTL_DATE_3,
		line.DTL_DATE_4,
		--GS1_Data CONTEXT
		line.GS1_DATA,
		--GS1 Data CONTEXT
		line.GS1_LABEL_DATA1,
		line.GS1_LABEL_DATA2,
		line.GS1_LABEL_DATA3,
		line.GS1_LABEL_DATA4,
		line.GS1_LABEL_DATA5,
		line.GS1_LABEL_DATA6,
		line.GS1_LABEL_DATA7,
		line.GS1_LABEL_DATA8,
		line.GS1_LABEL_DATA9,
		line.GS1_LABEL_DATA10,
		line.GS1_LABEL_TAG1,
		line.GS1_LABEL_TAG2,
		line.GS1_LABEL_TAG3,
		line.GS1_LABEL_TAG4,
		line.GS1_LABEL_TAG5,
		line.GS1_LABEL_TAG6,
		line.GS1_LABEL_TAG7,
		line.GS1_LABEL_TAG8,
		line.GS1_LABEL_TAG9,
		line.GS1_LABEL_TAG10,
		--EDI Product CONTEXT
		line.PRODUCT_QUAL1,
		line.PRODUCT_QUAL2,
		line.PRODUCT_QUAL3,
		line.PRODUCT_QUAL4,
		line.PRODUCT_QUAL5,
		line.PRODUCT_QUAL6,
		line.PRODUCT_QUAL7,
		line.PRODUCT_QUAL8,
		line.PRODUCT_QUAL9,
		line.PRODUCT_QUAL10,
		line.PRODUCT_ID1,
		line.PRODUCT_ID2,
		line.PRODUCT_ID3,
		line.PRODUCT_ID4,
		line.PRODUCT_ID5,
		line.PRODUCT_ID6,
		line.PRODUCT_ID7,
		line.PRODUCT_ID8,
		line.PRODUCT_ID9,
		line.PRODUCT_ID10,
		--Ref CONTEXT
		line.REF_Q1,
		line.REF_Q2,
		line.REF_Q3,
		line.REF_Q4,
		line.REF_Q5,
		line.REF_DATA1,
		line.REF_DATA2,
		line.REF_DATA3,
		line.REF_DATA4,
		line.REF_DATA5,
		--Item Details CONTEXT
			--line.TICKET_TYPE,
			--line.COLOR,
			--line.CUSTOMER_RETAIL_PRICE,
			--line.CUSTOMER_UNIT_NET_PRICE,
			--line.CUSTOMER_DISCOUNT,
			--line.PRODUCT_SIZE,
			--Custom Order CONTEXT
			--line.CUSTOMER_PACK_QTY,
		--Delivery On CONTEXT
		hdr.EARLY_DELIVERY_DATE,
		hdr.MUST_ARRIVE_BY_DATE,
		--Ship on CONTEXT
		hdr.MUST_SHIP_BY_DATE,
		--Sales Type CONTEXT
		hdr.SALES_TYPE

	FROM 	HBG_STERLING_DETAIL line,
			HBG_STERLING_HEADER hdr
	WHERE 	line.SBI_UUID = p_sbi_uuid
		AND line.IMPORT_STATUS = 'NEW'
		and hdr.SBI_UUID = line.SBI_UUID
		and hdr.PURCHASE_ORDER_NO = line.PURCHASE_ORDER_NO
		and hdr.STAGE_ACCOUNT_NO = line.STAGE_ACCOUNT_NO
	ORDER BY 	line.stage_account_no, 
				line.purchase_order_no, 
				line.LINE_SEQUENCE,
                row_no,
				line.SHIPTO_NO, 
				line.SHIPTO_SAN;

	--DATA FOR SALES ORDER ADRESSES lines FBDI
	CURSOR c_doo_addresses_all_interface IS
	SELECT DISTINCT
		adr.SOURCE_TRANSACTION_ID,
		adr.SOURCE_TRANSACTION_SYSTEM,
		adr.SOURCE_TRANSACTION_LINE_ID,
		adr.SOURCE_TRANSACTION_SCHEDULE_ID,
		adr.SOURCE_PURCHASE_ORDER_NO as PURCHASE_ORDER_NO,
		adr.SOURCE_ACCOUNT_NO,
        adr.SOURCE_PURCHASE_ORDER_NO,
        CASE 
            WHEN lef.SOURCE_TRANSACTION_LINE_ID IS NULL THEN hef.ATTRIBUTE_CHAR6
            ELSE lef.attribute_char13 END AS source_ship_no,
        CASE 
            WHEN lef.SOURCE_TRANSACTION_LINE_ID IS NULL THEN hef.ATTRIBUTE_CHAR7
            ELSE lef.attribute_char14 END AS source_shipto_san,
        CASE 
            WHEN lef.SOURCE_TRANSACTION_LINE_ID IS NULL THEN hef.ATTRIBUTE_CHAR8
            ELSE lef.attribute_char15 END AS source_edi_ship_id
	FROM
		HBG_PROCESS_ORDERS_LINES_FBDI adr,
        hbg_process_orders_hdrS_eff_fbdi hef,
        HBG_PROCESS_ORDERS_LINES_EFF_FBDI lef

	WHERE 
		adr.SBI_UUID = p_sbi_uuid
	AND	adr.STATUS = 'NEW'
    AND adr.SOURCE_TRANSACTION_ID = hef.SOURCE_TRANSACTION_ID         
    AND adr.SOURCE_TRANSACTION_LINE_ID = lef.SOURCE_TRANSACTION_LINE_ID (+)
    AND (lef.attribute_char13 (+) IS NOT NULL
         OR lef.attribute_char14 (+) IS NOT NULL
         OR lef.attribute_char14 (+) IS NOT NULL)
    AND hef.CONTEXT_CODE = 'EDI Customer'
    AND lef.CONTEXT_CODE (+) = 'EDI General';

	/*--DATA FOR SALES ORDER ADRESSES HEADER FBDI
	CURSOR c_doo_addresses_hdr_interface IS	
	SELECT DISTINCT
		adr.SOURCE_TRANSACTION_ID,
		adr.SOURCE_TRANSACTION_SYSTEM,
		adr.ADDRESS_USE_TYPE,
		adr.SOURCE_ACCOUNT_NO,
		hdr.SOURCE_TRANSACTION_NUMBER as PURCHASE_ORDER_NO
	FROM HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr,
		 HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
	WHERE adr.SBI_UUID = p_sbi_uuid
	  and hdr.SBI_UUID = adr.SBI_UUID
	  and adr.SOURCE_TRANSACTION_ID = hdr.SOURCE_TRANSACTION_ID
	  and adr.ADDRESS_USE_TYPE = 'BILL_TO'
	  AND adr.STATUS = 'NEW';*/

	/*-----------------------------------------------------------------------------------------------------
			CURSOR TABLE TYPES
	------------------------------------------------------------------------------------------------------*/

	TYPE lt_doo_header_all_interface_tb 		IS TABLE OF c_doo_header_all_interface%ROWTYPE;
	TYPE lt_doo_hdr_effs_all_interface_tb  		IS TABLE OF c_doo_hdr_effs_all_interface%ROWTYPE;
	TYPE lt_doo_lines_all_interface_tb  		IS TABLE OF c_doo_lines_all_interface%ROWTYPE;
	TYPE lt_doo_lines_effs_all_interface_tb  	IS TABLE OF c_doo_lines_effs_all_interface%ROWTYPE;
	TYPE lt_doo_addresses_all_interface_tb  	IS TABLE OF c_doo_addresses_all_interface%ROWTYPE;
	--TYPE lt_doo_addresses_hdr_interface_tb  	IS TABLE OF c_doo_addresses_hdr_interface%ROWTYPE;

	/*-----------------------------------------------------------------------------------------------------
			VARIABLES
	------------------------------------------------------------------------------------------------------*/

	l_doo_header_all_interface_tb  		lt_doo_header_all_interface_tb ; 	
	l_doo_hdr_effs_all_interface_tb  	lt_doo_hdr_effs_all_interface_tb ;	
    l_doo_lines_all_interface_tb  	    lt_doo_lines_all_interface_tb ; 	
    l_doo_lines_effs_all_interface_tb	lt_doo_lines_effs_all_interface_tb ;
	l_doo_addresses_all_interface_tb	lt_doo_addresses_all_interface_tb;
	--l_doo_addresses_hdr_interface_tb	lt_doo_addresses_hdr_interface_tb;
	l_count									NUMBER := 0;
	l_count_success							NUMBER := 0;
	l_count_fail							NUMBER := 0;
	l_source_transaction_sys        	VARCHAR2(10)  := 'STEDI';
	l_update_errmsg		            	NUMBER;
	l_update_success	            	NUMBER;
	l_errbuf                        	VARCHAR2(2000) := NULL;
	l_retcode			            	NUMBER;
	l_ship_date                     	VARCHAR2(19);

	/*-----------------------------------------------------------------------------------------------------
			EXCEPTIONS
	------------------------------------------------------------------------------------------------------*/
	le_custom_exception EXCEPTION;
    le_insert_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_insert_exception, -24381);

	/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS_SBI_UUID_DATA PROCEDURE
	------------------------------------------------------------------------------------------------------*/
	BEGIN

		IF p_debug = 'true' then
			DEBUG_MSG ( 
				p_file_name => p_debug_filename,
				p_debug_msg => 'BEGIN PROCESS_SBI_UUID_DATA' );
		end if;

		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS HEADER DATA
		------------------------------------------------------------------------------------------------------*/
		BEGIN
        dbms_output.put_line(systimestamp); 
			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS HEADER DATA - OPEN c_doo_header_all_interface' );
			end if;
            dbms_output.put_line('header');
			OPEN c_doo_header_all_interface;
			LOOP
				FETCH c_doo_header_all_interface BULK COLLECT INTO l_doo_header_all_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_header_all_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_header_all_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS HEADER DATA - Bulk Collect count '||l_count );
				end if;

				BEGIN
					FORALL i IN 1 .. l_doo_header_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HEADERS_FBDI
						(
							SOURCE_TRANSACTION_ID, 	
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_NUMBER,
							TRANSACTIONAL_CURRENCY_CODE,
							TRANSACTION_ON,			
							REQUESTING_BUSINESS_UNIT,  
							GIS_ID,					
							SBI_UUID,                   
							STATUS,					
							BATCH_NAME,                 
							FREEZE_PRICING,             
							SOURCE_ACCOUNT_NO,          
							SOURCE_SYSTEM,              
							SUBMIT_FLAG,                
				            CUSTOMER_PO_NUMBER,
                            GIS_HEADER_ID
						)
						VALUES
						(
							p_sbi_uuid || l_doo_header_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID, 	
							l_source_transaction_sys,                                       --SOURCE_TRANSACTION_SYSTEM,
							l_doo_header_all_interface_tb(i).PURCHASE_ORDER_NO,             --SOURCE_TRANSACTION_NUMBER,
							'USD',                                                          --TRANSACTIONAL_CURRENCY_CODE,
							l_doo_header_all_interface_tb(i).ORDER_DATE,                    --TRANSACTION_ON,			
							'HBG US BU',                                                    --REQUESTING_BUSINESS_UNIT,  
							p_gid_id,                                                       --GIS_ID,					
							p_sbi_uuid,                                                     --SBI_UUID,                   
							'NEW',                                                          --STATUS,					
							p_sbi_uuid,                                                     --BATCH_NAME,                 
							'N',                                                            --FREEZE_PRICING,             
							l_doo_header_all_interface_tb(i).STAGE_ACCOUNT_NO,              --SOURCE_ACCOUNT_NO,          
							'STERLING',                                                     --SOURCE_SYSTEM,              
							'N',                                                            --SUBMIT_FLAG,                
							l_doo_header_all_interface_tb(i).PURCHASE_ORDER_NO,             --CUSTOMER_PO_NUMBER,
                            l_doo_header_all_interface_tb(i).GIS_HEADER_UID                 --GIS_HEADER_ID
						);

					COMMIT;
					l_count_success := l_count_success + l_doo_header_all_interface_tb.COUNT;
				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_header_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_header_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_header_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
                        dbms_output.put_line(sqlerrm);
						l_errbuf := sqlerrm;
						RAISE le_custom_exception;
				END;

			END LOOP;	

            IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'BEGIN PROCESS HEADER DATA - '||l_count_fail||' orders failed');
            end if;

            IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'BEGIN PROCESS HEADER DATA - '||l_count_success||' orders succeeded');
            end if;
			CLOSE c_doo_header_all_interface;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_header_all_interface loop' );
            end if;

		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_header_all_interface%ISOPEN THEN
				   CLOSE c_doo_header_all_interface;
				END IF;
                dbms_output.put_line(sqlerrm);
				l_errbuf := sqlerrm;
				RAISE le_custom_exception;
		END;


		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS HEADER EFFS DATA
		------------------------------------------------------------------------------------------------------*/
		l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS HEADER EFFS DATA - OPEN c_doo_hdr_effs_all_interface' );
			end if;
            dbms_output.put_line('header eff');
			OPEN c_doo_hdr_effs_all_interface;
			LOOP
				FETCH c_doo_hdr_effs_all_interface BULK COLLECT INTO l_doo_hdr_effs_all_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_hdr_effs_all_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_hdr_effs_all_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS HEADER DATA - Bulk Collect count '||l_count );
				end if;


				/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - EDI General CONTEXT
				-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS

						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,            
							ATTRIBUTE_TIMESTAMP1,    
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,         
							ATTRIBUTE_CHAR11,        
							ATTRIBUTE_CHAR12,         
							ATTRIBUTE_CHAR13,         
							ATTRIBUTE_CHAR14,         
							ATTRIBUTE_CHAR15,         
							ATTRIBUTE_CHAR16,         
							ATTRIBUTE_CHAR17,         
							ATTRIBUTE_CHAR18,        
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               						--SOURCE_TRANSACTION_SYSTEM,
							'EDI General',                          						--CONTEXT_CODE,            
							l_doo_hdr_effs_all_interface_tb(i).CANCEL_DATE,                 --ATTRIBUTE_TIMESTAMP1,    
							l_doo_hdr_effs_all_interface_tb(i).ORDER_STATUS,                --ATTRIBUTE_CHAR1,         
							l_doo_hdr_effs_all_interface_tb(i).DEPARTMENT_NO,               --ATTRIBUTE_CHAR2,          
							l_doo_hdr_effs_all_interface_tb(i).VENDOR_NO,                   --ATTRIBUTE_CHAR3,          
							l_doo_hdr_effs_all_interface_tb(i).BATCH_ID,                    --ATTRIBUTE_CHAR4,          
							l_doo_hdr_effs_all_interface_tb(i).DESTINATION_ACCOUNT_NO,      --ATTRIBUTE_CHAR5,          
							l_doo_hdr_effs_all_interface_tb(i).FREIGHT_CHARGE_IND,          --ATTRIBUTE_CHAR6,          
							l_doo_hdr_effs_all_interface_tb(i).GIFT_MESSAGE,                --ATTRIBUTE_CHAR7,         
							l_doo_hdr_effs_all_interface_tb(i).POA_FLAG,                    --ATTRIBUTE_CHAR8,          
							l_doo_hdr_effs_all_interface_tb(i).AGENCY_NAME,                 --ATTRIBUTE_CHAR9,          
							l_doo_hdr_effs_all_interface_tb(i).ACCOUNT_CODE,                --ATTRIBUTE_CHAR10,         
							l_doo_hdr_effs_all_interface_tb(i).BUYER_NAME,                  --ATTRIBUTE_CHAR11,        
							l_doo_hdr_effs_all_interface_tb(i).COST_CENTER_CODE,            --ATTRIBUTE_CHAR12,         
							l_doo_hdr_effs_all_interface_tb(i).EDI_DATES,                   --ATTRIBUTE_CHAR13,         
							l_doo_hdr_effs_all_interface_tb(i).EDI_PO_TYPE_CODE,            --ATTRIBUTE_CHAR14,         
							l_doo_hdr_effs_all_interface_tb(i).EDI_DC_ID,                   --ATTRIBUTE_CHAR15,         
							l_doo_hdr_effs_all_interface_tb(i).BACKORDER_CODE,              --ATTRIBUTE_CHAR16,         
							l_doo_hdr_effs_all_interface_tb(i).SALES_TYPE,                  --ATTRIBUTE_CHAR17,         
							p_sbi_uuid,                   									--ATTRIBUTE_CHAR18,        
							'STERLING',                             						--SOURCE_SYSTEM,            
							'NEW',                                  						--STATUS,					
							p_gid_id,                     									--GIS_ID,					
							p_sbi_uuid                    									--SBI_UUID                 

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
                        dbms_output.put_line(sqlerrm);
						l_errbuf := sqlerrm;
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - EDI Customer CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,         
							ATTRIBUTE_CHAR11,               
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							'EDI Customer',                          									--CONTEXT_CODE,            
							substr(l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,1,150), 	--ATTRIBUTE_CHAR1,         
							l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_EMAIL,       					--ATTRIBUTE_CHAR2,          
							l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_TELEPHONE_NO,       			--ATTRIBUTE_CHAR3,          
							l_doo_hdr_effs_all_interface_tb(i).COMPANY_CODE,       						--ATTRIBUTE_CHAR4,          
							l_doo_hdr_effs_all_interface_tb(i).BUYER_PHONE,      						--ATTRIBUTE_CHAR5,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_NO,       						--ATTRIBUTE_CHAR6,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_SAN,       						--ATTRIBUTE_CHAR7,         
							l_doo_hdr_effs_all_interface_tb(i).EDI_SHIP_ID,       						--ATTRIBUTE_CHAR8,          
							substr(l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,151,150),   --ATTRIBUTE_CHAR9,          
							substr(l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,301,150),   --ATTRIBUTE_CHAR10,         
							substr(l_doo_hdr_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,451,50),    --ATTRIBUTE_CHAR11,        
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - GS1 Data CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,           
							ATTRIBUTE_CHAR6,           
							ATTRIBUTE_CHAR7,           
							ATTRIBUTE_CHAR8,           
							ATTRIBUTE_CHAR9,           
							ATTRIBUTE_CHAR10,          
							ATTRIBUTE_CHAR11,                
							ATTRIBUTE_CHAR12,          
							ATTRIBUTE_CHAR13,          
							ATTRIBUTE_CHAR14,          
							ATTRIBUTE_CHAR15,          
                            ATTRIBUTE_CHAR16,          
                            ATTRIBUTE_CHAR17,          
                            ATTRIBUTE_CHAR18,          
                            ATTRIBUTE_CHAR19,          
                            ATTRIBUTE_CHAR20,          
                            SOURCE_SYSTEM,             
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               						--SOURCE_TRANSACTION_SYSTEM, 
							'GS1 Data',                          							--CONTEXT_CODE,             
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG10,				--ATTRIBUTE_CHAR1
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA1,				--ATTRIBUTE_CHAR2
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA2,				--ATTRIBUTE_CHAR3
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA3,				--ATTRIBUTE_CHAR4 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA4,				--ATTRIBUTE_CHAR5 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA5,				--ATTRIBUTE_CHAR6 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA6,				--ATTRIBUTE_CHAR7 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA7,				--ATTRIBUTE_CHAR8 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA8,				--ATTRIBUTE_CHAR9 
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA9,				--ATTRIBUTE_CHAR10
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_DATA10,				--ATTRIBUTE_CHAR11
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG1,				--ATTRIBUTE_CHAR12
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG2,				--ATTRIBUTE_CHAR13
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG3,				--ATTRIBUTE_CHAR14
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG4,				--ATTRIBUTE_CHAR15
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG5,				--ATTRIBUTE_CHAR16
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG6,				--ATTRIBUTE_CHAR17
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG7,				--ATTRIBUTE_CHAR18
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG8,				--ATTRIBUTE_CHAR19
							l_doo_hdr_effs_all_interface_tb(i).GS1_LABEL_TAG9,				--ATTRIBUTE_CHAR20
							'STERLING',														--SOURCE_SYSTEM   
							'NEW',     														--STATUS			
							p_gid_id,  														--GIS_ID			
							p_sbi_uuid 														--SBI_UUID        

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
                        dbms_output.put_line(sqlerrm);
						l_errbuf := sqlerrm;
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - GS1_Data CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,                    
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               						--SOURCE_TRANSACTION_SYSTEM, 
							'GS1_Data',                          							--CONTEXT_CODE,             
							l_doo_hdr_effs_all_interface_tb(i).GS1_DATA,						--ATTRIBUTE_CHAR1
							'STERLING',														--SOURCE_SYSTEM   
							'NEW',     														--STATUS			
							p_gid_id,  														--GIS_ID			
							p_sbi_uuid 														--SBI_UUID        

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
                        dbms_output.put_line(sqlerrm);
						l_errbuf := sqlerrm;
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - HDR Date CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,
							ATTRIBUTE_TIMESTAMP1,
                            ATTRIBUTE_TIMESTAMP2,
                            ATTRIBUTE_TIMESTAMP3,
                            ATTRIBUTE_TIMESTAMP4,
							ATTRIBUTE_TIMESTAMP5,
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,                   
                            SOURCE_SYSTEM,             
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID     	 
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM  
							'HDR Date',                          										--CONTEXT_CODE
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_1,								--ATTRIBUTE_TIMESTAMP1
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_2,								--ATTRIBUTE_TIMESTAMP2
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_3,								--ATTRIBUTE_TIMESTAMP3
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_4,								--ATTRIBUTE_TIMESTAMP4
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_5,								--ATTRIBUTE_TIMESTAMP5
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q1,								--ATTRIBUTE_CHAR1           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q2,								--ATTRIBUTE_CHAR2           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q3,								--ATTRIBUTE_CHAR3           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q4,								--ATTRIBUTE_CHAR4           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q5,								--ATTRIBUTE_CHAR5           
							'STERLING',																	--SOURCE_SYSTEM             
							'NEW',     																	--STATUS						
							p_gid_id,  																	--GIS_ID						
							p_sbi_uuid 																	--SBI_UUID                  															

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - HDR_2 Date CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,
							ATTRIBUTE_TIMESTAMP1,
                            ATTRIBUTE_TIMESTAMP2,
                            ATTRIBUTE_TIMESTAMP3,
                            ATTRIBUTE_TIMESTAMP4,
							ATTRIBUTE_TIMESTAMP5,
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,                   
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID     	 
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM  
							'HDR_2 Date',                          										--CONTEXT_CODE
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_6,								--ATTRIBUTE_TIMESTAMP1
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_7,								--ATTRIBUTE_TIMESTAMP2
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_8,								--ATTRIBUTE_TIMESTAMP3
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_9,								--ATTRIBUTE_TIMESTAMP4
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_10,								--ATTRIBUTE_TIMESTAMP5
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q6,								--ATTRIBUTE_CHAR1           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q7,								--ATTRIBUTE_CHAR2           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q8,								--ATTRIBUTE_CHAR3           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q9,								--ATTRIBUTE_CHAR4           
							l_doo_hdr_effs_all_interface_tb(i).HDR_DATE_Q10,								--ATTRIBUTE_CHAR5           
							'STERLING',																	--SOURCE_SYSTEM             
							'NEW',     																	--STATUS						
							p_gid_id,  																	--GIS_ID						
							p_sbi_uuid 																	--SBI_UUID                  															

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - General CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,
							ATTRIBUTE_CHAR2,
							ATTRIBUTE_DATE1,
                            SOURCE_SYSTEM,             
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
							'General',                          								--CONTEXT_CODE,             
							l_doo_hdr_effs_all_interface_tb(i).DESTINATION_ACCOUNT_NO,			--ATTRIBUTE_CHAR1
							l_doo_hdr_effs_all_interface_tb(i).AGENCY_NAME,						--ATTRIBUTE_CHAR2
							to_char(l_doo_hdr_effs_all_interface_tb(i).CANCEL_DATE,'YYYY/MM/DD'),--ATTRIBUTE_DATE1
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - EDI Promo Code CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,                       
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							'EDI Promo Code',                          									--CONTEXT_CODE,            
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE1,								--ATTRIBUTE_CHAR1,         
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE2,								--ATTRIBUTE_CHAR2,          
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE3,   							--ATTRIBUTE_CHAR3,          
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE4,								--ATTRIBUTE_CHAR4,          
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE5,								--ATTRIBUTE_CHAR5,                  
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - Ref Q CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,                       
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							'Ref Q',                          											--CONTEXT_CODE,            
							l_doo_hdr_effs_all_interface_tb(i).REF_Q1,									--ATTRIBUTE_CHAR1,         
							l_doo_hdr_effs_all_interface_tb(i).REF_Q2,									--ATTRIBUTE_CHAR2,          
							l_doo_hdr_effs_all_interface_tb(i).REF_Q3,       							--ATTRIBUTE_CHAR3,          
							l_doo_hdr_effs_all_interface_tb(i).REF_Q4,									--ATTRIBUTE_CHAR4,          
							l_doo_hdr_effs_all_interface_tb(i).REF_Q5,									--ATTRIBUTE_CHAR5,          
							l_doo_hdr_effs_all_interface_tb(i).REF_DATA1,								--ATTRIBUTE_CHAR6,          
							l_doo_hdr_effs_all_interface_tb(i).REF_DATA2,								--ATTRIBUTE_CHAR7,         
							l_doo_hdr_effs_all_interface_tb(i).REF_DATA3,								--ATTRIBUTE_CHAR8,          
							l_doo_hdr_effs_all_interface_tb(i).REF_DATA4,   							--ATTRIBUTE_CHAR9,          
							l_doo_hdr_effs_all_interface_tb(i).REF_DATA5,   							--ATTRIBUTE_CHAR10,               
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - EDI Address CONTEXT
					-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,                       
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							'EDI Address',                          									--CONTEXT_CODE,            
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_NAME,								--ATTRIBUTE_CHAR1,         
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_ADDR1,							--ATTRIBUTE_CHAR2,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_ADDR2,    						--ATTRIBUTE_CHAR3,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_ADDR3,							--ATTRIBUTE_CHAR4,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_ADDR4,							--ATTRIBUTE_CHAR5,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_CITY,								--ATTRIBUTE_CHAR6,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_STATE,							--ATTRIBUTE_CHAR7,         
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_POSTAL_CODE,						--ATTRIBUTE_CHAR8,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_COUNTRY,   						--ATTRIBUTE_CHAR9,          
							l_doo_hdr_effs_all_interface_tb(i).SHIPTO_ATTENTION,   						--ATTRIBUTE_CHAR10,               
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - Custom Order CONTEXT
					-------------------------------------------------------------------------------*/
/*				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS	
					INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR2,                    
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               						--SOURCE_TRANSACTION_SYSTEM, 
							'Custom Order',                          						--CONTEXT_CODE,             
							l_doo_hdr_effs_all_interface_tb(i).DEPARTMENT_NO,					--ATTRIBUTE_CHAR2
							'STERLING',														--SOURCE_SYSTEM   
							'NEW',     														--STATUS			
							p_gid_id,  														--GIS_ID			
							p_sbi_uuid 														--SBI_UUID        

						);


					COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
					/*	FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;*/

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - Promo Code CONTEXT
					-------------------------------------------------------------------------------*/
/*				BEGIN
					FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS	
						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,                    
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               						--SOURCE_TRANSACTION_SYSTEM, 
							'Promo Code',                          							--CONTEXT_CODE,             
							l_doo_hdr_effs_all_interface_tb(i).PROMO_CODE1,					--ATTRIBUTE_CHAR1
							'STERLING',														--SOURCE_SYSTEM   
							'NEW',     														--STATUS			
							p_gid_id,  														--GIS_ID			
							p_sbi_uuid 														--SBI_UUID        

						);*/


					/*COMMIT;

					l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						/*FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_hdr_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_hdr_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;


					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;*/

			END LOOP;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS HEADER EFFs DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS HEADER EFFs DATA - '||l_count_success||' orders succeeded');
			end if;

			CLOSE c_doo_hdr_effs_all_interface;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_hdr_effs_all_interface table loop' );
            end if;

		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_hdr_effs_all_interface%ISOPEN THEN
				   CLOSE c_doo_hdr_effs_all_interface;
				END IF;
				l_errbuf := sqlerrm;
                dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
		END;

		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS LINE DATA
		------------------------------------------------------------------------------------------------------*/
		l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;
		l_ship_date := to_char(sysdate + 1,'YYYY/MM/DD HH24:MI:SS');

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS LINE DATA - OPEN c_doo_lines_all_interface' );
			end if;

            dbms_output.put_line('line');
			OPEN c_doo_lines_all_interface;
			LOOP
				FETCH c_doo_lines_all_interface BULK COLLECT INTO l_doo_lines_all_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_lines_all_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_lines_all_interface_tb.COUNT;
                --dbms_output.put_line(l_count);

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS LINE DATA - Bulk Collect count '||l_count );
				end if;

				BEGIN
					FORALL i IN 1 .. l_doo_lines_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_FBDI
						(
							SOURCE_TRANSACTION_ID, 	
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,		
							SOURCE_TRANSACTION_SCHEDULE_ID,	
							SOURCE_TRANSACTION_SCHEDULE_NO,	
							SOURCE_TRANSACTION_LINE_NO,
							PRODUCT_NUMBER,							
							ORDERED_QUANTITY,			
							ORDERED_UOM_CODE,			
							BUSINESS_UNIT_NAME,			
							TRANSACTION_CATEGORY_CODE,
							GIS_ID,						
							SBI_UUID,					
							STATUS,						
							PAYMENT_TERM,            
							SOURCE_SYSTEM,            
							SOURCE_LINE_SEQUENCE,     
							SOURCE_PURCHASE_ORDER_NO, 
							SOURCE_ACCOUNT_NO,        
							REQUESTED_SHIP_DATE,      
							SCHEDULE_SHIP_DATE,
                            GIS_HEADER_ID
						)
						VALUES
						(
							p_sbi_uuid || l_doo_lines_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID, 	
							l_source_transaction_sys,                                       --SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_all_interface_tb(i).ROW_NO,            						--SOURCE_TRANSACTION_LINE_ID,
							p_gid_id || l_doo_lines_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_all_interface_tb(i).ROW_NO,									--SOURCE_TRANSACTION_SCHEDULE_ID,
							l_doo_lines_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_all_interface_tb(i).ROW_NO,														--SOURCE_TRANSACTION_SCHEDULE_NO
							l_doo_lines_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_all_interface_tb(i).ROW_NO,														--SOURCE_TRANSACTION_LINE_NO
							l_doo_lines_all_interface_tb(i).EAN,                            --PRODUCT_NUMBER,				
							l_doo_lines_all_interface_tb(i).ORDER_QTY,                      --ORDERED_QUANTITY,			
							'Ea',                                                           --ORDERED_UOM_CODE,			
							'HBG US BU',                                                    --BUSINESS_UNIT_NAME,			
							'ORDER',                                                        --TRANSACTION_CATEGORY_CODE,
							p_gid_id,                                                       --GIS_ID,						
							p_sbi_uuid,                                                     --SBI_UUID,					
							'NEW',                                                          --STATUS,						
							'IMMEDIATE',                                                    --PAYMENT_TERM,            
							'STERLING',                                                     --SOURCE_SYSTEM,            
							l_doo_lines_all_interface_tb(i).LINE_SEQUENCE,                  --SOURCE_LINE_SEQUENCE,     
							l_doo_lines_all_interface_tb(i).PURCHASE_ORDER_NO,              --SOURCE_PURCHASE_ORDER_NO, 
							l_doo_lines_all_interface_tb(i).STAGE_ACCOUNT_NO,               --SOURCE_ACCOUNT_NO,        
							l_ship_date,                                                    --REQUESTED_SHIP_DATE,      
							l_ship_date,                                                    --SCHEDULE_SHIP_DATE,
                            l_doo_lines_all_interface_tb(i).GIS_HEADER_UID                  --GIS_HEADER_UID
						);

					COMMIT;
					l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT;
                    --dbms_output.put_line(l_count_success);
					IF p_debug = 'true' then
						DEBUG_MSG ( 
							p_file_name => p_debug_filename,
							p_debug_msg => 'BEGIN PROCESS LINE DATA - Sucessfully inserted count '||l_count_success );
					end if;

				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                        --dbms_output.put_line('error line');
						l_errbuf := 'ERROR INSERTING LINE - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
                        --dbms_output.put_line('l_count_fail ' || l_count_fail);
                        --dbms_output.put_line('l_count_success ' || l_count_success);

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'BEGIN PROCESS LINE DATA - '||l_count_fail||' orders failed');
						end if;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'BEGIN PROCESS LINE DATA - '||l_count_success||' orders succeeded');
						end if;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;	

			CLOSE c_doo_lines_all_interface;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_lines_all_interface loop' );
            end if;
		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_lines_all_interface%ISOPEN THEN
				   CLOSE c_doo_lines_all_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
		END;

		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS LINES EFFS DATA
		------------------------------------------------------------------------------------------------------*/
		l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS LINES EFFS DATA - OPEN c_doo_lines_effs_all_interface' );
			end if;
            dbms_output.put_line('lines eff');
			OPEN c_doo_lines_effs_all_interface;
			LOOP
				FETCH c_doo_lines_effs_all_interface BULK COLLECT INTO l_doo_lines_effs_all_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_lines_effs_all_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_lines_effs_all_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS LINE EFFS DATA - Bulk Collect count '||l_count );
				end if;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - EDI General CONTEXT
			-------------------------------------------------------------------------------*/				
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,         
							ATTRIBUTE_CHAR11,        
							ATTRIBUTE_CHAR12,         
							ATTRIBUTE_CHAR13,         
							ATTRIBUTE_CHAR14,         
							ATTRIBUTE_CHAR15, 
							ATTRIBUTE_NUMBER1,
							ATTRIBUTE_NUMBER2,
                            ATTRIBUTE_NUMBER3,
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      --SOURCE_TRANSACTION_SCHEDULE_ID,
							'EDI General',                          							--CONTEXT_CODE,            
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_DESCRIPTION,      		--ATTRIBUTE_CHAR1,     
							l_doo_lines_effs_all_interface_tb(i).ITEM_UOM,      				--ATTRIBUTE_CHAR2,         
							l_doo_lines_effs_all_interface_tb(i).SALES_CHANNEL,      			--ATTRIBUTE_CHAR3,          
							l_doo_lines_effs_all_interface_tb(i).TICKET_TYPE,      				--ATTRIBUTE_CHAR4,          
							l_doo_lines_effs_all_interface_tb(i).COLOR,      					--ATTRIBUTE_CHAR5,          
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_SIZE,      			--ATTRIBUTE_CHAR6,          
							l_doo_lines_effs_all_interface_tb(i).CLASS_ID,      				--ATTRIBUTE_CHAR7,          
							l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE,      			--ATTRIBUTE_CHAR8,         
							l_doo_lines_effs_all_interface_tb(i).EAN,      						--ATTRIBUTE_CHAR9,          
							l_doo_lines_effs_all_interface_tb(i).ISBN,     						--ATTRIBUTE_CHAR10,         
							l_doo_lines_effs_all_interface_tb(i).SKU,      						--ATTRIBUTE_CHAR11,         
							l_doo_lines_effs_all_interface_tb(i).UPC,      						--ATTRIBUTE_CHAR12,        
							l_doo_lines_effs_all_interface_tb(i).SHIPTO_NO,      				--ATTRIBUTE_CHAR13,         
							l_doo_lines_effs_all_interface_tb(i).SHIPTO_SAN,      				--ATTRIBUTE_CHAR14,         
							l_doo_lines_effs_all_interface_tb(i).EDI_SHIP_ID,      				--ATTRIBUTE_CHAR15,         
							l_doo_lines_effs_all_interface_tb(i).EXTENDED_NET_COST,      		--ATTRIBUTE_NUMBER1,        
							l_doo_lines_effs_all_interface_tb(i).MASTER_PACK,      				--ATTRIBUTE_NUMBER2,         
							l_doo_lines_effs_all_interface_tb(i).INNER_PACK,      				--ATTRIBUTE_NUMBER3,          
							'STERLING',                             							--SOURCE_SYSTEM,            
							'NEW',                                  							--STATUS,					
							p_gid_id,                     										--GIS_ID,					
							p_sbi_uuid                    										--SBI_UUID                 

						);

					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - EDI Customer CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,    
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,
							ATTRIBUTE_NUMBER1,		
							ATTRIBUTE_NUMBER2,		
							ATTRIBUTE_NUMBER3,		
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,                         
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,			--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,												--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                              --SOURCE_TRANSACTION_SCHEDULE_ID,
							'EDI Customer',                          									--CONTEXT_CODE, 
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_RETAIL_PRICE,					--ATTRIBUTE_NUMBER1,
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_UNIT_NET_PRICE,               --ATTRIBUTE_NUMBER2,
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_PACK_QTY,                     --ATTRIBUTE_NUMBER3,
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_DISCOUNT,                     --ATTRIBUTE_CHAR1,  
							substr(l_doo_lines_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,1,150), 	--ATTRIBUTE_CHAR2,         
							substr(l_doo_lines_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,151,150),--ATTRIBUTE_CHAR3,                  
							substr(l_doo_lines_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,301,150),--ATTRIBUTE_CHAR4,          
							substr(l_doo_lines_effs_all_interface_tb(i).CUSTOMER_SPECIFIC_DATA,451,50),	--ATTRIBUTE_CHAR5,                      
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - GS1 Data CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,    
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,           
							ATTRIBUTE_CHAR6,           
							ATTRIBUTE_CHAR7,           
							ATTRIBUTE_CHAR8,           
							ATTRIBUTE_CHAR9,           
							ATTRIBUTE_CHAR10,          
							ATTRIBUTE_CHAR11,                
							ATTRIBUTE_CHAR12,          
							ATTRIBUTE_CHAR13,          
							ATTRIBUTE_CHAR14,          
							ATTRIBUTE_CHAR15,          
                            ATTRIBUTE_CHAR16,          
                            ATTRIBUTE_CHAR17,          
                            ATTRIBUTE_CHAR18,          
                            ATTRIBUTE_CHAR19,          
                            ATTRIBUTE_CHAR20,          
                            SOURCE_SYSTEM,             
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                  	--SOURCE_TRANSACTION_SCHEDULE_ID,
							'GS1 Data',                          								--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA1,				--ATTRIBUTE_CHAR1
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA2,				--ATTRIBUTE_CHAR2
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA3,				--ATTRIBUTE_CHAR3
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA4,				--ATTRIBUTE_CHAR4 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA5,				--ATTRIBUTE_CHAR5 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA6,				--ATTRIBUTE_CHAR6 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA7,				--ATTRIBUTE_CHAR7 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA8,				--ATTRIBUTE_CHAR8 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA9,				--ATTRIBUTE_CHAR9 
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_DATA10,				--ATTRIBUTE_CHAR10
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG1,				--ATTRIBUTE_CHAR11
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG2,				--ATTRIBUTE_CHAR12
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG3,				--ATTRIBUTE_CHAR13
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG4,				--ATTRIBUTE_CHAR14
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG5,				--ATTRIBUTE_CHAR15
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG6,				--ATTRIBUTE_CHAR16
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG7,				--ATTRIBUTE_CHAR17
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG8,				--ATTRIBUTE_CHAR18
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG9,				--ATTRIBUTE_CHAR19
							l_doo_lines_effs_all_interface_tb(i).GS1_LABEL_TAG10,				--ATTRIBUTE_CHAR20
							'STERLING',														--SOURCE_SYSTEM   
							'NEW',     														--STATUS			
							p_gid_id,  														--GIS_ID			
							p_sbi_uuid 														--SBI_UUID        

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - GS1_Data CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM, 
							SOURCE_TRANSACTION_LINE_ID,    
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,                    
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                  	--SOURCE_TRANSACTION_SCHEDULE_ID,
							'GS1_Data',                          								--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).GS1_DATA,						--ATTRIBUTE_CHAR1
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - DTL Q Date CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,
							ATTRIBUTE_TIMESTAMP1,
                            ATTRIBUTE_TIMESTAMP2,
                            ATTRIBUTE_TIMESTAMP3,
                            ATTRIBUTE_TIMESTAMP4,
							ATTRIBUTE_TIMESTAMP5,
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,                   
                            SOURCE_SYSTEM,             
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,			--SOURCE_TRANSACTION_ID     	 
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,												--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      		--SOURCE_TRANSACTION_SCHEDULE_ID,
							'DTL Q Date',                          										--CONTEXT_CODE
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_1,							--ATTRIBUTE_TIMESTAMP1
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_2,							--ATTRIBUTE_TIMESTAMP2
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_3,							--ATTRIBUTE_TIMESTAMP3
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_4,							--ATTRIBUTE_TIMESTAMP4
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_5,							--ATTRIBUTE_TIMESTAMP5
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_Q1,							--ATTRIBUTE_CHAR1           
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_Q2,							--ATTRIBUTE_CHAR2           
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_Q3,							--ATTRIBUTE_CHAR3           
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_Q4,							--ATTRIBUTE_CHAR4           
							l_doo_lines_effs_all_interface_tb(i).DTL_DATE_Q5,							--ATTRIBUTE_CHAR5           
							'STERLING',																	--SOURCE_SYSTEM             
							'NEW',     																	--STATUS						
							p_gid_id,  																	--GIS_ID						
							p_sbi_uuid 																	--SBI_UUID                  															

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - EDI Product CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,
							ATTRIBUTE_CHAR1,           
							ATTRIBUTE_CHAR2,           
							ATTRIBUTE_CHAR3,           
							ATTRIBUTE_CHAR4,           
							ATTRIBUTE_CHAR5,
							ATTRIBUTE_CHAR6, 
							ATTRIBUTE_CHAR7, 
							ATTRIBUTE_CHAR8, 
							ATTRIBUTE_CHAR9, 
							ATTRIBUTE_CHAR10,
							ATTRIBUTE_CHAR11,
							ATTRIBUTE_CHAR12,
							ATTRIBUTE_CHAR13,
							ATTRIBUTE_CHAR14,
							ATTRIBUTE_CHAR15,
							ATTRIBUTE_CHAR16,
							ATTRIBUTE_CHAR17,
							ATTRIBUTE_CHAR18,
							ATTRIBUTE_CHAR19,
							ATTRIBUTE_CHAR20,
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,			--SOURCE_TRANSACTION_ID     	 
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM 
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,												--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      		--SOURCE_TRANSACTION_SCHEDULE_ID,
							'EDI Product',                          									--CONTEXT_CODE
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL1,							--ATTRIBUTE_CHAR1           
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL2,							--ATTRIBUTE_CHAR2           
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL3,							--ATTRIBUTE_CHAR3           
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL4,							--ATTRIBUTE_CHAR4           
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL5,							--ATTRIBUTE_CHAR5 
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL6,							--ATTRIBUTE_CHAR6, 
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL7,                         --ATTRIBUTE_CHAR7, 
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL8,                         --ATTRIBUTE_CHAR8, 
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL9,                         --ATTRIBUTE_CHAR9, 
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_QUAL10,                        --ATTRIBUTE_CHAR10,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID1,                           --ATTRIBUTE_CHAR11,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID2,                           --ATTRIBUTE_CHAR12,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID3,                           --ATTRIBUTE_CHAR13,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID4,                           --ATTRIBUTE_CHAR14,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID5,                           --ATTRIBUTE_CHAR15,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID6,                           --ATTRIBUTE_CHAR16,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID7,                           --ATTRIBUTE_CHAR17,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID8,                           --ATTRIBUTE_CHAR18,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID9,                           --ATTRIBUTE_CHAR19,
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_ID10,                          --ATTRIBUTE_CHAR20,
							'STERLING',																	--SOURCE_SYSTEM             
							'NEW',     																	--STATUS						
							p_gid_id,  																	--GIS_ID						
							p_sbi_uuid 																	--SBI_UUID                  															

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;



			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Ref CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,         
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,          
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,          
							ATTRIBUTE_CHAR10,                       
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,												--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      		--SOURCE_TRANSACTION_SCHEDULE_ID,
							'Ref',                          											--CONTEXT_CODE,            
							l_doo_lines_effs_all_interface_tb(i).REF_Q1,									--ATTRIBUTE_CHAR1,         
							l_doo_lines_effs_all_interface_tb(i).REF_Q2,									--ATTRIBUTE_CHAR2,          
							l_doo_lines_effs_all_interface_tb(i).REF_Q3,       							--ATTRIBUTE_CHAR3,          
							l_doo_lines_effs_all_interface_tb(i).REF_Q4,									--ATTRIBUTE_CHAR4,          
							l_doo_lines_effs_all_interface_tb(i).REF_Q5,									--ATTRIBUTE_CHAR5,          
							l_doo_lines_effs_all_interface_tb(i).REF_DATA1,								--ATTRIBUTE_CHAR6,          
							l_doo_lines_effs_all_interface_tb(i).REF_DATA2,								--ATTRIBUTE_CHAR7,         
							l_doo_lines_effs_all_interface_tb(i).REF_DATA3,								--ATTRIBUTE_CHAR8,          
							l_doo_lines_effs_all_interface_tb(i).REF_DATA4,   							--ATTRIBUTE_CHAR9,          
							l_doo_lines_effs_all_interface_tb(i).REF_DATA5,   							--ATTRIBUTE_CHAR10,               
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Item Details CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR11,         
							ATTRIBUTE_CHAR12,          
							ATTRIBUTE_CHAR13,          
							ATTRIBUTE_CHAR14,          
							ATTRIBUTE_CHAR15,          
							ATTRIBUTE_CHAR17,                                 
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,				--SOURCE_TRANSACTION_ID,    
							l_source_transaction_sys,               									--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,												--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      		--SOURCE_TRANSACTION_SCHEDULE_ID,
							'Item Details',                          									--CONTEXT_CODE,            
							l_doo_lines_effs_all_interface_tb(i).TICKET_TYPE,							--ATTRIBUTE_CHAR11,         
							l_doo_lines_effs_all_interface_tb(i).COLOR,									--ATTRIBUTE_CHAR12,          
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_RETAIL_PRICE,  				--ATTRIBUTE_CHAR13,          
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_UNIT_NET_PRICE,				--ATTRIBUTE_CHAR14,          
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_DISCOUNT,						--ATTRIBUTE_CHAR15,          
							l_doo_lines_effs_all_interface_tb(i).PRODUCT_SIZE,						 	--ATTRIBUTE_CHAR17,                      
							'STERLING',                             									--SOURCE_SYSTEM,            
							'NEW',                                  									--STATUS,					
							p_gid_id,                     												--GIS_ID,					
							p_sbi_uuid                    												--SBI_UUID                 

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Custom Order CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,							
							CONTEXT_CODE,                 
							ATTRIBUTE_NUMBER3,                    
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM,
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      --SOURCE_TRANSACTION_SCHEDULE_ID,
							'Custom Order',                          							--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).CUSTOMER_PACK_QTY,				--ATTRIBUTE_NUMBER3
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Delivery On CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                 
							ATTRIBUTE_TIMESTAMP1,
							ATTRIBUTE_TIMESTAMP2,
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      --SOURCE_TRANSACTION_SCHEDULE_ID,
							'Delivery On',                          							--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).EARLY_DELIVERY_DATE,			--ATTRIBUTE_TIMESTAMP1
							l_doo_lines_effs_all_interface_tb(i).MUST_ARRIVE_BY_DATE,			--ATTRIBUTE_TIMESTAMP2
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Ship on CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                 
							ATTRIBUTE_TIMESTAMP2,
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      --SOURCE_TRANSACTION_SCHEDULE_ID,
							'Ship On',                          								--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).MUST_SHIP_BY_DATE,				--ATTRIBUTE_TIMESTAMP2
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);
					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI LINE EFF FILE - Sales Type CONTEXT
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_lines_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,     
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,
							SOURCE_TRANSACTION_SCHEDULE_ID,
							CONTEXT_CODE,                 
							ATTRIBUTE_CHAR1,
                            SOURCE_SYSTEM,            
                            STATUS,						
                            GIS_ID,						
                            SBI_UUID                  	
						)

						VALUES
						(
							p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID,	--SOURCE_TRANSACTION_ID,    	 
							l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,										--SOURCE_TRANSACTION_LINE_ID,    
							p_gid_id || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID || l_doo_lines_effs_all_interface_tb(i).LINE_SEQUENCE || l_doo_lines_effs_all_interface_tb(i).ROW_NO,                                      --SOURCE_TRANSACTION_SCHEDULE_ID,
							'Sales Type',                          								--CONTEXT_CODE,             
							l_doo_lines_effs_all_interface_tb(i).SALES_TYPE,					--ATTRIBUTE_CHAR1
							'STERLING',															--SOURCE_SYSTEM   
							'NEW',     															--STATUS			
							p_gid_id,  															--GIS_ID			
							p_sbi_uuid 															--SBI_UUID        

						);


					COMMIT;
					l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT;

				EXCEPTION 

					WHEN le_insert_exception THEN
					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_lines_effs_all_interface_tb(i).PURCHASE_ORDER_NO, 
																p_sbi_uuid || l_doo_lines_effs_all_interface_tb(i).GIS_HEADER_UID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP; 

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_lines_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS LINE EFFs DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS LINE EFFs DATA - '||l_count_success||' orders succeeded');
			end if;

			CLOSE c_doo_lines_effs_all_interface;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_lines_effs_all_interface table loop' );
            end if;

		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_lines_effs_all_interface%ISOPEN THEN
				   CLOSE c_doo_lines_effs_all_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
		END;


		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS ADDRESS DATA
		------------------------------------------------------------------------------------------------------*/
		l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS DATA - OPEN c_doo_addresses_all_interface' );
			end if;

            dbms_output.put_line('addresses');
			OPEN c_doo_addresses_all_interface;
			LOOP
				FETCH c_doo_addresses_all_interface BULK COLLECT INTO l_doo_addresses_all_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_addresses_all_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_addresses_all_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS ADDRESS DATA - Bulk Collect count '||l_count );
				end if;

			/*-----------------------------------------------------------------------------
					MAPPING FOR FBDI ADDRESSES FILE - SHIP_TO
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_addresses_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_ADDRESSES_FBDI
						(
							SOURCE_TRANSACTION_ID, 	
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,		
							SOURCE_TRANSACTION_SCHEDULE_ID,	
							ADDRESS_USE_TYPE,
                            SOURCE_SHIP_NO,
                            SOURCE_SHIPTO_SAN,
                            SOURCE_EDI_SHIP_ID,
							GIS_ID,			
							SBI_UUID,			
							STATUS,			
							SOURCE_SYSTEM,    
                            SOURCE_ACCOUNT_NO

						)
						VALUES
						(

							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_ID,				--SOURCE_TRANSACTION_ID, 	
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_SYSTEM,          --SOURCE_TRANSACTION_SYSTEM,
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_LINE_ID,         --SOURCE_TRANSACTION_LINE_ID,		
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_SCHEDULE_ID,     --SOURCE_TRANSACTION_SCHEDULE_ID,
							'SHIP_TO',                                                              --ADDRESS_USE_TYPE,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIP_NO,                     --SOURCE_SHIP_NO,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIPTO_SAN,                  --SOURCE_SHIPTO_SAN
                            l_doo_addresses_all_interface_tb(i).SOURCE_EDI_SHIP_ID,                 --SOURCE_EDI_SHIP_ID
							p_gid_id,                                                               --GIS_ID,			
							p_sbi_uuid ,                                                            --SBI_UUID,			
							'NEW',                                                                  --STATUS,			
							'STERLING',                                                             --SOURCE_SYSTEM,    
							l_doo_addresses_all_interface_tb(i).SOURCE_ACCOUNT_NO                   --SOURCE_ACCOUNT_NO,

						);

						COMMIT;
						l_count_success := l_count_success + l_doo_addresses_all_interface_tb.COUNT;


				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING ADDRESS LINE - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_addresses_all_interface_tb(i).SOURCE_PURCHASE_ORDER_NO, 
																l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_ID, 
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_addresses_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			/*-----------------------------------------------------------------------------
				MAPPING FOR FBDI ADDRESSES FILE - BILL_TO
			-------------------------------------------------------------------------------*/
				BEGIN
					FORALL i IN 1 .. l_doo_addresses_all_interface_tb.COUNT SAVE EXCEPTIONS
						INSERT INTO HBG_PROCESS_ORDERS_ADDRESSES_FBDI
						(
							SOURCE_TRANSACTION_ID, 	
							SOURCE_TRANSACTION_SYSTEM,
							SOURCE_TRANSACTION_LINE_ID,		
							SOURCE_TRANSACTION_SCHEDULE_ID,	
							ADDRESS_USE_TYPE,
                            SOURCE_SHIP_NO,
                            SOURCE_SHIPTO_SAN,
                            SOURCE_EDI_SHIP_ID,
							GIS_ID,			
							SBI_UUID,			
							STATUS,			
							SOURCE_SYSTEM,    
                            SOURCE_ACCOUNT_NO

						)
						VALUES
						(

							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_ID,				--SOURCE_TRANSACTION_ID, 	
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_SYSTEM,          --SOURCE_TRANSACTION_SYSTEM,
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_LINE_ID,         --SOURCE_TRANSACTION_LINE_ID,		
							l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_SCHEDULE_ID,     --SOURCE_TRANSACTION_SCHEDULE_ID,
                            'BILL_TO',                                                              --ADDRESS_USE_TYPE,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIP_NO,                     --SOURCE_SHIP_NO,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIPTO_SAN,                  --SOURCE_SHIPTO_SAN
                            l_doo_addresses_all_interface_tb(i).SOURCE_EDI_SHIP_ID,                 --SOURCE_EDI_SHIP_ID	
							p_gid_id,                                                               --GIS_ID,			
							p_sbi_uuid ,                                                            --SBI_UUID,			
							'NEW',                                                                  --STATUS,			
							'STERLING',                                                             --SOURCE_SYSTEM,    
							l_doo_addresses_all_interface_tb(i).SOURCE_ACCOUNT_NO                   --SOURCE_ACCOUNT_NO,

						);


						COMMIT;
						l_count_success := l_count_success + l_doo_addresses_all_interface_tb.COUNT;


				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING ADDRESS LINE - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_addresses_all_interface_tb(i).SOURCE_PURCHASE_ORDER_NO, 
																l_doo_addresses_all_interface_tb(i).SOURCE_TRANSACTION_ID,
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_addresses_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;	

			CLOSE c_doo_addresses_all_interface;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS DATA - '||l_count_success||' orders succeeded');
			end if;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_addresses_all_interface loop' );
            end if;
		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_addresses_all_interface%ISOPEN THEN
				   CLOSE c_doo_addresses_all_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
		END;

		/*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS ADDRESS HEADER DATA
		------------------------------------------------------------------------------------------------------*/
		/*l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - OPEN c_doo_addresses_hdr_interface' );
			end if;


			OPEN c_doo_addresses_hdr_interface;
			LOOP
				FETCH c_doo_addresses_hdr_interface BULK COLLECT INTO l_doo_addresses_hdr_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_addresses_hdr_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_addresses_hdr_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - Bulk Collect count '||l_count );
				end if;

				BEGIN
					FORALL i IN 1 .. l_doo_addresses_hdr_interface_tb.COUNT SAVE EXCEPTIONS

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI ADDRESSES FILE - HEADER BILL_TO
					-------------------------------------------------------------------------------*/

				/*		INSERT INTO HBG_PROCESS_ORDERS_ADDRESSES_FBDI
						(
							SOURCE_TRANSACTION_ID, 	
							SOURCE_TRANSACTION_SYSTEM,
							ADDRESS_USE_TYPE,
                            SOURCE_SHIP_NO,
                            SOURCE_SHIPTO_SAN,
                            SOURCE_EDI_SHIP_ID,
							GIS_ID,			
							SBI_UUID,			
							STATUS,			
							SOURCE_SYSTEM,    
                            SOURCE_ACCOUNT_NO

						)
						VALUES
						(

							l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_ID,				--SOURCE_TRANSACTION_ID, 	
							l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_SYSTEM,          --SOURCE_TRANSACTION_SYSTEM,
							l_doo_addresses_hdr_interface_tb(i).ADDRESS_USE_TYPE,                   --ADDRESS_USE_TYPE,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIP_NO,                     --SOURCE_SHIP_NO,
                            l_doo_addresses_all_interface_tb(i).SOURCE_SHIPTO_SAN,                  --SOURCE_SHIPTO_SAN
                            l_doo_addresses_all_interface_tb(i).SOURCE_EDI_SHIP_ID,                 --SOURCE_EDI_SHIP_ID
							p_gid_id,                                                               --GIS_ID,			
							p_sbi_uuid ,                                                            --SBI_UUID,			
							'NEW',                                                                  --STATUS,			
							'STERLING',                                                             --SOURCE_SYSTEM,    
							l_doo_addresses_hdr_interface_tb(i).SOURCE_ACCOUNT_NO                   --SOURCE_ACCOUNT_NO,

						);

						COMMIT;
						l_count_success := l_count_success + l_doo_addresses_hdr_interface_tb.COUNT;				
				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
				/*		FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING ADDRESS HEADER - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_addresses_hdr_interface_tb(i).SOURCE_PURCHASE_ORDER_NO, 
																l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_ID,
																p_sbi_uuid, 
																'NEW');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_addresses_hdr_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;	

			CLOSE c_doo_addresses_hdr_interface;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - '||l_count_success||' orders succeeded');
			end if;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_addresses_hdr_interface loop' );
            end if;
		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_addresses_hdr_interface%ISOPEN THEN
				   CLOSE c_doo_addresses_hdr_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
		END;*/

	/*----------------------------------------------------------------------------------------------------
				ERROR HANDLING
		-------------------------------------------------------------------------------------------------------*/

			/*-------------------------------------------------------------
				----	IF ANY RECORDS FAILED IN FBDI TABLE INSERT 
			*/-------------------------------------------------------------

			IF l_retcode = 1 THEN

				UPDATE HBG_STERLING_CONTROL 
					SET IMPORT_STATUS 	= 'ERROR',
						IMPORT_COMMENTS = 'ERROR INSERTING DATA TO FBDI TABLES - CHECK STG TABLES FOR MORE DETAILS'
					WHERE SBI_UUID = p_sbi_uuid
					AND IMPORT_STATUS = 'TRANSFERRED';	

				errbuf := 'ERROR INSERTING DATA TO FBDI TABLES - CHECK STG TABLES FOR MORE DETAILS';
                retcode := 1;
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'RECORDS FAILED IN FBDI TABLE INSERT
                    UPDATE HBG_STERLING_CONTROL - ERROR INSERTING DATA TO FBDI TABLES - CHECK STG TABLES FOR MORE DETAILS');
                end if;

                commit;


		/*----------------------------------------------------------------------------------------------------
				UPDATE CONTROL AND PROCESS TABLES WITH SUCCESS MESSAGES.
		-------------------------------------------------------------------------------------------------------*/

			ELSE
				l_update_success := UPDATE_SUCCESS_MSG(p_sbi_uuid);
                IF p_debug = 'true' then
                   DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'l_update_success := ' || l_update_success); 
                end if;
			END IF;

    dbms_output.put_line(systimestamp); 
	EXCEPTION 
		WHEN le_custom_exception THEN
            l_errbuf := SQLERRM;
			UPDATE HBG_STERLING_CONTROL 
				SET IMPORT_STATUS = 'ERROR',
					IMPORT_COMMENTS = l_errbuf
			WHERE SBI_UUID = p_sbi_uuid;
			COMMIT;
			retcode := 1;
			errbuf := SQLERRM;
                        dbms_output.put_line(sqlerrm);
		WHEN OTHERS THEN 
            l_errbuf := SQLERRM;
			UPDATE HBG_STERLING_CONTROL 
				SET IMPORT_STATUS = 'ERROR',
					IMPORT_COMMENTS = l_errbuf
			WHERE SBI_UUID = p_sbi_uuid;
			COMMIT;
			retcode := 1;
			errbuf := SQLERRM;
                        dbms_output.put_line(sqlerrm);

	END PROCESS_SBI_UUID_DATA;



-----------------------------------------------------------------------------------------------------------------------------------------------
/*									STERLING_TO_STAGE_TABLES																							*/
-----------------------------------------------------------------------------------------------------------------------------------------------



	PROCEDURE STERLING_TO_STAGE_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
        p_instanceid  IN NUMBER
		) AS

		l_fbdi_header_rec  	            HBG_PROCESS_ORDERS_HEADERS_FBDI%ROWTYPE;
		l_fbdi_lines_rec   	            HBG_PROCESS_ORDERS_LINES_FBDI%ROWTYPE;
		l_fbdi_address_rec              HBG_PROCESS_ORDERS_ADDRESSES_FBDI%ROWTYPE;
        l_fbdi_hdrs_eff_rec             HBG_PROCESS_ORDERS_HDRS_EFF_FBDI%ROWTYPE;
        l_fbdi_lines_eff_rec            HBG_PROCESS_ORDERS_LINES_EFF_FBDI%ROWTYPE;
		l_retcode			            NUMBER;
		l_fbdi_retcode		            NUMBER;
		l_fbdi_errbuf		            VARCHAR2(500);
        l_errbuf                        VARCHAR2(2000) := NULL;
		file_exception		            EXCEPTION;
		l_update_errmsg		            NUMBER;
		l_update_success	            NUMBER;
        l_transaction_id                VARCHAR2(100);
        l_debug_file_name	            VARCHAR2(100) := 'ProcessOrders_' || to_char(sysdate, 'YYMMDDHH24MMSS');
        l_source_transaction_sys        VARCHAR2(10)  := 'STEDI';
        l_line_sequence                 VARCHAR2(50)  := NULL;
        l_count_line                    NUMBER;
		l_headers_count					NUMBER;
        l_new_line_seq                  VARCHAR2(10);
        l_no_same_line                  NUMBER;
        l_line_seq_count                NUMBER;
        l_validate_errbuf               VARCHAR2(500);
        l_validate_retcode              NUMBER;
        l_hdr_bill_count                NUMBER;
        l_ship_date                     VARCHAR2(19);
        l_ftp_filename                  VARCHAR2(70);
		errbuf                          VARCHAR2(4000);
        retcode                         NUMBER;

	BEGIN 

        dbms_output.put_line(systimestamp);
        execute immediate 'alter session set optimizer_index_cost_adj=10';
		errbuf := NULL;
		retcode := 0;

        UPDATE HBG_STERLING_JOB_TRACKER SET STATUS = 'RUNNING' WHERE instanceid = p_instanceid;
        COMMIT;

        IF p_debug = 'true' then
            DEBUG_MSG ( 
                        p_file_name => l_debug_file_name,
                        p_debug_msg => 'Initiating SBI_UUID loop in HBG_STERLING_CONTROL_PROCESS table');
        end if;

        /*-----------------------------------------------------------------------------------------------------
			FOR EACH NEW GIS ID IN CONTROL TABLE
		------------------------------------------------------------------------------------------------------*/

		FOR l_gisid_rec in (
			SELECT GIS_ID, SBI_UUID
			FROM HBG_STERLING_CONTROL
			WHERE IMPORT_STATUS = 'TRANSFERRED'
		)

		LOOP
            IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => l_debug_file_name,
                            p_debug_msg => 'SBI_UUID: ' || l_gisid_rec.SBI_UUID );
            end if;

			l_retcode			:= 0;
			l_fbdi_retcode		:= 0;
			l_fbdi_errbuf		:= NULL;

			--GET HEADER COUNT FROM SBI_UUID BATCH	
			SELECT MAX(LENGTH(GIS_HEADER_UID))
					INTO l_headers_count
			FROM HBG_STERLING_DETAIL
			WHERE SBI_UUID = l_gisid_rec.SBI_UUID;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => l_debug_file_name,
                            p_debug_msg => 'Max gis header id ['||l_headers_count||'] for sbi_uuid ['||l_gisid_rec.SBI_UUID||']' );

            end if;

			--GET MAX LINE SEQUENCE FROM SBI_UUID BATCH	

			SELECT 	LENGTH(MAX(COUNT_LINES)) 
					INTO l_no_same_line
			FROM (SELECT COUNT(1) AS COUNT_LINES,
                    CASE WHEN LINE_SEQUENCE IS NULL OR LINE_SEQUENCE = 0 THEN LINE_SEQUENCE2
                    ELSE LINE_SEQUENCE END AS LINE_SEQUENCE
					FROM HBG_STERLING_DETAIL 
					WHERE SBI_UUID = l_gisid_rec.SBI_UUID
					group by LINE_SEQUENCE,LINE_SEQUENCE2);
            
            SELECT MAX(LENGTH(LINE_SEQUENCE)) AS MAX_LINE_SEQ
                   INTO l_line_seq_count  
            FROM (SELECT CASE WHEN LINE_SEQUENCE = 0 OR LINE_SEQUENCE IS NULL THEN LINE_SEQUENCE2
                              ELSE LINE_SEQUENCE END AS LINE_SEQUENCE
					FROM HBG_STERLING_DETAIL
					WHERE SBI_UUID = l_gisid_rec.SBI_UUID);
                    
			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => l_debug_file_name,
                            p_debug_msg => 'Max Line sequence ['||l_no_same_line||'] for sbi_uuid ['||l_gisid_rec.SBI_UUID||']' );

            end if;

		 -----------------------------------------------------------------------------------------------------------------------------------------------
        /*										Check for Complete Order Data													    */
        -----------------------------------------------------------------------------------------------------------------------------------------------  

		 /*UPDATE HBG_STERLING_HEADER hdr
			SET IMPORT_STATUS = 'ERROR',
				IMPORT_COMMENTS = 'MISSING SHIP LINE'
			WHERE EXISTS (SELECT )*/

		/*----------------------------------------------------------------------------------------------------
				INSERT STERLING DATA IN FBDI PROCESS TABLES
		-------------------------------------------------------------------------------------------------------*/	

			PROCESS_SBI_UUID_DATA (
					p_debug   			=> p_debug,
					p_debug_filename	=> l_debug_file_name,
					p_sbi_uuid	  		=> l_gisid_rec.SBI_UUID,
					p_gid_id			=> l_gisid_rec.GIS_ID,
					p_headers_count		=> l_headers_count,
                    p_line_seq_count    => l_line_seq_count,
					p_line_count		=> l_no_same_line,
					errbuf				=> l_fbdi_errbuf,
					retcode				=> l_fbdi_retcode
			);

			IF l_fbdi_retcode = 1 THEN
				RAISE file_exception;
			END IF;

        /*----------------------------------------------------------------------------------------------------
				VALIDATE STERLING DATA IN FBDI PROCESS TABLES
		-------------------------------------------------------------------------------------------------------*/

             VALIDATE_STERLING_DATA(l_debug_file_name, p_debug, l_gisid_rec.SBI_UUID, l_validate_errbuf, l_validate_retcode);

            IF p_debug = 'true' then
               DEBUG_MSG ( 
                p_file_name => l_debug_file_name,
                p_debug_msg => 'Validate Sterling Data for SBI_UUID ['||l_gisid_rec.SBI_UUID||']. Errbuf := ' 
                || l_validate_errbuf || '. Retcode := ' ||l_validate_retcode); 
            end if;


            /*--------------------------------------------------------------------------------------
				GENERATE FBDI PROCEDURE TO CREATE, ZIP AND SEND FBDI FILES TO FTP
			---------------------------------------------------------------------------------------*/
			generate_fbdi (
                l_gisid_rec.SBI_UUID,
                'CREATE',
				l_fbdi_errbuf,
				l_fbdi_retcode,
                l_ftp_filename
			);

             IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => l_debug_file_name,
                    p_debug_msg => 'GENERATE FBDI PROCEDURE TO CREATE, ZIP AND SEND FBDI FILES TO FTP
                    l_fbdi_errbuf := ' || l_fbdi_errbuf);
            end if;


            /*-------------------------------------------------------------
				----	IF FAIL TO CREATE/SEND FBDI FILES TO FTP
			*/-------------------------------------------------------------

            IF l_fbdi_retcode = 1 THEN

				l_errbuf := 'ERROR GENERATING FBDI FILE IN FTP - ' || l_fbdi_errbuf;

				UPDATE HBG_STERLING_CONTROL 
					SET IMPORT_STATUS 	= 'ERROR',
						IMPORT_COMMENTS	= l_errbuf
					WHERE SBI_UUID = l_gisid_rec.SBI_UUID
					AND IMPORT_STATUS = 'NEW';

                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                    p_file_name => l_debug_file_name,
                    p_debug_msg => 'FAIL TO CREATE/SEND FBDI FILES TO FTP
                    UPDATE HBG_STERLING_CONTROL - ' || l_errbuf);

                end if;

				l_update_errmsg := UPDATE_ERROR_MSG	(l_errbuf, NULL,NULL, l_gisid_rec.SBI_UUID, 'NEW','STERLING');
				errbuf := l_errbuf;
				RAISE file_exception;

            end if;
		---------- END OF GIS ID LOOP -----------------
            IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => l_debug_file_name,
                    p_debug_msg => 'END OF SBI_UUID LOOP');
            end if;
		END LOOP;

        IF p_debug = 'true' then
            DEBUG_MSG (p_file_name => l_debug_file_name,
                                  p_debug_op => 'CLOSE');  
        end if;

        UPDATE HBG_STERLING_JOB_TRACKER SET STATUS = 'COMPLETE', 
        errbuf = errbuf, retcode = retcode
        where instanceid = p_instanceid;
        COMMIT;

        dbms_output.put_line(systimestamp);

		EXCEPTION 

		WHEN file_exception THEN
            IF p_debug = 'true' then
                DEBUG_MSG (p_file_name => l_debug_file_name,
                                      p_debug_op => 'CLOSE');
            end if;

			retcode := 1;

        UPDATE HBG_STERLING_JOB_TRACKER SET STATUS = 'ERROR', 
            ERRBUF = errbuf, retcode = retcode
            where instanceid = p_instanceid;
            COMMIT;

		WHEN OTHERS THEN
            IF p_debug = 'true' then
                DEBUG_MSG (p_file_name => l_debug_file_name,
                                      p_debug_op => 'CLOSE');
            end if;
			retcode := 1;
			errbuf  := sqlerrm;
            UPDATE HBG_STERLING_JOB_TRACKER SET STATUS = 'ERROR', 
            ERRBUF = errbuf, retcode = retcode
            where instanceid = p_instanceid;
            COMMIT;

	END STERLING_TO_STAGE_TABLES;

-----------------------------------------------------------------------------------------------------------------------------------------------
/*										UPDATE CONTROL PROCESS TABLE																			*/
-----------------------------------------------------------------------------------------------------------------------------------------------

	PROCEDURE UPDATE_CTRL_PROCESS (
        p_debug       IN VARCHAR2 DEFAULT 'false',
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER
		) AS

		BEGIN 
			errbuf := NULL;
			retcode := 0;

			INSERT INTO HBG_STERLING_CONTROL (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS, SYSDATE AS IMPORT_DATE FROM HBG_STERLING_CONTROL_TABLE C
														WHERE STATUS = 'Complete'
                                                       AND  SBI_UUID NOT IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE (IMPORT_STATUS = 'PROCESSED' OR IMPORT_STATUS = 'NEW'
																															OR IMPORT_STATUS = 'TRANSFERRED')));
			COMMIT;

		EXCEPTION WHEN OTHERS THEN
			errbuf := sqlerrm;
			retcode := 1;

	END UPDATE_CTRL_PROCESS;


-----------------------------------------------------------------------------------------------------------------------------------------------
/*										UPDATE PROCESS TABLES																			*/
-----------------------------------------------------------------------------------------------------------------------------------------------

	PROCEDURE UPDATE_PROCESS_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER
		) AS

		BEGIN 
			errbuf := NULL;
			retcode := 0;

			INSERT INTO HBG_STERLING_HEADER (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS FROM HBG_STERLING_HEADER_STG C
														WHERE SBI_UUID IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE IMPORT_STATUS = 'NEW' ));


			INSERT INTO HBG_STERLING_SHIP (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS FROM HBG_STERLING_SHIP_STG C
														WHERE SBI_UUID IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE IMPORT_STATUS = 'NEW' ));	


			INSERT INTO HBG_STERLING_DETAIL (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS FROM HBG_STERLING_DETAIL_STG C
														WHERE SBI_UUID IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE IMPORT_STATUS = 'NEW' ));


			INSERT INTO HBG_STERLING_DETAIL_DIST (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS FROM HBG_STERLING_DETAIL_DIST_STG C
														WHERE SBI_UUID IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE IMPORT_STATUS = 'NEW' ));


			INSERT INTO HBG_STERLING_COMMENT (SELECT C.*, 'NEW' AS IMPORT_STATUS, NULL AS IMPORT_COMMENTS FROM HBG_STERLING_COMMENT_STG C
														WHERE SBI_UUID IN (SELECT SBI_UUID 
																				FROM HBG_STERLING_CONTROL WHERE IMPORT_STATUS = 'NEW' ));

			COMMIT;


		UPDATE HBG_STERLING_CONTROL SET IMPORT_STATUS = 'TRANSFERRED' WHERE IMPORT_STATUS = 'NEW';

		COMMIT;

		EXCEPTION WHEN OTHERS THEN
			errbuf := sqlerrm;
			retcode := 1;

	END UPDATE_PROCESS_TABLES;


-----------------------------------------------------------------------------------------------------------------------------------------------
/*										FUNCTION UPDATE ERROR STATUS																		*/
-----------------------------------------------------------------------------------------------------------------------------------------------

	FUNCTION UPDATE_ERROR_MSG
	( 	p_errbuf 			VARCHAR2,
		p_purchase_order_no	NUMBER DEFAULT NULL,
        p_transaction_id    VARCHAR2,
		p_SBI_UUID			VARCHAR2 DEFAULT NULL,
		p_import_status		VARCHAR2,
        p_source_sys        VARCHAR2
	) RETURN NUMBER AS

	BEGIN		

    IF p_source_sys = 'STERLING' THEN
		UPDATE HBG_STERLING_HEADER 
			SET IMPORT_STATUS 	= 'ERROR',
				IMPORT_COMMENTS = p_errbuf
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = p_import_status
			AND	(PURCHASE_ORDER_NO = p_purchase_order_no
						OR p_purchase_order_no IS NULL);

		UPDATE HBG_STERLING_COMMENT 
			SET IMPORT_STATUS 	= 'ERROR',
				IMPORT_COMMENTS = p_errbuf
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = p_import_status
			AND	(PURCHASE_ORDER_NO = p_purchase_order_no
						OR p_purchase_order_no IS NULL);

		UPDATE HBG_STERLING_DETAIL_DIST 
			SET IMPORT_STATUS 	= 'ERROR',
				IMPORT_COMMENTS = p_errbuf
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = p_import_status
			AND	(PURCHASE_ORDER_NO = p_purchase_order_no
						OR p_purchase_order_no IS NULL);

		UPDATE HBG_STERLING_DETAIL 
			SET IMPORT_STATUS 	= 'ERROR',
				IMPORT_COMMENTS = p_errbuf
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = p_import_status
			AND	(PURCHASE_ORDER_NO = p_purchase_order_no
						OR p_purchase_order_no IS NULL);

		UPDATE HBG_STERLING_SHIP 
			SET IMPORT_STATUS 	= 'ERROR',
				IMPORT_COMMENTS = p_errbuf
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = p_import_status
			AND	(PURCHASE_ORDER_NO = p_purchase_order_no
						OR p_purchase_order_no IS NULL);
        
    ELSIF p_source_sys = 'CX' THEN
        
        UPDATE HBG_CX_ORDER_HEADER
        SET INTEGRATION_STATUS_ERP = 'ERROR',
            IMPORT_COMMENTS = p_errbuf
        WHERE SYSTEM_ORDER_ID = p_transaction_id
          AND INTEGRATION_STATUS_ERP = p_import_status;
        
        UPDATE HBG_CX_ORDER_LINE
        SET INTEGRATION_STATUS_ERP = 'ERROR',
            IMPORT_COMMENTS = p_errbuf
        WHERE ORDER_HEADER_SOURCE_ID = p_transaction_id
          AND INTEGRATION_STATUS_ERP = p_import_status;
          
    END IF;

		DELETE FROM HBG_PROCESS_ORDERS_HEADERS_FBDI 
			WHERE 	SBI_UUID = p_SBI_UUID
			AND		(SOURCE_TRANSACTION_ID = p_transaction_id
						OR p_transaction_id IS NULL);

		DELETE FROM HBG_PROCESS_ORDERS_LINES_FBDI 
			WHERE 	SBI_UUID = p_SBI_UUID
			AND		(SOURCE_TRANSACTION_ID = p_transaction_id
						OR p_transaction_id IS NULL);

		DELETE FROM HBG_PROCESS_ORDERS_ADDRESSES_FBDI 
			WHERE 	SBI_UUID = p_SBI_UUID
			AND		(SOURCE_TRANSACTION_ID = p_transaction_id
						OR p_transaction_id IS NULL);

        DELETE FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI 
			WHERE 	SBI_UUID = p_SBI_UUID
			AND		(SOURCE_TRANSACTION_ID = p_transaction_id
						OR p_transaction_id IS NULL);

        DELETE FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI 
			WHERE 	SBI_UUID = p_SBI_UUID
			AND		(SOURCE_TRANSACTION_ID = p_transaction_id
						OR p_transaction_id IS NULL);

		commit;

			RETURN 1;

		EXCEPTION WHEN OTHERS THEN
			RETURN 0;

		END UPDATE_ERROR_MSG;

-----------------------------------------------------------------------------------------------------------------------------------------------
/*										FUNCTION UPDATE SUCCESS STATUS																		*/
-----------------------------------------------------------------------------------------------------------------------------------------------

	FUNCTION UPDATE_SUCCESS_MSG (p_SBI_UUID VARCHAR2) 
	RETURN NUMBER AS

	BEGIN		

		UPDATE HBG_STERLING_CONTROL 
					SET IMPORT_STATUS 	= 'PROCESSED',
						IMPORT_COMMENTS	= NULL
					WHERE SBI_UUID = p_SBI_UUID
					AND IMPORT_STATUS = 'TRANSFERRED';

		UPDATE HBG_STERLING_HEADER 
			SET IMPORT_STATUS 	= 'PROCESSED',
				IMPORT_COMMENTS = NULL
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = 'NEW';

		UPDATE HBG_STERLING_COMMENT 
			SET IMPORT_STATUS 	= 'PROCESSED',
				IMPORT_COMMENTS = NULL
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = 'NEW';

		UPDATE HBG_STERLING_DETAIL_DIST 
			SET IMPORT_STATUS 	= 'PROCESSED',
				IMPORT_COMMENTS = NULL
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = 'NEW';

		UPDATE HBG_STERLING_DETAIL 
			SET IMPORT_STATUS 	= 'PROCESSED',
				IMPORT_COMMENTS = NULL
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = 'NEW';

		UPDATE HBG_STERLING_SHIP 
			SET IMPORT_STATUS 	= 'PROCESSED',
				IMPORT_COMMENTS = NULL
			WHERE SBI_UUID = p_SBI_UUID
			AND IMPORT_STATUS = 'NEW';

		/*UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
			SET STATUS 	= 'TRANSFERRED'
			WHERE GIS_ID = p_gis_id
			AND STATUS = 'NEW';

		UPDATE HBG_PROCESS_ORDERS_LINES_FBDI 
			SET STATUS 	= 'TRANSFERRED'
			WHERE GIS_ID = p_gis_id
			AND STATUS = 'NEW';

		UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI 
			SET STATUS 	= 'TRANSFERRED'
			WHERE GIS_ID = p_gis_id
			AND STATUS = 'NEW';*/

		commit;

	RETURN 1;

	EXCEPTION WHEN OTHERS THEN
		RETURN 0;

	END UPDATE_SUCCESS_MSG;


 -----------------------------------------------------------------------------------------------------------------------------------------------
/*										FUNCTION DEBUG																	*/
-----------------------------------------------------------------------------------------------------------------------------------------------

    PROCEDURE DEBUG_MSG
	(   p_file_name             IN VARCHAR2,   
		p_debug_msg        	    IN VARCHAR2 DEFAULT NULL,
        p_debug_op              IN VARCHAR2 DEFAULT NULL,
        p_debug_header_fbdi     IN HBG_PROCESS_ORDERS_HEADERS_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_hdr_eff         IN HBG_PROCESS_ORDERS_HDRS_EFF_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_line_fbdi       IN HBG_PROCESS_ORDERS_LINES_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_address_fbdi    IN HBG_PROCESS_ORDERS_ADDRESSES_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_lines_eff       IN HBG_PROCESS_ORDERS_LINES_EFF_FBDI%ROWTYPE DEFAULT NULL

	) AS  

        l_debug_file            utl_file.file_type;
        l_debug_blob            BLOB;

        BEGIN

            l_debug_file := utl_file.fopen(g_directory, p_file_name, 'a', 32767);

            IF p_debug_msg IS NOT NULL THEN 
                utl_file.put_line(l_debug_file,p_debug_msg);
            ELSIF p_debug_op = 'HEADER' THEN
                IF p_debug_header_fbdi.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture header fbdi rowtype data');
                ELSE
                        utl_file.put_line(l_debug_file,'MAPPING FOR FBDI HEADER FILE');
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SOURCE_TRANSACTION_ID 		:= '|| p_debug_header_fbdi.SOURCE_TRANSACTION_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SOURCE_TRANSACTION_SYSTEM 	:= '|| p_debug_header_fbdi.SOURCE_TRANSACTION_SYSTEM);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SOURCE_TRANSACTION_NUMBER 	:= '|| p_debug_header_fbdi.SOURCE_TRANSACTION_NUMBER);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.BUYING_PARTY_ID               := '|| p_debug_header_fbdi.BUYING_PARTY_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.TRANSACTIONAL_CURRENCY_CODE	:= '|| p_debug_header_fbdi.TRANSACTIONAL_CURRENCY_CODE);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.TRANSACTION_ON				:= '|| p_debug_header_fbdi.TRANSACTION_ON);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.REQUESTING_BUSINESS_UNIT  	:= '|| p_debug_header_fbdi.REQUESTING_BUSINESS_UNIT);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.GIS_ID						:= '|| p_debug_header_fbdi.GIS_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SBI_UUID						:= '|| p_debug_header_fbdi.SBI_UUID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.STATUS						:= '|| p_debug_header_fbdi.STATUS);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.BATCH_NAME                    := '|| p_debug_header_fbdi.BATCH_NAME);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.FREEZE_PRICING                := '|| p_debug_header_fbdi.FREEZE_PRICING);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SOURCE_SYSTEM                 := '|| p_debug_header_fbdi.SOURCE_SYSTEM);
                        utl_file.put_line(l_debug_file,'    l_fbdi_header_rec.SOURCE_ACCOUNT_NO             := '|| p_debug_header_fbdi.SOURCE_ACCOUNT_NO);

                END IF;
            ELSIF p_debug_op = 'HDR_EFF' THEN
                IF p_debug_hdr_eff.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture header effs fbdi rowtype data');
                ELSE
                        utl_file.put_line(l_debug_file,'MAPPING FOR FBDI HEADER EFF FILE - ' || p_debug_hdr_eff.CONTEXT_CODE);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.SOURCE_TRANSACTION_ID     := '|| p_debug_hdr_eff.SOURCE_TRANSACTION_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.SOURCE_TRANSACTION_SYSTEM := '|| p_debug_hdr_eff.SOURCE_TRANSACTION_SYSTEM);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.CONTEXT_CODE              := '|| p_debug_hdr_eff.CONTEXT_CODE);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR1           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR1);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR2           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR2);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR3           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR3);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR4           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR4);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR5           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR5);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR6           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR6);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR7           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR7);
						utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR8           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR8);
						utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR9           := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR9);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR10          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR10);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR11          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR11);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR12          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR12);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR13          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR13);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR14          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR14);
					    utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR15          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR15);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR16          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR16);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR17          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR17);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR18          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR18);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR19          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR19);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_CHAR20          := '|| p_debug_hdr_eff.ATTRIBUTE_CHAR20);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_TIMESTAMP1      := '|| p_debug_hdr_eff.ATTRIBUTE_TIMESTAMP1);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_TIMESTAMP2      := '|| p_debug_hdr_eff.ATTRIBUTE_TIMESTAMP2);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_TIMESTAMP3      := '|| p_debug_hdr_eff.ATTRIBUTE_TIMESTAMP3);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_TIMESTAMP4      := '|| p_debug_hdr_eff.ATTRIBUTE_TIMESTAMP4);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.ATTRIBUTE_TIMESTAMP5      := '|| p_debug_hdr_eff.ATTRIBUTE_TIMESTAMP5);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.GIS_ID				      := '|| p_debug_hdr_eff.GIS_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_hdrs_eff_rec.SBI_UUID				  := '|| p_debug_hdr_eff.SBI_UUID);

                END IF;
            ELSIF p_debug_op = 'LINE' THEN
                IF p_debug_line_fbdi.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture line fbdi rowtype data');
                ELSE

                        utl_file.put_line(l_debug_file,'MAPPING FOR FBDI LINES FILE');
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_ID 			:=  '|| p_debug_line_fbdi.SOURCE_TRANSACTION_ID 			);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_SYSTEM 		:=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_SYSTEM 		);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_LINE_ID		:=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_LINE_ID		);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_SCHEDULE_ID	:=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_SCHEDULE_ID	);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_SCHEDULE_NO	:=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_SCHEDULE_NO	);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_LINE_NO		:=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_LINE_NO		);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.PRODUCT_NUMBER					:=  '|| p_debug_line_fbdi.PRODUCT_NUMBER					);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.ORDERED_QUANTITY				:=	'|| p_debug_line_fbdi.ORDERED_QUANTITY			        );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.ORDERED_UOM_CODE				:=  '|| p_debug_line_fbdi.ORDERED_UOM_CODE			        );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.BUSINESS_UNIT_NAME				:=  '|| p_debug_line_fbdi.BUSINESS_UNIT_NAME			    );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.TRANSACTION_CATEGORY_CODE		:=  '|| p_debug_line_fbdi.TRANSACTION_CATEGORY_CODE	        );
						utl_file.put_line(l_debug_file,'	l_fbdi_lines_rec.GIS_ID							:=	'|| p_debug_line_fbdi.GIS_ID						    );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.STATUS							:=	'|| p_debug_line_fbdi.STATUS						    );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.PAYMENT_TERM                   :=  '|| p_debug_line_fbdi.PAYMENT_TERM                      );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_SYSTEM                  := 	'|| p_debug_line_fbdi.SOURCE_SYSTEM                     );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_LINE_SEQUENCE           := 	'|| p_debug_line_fbdi.SOURCE_LINE_SEQUENCE              );
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SBI_UUID				        :=  '|| p_debug_line_fbdi.SBI_UUID);

                END IF;

            ELSIF p_debug_op = 'SHIPTO' THEN
                IF p_debug_address_fbdi.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture ship to address fbdi rowtype data');
                ELSE

                    utl_file.put_line(l_debug_file,'MAPPING FOR FBDI ADDRESSES FILE - SHIP_TO');
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_TRANSACTION_ID 			:=	'|| p_debug_address_fbdi.SOURCE_TRANSACTION_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_TRANSACTION_SYSTEM 		:=	'|| p_debug_address_fbdi.SOURCE_TRANSACTION_SYSTEM);
                    utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_LINE_ID		    :=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_LINE_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_SCHEDULE_ID	    :=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_SCHEDULE_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.ADDRESS_USE_TYPE					:=	'|| p_debug_address_fbdi.ADDRESS_USE_TYPE);
                    utl_file.put_line(l_debug_file,'	l_fbdi_address_rec.GIS_ID							:=	'|| p_debug_address_fbdi.GIS_ID	);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SBI_UUID				            :=  '|| p_debug_address_fbdi.SBI_UUID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.STATUS							:=	'|| p_debug_address_fbdi.STATUS);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SYSTEM                    := 	'|| p_debug_address_fbdi.SOURCE_SYSTEM);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_ACCOUNT_NO                := 	'|| p_debug_address_fbdi.SOURCE_ACCOUNT_NO);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SHIP_NO                   := 	'|| p_debug_address_fbdi.SOURCE_SHIP_NO	);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SHIPTO_SAN                := 	'|| p_debug_address_fbdi.SOURCE_SHIPTO_SAN);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_LINE_SEQUENCE             := 	'|| p_debug_address_fbdi.SOURCE_LINE_SEQUENCE);

                END IF;

            ELSIF p_debug_op = 'BILLTO' THEN
                IF p_debug_address_fbdi.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture bill to address fbdi rowtype data');
                ELSE
                    utl_file.put_line(l_debug_file,'MAPPING FOR FBDI ADDRESSES FILE - BILL_TO');
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_TRANSACTION_ID 			:=	'|| p_debug_address_fbdi.SOURCE_TRANSACTION_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_TRANSACTION_SYSTEM 		:=	'|| p_debug_address_fbdi.SOURCE_TRANSACTION_SYSTEM);
                    utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_LINE_ID		    :=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_LINE_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_lines_rec.SOURCE_TRANSACTION_SCHEDULE_ID	    :=	'|| p_debug_line_fbdi.SOURCE_TRANSACTION_SCHEDULE_ID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.ADDRESS_USE_TYPE					:=	'|| p_debug_address_fbdi.ADDRESS_USE_TYPE);
                    utl_file.put_line(l_debug_file,'	l_fbdi_address_rec.GIS_ID							:=	'|| p_debug_address_fbdi.GIS_ID	);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SBI_UUID				            :=  '|| p_debug_address_fbdi.SBI_UUID);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.STATUS							:=	'|| p_debug_address_fbdi.STATUS);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SYSTEM                    := 	'|| p_debug_address_fbdi.SOURCE_SYSTEM);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_ACCOUNT_NO                := 	'|| p_debug_address_fbdi.SOURCE_ACCOUNT_NO);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SHIP_NO                   := 	'|| p_debug_address_fbdi.SOURCE_SHIP_NO	);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_SHIPTO_SAN                := 	'|| p_debug_address_fbdi.SOURCE_SHIPTO_SAN);
                    utl_file.put_line(l_debug_file,'    l_fbdi_address_rec.SOURCE_LINE_SEQUENCE             := 	'|| p_debug_address_fbdi.SOURCE_LINE_SEQUENCE);							
                END IF;

            ELSIF p_debug_op = 'LINE_EFF' THEN
                IF p_debug_lines_eff.SOURCE_TRANSACTION_ID is null THEN
                    utl_file.put_line(l_debug_file,'Fail to capture header effs fbdi rowtype data');
                ELSE
                        utl_file.put_line(l_debug_file,'MAPPING FOR FBDI LINE EFF FILE - ' || p_debug_lines_eff.CONTEXT_CODE);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.SOURCE_TRANSACTION_ID     := '|| p_debug_lines_eff.SOURCE_TRANSACTION_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.SOURCE_TRANSACTION_SYSTEM := '|| p_debug_lines_eff.SOURCE_TRANSACTION_SYSTEM);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.SOURCE_TRANSACTION_LINE_ID := '|| p_debug_lines_eff.SOURCE_TRANSACTION_LINE_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.SOURCE_TRANSACTION_SCHEDULE_ID := '|| p_debug_lines_eff.SOURCE_TRANSACTION_SCHEDULE_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.CONTEXT_CODE              := '|| p_debug_lines_eff.CONTEXT_CODE);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR1           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR1);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR2           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR2);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR3           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR3);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR4           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR4);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR5           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR5);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR6           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR6);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR7           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR7);
						utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR8           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR8);
						utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR9           := '|| p_debug_lines_eff.ATTRIBUTE_CHAR9);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR10          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR10);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR11          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR11);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR12          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR12);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR13          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR13);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR14          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR14);
					    utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR15          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR15);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR16          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR16);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR17          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR17);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR18          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR18);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR19          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR19);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_CHAR20          := '|| p_debug_lines_eff.ATTRIBUTE_CHAR20);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_TIMESTAMP1           := '|| p_debug_lines_eff.ATTRIBUTE_TIMESTAMP1);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_TIMESTAMP2           := '|| p_debug_lines_eff.ATTRIBUTE_TIMESTAMP2);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_TIMESTAMP3           := '|| p_debug_lines_eff.ATTRIBUTE_TIMESTAMP3);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_TIMESTAMP4           := '|| p_debug_lines_eff.ATTRIBUTE_TIMESTAMP4);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_TIMESTAMP5           := '|| p_debug_lines_eff.ATTRIBUTE_TIMESTAMP5);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_NUMBER1         := '|| p_debug_lines_eff.ATTRIBUTE_NUMBER1);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_NUMBER2         := '|| p_debug_lines_eff.ATTRIBUTE_NUMBER2);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.ATTRIBUTE_NUMBER3         := '|| p_debug_lines_eff.ATTRIBUTE_NUMBER3);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.GIS_ID				       := '|| p_debug_lines_eff.GIS_ID);
                        utl_file.put_line(l_debug_file,'    l_fbdi_lines_eff_rec.SBI_UUID				   := '|| p_debug_lines_eff.SBI_UUID);


                END IF;

            END IF;

            utl_file.fclose(l_debug_file);
        IF p_debug_op = 'CLOSE' THEN

             l_debug_blob := file_to_blob(p_file_name);

            INSERT INTO HBG_PROCESS_ORDERS_DEBUG (PROCESS_ID,SOURCE, DEBUG_FILE, CREATION_DATE) 
            VALUES (TO_CHAR(sysdate,'YYMMDDHH24MISS'),'STERLING', l_debug_blob, sysdate);
            commit;

        END IF;

        EXCEPTION WHEN OTHERS THEN
            --utl_file.put_line(l_debug_file,'DEBUG FAILED');
            --utl_file.fclose(l_debug_file);
            dbms_output.put_line(sqlerrm);

        END DEBUG_MSG;

 -----------------------------------------------------------------------------------------------------------------------------------------------
/*										VALIDATE STERLING DATA																	*/
-----------------------------------------------------------------------------------------------------------------------------------------------  
 PROCEDURE VALIDATE_STERLING_DATA
	(   p_debug_filename   IN VARCHAR2 DEFAULT NULL,   
		p_debug       IN VARCHAR2 DEFAULT 'false',
        p_SBI_UUID 	  IN VARCHAR2,
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER

	) AS

    --DATA FOR SALES ORDER ADRESSES HEADER FBDI
	CURSOR c_doo_addresses_hdr_interface IS	
	SELECT DISTINCT
		adr.SOURCE_TRANSACTION_ID,
		adr.SOURCE_TRANSACTION_SYSTEM,
		adr.ADDRESS_USE_TYPE,
        adr.GIS_ID,	
        adr.SBI_UUID,
        adr.STATUS,
		adr.SOURCE_ACCOUNT_NO,
        adr.CUSTOMER_ID,
        adr.ACCOUNT_SITE_USE_ID
	FROM HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
	WHERE adr.SBI_UUID = p_sbi_uuid
	  and adr.ADDRESS_USE_TYPE = 'BILL_TO'
	  AND adr.STATUS = 'NEW';

	--DATA FOR ONE TIME ADDRESS EFF
	CURSOR c_doo_onetimeadr_hdr_eff IS	
	SELECT DISTINCT
		hef1.SOURCE_TRANSACTION_ID,    
		hef1.SOURCE_TRANSACTION_SYSTEM,
		hef1.CONTEXT_CODE,                
		hef1.ATTRIBUTE_CHAR1		AS SHIPTO_NAME,			     
		hef1.ATTRIBUTE_CHAR2		AS SHIPTO_ADDR1,		      
		hef1.ATTRIBUTE_CHAR3		AS SHIPTO_ADDR2,    	      
		hef1.ATTRIBUTE_CHAR4		AS SHIPTO_ADDR3,		      
		hef1.ATTRIBUTE_CHAR5		AS SHIPTO_ADDR4,		      
		hef1.ATTRIBUTE_CHAR6		AS SHIPTO_CITY,			      
		hef1.ATTRIBUTE_CHAR7		AS SHIPTO_STATE,		     
		hef1.ATTRIBUTE_CHAR8		AS SHIPTO_POSTAL_CODE,	      
		ftb.TERRITORY_CODE		    AS SHIPTO_COUNTRY,   	      
		hef1.ATTRIBUTE_CHAR1		AS SHIPTO_ATTENTION,
		hef2.ATTRIBUTE_CHAR4		AS COMPANY_CODE,
		hef2.ATTRIBUTE_CHAR5		AS BUYER_PHONE,
		hef1.SOURCE_SYSTEM,            
		hef1.STATUS,					
		hef1.GIS_ID,					
		hef1.SBI_UUID,
        hdr.SOURCE_ACCOUNT_NO
        
	FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef1,
		 HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef2,
         HBG_PROCESS_ORDERS_HEADERS_FBDI hdr,
		 HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr,
         FND_TERRITORIES_B ftb
	WHERE hef1.SBI_UUID = p_sbi_uuid
	  and hef1.CONTEXT_CODE = 'EDI Address'
	  AND hef1.STATUS = 'NEW'
	  AND adr.STATUS = 'NEW'
	  AND adr.ADDRESS_USE_TYPE = 'SHIP_TO'
      AND adr.PARTY_SITE_ID IS NULL
	  AND adr.SOURCE_TRANSACTION_ID = hef1.SOURCE_TRANSACTION_ID
      AND adr.SBI_UUID = hef1.SBI_UUID
	  AND hef1.SBI_UUID = hef2.SBI_UUID
	  AND hef1.SOURCE_TRANSACTION_ID = hef2.SOURCE_TRANSACTION_ID
      AND hef1.SBI_UUID = hdr.SBI_UUID
	  AND hef1.SOURCE_TRANSACTION_ID = hdr.SOURCE_TRANSACTION_ID
	  and hef2.CONTEXT_CODE = 'EDI Customer'
	  AND hef2.STATUS = 'NEW'
      AND hef1.ATTRIBUTE_CHAR2 IS NOT NULL
      AND ftb.ISO_TERRITORY_CODE = hef1.ATTRIBUTE_CHAR9;

/*-----------------------------------------------------------------------------------------------------
        CURSOR TABLE TYPES
------------------------------------------------------------------------------------------------------*/  
    TYPE lt_doo_addresses_hdr_interface_tb  	IS TABLE OF c_doo_addresses_hdr_interface%ROWTYPE;
	TYPE lt_doo_onetimeadr_hdr_eff_tb  			IS TABLE OF c_doo_onetimeadr_hdr_eff%ROWTYPE;
/*-----------------------------------------------------------------------------------------------------
        VARIABLES
------------------------------------------------------------------------------------------------------*/
    l_doo_addresses_hdr_interface_tb	lt_doo_addresses_hdr_interface_tb;
	l_doo_onetimeadr_hdr_eff_tb			lt_doo_onetimeadr_hdr_eff_tb;
    l_count									NUMBER := 0;
	l_count_success							NUMBER := 0;
	l_count_fail							NUMBER := 0;
    l_errbuf                        	VARCHAR2(2000) := NULL;
	l_retcode			            	NUMBER;
    l_update_errmsg		            	NUMBER;
    l_quantity                          NUMBER;
    l_source_transaction_line_id        VARCHAR2(50);
    l_source_line_no                    varchar2(50);
/*-----------------------------------------------------------------------------------------------------
        EXCEPTIONS
------------------------------------------------------------------------------------------------------*/
	le_custom_exception EXCEPTION;
    le_insert_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_insert_exception, -24381);

    BEGIN

        errbuf := null;
        retcode := 0;
           
     -----------------------------------------------------------------------------------------------------------------------------------------------
    /*										Check for duplicated orders under the same Gis ID													    */
    -----------------------------------------------------------------------------------------------------------------------------------------------  
        dbms_output.put_line('Check for duplicated orders under the same Gis ID - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI HDR
            SET STATUS = 'ERROR',
                ERROR_MSG = 'Duplicate order found for Account No <'
                                ||SOURCE_ACCOUNT_NO||
                                '>  and Purchase Order No <'
                                ||SOURCE_TRANSACTION_NUMBER||
                                '> under SBI_UUID '||SBI_UUID,
               SOURCE_SYSTEM_ERROR_FLAG = 'E'
        WHERE EXISTS (    
                        SELECT SOURCE_ACCOUNT_NO, SOURCE_TRANSACTION_NUMBER 
                            FROM ( SELECT SOURCE_ACCOUNT_NO, SOURCE_TRANSACTION_NUMBER, count(1) 
                                    FROM HBG_PROCESS_ORDERS_HEADERS_FBDI 
                                    WHERE SBI_UUID = p_SBI_UUID 
                                    GROUP BY SOURCE_ACCOUNT_NO, SOURCE_TRANSACTION_NUMBER
                                    HAVING COUNT(1)>1) a
                            WHERE   a.SOURCE_ACCOUNT_NO = hdr.SOURCE_ACCOUNT_NO
                                AND a.SOURCE_TRANSACTION_NUMBER = hdr.SOURCE_TRANSACTION_NUMBER
                    )
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW';

            dbms_output.put_line('END duplicated orders under the same Gis ID - ' || systimestamp);

            IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Checking for Duplicate Orders under SBI_UUID - ['||p_SBI_UUID||']');
            end if;

    -----------------------------------------------------------------------------------------------------------------------------------------------
    /*                          REQUIRED FIELDS VALIDATION                                                                                       */
    ------------------------------------------------------------------------------------------------------------------------------------------------
        --REQUIRED FIELDS WITHIN HEADER
        
         dbms_output.put_line('check for header required fields - ' || systimestamp);
        MERGE INTO HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
            USING (SELECT DISTINCT STATUS, 
                    LISTAGG(ERROR_MSG, ';') OVER (PARTITION BY SOURCE_TRANSACTION_ID) AS ERROR_MSG, 
                    SOURCE_TRANSACTION_ID
                    FROM (SELECT 'ERROR' AS STATUS, 
                                'Missing Stage Account Number' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_ID
                            FROM HBG_PROCESS_ORDERS_HEADERS_FBDI header
                            WHERE SOURCE_ACCOUNT_NO IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                        
                                 UNION
                                 
                                 SELECT 'ERROR' AS STATUS, 
                                        'Missing Purchase Order Number' AS ERROR_MSG, 
                                         SOURCE_TRANSACTION_ID
                                    FROM HBG_PROCESS_ORDERS_HEADERS_FBDI header
                                    WHERE SOURCE_TRANSACTION_NUMBER IS NULL      
                                      AND SBI_UUID = p_SBI_UUID
                                      AND status = 'NEW'
                                      
                                 UNION
                                 
                                 SELECT 'ERROR' AS STATUS, 
                                        'Missing GIS ID' AS ERROR_MSG, 
                                         SOURCE_TRANSACTION_ID
                                    FROM HBG_PROCESS_ORDERS_HEADERS_FBDI header
                                    WHERE GIS_ID IS NULL      
                                      AND SBI_UUID = p_SBI_UUID
                                      AND status = 'NEW'
                                      
                                 UNION
                                 
                                  SELECT 'ERROR' AS STATUS, 
                                        'Missing GIS HEADER ID' AS ERROR_MSG, 
                                         SOURCE_TRANSACTION_ID
                                    FROM HBG_PROCESS_ORDERS_HEADERS_FBDI header
                                    WHERE GIS_HEADER_ID IS NULL      
                                      AND SBI_UUID = p_SBI_UUID
                                       AND status = 'NEW')
             
             )header
         
         ON (header.SOURCE_TRANSACTION_ID = hdr.SOURCE_TRANSACTION_ID
                and hdr.sbi_uuid = p_SBI_UUID)
                
        WHEN MATCHED THEN UPDATE SET hdr.STATUS = header.STATUS,
                                    hdr.ERROR_MSG = header.ERROR_MSG;

        dbms_output.put_line('END check for header required fields - ' || systimestamp);
        --REQUIRED FIELDS WITHIN LINE
        
        dbms_output.put_line('check for lines required fields - ' || systimestamp);
        MERGE INTO HBG_PROCESS_ORDERS_LINES_FBDI line
            USING (SELECT DISTINCT STATUS,
                        LISTAGG(ERROR_MSG, ';') OVER (PARTITION BY SOURCE_TRANSACTION_LINE_ID) AS ERROR_MSG,
                        SOURCE_TRANSACTION_LINE_ID    
                    FROM (SELECT 'ERROR' AS STATUS, 
                            'Missing Stage Account Number' AS ERROR_MSG, 
                             SOURCE_TRANSACTION_LINE_ID
                        FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                        WHERE SOURCE_ACCOUNT_NO IS NULL      
                          AND SBI_UUID = p_SBI_UUID
                          AND status = 'NEW'
                    
                         UNION
                         
                         SELECT 'ERROR' AS STATUS, 
                                'Missing Purchase Order Number' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE SOURCE_PURCHASE_ORDER_NO IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                              
                         UNION
                         
                         SELECT 'ERROR' AS STATUS, 
                                'Missing GIS ID' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE GIS_ID IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                              
                         UNION
                         
                          SELECT 'ERROR' AS STATUS, 
                                'Missing GIS HEADER ID' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE GIS_HEADER_ID IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                              
                        UNION
                         
                          SELECT 'ERROR' AS STATUS, 
                                'Missing Product ID' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE PRODUCT_NUMBER IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                              
                        UNION
                         
                          SELECT 'ERROR' AS STATUS, 
                                'Missing Line Sequence' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE SOURCE_LINE_SEQUENCE IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                              
                        UNION
                         
                          SELECT 'ERROR' AS STATUS, 
                                'Missing Line Sequence' AS ERROR_MSG, 
                                 SOURCE_TRANSACTION_LINE_ID
                            FROM HBG_PROCESS_ORDERS_LINES_FBDI chk
                            WHERE SOURCE_LINE_SEQUENCE IS NULL      
                              AND SBI_UUID = p_SBI_UUID
                              AND status = 'NEW'
                     
             ))chk
             
             ON (chk.SOURCE_TRANSACTION_LINE_ID = line.SOURCE_TRANSACTION_LINE_ID
                    and line.sbi_uuid = p_SBI_UUID)
                    
            WHEN MATCHED THEN UPDATE SET line.STATUS = chk.STATUS,
                                        line.ERROR_MSG = chk.ERROR_MSG;
            
            dbms_output.put_line('end check for lines required fields - ' || systimestamp);
                                        
        ----LINE QUANTITY VALIDATION 25 FOR VALID HEADER VALIDATION

        dbms_output.put_line('check for line quantity - ' || systimestamp);
        
        UPDATE HBG_PROCESS_ORDERS_LINES_FBDI
            SET STATUS = 'ERROR',
                ERROR_MSG = 'Line quantity must be a positive and non-zero number'
        WHERE sbi_uuid = p_SBI_UUID
        AND STATUS = 'NEW'
        AND (ORDERED_QUANTITY <= 0 OR ORDERED_QUANTITY IS NULL)
         ; 
        
        dbms_output.put_line('END check for line quantity - ' || systimestamp);
             
        --REQUIRED FIELDS VALIDATION 2 - CHECK FOR VALID LINE OR VALID HEADER
         
         dbms_output.put_line('CHECK FOR VALID LINES - ' || systimestamp); 
         
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
        SET STATUS = 'ERROR',
            ERROR_MSG = 'Missing Valid Lines'
        WHERE hdr.sbi_uuid = p_SBI_UUID
        AND source_transaction_id not in (SELECT line.SOURCE_TRANSACTION_ID FROM HBG_PROCESS_ORDERS_LINES_FBDI line
                            WHERE line.sbi_uuid = p_SBI_UUID
                            AND line.STATUS = 'NEW')
        AND STATUS = 'NEW';
        
        dbms_output.put_line('END CHECK FOR VALID LINES - ' || systimestamp); 
        
        dbms_output.put_line('CHECK FOR VALID HEADER - ' || systimestamp); 
        UPDATE HBG_PROCESS_ORDERS_LINES_FBDI line
        SET STATUS = 'ERROR',
            ERROR_MSG = 'Missing Header Data'
        WHERE line.sbi_uuid = p_SBI_UUID
        AND line.source_transaction_id not in (SELECT hdr.SOURCE_TRANSACTION_ID FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
                            WHERE hdr.sbi_uuid = p_SBI_UUID
                            AND hdr.STATUS = 'NEW')
        AND line.STATUS = 'NEW';
        
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
            SET STATUS = 'ERROR'
            WHERE SOURCE_TRANSACTION_ID IN (SELECT DISTINCT SOURCE_TRANSACTION_ID FROM  HBG_PROCESS_ORDERS_LINES_FBDI line
                                                    WHERE line.STATUS = 'ERROR' AND hdr.SBI_UUID = line.SBI_UUID)
            AND SBI_UUID =  p_SBI_UUID
            AND status = 'NEW';  
        
        dbms_output.put_line('END CHECK FOR VALID HEADER - ' || systimestamp);
        
    -----------------------------------------------------------------------------------------------------------------------------------------------
    /*										GS1 TAGS														                        */
    -----------------------------------------------------------------------------------------------------------------------------------------------  
    
    /*=========================================================================*/
    /*          HEADER GS1 TAGS                                                 */
    /*=========================================================================*/
    
    dbms_output.put_line('CHECK HEADER GS1 TAGS - ' || systimestamp);
        MERGE INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hdr
        USING (SELECT DISTINCT STATUS, 
            'GS1 code ['|| LISTAGG(ERROR_MSG, ',') OVER (PARTITION BY SOURCE_TRANSACTION_ID) || '] does not exist on master data table' AS ERROR_MSG,
            SOURCE_TRANSACTION_ID,
            CONTEXT_CODE
        FROM (
 
        --GS1_LABEL_TAG1
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR12 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR12 )
           
        UNION  
        --GS1_LABEL_TAG2  
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR13 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR13 )
            
        UNION
        
        --GS1_LABEL_TAG3    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR14 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR14 )
        
        UNION      
        --GS1_LABEL_TAG4    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR15 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR15 )
        
        UNION
        --GS1_LABEL_TAG5    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR16 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG6
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR17 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG7
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR18 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG8
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR19 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG9
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR20 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG10
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR1 AS ERROR_MSG,
                SOURCE_TRANSACTION_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID)hef
        WHERE NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hef.ERROR_MSG )
        AND ERROR_MSG IS NOT NULL)hef
    ON (hdr.SOURCE_TRANSACTION_ID = hef.SOURCE_TRANSACTION_ID
        and hdr.sbi_uuid = p_SBI_UUID
        and hdr.CONTEXT_CODE = hef.CONTEXT_CODE)
    WHEN MATCHED THEN 
    UPDATE SET STATUS = hef.STATUS,
              ERROR_MSG = hef.ERROR_MSG;   
            
        UPDATE HBG_PROCESS_ORDERS_HDRS_EFF_FBDI 
            SET STATUS = 'ERROR', 
                ERROR_MSG = 'GS1 code found without data. Please contact the EDI/Compliance department'
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            AND(   (ATTRIBUTE_CHAR12 IS NOT NULL AND ATTRIBUTE_CHAR2 IS NULL)
                OR (ATTRIBUTE_CHAR13 IS NOT NULL AND ATTRIBUTE_CHAR3 IS NULL)
                OR (ATTRIBUTE_CHAR14 IS NOT NULL AND ATTRIBUTE_CHAR4 IS NULL)
                OR (ATTRIBUTE_CHAR15 IS NOT NULL AND ATTRIBUTE_CHAR5 IS NULL)
                OR (ATTRIBUTE_CHAR16 IS NOT NULL AND ATTRIBUTE_CHAR6 IS NULL)
                OR (ATTRIBUTE_CHAR17 IS NOT NULL AND ATTRIBUTE_CHAR7 IS NULL)
                OR (ATTRIBUTE_CHAR18 IS NOT NULL AND ATTRIBUTE_CHAR8 IS NULL)
                OR (ATTRIBUTE_CHAR18 IS NOT NULL AND ATTRIBUTE_CHAR9 IS NULL)
                OR (ATTRIBUTE_CHAR20 IS NOT NULL AND ATTRIBUTE_CHAR10 IS NULL)
                OR (ATTRIBUTE_CHAR1  IS NOT NULL AND ATTRIBUTE_CHAR11 IS NULL)
            )
            AND STATUS = 'NEW'
            ;
            
            UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
            SET STATUS = 'ERROR'
            WHERE SOURCE_TRANSACTION_ID IN (SELECT DISTINCT SOURCE_TRANSACTION_ID FROM  HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef
                                                    WHERE hef.STATUS = 'ERROR' AND hdr.SBI_UUID = hef.SBI_UUID)
            AND SBI_UUID =  p_SBI_UUID
            AND status = 'NEW';                             

        dbms_output.put_line('END CHECK HEADER GS1 TAGS - ' || systimestamp);
    /*=========================================================================*/
    /*          LINE GS1 TAGS                                                 */
    /*=========================================================================*/
    
    dbms_output.put_line('CHECK LINES GS1 TAGS - ' || systimestamp);
        MERGE INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI hdr
        USING (SELECT DISTINCT STATUS, 
            'GS1 code ['|| LISTAGG(ERROR_MSG, ',') OVER (PARTITION BY SOURCE_TRANSACTION_LINE_ID) || '] does not exist on master data table' AS ERROR_MSG,
            SOURCE_TRANSACTION_LINE_ID,
            CONTEXT_CODE
        FROM (
 
        --GS1_LABEL_TAG1
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR11 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR12 )
           
        UNION  
        --GS1_LABEL_TAG2  
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR12 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR13 )
            
        UNION
        
        --GS1_LABEL_TAG3    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR13 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR14 )
        
        UNION      
        --GS1_LABEL_TAG4    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR14 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            --AND NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hdr.ATTRIBUTE_CHAR15 )
        
        UNION
        --GS1_LABEL_TAG5    
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR15 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG6
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR16 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG7
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR17 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG8
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR18 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG9
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR19 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
        
        UNION
        --GS1_LABEL_TAG10
        SELECT 'ERROR' AS STATUS, 
                ATTRIBUTE_CHAR20 AS ERROR_MSG,
                SOURCE_TRANSACTION_LINE_ID,
                CONTEXT_CODE
        FROM HBG_PROCESS_ORDERS_LINES_EFF_FBDI
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID)hef
        WHERE NOT EXISTS (SELECT 1 FROM HBG_STERLING_GS1_DATA_TAGS WHERE CODE = hef.ERROR_MSG )
        AND ERROR_MSG IS NOT NULL)hef
    ON (hdr.SOURCE_TRANSACTION_LINE_ID = hef.SOURCE_TRANSACTION_LINE_ID
        and hdr.sbi_uuid = p_SBI_UUID
        and hdr.CONTEXT_CODE = hef.CONTEXT_CODE)
    WHEN MATCHED THEN 
    UPDATE SET STATUS = hef.STATUS,
              ERROR_MSG = hef.ERROR_MSG;   
            
        UPDATE HBG_PROCESS_ORDERS_LINES_EFF_FBDI 
            SET STATUS = 'ERROR', 
                ERROR_MSG = 'GS1 code found without data. Please contact the EDI/Compliance department'
        WHERE   CONTEXT_CODE = 'GS1 Data'
            AND SBI_UUID = p_SBI_UUID
            AND(   (ATTRIBUTE_CHAR12 IS NOT NULL AND ATTRIBUTE_CHAR2 IS NULL)
                OR (ATTRIBUTE_CHAR13 IS NOT NULL AND ATTRIBUTE_CHAR3 IS NULL)
                OR (ATTRIBUTE_CHAR14 IS NOT NULL AND ATTRIBUTE_CHAR4 IS NULL)
                OR (ATTRIBUTE_CHAR15 IS NOT NULL AND ATTRIBUTE_CHAR5 IS NULL)
                OR (ATTRIBUTE_CHAR16 IS NOT NULL AND ATTRIBUTE_CHAR6 IS NULL)
                OR (ATTRIBUTE_CHAR17 IS NOT NULL AND ATTRIBUTE_CHAR7 IS NULL)
                OR (ATTRIBUTE_CHAR18 IS NOT NULL AND ATTRIBUTE_CHAR8 IS NULL)
                OR (ATTRIBUTE_CHAR18 IS NOT NULL AND ATTRIBUTE_CHAR9 IS NULL)
                OR (ATTRIBUTE_CHAR20 IS NOT NULL AND ATTRIBUTE_CHAR10 IS NULL)
                OR (ATTRIBUTE_CHAR11  IS NOT NULL AND ATTRIBUTE_CHAR1 IS NULL)
            )
            AND STATUS = 'NEW'
            ;
            
            
            UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
            SET STATUS = 'ERROR'
            WHERE SOURCE_TRANSACTION_ID IN (SELECT DISTINCT SOURCE_TRANSACTION_ID FROM  HBG_PROCESS_ORDERS_LINES_EFF_FBDI lef
                                                    WHERE lef.STATUS = 'ERROR' AND hdr.SBI_UUID = lef.SBI_UUID)
            AND SBI_UUID =  p_SBI_UUID
            AND status = 'NEW';   
            
            dbms_output.put_line('END CHECK LINES GS1 TAGS - ' || systimestamp);
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    /*                              SEND ERROR STATUS BETWEEN TABLES                                                                                    */
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
            --UPDATE LINES TABLE
            dbms_output.put_line('LINES ERROR UPDATE - ' || systimestamp);
            UPDATE HBG_PROCESS_ORDERS_LINES_FBDI line
            SET STATUS = 'ERROR'
            WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = line.source_transaction_id and 
                            hdr.STATUS = 'ERROR')
            AND SBI_UUID = p_SBI_UUID
            AND status = 'NEW';
            dbms_output.put_line('END LINES ERROR UPDATE - ' || systimestamp);
            
            --UPDATE HEADER EFF TABLE
            dbms_output.put_line('HDRS_EFF ERROR UPDATED - ' || systimestamp);
            UPDATE HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef
            SET STATUS = 'ERROR'
            WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = hef.source_transaction_id and 
                            hdr.STATUS = 'ERROR' )
            AND SBI_UUID = p_SBI_UUID
            AND status = 'NEW'; 
            dbms_output.put_line('END HDRS_EFF ERROR UPDATE - ' || systimestamp);
            
            --UPDATE LINE EFF TABLE
            dbms_output.put_line('LINES_EFF ERROR UPDATE - ' || systimestamp);
            UPDATE HBG_PROCESS_ORDERS_LINES_EFF_FBDI lef
            SET STATUS = 'ERROR'
            WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = lef.source_transaction_id and 
                            hdr.STATUS = 'ERROR' )
            AND SBI_UUID = p_SBI_UUID
            AND status = 'NEW'; 
            dbms_output.put_line('END LINES_EFF ERROR UPDATE - ' || systimestamp);
            
            --UPDATE ADDRESS TABLE
            dbms_output.put_line('ADDRESSES ERROR UPDATE - ' || systimestamp);
            UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR'
            WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = adr.source_transaction_id and 
                            hdr.STATUS = 'ERROR' )
            AND SBI_UUID = p_SBI_UUID
            AND status = 'NEW'; 
            dbms_output.put_line('END ADDRESSES ERROR UPDATE - ' || systimestamp);
        -----------------------------------------------------------------------------------------------------------------------------------------------
        /*										Account Validation															                        */
        -----------------------------------------------------------------------------------------------------------------------------------------------  
        ----------------------------------------------------------------------------
        /*      Derive and validate SAN                                             */
        ---------------------------------------------------------------------------- 

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving party ID from shipto_san');
            end if;
        dbms_output.put_line('Derive and validate SAN - party id and ship tos address table - ' || systimestamp);    
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET PARTY_ID = (SELECT distinct hzp.party_id 
                                FROM    HZ_PARTIES HZP ,
                                        HZ_CUST_ACCOUNTS HZA,
                                        HBG_STERLING_SHIPTO_SAN SAN
                                WHERE   hzP.party_id = HZA.party_id
                                    AND hza.account_number = san.ORACLE_ACCT_NO
                                    AND adr.source_shipto_san = san.shipto_san),
            SOURCE_SHIP_NO = (SELECT SUBSTR(SITE_NUMBER,-5,5)
                                    FROM HBG_STERLING_SHIPTO_SAN SAN
                                    WHERE adr.source_shipto_san = san.shipto_san
                                    and site_number like '%-%'),
            SOURCE_ACCOUNT_NO = (SELECT distinct substr(account_number,1,8)
                                    FROM HBG_STERLING_SHIPTO_SAN SAN
                                    WHERE adr.source_shipto_san = san.shipto_san)

            WHERE   adr.SBI_UUID = p_SBI_UUID
                    and adr.status = 'NEW'
                    and adr.source_shipto_san is not null;

        dbms_output.put_line('END Derive and validate SAN - party id and ship tos address table - ' || systimestamp);   

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving buying party ID from shipto_san');
            end if;
         dbms_output.put_line('Derive and validate SAN - party id header - ' || systimestamp);    
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI HDR 
            SET BUYING_PARTY_ID = (SELECT DISTINCT PARTY_ID
                                FROM    HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
                                WHERE   adr.SBI_UUID = p_SBI_UUID
                                    AND hdr.SOURCE_TRANSACTION_ID = adr.SOURCE_TRANSACTION_ID
                                    AND adr.ADDRESS_USE_TYPE = 'SHIP_TO')
            WHERE SBI_UUID = p_SBI_UUID
            and   status = 'NEW';

        dbms_output.put_line('END Derive and validate SAN - party id header - ' || systimestamp);  

         IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating party id values for shipto_SAN');
            end if; 
            dbms_output.put_line('Derive and validate SAN - adresses null account shipto san - ' || systimestamp);  
            UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
                SET STATUS = 'ERROR',
                    ERROR_MSG = 'Account not found for SAN <'||source_shipto_san||'>' ,
                    SOURCE_SYSTEM_ERROR_FLAG = 'E'
                WHERE PARTY_ID is null
                AND SBI_UUID = p_SBI_UUID
                AND source_shipto_san IS NOT NULL
                and status = 'NEW';
        dbms_output.put_line('END Derive and validate SAN - adresses null account shipto san - ' || systimestamp);  

         IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating buying party id values');
            end if;
       dbms_output.put_line('Derive and validate SAN - header null account shipto san - ' || systimestamp);  
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI HDR 
            SET STATUS = 'ERROR',
                ERROR_MSG = 'Account not found' ,
                SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE BUYING_PARTY_ID is null
            AND EXISTS (SELECT adr.SOURCE_TRANSACTION_ID 
                            from HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr 
                                where adr.SBI_UUID = p_SBI_UUID
                                    and hdr.SOURCE_TRANSACTION_ID = adr.SOURCE_TRANSACTION_ID
                                    and adr.source_shipto_san is not null )
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW';

        dbms_output.put_line('END Derive and validate SAN - header null account shipto san - ' || systimestamp);

        ----------------------------------------------------------------------------
        /*      Derive and validate account                                       */
        ---------------------------------------------------------------------------- 

         IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving party ID from account no');
            end if;
         dbms_output.put_line('Derive and validate SAN - addresses party id account shipto no - ' || systimestamp);  
         UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
                SET PARTY_ID = (SELECT  hzp.party_id 
                                FROM    HZ_PARTIES HZP ,
                                        HZ_CUST_ACCOUNTS HZA
                                WHERE   hzP.party_id = HZA.party_id
                                    AND SUBSTR(HZA.account_number,1,8) = adr.SOURCE_ACCOUNT_NO)
                WHERE  adr.SBI_UUID = p_SBI_UUID
                    AND adr.status = 'NEW'
                    and source_shipto_san is null;
                    --and adr.ADDRESS_USE_TYPE = 'SHIP_TO'; 
        dbms_output.put_line('END Derive and validate SAN - addresses party id account shipto no - ' || systimestamp);  

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving buying party ID from account no');
            end if;
        dbms_output.put_line('Derive and validate SAN - header party id account shipto no - ' || systimestamp);  
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI HDR 
            SET BUYING_PARTY_ID = (SELECT DISTINCT PARTY_ID
                                FROM    HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
                                WHERE   adr.SBI_UUID = p_SBI_UUID
                                    AND hdr.SOURCE_TRANSACTION_ID = adr.SOURCE_TRANSACTION_ID
                                    AND adr.ADDRESS_USE_TYPE = 'SHIP_TO'
                                    AND adr.source_shipto_san is null)
            WHERE SBI_UUID = p_SBI_UUID
            AND BUYING_PARTY_ID IS NULL
            and   status = 'NEW';

        dbms_output.put_line('END Derive and validate SAN - header party id account shipto no - ' || systimestamp);  

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating buying party id values');
            end if;

        dbms_output.put_line('Derive and validate SAN - null header party id account shipto no - ' || systimestamp);     
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI HDR 
            SET STATUS = 'ERROR',
                ERROR_MSG = 'Invalid Account No <'
                            ||SOURCE_ACCOUNT_NO||
                            '>  for PO no <'
                            ||SOURCE_TRANSACTION_NUMBER||'>',
                SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE BUYING_PARTY_ID is null
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW';

        dbms_output.put_line('END Derive and validate SAN - null header party id account shipto no - ' || systimestamp);  

          IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating party id values');
            end if;  
        dbms_output.put_line('Derive and validate SAN - null addresses party id account shipto no - ' || systimestamp);     
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR',
                ERROR_MSG = 'Invalid Account No <'
                            ||SOURCE_ACCOUNT_NO|| '>' ,
                SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE PARTY_ID is null
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW'
            AND adr.ADDRESS_USE_TYPE = 'SHIP_TO';
        dbms_output.put_line('END Derive and validate SAN - null addresses party id account shipto no - ' || systimestamp);  

        /*=========================================================================*/
        /*          Derive and Validate Ship Site                                  */
        /*=========================================================================*/

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving Party Site ID from Shipto_no');
            end if;
         dbms_output.put_line('Derive and Validate Ship Site - ' || systimestamp);      
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET PARTY_SITE_ID = (SELECT  hzps.party_site_id
                                    FROM HZ_PARTY_SITES hzps 
                                    WHERE   PARTY_ID = adr.PARTY_ID
                                        AND PARTY_SITE_NUMBER = adr.SOURCE_ACCOUNT_NO||'-'|| LPAD(adr.SOURCE_SHIP_NO,5,'0')
                                        and adr.SOURCE_SHIP_NO is not null)
            WHERE   SBI_UUID = p_SBI_UUID
                and status = 'NEW'
                and adr.ADDRESS_USE_TYPE = 'SHIP_TO'; 

        dbms_output.put_line('END Derive and Validate Ship Site - ' || systimestamp); 

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating Party Site ID values');
        end if;        
        dbms_output.put_line('null Ship Site - ' || systimestamp);         
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR',
                 ERROR_MSG = 'Invalid Ship to Location',
                 SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE PARTY_SITE_ID is null
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW'
            and adr.ADDRESS_USE_TYPE = 'SHIP_TO'
            and adr.SOURCE_SHIP_NO is not null;
        dbms_output.put_line('END null Ship Site - ' || systimestamp);

         /*=========================================================================*/
        /*          Derive and Validate Customer Info                                */
        /*=========================================================================*/            

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving CUSTOMER_ID from account');
        end if;
        dbms_output.put_line('Derive and Validate Customer Info - ' || systimestamp);  
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET CUSTOMER_ID = (SELECT hza.CUST_ACCOUNT_ID
                                FROM    HZ_CUST_ACCOUNTS HZA
                                where PARTY_ID = adr.PARTY_ID
                                AND hza.ACCOUNT_NUMBER like adr.SOURCE_ACCOUNT_NO || '%'),
                PARTY_ID  = NULL     
            WHERE SBI_UUID = p_SBI_UUID
                and status = 'NEW'
                and adr.ADDRESS_USE_TYPE = 'BILL_TO';
        dbms_output.put_line('END Derive and Validate Customer Info - ' || systimestamp); 

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating CUSTOMER_ID values');
        end if;
        dbms_output.put_line('null Customer Info - ' || systimestamp);  
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR',
                 ERROR_MSG = 'Unable to retrieve customer ID from account',
                 SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE CUSTOMER_ID is null
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW'
            and adr.ADDRESS_USE_TYPE = 'BILL_TO';
        dbms_output.put_line('END null Customer Info - ' || systimestamp); 

     /*=========================================================================*/
     /*          Derive and Validate Bill to Info                               */
     /*=========================================================================*/   

      IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Deriving ACCOUNT_SITE_USE_ID from account');
        end if;
       dbms_output.put_line('Derive and Validate Bill to Info - ' || systimestamp);  
      UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET ACCOUNT_SITE_USE_ID = (SELECT hzcsua.site_use_id
                                        FROM  HZ_CUST_ACCT_SITES_ALL hzcasa,
                                        HZ_CUST_SITE_USES_ALL hzcsua
                                        where   hzcasa.CUST_ACCOUNT_ID = adr.CUSTOMER_ID
                                            AND hzcasa.cust_acct_site_id = hzcsua.cust_acct_site_id
                                            and hzcasa.BILL_TO_FLAG = 'P'
                                            and hzcsua.SITE_USE_CODE = 'BILL_TO')
            WHERE SBI_UUID = p_SBI_UUID
                and status = 'NEW'
                and adr.ADDRESS_USE_TYPE = 'BILL_TO';

    dbms_output.put_line('END Derive and Validate Bill to Info - ' || systimestamp); 

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validating ACCOUNT_SITE_USE_ID values');
        end if;
        dbms_output.put_line('null Bill to Info - ' || systimestamp);  
        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR',
                 ERROR_MSG = 'Unable to retrieve Customer Account Site Use ID from account',
                 SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE ACCOUNT_SITE_USE_ID is null
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW'
            and adr.ADDRESS_USE_TYPE = 'BILL_TO';

        dbms_output.put_line('null Bill to Info - ' || systimestamp);

     /*=========================================================================*/
     /*         Derive Address Text and Validate Ship Info                      */
     /*=========================================================================*/   

       IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Derive Address Text Lines for null Ship IDs');
        end if;
        dbms_output.put_line('Derive Address Text and Validate Ship Info - ' || systimestamp);

        l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS TEXT DATA - OPEN c_doo_onetimeadr_hdr_eff' );
			end if;


			OPEN c_doo_onetimeadr_hdr_eff;
			LOOP
				FETCH c_doo_onetimeadr_hdr_eff BULK COLLECT INTO l_doo_onetimeadr_hdr_eff_tb LIMIT 1000;
				EXIT WHEN l_doo_onetimeadr_hdr_eff_tb.COUNT = 0;

				l_count := l_count + l_doo_onetimeadr_hdr_eff_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS ADDRESS TEXT DATA - Bulk Collect count '||l_count );
				end if;

				BEGIN
					FORALL i IN 1 .. l_doo_onetimeadr_hdr_eff_tb.COUNT SAVE EXCEPTIONS

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI HEADER EFF FILE - One Time Address Context
					-------------------------------------------------------------------------------*/

						INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
						(
							SOURCE_TRANSACTION_ID,    
							SOURCE_TRANSACTION_SYSTEM,
							CONTEXT_CODE,                
							ATTRIBUTE_CHAR1,        
							ATTRIBUTE_CHAR2,          
							ATTRIBUTE_CHAR3,          
							ATTRIBUTE_CHAR4,          
							ATTRIBUTE_CHAR5,          
							ATTRIBUTE_CHAR6,         
							ATTRIBUTE_CHAR7,         
							ATTRIBUTE_CHAR8,          
							ATTRIBUTE_CHAR9,         
							ATTRIBUTE_CHAR10,       
							ATTRIBUTE_CHAR11,
							ATTRIBUTE_CHAR12,
							SOURCE_SYSTEM,            
							STATUS,					
							GIS_ID,					
							SBI_UUID                 

						)
						VALUES
						(

							l_doo_onetimeadr_hdr_eff_tb(i).SOURCE_TRANSACTION_ID,				--SOURCE_TRANSACTION_ID,    					
							l_doo_onetimeadr_hdr_eff_tb(i).SOURCE_TRANSACTION_SYSTEM,          	--SOURCE_TRANSACTION_SYSTEM,            		
							'One Time Address',                   								--CONTEXT_CODE,                             	
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_COUNTRY,						--ATTRIBUTE_CHAR1,                      		
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_ATTENTION,					--ATTRIBUTE_CHAR2,                      		
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_ADDR1,						--ATTRIBUTE_CHAR3,                      			
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_ADDR2,         				--ATTRIBUTE_CHAR4,                      		
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_ADDR3,               			--ATTRIBUTE_CHAR5,                      
                            l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_ADDR4,        				--ATTRIBUTE_CHAR6,                         	
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_CITY,                         --ATTRIBUTE_CHAR7,                      
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_STATE,                        --ATTRIBUTE_CHAR8,                      
							l_doo_onetimeadr_hdr_eff_tb(i).COMPANY_CODE,                        --ATTRIBUTE_CHAR9,                      
							l_doo_onetimeadr_hdr_eff_tb(i).BUYER_PHONE,                         --ATTRIBUTE_CHAR10,       
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_NAME,                         --ATTRIBUTE_CHAR11,
							l_doo_onetimeadr_hdr_eff_tb(i).SHIPTO_POSTAL_CODE,	                --ATTRIBUTE_CHAR12,
							l_doo_onetimeadr_hdr_eff_tb(i).SOURCE_SYSTEM,                        --SOURCE_SYSTEM,            
							l_doo_onetimeadr_hdr_eff_tb(i).STATUS,                              --STATUS,					
							l_doo_onetimeadr_hdr_eff_tb(i).GIS_ID,	                            --GIS_ID,					
							l_doo_onetimeadr_hdr_eff_tb(i).SBI_UUID                            --SBI_UUID                 

						);

						COMMIT;
						l_count_success := l_count_success + l_doo_onetimeadr_hdr_eff_tb.COUNT;				
				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING ONE TIME ADDRESS EFF - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_onetimeadr_hdr_eff_tb(i).SOURCE_ACCOUNT_NO, 
																l_doo_onetimeadr_hdr_eff_tb(i).SOURCE_TRANSACTION_ID,
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_onetimeadr_hdr_eff_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;	

			CLOSE c_doo_onetimeadr_hdr_eff;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ONE TIME ADDRESS DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ONE TIME ADDRESS DATA - '||l_count_success||' orders succeeded');
			end if;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_onetimeadr_hdr_eff loop' );
            end if;
		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_addresses_hdr_interface%ISOPEN THEN
				   CLOSE c_doo_addresses_hdr_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
        END;

        IF p_debug = 'true' then
                DEBUG_MSG ( 
                    p_file_name => p_debug_filename,
                    p_debug_msg => 'Validate Ship Info');
        end if;
        dbms_output.put_line('END Derive Address Text and Validate Ship Info - ' || systimestamp);
        dbms_output.put_line('null Address Text and Validate Ship Info - ' || systimestamp);

        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
            SET STATUS = 'ERROR',
                 ERROR_MSG = 'No Ship_to information provided',
                 SOURCE_SYSTEM_ERROR_FLAG = 'E'
            WHERE PARTY_SITE_ID is null
            AND SOURCE_SHIP_NO IS NULL
            AND SOURCE_SHIPTO_SAN IS NULL
            and NOT EXISTS(SELECT 1 FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef 
								WHERE CONTEXT_CODE = 'One Time Address' 
								AND hef.sbi_uuid = adr.sbi_uuid 
								and hef.SOURCE_TRANSACTION_ID = adr.SOURCE_TRANSACTION_ID)
            AND SBI_UUID = p_SBI_UUID
            and status = 'NEW';
            
        DELETE FROM HBG_PROCESS_ORDERS_ADDRESSES_FBDI
        WHERE SOURCE_TRANSACTION_ID IN (SELECT SOURCE_TRANSACTION_ID 
                                            FROM HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
                                            WHERE CONTEXT_CODE = 'One Time Address'
                                            AND SBI_UUID = p_sbi_uuid)
        and SBI_UUID = p_sbi_uuid
        and ADDRESS_USE_TYPE = 'SHIP_TO';

        dbms_output.put_line('END null Address Text and Validate Ship Info - ' || systimestamp);


     /*=========================================================================*/
     /*         INSERT ADDRESS HEADER BILL TO LINE                              */
     /*=========================================================================*/   

        dbms_output.put_line('INSERT ADDRESS HEADER BILL TO LINE  - ' || systimestamp);
        l_count				:= 0;
		l_count_success		:= 0;
		l_count_fail		:= 0;

		BEGIN

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - OPEN c_doo_addresses_hdr_interface' );
			end if;


			OPEN c_doo_addresses_hdr_interface;
			LOOP
				FETCH c_doo_addresses_hdr_interface BULK COLLECT INTO l_doo_addresses_hdr_interface_tb LIMIT 1000;
				EXIT WHEN l_doo_addresses_hdr_interface_tb.COUNT = 0;

				l_count := l_count + l_doo_addresses_hdr_interface_tb.COUNT;

				IF p_debug = 'true' then
					DEBUG_MSG ( 
						p_file_name => p_debug_filename,
						p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - Bulk Collect count '||l_count );
				end if;

				BEGIN
					FORALL i IN 1 .. l_doo_addresses_hdr_interface_tb.COUNT SAVE EXCEPTIONS

					/*-----------------------------------------------------------------------------
						MAPPING FOR FBDI ADDRESSES FILE - HEADER BILL_TO
					-------------------------------------------------------------------------------*/

						INSERT INTO HBG_PROCESS_ORDERS_ADDRESSES_FBDI
						(
							SOURCE_TRANSACTION_ID,
                            SOURCE_TRANSACTION_SYSTEM,
                            ADDRESS_USE_TYPE,
                            GIS_ID,	
                            SBI_UUID,
                            STATUS,
                            SOURCE_ACCOUNT_NO,
                            CUSTOMER_ID,
                            ACCOUNT_SITE_USE_ID

						)
						VALUES
						(

							l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_ID,				--SOURCE_TRANSACTION_ID,
							l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_SYSTEM,          --SOURCE_TRANSACTION_SYSTEM,
							l_doo_addresses_hdr_interface_tb(i).ADDRESS_USE_TYPE,                   --ADDRESS_USE_TYPE,
							l_doo_addresses_hdr_interface_tb(i).GIS_ID,	                   			--GIS_ID,	
							l_doo_addresses_hdr_interface_tb(i).SBI_UUID,                  			--SBI_UUID,
							l_doo_addresses_hdr_interface_tb(i).STATUS,                    			--STATUS,
							l_doo_addresses_hdr_interface_tb(i).SOURCE_ACCOUNT_NO,         			--SOURCE_ACCOUNT_NO,
							l_doo_addresses_hdr_interface_tb(i).CUSTOMER_ID,               			--CUSTOMER_ID,
                            l_doo_addresses_hdr_interface_tb(i).ACCOUNT_SITE_USE_ID        			--ACCOUNT_SITE_USE_ID

						);

						COMMIT;
						l_count_success := l_count_success + l_doo_addresses_hdr_interface_tb.COUNT;				
				EXCEPTION 

					WHEN le_insert_exception THEN

					/*-----------------------------------------------------------------------------
						UPDATE PROCESS TABLES WITH LINES ERROR MSG
					-------------------------------------------------------------------------------*/
						FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
						l_errbuf := 'ERROR INSERTING ADDRESS HEADER - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
						l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
																l_doo_addresses_hdr_interface_tb(i).SOURCE_ACCOUNT_NO, 
																l_doo_addresses_hdr_interface_tb(i).SOURCE_TRANSACTION_ID,
																p_sbi_uuid, 
																'NEW',
                                                                'STERLING');
						l_retcode := 1;
						COMMIT;

						IF p_debug = 'true' then
							DEBUG_MSG ( 
								p_file_name => p_debug_filename,
								p_debug_msg => 'l_errbuf := ' || l_errbuf || '
								l_update_errmsg := ' || l_update_errmsg );
                        end if;

						END LOOP;

						l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
						l_count_success := l_count_success + l_doo_addresses_hdr_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;

					WHEN OTHERS THEN 
						l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
						RAISE le_custom_exception;
				END;

			END LOOP;	

			CLOSE c_doo_addresses_hdr_interface;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - '||l_count_fail||' orders failed');
			end if;

			IF p_debug = 'true' then
				DEBUG_MSG ( 
					p_file_name => p_debug_filename,
					p_debug_msg => 'BEGIN PROCESS ADDRESS HEADER DATA - '||l_count_success||' orders succeeded');
			end if;

			IF p_debug = 'true' then
                DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'end of c_doo_addresses_hdr_interface loop' );
            end if;
		EXCEPTION 
			WHEN OTHERS THEN
				IF c_doo_addresses_hdr_interface%ISOPEN THEN
				   CLOSE c_doo_addresses_hdr_interface;
				END IF;
				l_errbuf := sqlerrm;
                        dbms_output.put_line(sqlerrm);
				RAISE le_custom_exception;
        END;


         dbms_output.put_line('END INSERT ADDRESS HEADER BILL TO LINE  - ' || systimestamp);
    
	/*=========================================================================*/
    /*              SEND ADDRESS ERRORS TO ORDER TABLES                         */
    /*=========================================================================*/	

        dbms_output.put_line('SEND ADDRESS ERRORS TO ORDER TABLES  - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr
        SET STATUS = 'ERROR'
        WHERE SOURCE_TRANSACTION_ID IN (SELECT DISTINCT SOURCE_TRANSACTION_ID FROM  HBG_PROCESS_ORDERS_ADDRESSES_FBDI adr
                                                WHERE adr.STATUS = 'ERROR' AND hdr.SBI_UUID = adr.SBI_UUID)
        AND SBI_UUID =  p_SBI_UUID
        and status = 'NEW';
        
        --UPDATE LINES TABLE
        dbms_output.put_line('LINES ERROR ADDRESS UPDATE - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_LINES_FBDI line
        SET STATUS = 'ERROR'
        WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = line.source_transaction_id and 
                        hdr.STATUS = 'ERROR')
        AND SBI_UUID = p_SBI_UUID
        AND status = 'NEW';
        
        --UPDATE HEADER EFF TABLE
        dbms_output.put_line('HDRS_EFF ERROR ADDRESS UPDATED - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_HDRS_EFF_FBDI hef
        SET STATUS = 'ERROR'
        WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = hef.source_transaction_id and 
                        hdr.STATUS = 'ERROR' )
        AND SBI_UUID = p_SBI_UUID
        AND status = 'NEW'; 
        
        --UPDATE LINE EFF TABLE
        dbms_output.put_line('LINES_EFF ERROR ADDRESS UPDATE - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_LINES_EFF_FBDI lef
        SET STATUS = 'ERROR'
        WHERE EXISTS(SELECT hdr.source_transaction_id FROM HBG_PROCESS_ORDERS_HEADERS_FBDI hdr WHERE HDR.source_transaction_id = lef.source_transaction_id and 
                        hdr.STATUS = 'ERROR' )
        AND SBI_UUID = p_SBI_UUID
        AND status = 'NEW'; 
        
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------
  /*                LINE QUANTITY GRATER THAN 6 DIGITS                                                                                                              */
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------
        dbms_output.put_line('LINE QUANTITY GRATER THAN 6 DIGITS   - ' || systimestamp);
        FOR l_rec in (
                        SELECT * 
                        FROM HBG_PROCESS_ORDERS_LINES_FBDI
                        WHERE ORDERED_QUANTITY > 999999
                        AND STATUS = 'NEW'
                        AND sbi_uuid = p_SBI_UUID
                    )
                    
            LOOP
            
            BEGIN
            
                l_quantity := l_rec.ORDERED_QUANTITY;
                l_count := 1;
                WHILE l_quantity > 999999 LOOP
                    l_source_transaction_line_id := l_rec.SOURCE_TRANSACTION_LINE_ID || '-' || l_count;
                    l_source_line_no := l_rec.SOURCE_TRANSACTION_LINE_NO || '-' || l_count;
                    INSERT INTO HBG_PROCESS_ORDERS_LINES_FBDI 
                    (   SOURCE_TRANSACTION_ID,
                        SOURCE_TRANSACTION_SYSTEM,
                        SOURCE_TRANSACTION_LINE_ID,
                        SOURCE_TRANSACTION_SCHEDULE_ID,
                        SOURCE_TRANSACTION_SCHEDULE_NO,
                        SOURCE_TRANSACTION_LINE_NO,
                        PRODUCT_NUMBER,
                        ORDERED_QUANTITY,
                        ORDERED_UOM_CODE,
                        BUSINESS_UNIT_NAME,
                        REQUESTED_SHIP_DATE,
                        SCHEDULE_SHIP_DATE,
                        PAYMENT_TERM,
                        TRANSACTION_CATEGORY_CODE,
                        STATUS,
                        GIS_ID,
                        SOURCE_SYSTEM,
                        SOURCE_LINE_SEQUENCE,
                        SOURCE_PURCHASE_ORDER_NO,
                        SOURCE_ACCOUNT_NO,
                        SBI_UUID) 
                        VALUES
                        (
                            l_rec.SOURCE_TRANSACTION_ID,
                            l_rec.SOURCE_TRANSACTION_SYSTEM,
                            l_source_transaction_line_id,
                            l_source_transaction_line_id,
                            l_source_line_no,
                            l_source_line_no,
                            l_rec.PRODUCT_NUMBER,
                            999999,
                            l_rec.ORDERED_UOM_CODE,
                            l_rec.BUSINESS_UNIT_NAME,
                            l_rec.REQUESTED_SHIP_DATE,
                            l_rec.SCHEDULE_SHIP_DATE,
                            l_rec.PAYMENT_TERM,
                            l_rec.TRANSACTION_CATEGORY_CODE,
                            l_rec.STATUS,
                            l_rec.GIS_ID,
                            l_rec.SOURCE_SYSTEM,
                            l_rec.SOURCE_LINE_SEQUENCE,
                            l_rec.SOURCE_PURCHASE_ORDER_NO,
                            l_rec.SOURCE_ACCOUNT_NO,
                            l_rec.SBI_UUID);
                            
                    INSERT INTO HBG_PROCESS_ORDERS_ADDRESSES_FBDI (SOURCE_TRANSACTION_ID,
                                                                            SOURCE_TRANSACTION_SYSTEM,
                                                                            SOURCE_TRANSACTION_LINE_ID,
                                                                            SOURCE_TRANSACTION_SCHEDULE_ID,
                                                                            ADDRESS_USE_TYPE,
                                                                            PARTY_ID,
                                                                            CUSTOMER_ID,
                                                                            PARTY_SITE_ID,
                                                                            ACCOUNT_SITE_USE_ID,
                                                                            STATUS,
                                                                            GIS_ID,
                                                                            SOURCE_SYSTEM,
                                                                            SOURCE_ACCOUNT_NO,
                                                                            SOURCE_SHIP_NO,
                                                                            SOURCE_SHIPTO_SAN,
                                                                            SOURCE_LINE_SEQUENCE,
                                                                            SOURCE_EDI_SHIP_ID,
                                                                            SBI_UUID) 
                                                                            
                    SELECT 
                            SOURCE_TRANSACTION_ID,
                            SOURCE_TRANSACTION_SYSTEM,
                            l_source_transaction_line_id,
                            l_source_transaction_line_id,
                            ADDRESS_USE_TYPE,
                            PARTY_ID,
                            CUSTOMER_ID,
                            PARTY_SITE_ID,
                            ACCOUNT_SITE_USE_ID,
                            STATUS,
                            GIS_ID,
                            SOURCE_SYSTEM,
                            SOURCE_ACCOUNT_NO,
                            SOURCE_SHIP_NO,
                            SOURCE_SHIPTO_SAN,
                            SOURCE_LINE_SEQUENCE,
                            SOURCE_EDI_SHIP_ID,
                            SBI_UUID
                    FROM    HBG_PROCESS_ORDERS_ADDRESSES_FBDI
                    WHERE SOURCE_TRANSACTION_LINE_ID = l_rec.SOURCE_TRANSACTION_LINE_ID
                    AND sbi_uuid = p_SBI_UUID;
                    l_quantity := l_quantity - 999999;
                    l_count := l_count + 1;
                END LOOP;
                    
                UPDATE HBG_PROCESS_ORDERS_LINES_FBDI 
                    SET ORDERED_QUANTITY = l_quantity
                WHERE sbi_uuid =  p_SBI_UUID
                  AND SOURCE_TRANSACTION_LINE_ID = l_rec.SOURCE_TRANSACTION_LINE_ID
                  AND STATUS = 'NEW'; 
                COMMIT;
                
            EXCEPTION WHEN OTHERS THEN
                l_errbuf := SQLERRM;
                UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
                    SET STATUS = 'ERROR',
                        ERROR_MSG = l_errbuf
                WHERE sbi_uuid = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                
                UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI 
                    SET STATUS = 'ERROR',
                        ERROR_MSG = l_errbuf
                WHERE sbi_uuid = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                    
                UPDATE HBG_PROCESS_ORDERS_LINES_FBDI 
                    SET STATUS = 'ERROR',
                        ERROR_MSG = l_errbuf
                WHERE sbi_uuid = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                
                UPDATE HBG_PROCESS_ORDERS_LINES_EFF_FBDI 
                    SET STATUS = 'ERROR',
                        ERROR_MSG = l_errbuf
                WHERE sbi_uuid = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                    
                UPDATE HBG_PROCESS_ORDERS_HDRS_EFF_FBDI 
                    SET STATUS = 'ERROR',
                        ERROR_MSG = l_errbuf
                WHERE sbi_uuid = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                        
              END;                         
            END LOOP;
    
    dbms_output.put_line('END LINE QUANTITY GRATER THAN 6 DIGITS   - ' || systimestamp);
        
    /*=========================================================================*/
    /*              Update Status field with 'Validated'                       */
    /*=========================================================================*/
        dbms_output.put_line('Update Status field with Validated - ' || systimestamp);
        UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
        SET STATUS = 'VALIDATED'
        WHERE STATUS = 'NEW'
        AND SBI_UUID = p_SBI_UUID;

        UPDATE HBG_PROCESS_ORDERS_LINES_FBDI 
        SET STATUS = 'VALIDATED'
        WHERE STATUS = 'NEW'
        AND SBI_UUID = p_SBI_UUID;

        UPDATE HBG_PROCESS_ORDERS_HDRS_EFF_FBDI 
        SET STATUS = 'VALIDATED'
        WHERE STATUS = 'NEW'
        AND SBI_UUID = p_SBI_UUID;

        UPDATE HBG_PROCESS_ORDERS_LINES_EFF_FBDI 
        SET STATUS = 'VALIDATED'
        WHERE STATUS = 'NEW'
        AND SBI_UUID = p_SBI_UUID;

        UPDATE HBG_PROCESS_ORDERS_ADDRESSES_FBDI 
        SET STATUS = 'VALIDATED'
        WHERE STATUS = 'NEW'
        AND SBI_UUID = p_SBI_UUID;

        dbms_output.put_line('END Update Status field with Validated - ' || systimestamp);
        COMMIT;

    EXCEPTION 
        WHEN le_custom_exception THEN
            l_errbuf := SQLERRM;
			UPDATE HBG_STERLING_CONTROL 
				SET IMPORT_STATUS = 'ERROR',
					IMPORT_COMMENTS = l_errbuf
			WHERE SBI_UUID = p_sbi_uuid;
			COMMIT;
			retcode := 1;
			errbuf := SQLERRM;
            dbms_output.put_line(sqlerrm);
        WHEN OTHERS THEN
            retcode := 1;
            errbuf := sqlerrm;
            dbms_output.put_line(sqlerrm);

    END VALIDATE_STERLING_DATA;

 PROCEDURE UPDATE_STG_ERP_INT_DATA (
    p_filename IN VARCHAR2,
    p_batch_name IN VARCHAR2,
    p_load_request_id in NUMBER,
    errbuf     OUT VARCHAR2,
    retcode    OUT NUMBER,
    report_flag OUT VARCHAR2
    ) AS

    I_USER VARCHAR2(200);
    I_HOST VARCHAR2(200);
    I_PORT NUMBER;
    I_TRUST_SERVER BOOLEAN;
    l_report_flag VARCHAR2(5);
    l_ftp_folder    VARCHAR2(30);
    l_put_file NUMBER := 0;
    l_retry    number := 0;
    l_file_blob BLOB;

    BEGIN
 /*-----------------------------------------------------------------------------------------------------
			FTP CONNECTION AND CREDENTIALS
	------------------------------------------------------------------------------------------------------*/	
        SELECT  LOOKUP_VALUE,
                LOOKUP_VALUE1,
                TO_NUMBER(LOOKUP_VALUE2)
        INTO    I_USER,
                I_HOST,
                I_PORT
        FROM HBG_PROCESS_ORDERS_LOOKUP
        WHERE LOOKUP_CODE = 'FTP_CONNECTION';

        I_TRUST_SERVER := TRUE;

    /*-----------------------------------------------------------------------------------------------------
			FTP FOLDER
	------------------------------------------------------------------------------------------------------*/	
        SELECT LOOKUP_VALUE
        INTO   l_ftp_folder
        FROM HBG_PROCESS_ORDERS_LOOKUP
        WHERE LOOKUP_CODE = 'FTP_FOLDER';
	/*----------------------------------------------------------------------
					LOG IN FTP SERVER
    ------------------------------------------------------------------------*/  

        WHILE l_put_file = 0 and l_retry < 6 
        LOOP 

        BEGIN

             AS_SFTP_KEYMGMT.LOGIN(
                I_USER => I_USER,
                I_HOST => I_HOST,
                I_PORT => I_PORT,
                I_TRUST_SERVER => I_TRUST_SERVER
            );

        /*----------------------------------------------------------------------
					READ FILE IN FTP SERVER
		------------------------------------------------------------------------*/  
        as_sftp.get_file( '/OIC_IB/'||l_ftp_folder||'/reports/'||p_filename, i_file => l_file_blob );
        l_report_flag := 'true';
        l_put_file := 1;

        EXCEPTION WHEN OTHERS THEN
            l_retry := l_retry + 1;
            dbms_session.sleep(l_retry*60);
            dbms_output.put_line('retry: ' || l_retry ||' date: '|| systimestamp ); 
            l_put_file := 0;

            if l_retry = 6 then
                errbuf := sqlerrm;
                retcode := 1;
                dbms_output.put_line(sqlerrm); 

            end if;

        END;
    END LOOP;

    IF l_report_flag = 'true' THEN 
    --EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_PROCESS_ORDERS_REPORT_STG';
    INSERT INTO HBG_PROCESS_ORDERS_REPORT_STG
                (select COL001,  
                        COL003, 
                        COL004, 
                        COL002
                    from table( 
                           APEX_DATA_PARSER.parse(
                              p_content         => l_file_blob ,
                              p_file_name       => p_filename,
                              P_ADD_HEADERS_ROW => 'N',
                              p_skip_rows  => 1)));
              COMMIT;

    UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI hdr SET STATUS = 'ERROR',
        ERROR_MSG = (SELECT MESSAGE_TEXT 
                FROM HBG_PROCESS_ORDERS_REPORT_STG rpt
                WHERE rpt.SOURCE_TRANSACTION_ID = hdr.SOURCE_TRANSACTION_ID
                AND hdr.SBI_UUID = rpt.BATCH_NAME
                AND rpt.LOAD_REQUEST_ID =  p_load_request_id)
            WHERE SBI_UUID = p_batch_name
            AND EXISTS (SELECT rpt.SOURCE_TRANSACTION_ID FROM HBG_PROCESS_ORDERS_REPORT_STG rpt
                            WHERE rpt.SOURCE_TRANSACTION_ID = hdr.SOURCE_TRANSACTION_ID
                            and rpt.BATCH_NAME = p_batch_name
                            and hdr.SBI_UUID = rpt.BATCH_NAME
                            AND rpt.LOAD_REQUEST_ID =  p_load_request_id);
        COMMIT;

    report_flag := 'true';
    ELSE 
        report_flag := 'false';

     END IF;   

    EXCEPTION WHEN OTHERS THEN
        errbuf := sqlerrm;
        retcode := 1;
        report_flag := 'false';

    END UPDATE_STG_ERP_INT_DATA;

    PROCEDURE SUBMIT_ORDERS (p_SBI_UUID IN VARCHAR2,p_password IN VARCHAR2 )
    AS

    l_envelop CLOB;
    l_xml        XMLTYPE;
    l_status VARCHAR2(30);
    l_message_text  VARCHAR2(4000);
    l_sqlerrm       VARCHAR2(4000);
    l_xml_error     VARCHAR2(4000);

    BEGIN
        dbms_output.put_line('LOOP'); 
        FOR l_rec in (
            SELECT
                 SOURCE_TRANSACTION_ID,
                 SOURCE_TRANSACTION_SYSTEM
            FROM HBG_PROCESS_ORDERS_HEADERS_FBDI
            WHERE SBI_UUID = p_SBI_UUID
            AND STATUS = 'VALIDATED')
        LOOP
            BEGIN
            dbms_output.put_line('l_envelop'); 
             l_envelop := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/scm/fom/importOrders/orderImportService/types/" xmlns:ord="http://xmlns.oracle.com/apps/scm/fom/importOrders/orderImportService/">
<soapenv:Header/>
<soapenv:Body>
<typ:SubmitDraftOrder>
<typ:submitDraftOrderRequest>
<ord:DraftOrder>
<ord:SourceTransactionIdentifier>'||l_rec.SOURCE_TRANSACTION_ID||'</ord:SourceTransactionIdentifier>
<ord:SourceTransactionSystem>'||l_rec.SOURCE_TRANSACTION_SYSTEM||'</ord:SourceTransactionSystem>
</ord:DraftOrder>                   
</typ:submitDraftOrderRequest>
</typ:SubmitDraftOrder>
</soapenv:Body>
</soapenv:Envelope>';
            dbms_output.put_line('MAKE REQUEST'); 
            l_xml := apex_web_service.make_request(
               p_url               => 'https://fa-ehfx-dev3-saasfaprod1.fa.ocs.oraclecloud.com:443/fscmService/OrderImportService',
               p_action            => 'http://xmlns.oracle.com/apps/scm/fom/importOrders/orderImportService/SubmitDraftOrder',
               p_envelope          => l_envelop,
               p_username          => 'integrations',
               p_password          => p_password,
               p_wallet_path =>
                    'file:////u01/app/wallet/https_wallet'
            );

            -- Display the whole SOAP document returned.
              --dbms_output.put_line('GET CLOB'); 
              --DBMS_OUTPUT.put_line('l_xml=' || l_xml.getClobVal());
              dbms_output.put_line('PARSE STATUS');
            l_status := apex_web_service.parse_xml(
                 p_xml => l_xml,
                 p_xpath => ' //ns0:ReturnStatus/text()',
                 p_ns => ' xmlns:ns0="http://xmlns.oracle.com/apps/scm/fom/importOrders/orderImportService/' );
              DBMS_OUTPUT.put_line('l_status=' || l_status);   
              dbms_output.put_line('CHECK FOR ERROR');
              IF l_status = 'ERROR' THEN
                    dbms_output.put_line('PARSE MESSAGE');
                    l_message_text := apex_web_service.parse_xml(
                     p_xml => l_xml,
                     p_xpath => ' //ns0:MessageText/text()',
                     p_ns => ' xmlns:ns0="http://xmlns.oracle.com/apps/scm/fom/importOrders/orderImportService/' );
                  DBMS_OUTPUT.put_line('l_message_text=' || l_message_text);   
                  dbms_output.put_line('SUBMIT ERROR MSG');
                   UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
                   SET STATUS = 'ERROR',
                        ERROR_MSG = 'Submit Error: ' || l_message_text
                    WHERE SBI_UUID = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;

                    COMMIT;

                ELSE 
                    dbms_output.put_line('SUBMITTED');
                    UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
                   SET STATUS = 'SUBMITTED'
                    WHERE SBI_UUID = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                    COMMIT;
                END IF;
                EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line('SQLERRM - ' || sqlerrm);
                    l_xml_error := sqlerrm;
                    UPDATE HBG_PROCESS_ORDERS_HEADERS_FBDI 
                   SET STATUS = 'ERROR',
                   ERROR_MSG = 'Submit Error: ' || l_xml_error
                    WHERE SBI_UUID = p_SBI_UUID
                    AND SOURCE_TRANSACTION_ID = l_rec.SOURCE_TRANSACTION_ID;
                    COMMIT;
                END;
                END LOOP;
       UPDATE HBG_PROCESS_ORDERS_SUBMIT_BATCHES
       SET STATUS = 'COMPLETE'
       WHERE BATCH_NAME = p_SBI_UUID;
       COMMIT;

    EXCEPTION WHEN OTHERS THEN
        l_sqlerrm := sqlerrm;
        UPDATE HBG_PROCESS_ORDERS_SUBMIT_BATCHES
       SET STATUS = 'ERROR',
       COMMENTS = l_sqlerrm
       WHERE BATCH_NAME = p_SBI_UUID;
       COMMIT;

    END SUBMIT_ORDERS;

    PROCEDURE CALL_SUBMIT_JOB (
        p_SBI_UUID IN VARCHAR2,
        p_password        IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    ) AS
        l_errbuf  VARCHAR2(3000);
        l_retcode VARCHAR2(1);
        l_tracker HBG_PROCESS_ORDERS_SUBMIT_BATCHES%rowtype;
        l_timestamp VARCHAR2(20);
    BEGIN
        errbuf := NULL;
        retcode := 0;
        l_timestamp := to_char(sysdate,'YYYYMMDDHH24MISS');
        job_name := 'HBG_PROCESS_ORDERS_' || l_timestamp;
        dbms_scheduler.create_job(job_name => 'HBG_PROCESS_ORDERS_' || l_timestamp, job_type => 'PLSQL_BLOCK', job_action => 'BEGIN
                                        HBG_PROCESS_ORDERS_PKG.SUBMIT_ORDERS('''
                                                                                                                               || p_SBI_UUID
                                                                                                                               || ''','''
                                                                                                                               || p_password
                                                                                                                               || ''');
                                    END;', enabled => true, auto_drop => true,
                                 comments => 'HBG Process Order Batch ' || p_SBI_UUID);

        l_tracker.batch_name := p_SBI_UUID;
        l_tracker.status := 'NEW';
        l_tracker.comments := NULL;
        l_tracker.CREATION_DATE := sysdate;
        INSERT INTO HBG_PROCESS_ORDERS_SUBMIT_BATCHES VALUES l_tracker;

        COMMIT;
        job_status := l_tracker.status;
    EXCEPTION
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            job_status := 'ERROR';

    END CALL_SUBMIT_JOB;


        PROCEDURE CALL_STERLING_JOB (
        p_debug         IN VARCHAR2,
        p_instanceid    IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    ) AS
        l_errbuf  VARCHAR2(3000);
        l_retcode VARCHAR2(1);
        l_tracker HBG_STERLING_JOB_TRACKER%rowtype;
        --l_timestamp VARCHAR2(20);
    BEGIN
        errbuf := NULL;
        retcode := 0;
        --l_timestamp := to_char(sysdate,'YYYYMMDDHH24MISS');
        job_name := 'HBG_STERLING_ORDERS_' || p_instanceid;
        dbms_scheduler.create_job(job_name => 'HBG_STERLING_ORDERS_' || p_instanceid, job_type => 'PLSQL_BLOCK', job_action => 'BEGIN
                                        HBG_PROCESS_ORDERS_PKG.STERLING_TO_STAGE_TABLES('''
                                                                                                                               || p_debug
                                                                                                                               || ''','
                                                                                                                               || p_instanceid
                                                                                                                               || ');
                                    END;', enabled => true, auto_drop => true,
                                 comments => 'HBG Sterling To Stage Tables Instance ' || p_instanceid);

        l_tracker.instanceid := p_instanceid;
        l_tracker.status := 'NEW';
        l_tracker.retcode := 0;
        l_tracker.errbuf := NULL;
        l_tracker.CREATION_DATE := sysdate;
        INSERT INTO HBG_STERLING_JOB_TRACKER VALUES l_tracker;

        COMMIT;
        job_status := l_tracker.status;
    EXCEPTION
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            job_status := 'ERROR';

    END CALL_STERLING_JOB;
    
    
    PROCEDURE CX_TO_STAGE_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
        p_debug_filename IN VARCHAR DEFAULT NULL,
        p_instanceid  IN NUMBER,
        p_creation_date IN DATE
        
		) AS
        
        -------------------------------------------------------------------------
        /*          CURSORS                                                    */
        -------------------------------------------------------------------------
        --DATA FOR SALES ORDER HEADER FBDI
        CURSOR c_doo_header_all_interface IS
            SELECT 
                    SYSTEM_ORDER_ID,
                    X_PO_NUMBER,
                    hdr.SUBMITTED_DATE || ' 00:00:00' AS SUBMITTED_DATE,
                    ACCOUNT_ID,
                    CURRENCY_CODE
            FROM 	HBG_CX_ORDER_HEADER hdr
            WHERE INTEGRATION_STATUS_ERP = 'NEW'
            AND CREATION_DATE >= p_creation_date
            AND STATE = 'SUBMITTED';
 
        --DATA FOR SALES ORDER HEADER EFFS FBDI
        CURSOR c_doo_hdr_effs_all_interface IS
            SELECT 
                    --Header id
                    SYSTEM_ORDER_ID,
                    ACCOUNT_ID,
                    --One Time Address CONTEXT
                    ATTN,
                    SHIPPING_ADDRESS1,
                    SHIPPING_ADDRESS2,
                    SHIPPING_ADDRESS3,
                    SHIPPING_ADDRESS4,
                    SHIPPING_CITY,
                    SHIPPING_STATE,
                    SHIPPING_POSTAL_CODE,
                    SHIPPING_COUNTRY,
                    DEST_ATTN,
                    PHONE_NBR,
                    SHIP_TO_NOTIFICATION_EMAIL,
                    --GENERAL CONTEXT
                    CANCELLATION_DATE,
                    TO_DATE(ARRIVE_BY,'YYYY/MM/DD')	AS ARRIVE_BY,
                    CX_ORDER_TYPE,
                    --OVERRIDE CONTEXT
                    DECODE(OVERRIDE_NYP, 'true', 'Y', 'false', 'N') AS OVERRIDE_NYP,
                    --FREIGHT CONTEXT
                    FREIGHT_COST
                    --CUSTOMER_EMAIL
                               
            FROM 	HBG_CX_ORDER_HEADER hdr
            WHERE 	INTEGRATION_STATUS_ERP = 'NEW'
                AND CREATION_DATE >= p_creation_date
                AND STATE = 'SUBMITTED';
                
        --DATA FOR SALES ORDER LINES FBDI
        CURSOR c_doo_lines_all_interface IS
            SELECT  
                    ORDER_HEADER_SOURCE_ID,
                    LINE_ID,
                    LINE_NUMBER,
                    CATALOG_REF_ID,
                    QUANTITY,
                    PRICE,
                    TO_DATE(line.CANCELLATION_DATE,'YYYY/MM/DD') as CANCELLATION_DATE,
                    TO_DATE(hdr.ARRIVE_BY,'YYYY/MM/DD')	AS ARRIVE_BY,
                    hdr.ACCOUNT_ID
            FROM    HBG_CX_ORDER_LINE line,
                    HBG_CX_ORDER_HEADER hdr
            WHERE   hdr.INTEGRATION_STATUS_ERP = 'NEW'
                AND line.ORDER_HEADER_SOURCE_ID = hdr.SYSTEM_ORDER_ID
                AND line.CREATION_DATE >= p_creation_date
                AND hdr.STATE = 'SUBMITTED';
      
   /*-----------------------------------------------------------------------------------------------------
            CURSOR TABLE TYPES
    ------------------------------------------------------------------------------------------------------*/
    
        TYPE lt_doo_header_all_interface_tb 		IS TABLE OF c_doo_header_all_interface%ROWTYPE;
        TYPE lt_doo_hdr_effs_all_interface_tb  		IS TABLE OF c_doo_hdr_effs_all_interface%ROWTYPE;
        TYPE lt_doo_lines_all_interface_tb  		IS TABLE OF c_doo_lines_all_interface%ROWTYPE;
        --TYPE lt_doo_lines_effs_all_interface_tb  	IS TABLE OF c_doo_lines_effs_all_interface%ROWTYPE;
        --TYPE lt_doo_addresses_all_interface_tb  	IS TABLE OF c_doo_addresses_all_interface%ROWTYPE;
        --TYPE lt_doo_addresses_hdr_interface_tb  	IS TABLE OF c_doo_addresses_hdr_interface%ROWTYPE;
    
    /*-----------------------------------------------------------------------------------------------------
            VARIABLES
    ------------------------------------------------------------------------------------------------------*/
    
        l_doo_header_all_interface_tb  		lt_doo_header_all_interface_tb ; 	
        l_doo_hdr_effs_all_interface_tb  	lt_doo_hdr_effs_all_interface_tb ;	
        l_doo_lines_all_interface_tb  	    lt_doo_lines_all_interface_tb ; 	
        --l_doo_lines_effs_all_interface_tb	lt_doo_lines_effs_all_interface_tb ;
        --l_doo_addresses_all_interface_tb	lt_doo_addresses_all_interface_tb;
        --l_doo_addresses_hdr_interface_tb	lt_doo_addresses_hdr_interface_tb;
        l_count									NUMBER := 0;
        l_count_success							NUMBER := 0;
        l_count_fail							NUMBER := 0;
        l_source_transaction_sys        	    VARCHAR2(10)  := 'OPS';
        l_update_errmsg		            	    NUMBER;
        l_update_success	            	    NUMBER;
        l_errbuf                        	    VARCHAR2(2000) := NULL;
        l_retcode			            	    NUMBER;
        l_ship_date                     	    VARCHAR2(19);
        errbuf                                  VARCHAR2(4000);
        retcode                                 NUMBER;
    /*-----------------------------------------------------------------------------------------------------
            EXCEPTIONS
    ------------------------------------------------------------------------------------------------------*/
        le_custom_exception EXCEPTION;
        le_insert_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(le_insert_exception, -24381);
    
        BEGIN 
        
            dbms_output.put_line(systimestamp);
            --execute immediate 'alter session set optimizer_index_cost_adj=10';
            errbuf := NULL;
            retcode := 0;
    
            UPDATE HBG_CX_ORDERS_JOB_TRACKER SET STATUS = 'RUNNING' WHERE instanceid = p_instanceid;
            COMMIT;
    
            /*-----------------------------------------------------------------------------------------------------
                BEGIN PROCESS HEADER DATA
            ------------------------------------------------------------------------------------------------------*/
            BEGIN
            dbms_output.put_line(systimestamp); 
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER DATA - OPEN c_doo_header_all_interface' );
                end if;
                dbms_output.put_line('header');
                OPEN c_doo_header_all_interface;
                LOOP
                    FETCH c_doo_header_all_interface BULK COLLECT INTO l_doo_header_all_interface_tb LIMIT 1000;
                    EXIT WHEN l_doo_header_all_interface_tb.COUNT = 0;
    
                    l_count := l_count + l_doo_header_all_interface_tb.COUNT;
    
                    IF p_debug = 'true' then
                        DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'BEGIN PROCESS HEADER DATA - Bulk Collect count '||l_count );
                    end if;
    
                    BEGIN
                        FORALL i IN 1 .. l_doo_header_all_interface_tb.COUNT SAVE EXCEPTIONS
                            INSERT INTO HBG_PROCESS_ORDERS_HEADERS_FBDI
                            (
                                SOURCE_TRANSACTION_ID, 	
                                SOURCE_TRANSACTION_SYSTEM,
                                SOURCE_TRANSACTION_NUMBER,
                                TRANSACTIONAL_CURRENCY_CODE,
                                TRANSACTION_ON,			
                                REQUESTING_BUSINESS_UNIT,  				
                                SBI_UUID,                   
                                STATUS,					
                                BATCH_NAME,                 
                                FREEZE_PRICING,             
                                SOURCE_ACCOUNT_NO,          
                                SOURCE_SYSTEM,              
                                SUBMIT_FLAG,                
                                CUSTOMER_PO_NUMBER
                            )
                            VALUES
                            (
                                l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID,	            --SOURCE_TRANSACTION_ID, 	
                                l_source_transaction_sys,                                       --SOURCE_TRANSACTION_SYSTEM,
                                l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID,               --SOURCE_TRANSACTION_NUMBER,
                                l_doo_header_all_interface_tb(i).CURRENCY_CODE,                 --TRANSACTIONAL_CURRENCY_CODE,
                                l_doo_header_all_interface_tb(i).SUBMITTED_DATE,                --TRANSACTION_ON,			
                                'HBG US BU',                                                    --REQUESTING_BUSINESS_UNIT,  					
                                'CX' || p_instanceid,                                           --SBI_UUID,                   
                                'NEW',                                                          --STATUS,					
                                'CX' || p_instanceid,                                           --BATCH_NAME,                 
                                'Y',                                                            --FREEZE_PRICING,             
                                l_doo_header_all_interface_tb(i).ACCOUNT_ID,                    --SOURCE_ACCOUNT_NO,          
                                'CX',                                                           --SOURCE_SYSTEM,              
                                'N',                                                            --SUBMIT_FLAG,                
                                l_doo_header_all_interface_tb(i).X_PO_NUMBER                    --CUSTOMER_PO_NUMBER
                            );
    
                        COMMIT;
                        l_count_success := l_count_success + l_doo_header_all_interface_tb.COUNT;
                    EXCEPTION 
    
                        WHEN le_insert_exception THEN
    
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH HEADER ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING HEADER - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
                            COMMIT;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP;
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_header_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    
                        WHEN OTHERS THEN 
                            dbms_output.put_line(sqlerrm);
                            l_errbuf := sqlerrm;
                            RAISE le_custom_exception;
                    END;
    
                END LOOP;	
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER DATA - '||l_count_fail||' orders failed');
                end if;
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER DATA - '||l_count_success||' orders succeeded');
                end if;
                CLOSE c_doo_header_all_interface;
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                                p_file_name => p_debug_filename,
                                p_debug_msg => 'end of c_doo_header_all_interface loop' );
                end if;
    
            EXCEPTION 
                WHEN OTHERS THEN
                    IF c_doo_header_all_interface%ISOPEN THEN
                       CLOSE c_doo_header_all_interface;
                    END IF;
                    dbms_output.put_line(sqlerrm);
                    l_errbuf := sqlerrm;
                    RAISE le_custom_exception;
            END;
            
        /*-----------------------------------------------------------------------------------------------------
			BEGIN PROCESS HEADER EFFS DATA
		------------------------------------------------------------------------------------------------------*/
            l_count				:= 0;
            l_count_success		:= 0;
            l_count_fail		:= 0;
    
            BEGIN
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER EFFS DATA - OPEN c_doo_hdr_effs_all_interface' );
                end if;
                dbms_output.put_line('header eff');
                OPEN c_doo_hdr_effs_all_interface;
                LOOP
                    FETCH c_doo_hdr_effs_all_interface BULK COLLECT INTO l_doo_hdr_effs_all_interface_tb LIMIT 1000;
                    EXIT WHEN l_doo_hdr_effs_all_interface_tb.COUNT = 0;
    
                    l_count := l_count + l_doo_hdr_effs_all_interface_tb.COUNT;
    
                    IF p_debug = 'true' then
                        DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'BEGIN PROCESS HEADER DATA - Bulk Collect count '||l_count );
                    end if;
                    /*-----------------------------------------------------------------------------
                            MAPPING FOR FBDI HEADER EFF FILE - General CONTEXT
                    -------------------------------------------------------------------------------*/
                    BEGIN
                        FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
                            INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
                            (
                                SOURCE_TRANSACTION_ID,     
                                SOURCE_TRANSACTION_SYSTEM, 
                                CONTEXT_CODE,                 
                                ATTRIBUTE_DATE1,
                                ATTRIBUTE_TIMESTAMP1,
                                ATTRIBUTE_CHAR5,
                                SOURCE_SYSTEM,             
                                STATUS,											
                                SBI_UUID                  	
                            )
    
                            VALUES
                            (
                                l_doo_hdr_effs_all_interface_tb(i).SYSTEM_ORDER_ID,	                --SOURCE_TRANSACTION_ID,    	 
                                l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM, 
                                'General',                          								--CONTEXT_CODE,             
                                l_doo_hdr_effs_all_interface_tb(i).CANCELLATION_DATE,               --ATTRIBUTE_DATE1
                                l_doo_hdr_effs_all_interface_tb(i).ARRIVE_BY,                       --ATTRIBUTE_TIMESTAMP1
                                l_doo_hdr_effs_all_interface_tb(i).CX_ORDER_TYPE,                    --ATTRIBUTE_CHAR5
                                'CX',															    --SOURCE_SYSTEM   
                                'NEW',     															--STATUS						
                                'CX' || p_instanceid 												--SBI_UUID        
    
                            );
       
                        COMMIT;
    
                        l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;
    
                    EXCEPTION 
    
                        WHEN le_insert_exception THEN
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH HEADER EFFS ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING HEADER EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP; 
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    
    
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;
                    
                    BEGIN
                        FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
    
                        /*-----------------------------------------------------------------------------
                            MAPPING FOR FBDI HEADER EFF FILE - One Time Address Context
                        -------------------------------------------------------------------------------*/
    
                            INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
                            (
                                SOURCE_TRANSACTION_ID,    
                                SOURCE_TRANSACTION_SYSTEM,
                                CONTEXT_CODE,                
                                ATTRIBUTE_CHAR1,        
                                ATTRIBUTE_CHAR2,          
                                ATTRIBUTE_CHAR3,          
                                ATTRIBUTE_CHAR4,          
                                ATTRIBUTE_CHAR5,          
                                ATTRIBUTE_CHAR6,         
                                ATTRIBUTE_CHAR7,         
                                ATTRIBUTE_CHAR8,                 
                                ATTRIBUTE_CHAR10,       
                                ATTRIBUTE_CHAR11,
                                ATTRIBUTE_CHAR12,
                                SOURCE_SYSTEM,            
                                STATUS,									
                                SBI_UUID                 
    
                            )
                            VALUES
                            (
    
                                l_doo_hdr_effs_all_interface_tb(i).SYSTEM_ORDER_ID,				        --SOURCE_TRANSACTION_ID,    					
                                l_source_transaction_sys,          	                                    --SOURCE_TRANSACTION_SYSTEM,            		
                                'One Time Address',                   								    --CONTEXT_CODE,                             	
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_COUNTRY,					--ATTRIBUTE_CHAR1,                      		
                                l_doo_hdr_effs_all_interface_tb(i).DEST_ATTN,					        --ATTRIBUTE_CHAR2,                      		
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_ADDRESS1,					--ATTRIBUTE_CHAR3,                      			
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_ADDRESS2,         			--ATTRIBUTE_CHAR4,                      		
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_ADDRESS3,               	--ATTRIBUTE_CHAR5,                      
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_ADDRESS4,        			--ATTRIBUTE_CHAR6,                         	
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_CITY,                       --ATTRIBUTE_CHAR7,                      
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_STATE,                      --ATTRIBUTE_CHAR8,                                           
                                l_doo_hdr_effs_all_interface_tb(i).PHONE_NBR,                           --ATTRIBUTE_CHAR10,       
                                l_doo_hdr_effs_all_interface_tb(i).ATTN,                                --ATTRIBUTE_CHAR11,
                                l_doo_hdr_effs_all_interface_tb(i).SHIPPING_POSTAL_CODE,	            --ATTRIBUTE_CHAR12,
                                'CX',                                                                   --SOURCE_SYSTEM,            
                                'NEW',                                                                  --STATUS,										
                                'CX' || p_instanceid                                                    --SBI_UUID                     
                            );
    
                            COMMIT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;				
                    EXCEPTION    
                        WHEN le_insert_exception THEN
    
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH LINES ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING ONE TIME ADDRESS EFF - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
                            COMMIT;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP;
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;
                    
                    BEGIN
                        FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
    
                        /*-----------------------------------------------------------------------------
                            MAPPING FOR FBDI HEADER EFF FILE - Override Context
                        -------------------------------------------------------------------------------*/
    
                            INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
                            (
                                SOURCE_TRANSACTION_ID,    
                                SOURCE_TRANSACTION_SYSTEM,
                                CONTEXT_CODE,                
                                ATTRIBUTE_CHAR1,        
                                SOURCE_SYSTEM,            
                                STATUS,									
                                SBI_UUID                 
    
                            )
                            VALUES
                            (
    
                                l_doo_hdr_effs_all_interface_tb(i).SYSTEM_ORDER_ID,				        --SOURCE_TRANSACTION_ID,    					
                                l_source_transaction_sys,          	                                    --SOURCE_TRANSACTION_SYSTEM,            		
                                'Override',                   								            --CONTEXT_CODE,                             	
                                l_doo_hdr_effs_all_interface_tb(i).OVERRIDE_NYP,					    --ATTRIBUTE_CHAR1,                      		
                                'CX',                                                                   --SOURCE_SYSTEM,            
                                'NEW',                                                                  --STATUS,										
                                'CX' || p_instanceid                                                    --SBI_UUID                     
                            );
    
                            COMMIT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;				
                    EXCEPTION    
                        WHEN le_insert_exception THEN
    
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH LINES ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING ONE TIME ADDRESS EFF - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
                            COMMIT;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP;
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;
                    
                    BEGIN
                        FORALL i IN 1 .. l_doo_hdr_effs_all_interface_tb.COUNT SAVE EXCEPTIONS
    
                        /*-----------------------------------------------------------------------------
                            MAPPING FOR FBDI HEADER EFF FILE - Freight Context
                        -------------------------------------------------------------------------------*/
    
                            INSERT INTO HBG_PROCESS_ORDERS_HDRS_EFF_FBDI
                            (
                                SOURCE_TRANSACTION_ID,    
                                SOURCE_TRANSACTION_SYSTEM,
                                CONTEXT_CODE,                
                                ATTRIBUTE_NUMBER1,        
                                SOURCE_SYSTEM,            
                                STATUS,									
                                SBI_UUID                 
    
                            )
                            VALUES
                            (
    
                                l_doo_hdr_effs_all_interface_tb(i).SYSTEM_ORDER_ID,				        --SOURCE_TRANSACTION_ID,    					
                                l_source_transaction_sys,          	                                    --SOURCE_TRANSACTION_SYSTEM,            		
                                'Freight',                   								            --CONTEXT_CODE,                             	
                                l_doo_hdr_effs_all_interface_tb(i).FREIGHT_COST,					    --ATTRIBUTE_NUMBER1,                      		
                                'CX',                                                                   --SOURCE_SYSTEM,            
                                'NEW',                                                                  --STATUS,										
                                'CX' || p_instanceid                                                    --SBI_UUID                     
                            );
    
                            COMMIT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT;				
                    EXCEPTION    
                        WHEN le_insert_exception THEN
    
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH LINES ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING ONE TIME ADDRESS EFF - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    l_doo_header_all_interface_tb(i).SYSTEM_ORDER_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
                            COMMIT;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP;
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_hdr_effs_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
    
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;
                    
                END LOOP;

                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER EFFs DATA - '||l_count_fail||' orders failed');
                end if;
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS HEADER EFFs DATA - '||l_count_success||' orders succeeded');
                end if;
    
                CLOSE c_doo_hdr_effs_all_interface;
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                                p_file_name => p_debug_filename,
                                p_debug_msg => 'end of c_doo_hdr_effs_all_interface table loop' );
                end if;
    
            EXCEPTION 
                WHEN OTHERS THEN
                    IF c_doo_hdr_effs_all_interface%ISOPEN THEN
                       CLOSE c_doo_hdr_effs_all_interface;
                    END IF;
                    l_errbuf := sqlerrm;
                    dbms_output.put_line(sqlerrm);
                    RAISE le_custom_exception;
            END;
            
        /*-----------------------------------------------------------------------------------------------------
            BEGIN PROCESS LINE DATA
        ------------------------------------------------------------------------------------------------------*/
            l_count				:= 0;
            l_count_success		:= 0;
            l_count_fail		:= 0;
            l_ship_date := to_char(sysdate + 1,'YYYY/MM/DD HH24:MI:SS');
    
            BEGIN
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                        p_file_name => p_debug_filename,
                        p_debug_msg => 'BEGIN PROCESS LINE DATA - OPEN c_doo_lines_all_interface' );
                end if;
    
                dbms_output.put_line('line');
                OPEN c_doo_lines_all_interface;
                LOOP
                    FETCH c_doo_lines_all_interface BULK COLLECT INTO l_doo_lines_all_interface_tb LIMIT 1000;
                    EXIT WHEN l_doo_lines_all_interface_tb.COUNT = 0;
    
                    l_count := l_count + l_doo_lines_all_interface_tb.COUNT;
                    --dbms_output.put_line(l_count);
    
                    IF p_debug = 'true' then
                        DEBUG_MSG ( 
                            p_file_name => p_debug_filename,
                            p_debug_msg => 'BEGIN PROCESS LINE DATA - Bulk Collect count '||l_count );
                    end if;
    
                    BEGIN
                        FORALL i IN 1 .. l_doo_lines_all_interface_tb.COUNT SAVE EXCEPTIONS
                            INSERT INTO HBG_PROCESS_ORDERS_LINES_FBDI
                            (
                                SOURCE_TRANSACTION_ID, 	
                                SOURCE_TRANSACTION_SYSTEM,
                                SOURCE_TRANSACTION_LINE_ID,		
                                SOURCE_TRANSACTION_SCHEDULE_ID,	
                                SOURCE_TRANSACTION_SCHEDULE_NO,	
                                SOURCE_TRANSACTION_LINE_NO,
                                PRODUCT_NUMBER,							
                                ORDERED_QUANTITY,			
                                ORDERED_UOM_CODE,			
                                BUSINESS_UNIT_NAME,			
                                TRANSACTION_CATEGORY_CODE,				
                                SBI_UUID,					
                                STATUS,						
                                PAYMENT_TERM,            
                                SOURCE_SYSTEM,            
                                SOURCE_ACCOUNT_NO,        
                                REQUESTED_SHIP_DATE,      
                                SCHEDULE_SHIP_DATE

                            )
                            VALUES
                            (
                                l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID,	                	--SOURCE_TRANSACTION_ID, 	
                                l_source_transaction_sys,                                               	--SOURCE_TRANSACTION_SYSTEM,
                                l_doo_lines_all_interface_tb(i).LINE_ID,                                    --SOURCE_TRANSACTION_LINE_ID,
                                l_doo_lines_all_interface_tb(i).LINE_ID,									--SOURCE_TRANSACTION_SCHEDULE_ID,
                                l_doo_lines_all_interface_tb(i).LINE_NUMBER,								--SOURCE_TRANSACTION_SCHEDULE_NO
                                l_doo_lines_all_interface_tb(i).LINE_NUMBER,								--SOURCE_TRANSACTION_LINE_NO
                                l_doo_lines_all_interface_tb(i).CATALOG_REF_ID,                            	--PRODUCT_NUMBER,				
                                l_doo_lines_all_interface_tb(i).QUANTITY,                      				--ORDERED_QUANTITY,			
                                'Ea',                                                          				--ORDERED_UOM_CODE,			
                                'HBG US BU',                                                   				--BUSINESS_UNIT_NAME,			
                                'ORDER',                                                       				--TRANSACTION_CATEGORY_CODE,					
                                'CX' || p_instanceid ,                                         				--SBI_UUID,					
                                'NEW',                                                         				--STATUS,						
                                'IMMEDIATE',                                                   				--PAYMENT_TERM,            
                                'CX',                                                          				--SOURCE_SYSTEM,            
                                l_doo_lines_all_interface_tb(i).ACCOUNT_ID,                    				--SOURCE_ACCOUNT_NO,        
                                to_char(l_doo_lines_all_interface_tb(i).ARRIVE_BY,'YYYY/MM/DD HH24:MI:SS'), --REQUESTED_SHIP_DATE,      
                                to_char(l_doo_lines_all_interface_tb(i).ARRIVE_BY,'YYYY/MM/DD HH24:MI:SS')  --SCHEDULE_SHIP_DATE,
                            );
    
                        COMMIT;
                        l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT;
                        --dbms_output.put_line(l_count_success);
                        IF p_debug = 'true' then
                            DEBUG_MSG ( 
                                p_file_name => p_debug_filename,
                                p_debug_msg => 'BEGIN PROCESS LINE DATA - Sucessfully inserted count '||l_count_success );
                        end if;
    
                    EXCEPTION 
    
                        WHEN le_insert_exception THEN
    
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH LINES ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            --dbms_output.put_line('error line');
                            l_errbuf := 'ERROR INSERTING LINE - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID, 
                                                                    l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
                            COMMIT;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
    
                            END LOOP;
    
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
                            --dbms_output.put_line('l_count_fail ' || l_count_fail);
                            --dbms_output.put_line('l_count_success ' || l_count_success);
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'BEGIN PROCESS LINE DATA - '||l_count_fail||' orders failed');
                            end if;
    
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'BEGIN PROCESS LINE DATA - '||l_count_success||' orders succeeded');
                            end if;
    
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;
                    
                /*-----------------------------------------------------------------------------
                    MAPPING FOR FBDI LINE EFF FILE - Custom Order CONTEXT
                -------------------------------------------------------------------------------*/
                    BEGIN
                        FORALL i IN 1 .. l_doo_lines_all_interface_tb.COUNT SAVE EXCEPTIONS
                            INSERT INTO HBG_PROCESS_ORDERS_LINES_EFF_FBDI
                            (
                                SOURCE_TRANSACTION_ID,     
                                SOURCE_TRANSACTION_SYSTEM,
                                SOURCE_TRANSACTION_LINE_ID,
                                SOURCE_TRANSACTION_SCHEDULE_ID,							
                                CONTEXT_CODE,                 
                                ATTRIBUTE_TIMESTAMP1,                    
                                SOURCE_SYSTEM,            
                                STATUS,										
                                SBI_UUID                  	
                            )
        
                            VALUES
                            (
                                l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID,	            --SOURCE_TRANSACTION_ID,    	 
                                l_source_transaction_sys,               							--SOURCE_TRANSACTION_SYSTEM,
                                l_doo_lines_all_interface_tb(i).LINE_ID,							--SOURCE_TRANSACTION_LINE_ID,    
                                l_doo_lines_all_interface_tb(i).LINE_ID,                            --SOURCE_TRANSACTION_SCHEDULE_ID,
                                'Other',                          							        --CONTEXT_CODE,             
                                l_doo_lines_all_interface_tb(i).CANCELLATION_DATE,				    --ATTRIBUTE_TIMESTAMP1
                                'CX',															    --SOURCE_SYSTEM   
                                'NEW',     															--STATUS					
                                'CX' || p_instanceid  												--SBI_UUID        
        
                            );
                        COMMIT;
                        l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT;
        
                    EXCEPTION 
        
                        WHEN le_insert_exception THEN
                        /*-----------------------------------------------------------------------------
                            UPDATE PROCESS TABLES WITH LINE EFFS ERROR MSG
                        -------------------------------------------------------------------------------*/
                            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                            l_errbuf := 'ERROR INSERTING LINES EFFs - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                            l_update_errmsg := UPDATE_ERROR_MSG	(	l_errbuf, 
                                                                    l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID, 
                                                                    l_doo_lines_all_interface_tb(i).ORDER_HEADER_SOURCE_ID, 
                                                                    'CX' || p_instanceid, 
                                                                    'NEW',
                                                                    'CX');
                            l_retcode := 1;
        
                            IF p_debug = 'true' then
                                DEBUG_MSG ( 
                                    p_file_name => p_debug_filename,
                                    p_debug_msg => 'l_errbuf := ' || l_errbuf || '
                                    l_update_errmsg := ' || l_update_errmsg );
                            end if;
        
                            END LOOP; 
        
                            l_count_fail := l_count_fail + SQL%BULK_EXCEPTIONS.COUNT;
                            l_count_success := l_count_success + l_doo_lines_all_interface_tb.COUNT - SQL%BULK_EXCEPTIONS.COUNT;
        
                        WHEN OTHERS THEN 
                            l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                            RAISE le_custom_exception;
                    END;

    
                END LOOP;	
    
                CLOSE c_doo_lines_all_interface;
    
                IF p_debug = 'true' then
                    DEBUG_MSG ( 
                                p_file_name => p_debug_filename,
                                p_debug_msg => 'end of c_doo_lines_all_interface loop' );
                end if;
            EXCEPTION 
                WHEN OTHERS THEN
                    IF c_doo_lines_all_interface%ISOPEN THEN
                       CLOSE c_doo_lines_all_interface;
                    END IF;
                    l_errbuf := sqlerrm;
                            dbms_output.put_line(sqlerrm);
                    RAISE le_custom_exception;
            END;

                
        EXCEPTION 
            WHEN le_custom_exception THEN
                l_errbuf := SQLERRM;
                UPDATE HBG_CX_ORDERS_JOB_TRACKER 
                    SET STATUS = 'ERROR',
                        ERRBUF = l_errbuf,
                        retcode = 1
                WHERE INSTANCEID = p_instanceid;
                COMMIT;
                retcode := 1;
                errbuf := SQLERRM;
                dbms_output.put_line(sqlerrm);
            WHEN OTHERS THEN 
                l_errbuf := SQLERRM;
                UPDATE HBG_CX_ORDERS_JOB_TRACKER 
                    SET STATUS = 'ERROR',
                        ERRBUF = l_errbuf,
                        retcode = 1
                WHERE INSTANCEID = p_instanceid;
                COMMIT;
                retcode := 1;
                errbuf := SQLERRM;
                dbms_output.put_line(sqlerrm);
                    
    END CX_TO_STAGE_TABLES;



END HBG_PROCESS_ORDERS_PKG;

/

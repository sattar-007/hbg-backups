--------------------------------------------------------
--  DDL for Package HBG_PROCESS_ORDERS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_PKG" IS
  /*************************************************************************
  *
  * Description:   HBG Process Orders Integration
  *
  * Modifications:
  *
  * DATE         AUTHOR           	DESCRIPTION
  * ----------   -----------      	------------------------------------------
  * 11/25/2022   Mariana Teixeira   INITIAL VERSION
  *
  ************************************************************************/
    g_directory    VARCHAR2(50) := 'HBG_JSON_IMPORT';


	PROCEDURE STERLING_TO_STAGE_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
        p_instanceid  IN NUMBER
		);

	FUNCTION file_to_blob (
			p_filename VARCHAR2
	) RETURN BLOB;

	 PROCEDURE generate_fbdi (
        p_SBI_UUID 	      IN VARCHAR2,
        p_source_system   IN VARCHAR2,
		errbuf            OUT VARCHAR2,
        retcode           OUT NUMBER,
        ftp_filename      OUT VARCHAR2 

    );

	PROCEDURE UPDATE_PROCESS_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER
	);

	PROCEDURE UPDATE_CTRL_PROCESS (
        p_debug       IN VARCHAR2 DEFAULT 'false',
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER
	);

	FUNCTION UPDATE_SUCCESS_MSG (p_SBI_UUID VARCHAR2) 
	RETURN NUMBER;

	FUNCTION UPDATE_ERROR_MSG
	( 	p_errbuf 			VARCHAR2,
		p_purchase_order_no	varchar2 DEFAULT NULL,
        p_transaction_id    VARCHAR2,
		p_SBI_UUID			VARCHAR2 DEFAULT NULL,
		p_import_status		VARCHAR2,
        p_source_sys        VARCHAR2
	) RETURN NUMBER;
    
    PROCEDURE DEBUG_MSG
	(   p_file_name             IN VARCHAR2,   
		p_debug_msg        	    IN VARCHAR2 DEFAULT NULL,
        p_debug_op              IN VARCHAR2 DEFAULT NULL,
        p_debug_header_fbdi     IN HBG_PROCESS_ORDERS_HEADERS_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_hdr_eff         IN HBG_PROCESS_ORDERS_HDRS_EFF_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_line_fbdi       IN HBG_PROCESS_ORDERS_LINES_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_address_fbdi    IN HBG_PROCESS_ORDERS_ADDRESSES_FBDI%ROWTYPE DEFAULT NULL,
        p_debug_lines_eff       IN HBG_PROCESS_ORDERS_LINES_EFF_FBDI%ROWTYPE DEFAULT NULL
        
        
	);
    
     PROCEDURE VALIDATE_STERLING_DATA
	(   p_debug_filename   IN VARCHAR2 DEFAULT NULL,   
		p_debug       IN VARCHAR2 DEFAULT 'false',
        p_SBI_UUID 	  IN VARCHAR2,
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER
        
	);
    
    PROCEDURE UPDATE_STG_ERP_INT_DATA (
        p_filename IN VARCHAR2,
        p_batch_name IN VARCHAR2,
        p_load_request_id in NUMBER,
        errbuf     OUT VARCHAR2,
        retcode    OUT NUMBER,
        report_flag OUT VARCHAR2
        );
        
    /*PROCEDURE CREATE_SUBMIT_FILE(
            p_SBI_UUID 	  IN VARCHAR2);*/
            
    PROCEDURE SUBMIT_ORDERS (p_SBI_UUID IN VARCHAR2,p_password IN VARCHAR2, p_erp_url in VARCHAR2 ) ;
    
    PROCEDURE CALL_SUBMIT_JOB (
        p_SBI_UUID IN VARCHAR2,
        p_password        IN VARCHAR2,
        p_erp_url     in  VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    );
    
    PROCEDURE CALL_STERLING_JOB (
        p_debug         IN VARCHAR2,
        p_instanceid    IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    );


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
	);
    
    PROCEDURE SEND_ORDER_ATTACHMENTS (p_batch_id IN VARCHAR2, p_password IN VARCHAR2, p_erp_url in  VARCHAR2 );
    
     PROCEDURE CALL_ATTACHMENT_JOB (
        p_batch_id IN VARCHAR2,
        p_password        IN VARCHAR2,
        p_erp_url       IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    );
    
     PROCEDURE CX_TO_STAGE_TABLES (
        p_debug       IN VARCHAR2 DEFAULT 'false',
        p_debug_filename IN VARCHAR DEFAULT NULL,
        p_instanceid  IN NUMBER,
        p_creation_date IN DATE
        
		);
        
    PROCEDURE VALIDATE_CX_DATA
	(   p_debug_filename   IN VARCHAR2 DEFAULT NULL,   
		p_debug       IN VARCHAR2 DEFAULT 'false',
        p_batch_id 	  IN VARCHAR2,
		errbuf        OUT VARCHAR2,
        retcode       OUT NUMBER

	);
END HBG_PROCESS_ORDERS_PKG;

/

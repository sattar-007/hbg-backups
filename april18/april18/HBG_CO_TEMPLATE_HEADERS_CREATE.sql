--------------------------------------------------------
--  DDL for Procedure HBG_CO_TEMPLATE_HEADERS_CREATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "HBG_INTEGRATION"."HBG_CO_TEMPLATE_HEADERS_CREATE" (
        p_template_name             IN   VARCHAR2,
        p_template_description      IN   VARCHAR2,
        p_cust_account_id           IN   NUMBER,
        p_owner_code 		        IN   VARCHAR2,
        p_owner_name 		        IN   VARCHAR2,
        p_account_number            IN   VARCHAR2,
        p_account_description       IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,       
        p_return_status             OUT  VARCHAR2
    )IS
        l_temp_cnt NUMBER := 0;
    BEGIN
        IF ( p_template_name IS NULL OR p_template_description IS NULL ) THEN
            p_return_status := ' Template Name, Template Description cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_temp_cnt
                FROM
                    hbg_co_template_headers
                WHERE
                        template_name = p_template_name;                 

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_temp_cnt > 0 THEN
                p_return_status := ' Template Name '
                                   || p_template_name
                                   || ' already exists please create unique Template Name';
            ELSE
                INSERT INTO hbg_co_template_headers (
                      template_name        
				     ,template_description 
				     ,cust_account_id      
				     ,owner_code 		   
				     ,owner_name 		   
				     ,account_number       
				     ,account_description  
				     ,start_date           
				     ,end_date             
				     ,entered_by
                    ,entered_date
                    ,updated_by
                    ,updated_date         
             
                ) VALUES (
                    p_template_name,
                    p_template_description ,
                    p_cust_account_id ,
                    p_owner_code,
					p_owner_name,
					p_account_number   ,
					p_account_description,
					to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Template Header :' || sqlerrm;
    END;
	
	
	PROCEDURE hbg_co_template_headers_update (
	    p_template_id               IN   Number,
        p_template_name             IN   VARCHAR2,
        p_template_description      IN   VARCHAR2,
        p_cust_account_id           IN   NUMBER,
        p_owner_code 		        IN   VARCHAR2,
        p_owner_name 		        IN   VARCHAR2,
        p_account_number            IN   VARCHAR2,
        p_account_description       IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,       
        p_return_status             OUT  VARCHAR2
    )AS
        l_status VARCHAR2(20);
    BEGIN
        IF p_template_id IS NOT NULL THEN

            UPDATE hbg_co_template_headers
            SET
                template_name = p_template_name,
                template_description = p_template_description,
                cust_account_id = p_cust_account_id,
                owner_code = p_owner_code,
				owner_name = p_owner_name,
				account_number = p_account_number,
				account_description = p_account_description,
				start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                updated_by = p_updated_by,
                updated_date = sysdate
            WHERE
                p_template_id = p_template_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Headers :' || sqlerrm;
    END;


    PROCEDURE hbg_co_template_lines_create (
        p_template_id               IN   Number,
        p_sequence                  IN   Number,
        p_category_code 		    IN   VARCHAR2,
        p_category_name 		    IN   VARCHAR2,
        p_instructions_text         IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,       
        p_return_status             OUT  VARCHAR2
    )IS
    BEGIN
        IF ( p_template_id IS NULL ) THEN
            p_return_status := ' Template Header Id cannot be blank';
        ELSE
            BEGIN
                 INSERT INTO hbg_co_template_lines (
                      template_id        
				     ,sequence 
				     ,ategory_code      
				     ,category_name 		   
				     ,instructions_text 		          
				     ,entered_by
                     ,entered_date
                     ,updated_by
                     ,updated_date      
                ) VALUES (
                    p_template_id,
                    p_sequence ,
                    p_category_code ,
                    p_category_name,
					p_instructions_text,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Template Line :' || sqlerrm;
    END;
	
		
    PROCEDURE hbg_co_template_lines_update (
		p_line_id                   IN   Number ,
        p_template_id               IN   Number,
        p_sequence                  IN   Number,
        p_category_code 		    IN   VARCHAR2,
        p_category_name 		    IN   VARCHAR2,
        p_instructions_text         IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,       
        p_return_status             OUT  VARCHAR2
    )IS
    BEGIN
        IF p_line_id IS NOT NULL THEN

            UPDATE hbg_co_template_lines
            SET
                template_id = p_template_id,
                sequence = p_sequence,
                category_code = p_category_code,
                category_name = p_category_name,
				instructions_text = p_instructions_text,
                updated_by = p_updated_by,
                updated_date = sysdate
            WHERE
                p_line_id = p_line_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Lines :' || sqlerrm;
    END;

/

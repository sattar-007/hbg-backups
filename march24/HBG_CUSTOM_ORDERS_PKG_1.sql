--------------------------------------------------------
--  DDL for Package Body HBG_CUSTOM_ORDERS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_CUSTOM_ORDERS_PKG" IS 
 
  PROCEDURE hbg_co_template_headers_create (
        p_template_name             IN   VARCHAR2,
        p_template_description      IN   VARCHAR2,
        p_cust_account_id           IN   NUMBER,
        p_owner_code                IN   VARCHAR2,
        p_owner_name                IN   VARCHAR2,
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
        p_owner_code                IN   VARCHAR2,
        p_owner_name                IN   VARCHAR2,
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
                template_id = p_template_id;
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
        p_category_code             IN   VARCHAR2,
        p_category_name             IN   VARCHAR2,
        p_instructions_text         IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,       
        p_return_status             OUT  VARCHAR2
    )IS
    BEGIN
        IF ( p_template_id IS NULL ) THEN
            p_return_status := ' Template Header Id cannot be blank';
        ELSE
           
                 INSERT INTO hbg_co_template_lines (
                      template_id        
                     ,sequence 
                     ,category_code      
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
				
			 COMMIT;	
                p_return_status := 'SUCCESS';
        
            
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Template Line :' || sqlerrm;
    END;


    PROCEDURE hbg_co_template_lines_update (
        p_line_id                   IN   Number ,
        p_template_id               IN   Number,
        p_sequence                  IN   Number,
        p_category_code             IN   VARCHAR2,
        p_category_name             IN   VARCHAR2,
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
                line_id = p_line_id;
            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Lines :' || sqlerrm;
    END;
    
    
        PROCEDURE hbg_co_rules_headers_create (	
        p_organization_id           IN   NUMBER,
		p_organization_number       IN   VARCHAR2,
		p_organization_name         IN   VARCHAR2,
		p_cust_account_id           IN   NUMBER,
		p_account_number            IN   VARCHAR2,
        p_account_description       IN   VARCHAR2,
        p_destination_account       IN   VARCHAR2,
        p_department_id             IN   NUMBER,
        p_sales_channel 		    IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,
        p_return_status             OUT  VARCHAR2
    )IS
        l_hdr_cnt NUMBER := 0;
    BEGIN
        IF ( p_organization_number IS NULL OR p_organization_name IS NULL or p_account_number IS NULL ) THEN
            p_return_status := ' Organization Number, Account Number cannot be blank';
   
            ELSE
                INSERT INTO hbg_co_rules_headers (
                     organization_id       
                    ,organization_number   
                    ,organization_name     
                    ,cust_account_id       
                    ,account_number        
                    ,account_description   
                    ,destination_account   
                    ,department_id         
                    ,sales_channel 
					,entered_by
					,entered_date
					,updated_by
					,updated_date
					,start_date
                    ,end_date
                ) VALUES (
                     p_organization_id       
                    ,p_organization_number   
                    ,p_organization_name     
                    ,p_cust_account_id       
                    ,p_account_number        
                    ,p_account_description   
                    ,p_destination_account   
                    ,p_department_id         
                    ,p_sales_channel
                    ,p_entered_by
                    ,sysdate
                    ,p_updated_by
                    ,sysdate
                    ,to_date(p_start_date, 'YYYY-MM-DD')
                    ,to_date(p_end_date, 'YYYY-MM-DD')
                );

                p_return_status := 'SUCCESS';
            

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Header :' || sqlerrm;
    END;
	
	
		PROCEDURE hbg_co_rules_headers_update (	
		P_rule_id				    IN  NUMBER,
        p_organization_id           IN   NUMBER,
		p_organization_number       IN   VARCHAR2,
		p_organization_name         IN   VARCHAR2,
		p_cust_account_id           IN   NUMBER,
		p_account_number            IN   VARCHAR2,
        p_account_description       IN   VARCHAR2,
        p_destination_account       IN   VARCHAR2,
        p_department_id             IN   NUMBER,
        p_sales_channel 		    IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,
        p_return_status            OUT  VARCHAR2
    )AS
    BEGIN
        IF P_rule_id IS NOT NULL THEN
            UPDATE hbg_co_rules_headers
            SET		 
        organization_id       = p_organization_id  ,  
        organization_number   = p_organization_number,
        organization_name     = p_organization_name,  
        cust_account_id       = p_cust_account_id,    
        account_number        = p_account_number,     
        account_description   = p_account_description,
        destination_account   = p_destination_account,
        department_id         = p_department_id ,     
        sales_channel 	      = p_sales_channel ,	
        start_date            = to_date(p_start_date, 'YYYY-MM-DD'),
        end_date              = to_date(p_end_date, 'YYYY-MM-DD'),        
        updated_by            = p_updated_by         
            WHERE
                rule_id = P_rule_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Rule Header :' || sqlerrm;
    END;
	
		PROCEDURE hbg_co_rules_lines_create (	
     P_rule_id                       IN   NUMBER,   
     P_sequence	                     IN   NUMBER,
     P_ship_to_number                IN   VARCHAR2,
     P_ship_to_name  	             IN   VARCHAR2,  
     P_owner_code	                 IN   VARCHAR2,
     P_owner_name                    IN   VARCHAR2,
     P_reporting_group               IN   VARCHAR2,
     P_reporting_group_description 	 IN   VARCHAR2,           
     P_publisher	                 IN   VARCHAR2,
     P_publisher_name	             IN   VARCHAR2,     
     P_imprint	                     IN   VARCHAR2,
     P_imprint_name	                 IN   VARCHAR2,      
     P_format	                     IN   VARCHAR2,
     P_format_name                   IN   VARCHAR2,  
     P_sub_format                    IN   VARCHAR2,
     P_sub_format_name               IN   VARCHAR2,
     P_item                          IN   VARCHAR2,
     P_price_on_book	             IN   VARCHAR2,
     P_shrink_wrap	                 IN   VARCHAR2, 
     P_master_pack	                 IN   VARCHAR2,
     P_inner_pack	                 IN   VARCHAR2,
     P_new_pack_quantity	         IN   VARCHAR2,             
     P_entered_by	                 IN   VARCHAR2,
     P_updated_by                    IN   VARCHAR2,
     p_return_status                 OUT  VARCHAR2
    )IS
    BEGIN
        IF ( P_sequence IS NULL OR P_rule_id IS NULL ) THEN
            p_return_status := ' Sequence, Rule Id cannot be blank';
   
            ELSE
                INSERT INTO HBG_CO_RULES_LINES (
                     rule_id                    
					,sequence	                  
					,ship_to_number             
					,ship_to_name  	          
					,owner_code	              
					,owner_name                 
					,reporting_group            
					,reporting_group_description
					,publisher	              
					,publisher_name	          
					,imprint	                  
					,imprint_name	              
					,format	                  
					,format_name                
					,sub_format                 
					,sub_format_name            
					,item                       
					,price_on_book	          
					,shrink_wrap	              
					,master_pack	              
					,inner_pack	              
					,new_pack_quantity	 					
					,entered_by
					,entered_date
					,updated_by
					,updated_date
                ) VALUES (
                     P_rule_id                    
					,P_sequence	                  
					,P_ship_to_number             
					,P_ship_to_name  	          
					,P_owner_code	              
					,P_owner_name                 
					,P_reporting_group            
					,P_reporting_group_description
					,P_publisher	              
					,P_publisher_name	          
					,P_imprint	                  
					,P_imprint_name	              
					,P_format	                  
					,P_format_name                
					,P_sub_format                 
					,P_sub_format_name            
					,P_item                       
					,P_price_on_book	          
					,P_shrink_wrap	              
					,P_master_pack	              
					,P_inner_pack	              
					,P_new_pack_quantity  
                    ,p_entered_by
                    ,sysdate
                    ,p_updated_by
                    ,sysdate
                );

                p_return_status := 'SUCCESS';
            

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Lines :' || sqlerrm;
    END;
	
		PROCEDURE hbg_co_rules_lines_update (	
	 p_rule_line_id                  IN   NUMBER,
     P_rule_id                       IN   NUMBER,   
     P_sequence	                     IN   NUMBER,
     P_ship_to_number                IN   VARCHAR2,
     P_ship_to_name  	             IN   VARCHAR2,  
     P_owner_code	                 IN   VARCHAR2,
     P_owner_name                    IN   VARCHAR2,
     P_reporting_group               IN   VARCHAR2,
     P_reporting_group_description 	 IN   VARCHAR2,           
     P_publisher	                 IN   VARCHAR2,
     P_publisher_name	             IN   VARCHAR2,     
     P_imprint	                     IN   VARCHAR2,
     P_imprint_name	                 IN   VARCHAR2,      
     P_format	                     IN   VARCHAR2,
     P_format_name                   IN   VARCHAR2,  
     P_sub_format                    IN   VARCHAR2,
     P_sub_format_name               IN   VARCHAR2,
     P_item                          IN   VARCHAR2,
     P_price_on_book	             IN   VARCHAR2,
     P_shrink_wrap	                 IN   VARCHAR2, 
     P_master_pack	                 IN   VARCHAR2,
     P_inner_pack	                 IN   VARCHAR2,
     P_new_pack_quantity	         IN   VARCHAR2,             
     P_updated_by                    IN   VARCHAR2,
     p_return_status                 OUT  VARCHAR2
    )IS
    BEGIN
        IF ( P_sequence IS NULL OR P_rule_id IS NULL) THEN
            p_return_status := ' Sequence, Rule Id cannot be blank';   
            ELSE
            UPDATE HBG_CO_RULES_LINES
            SET
                     rule_id                        = P_rule_id   ,                  
                     sequence	                    = P_sequence,	                  
                     ship_to_number                 = P_ship_to_number  ,           
                     ship_to_name  	                = P_ship_to_name  ,	            
                     owner_code	                    = P_owner_code	,              
                     owner_name                     = P_owner_name  ,               
                     reporting_group                = P_reporting_group ,           
                     reporting_group_description 	= P_reporting_group_description ,          
                     publisher	                    = P_publisher	 ,             
                     publisher_name	                = P_publisher_name,	               
                     imprint	                    = P_imprint	 ,                 
                     imprint_name	                = P_imprint_name,	                    
                     format	                        = P_format	,                  
                     format_name                    = P_format_name,                  
                     sub_format                     = P_sub_format ,                
                     sub_format_name                = P_sub_format_name,            
                     item                           = P_item ,                      
                     price_on_book	                = P_price_on_book,	          
                     shrink_wrap	                = P_shrink_wrap	 ,              
                     master_pack	                = P_master_pack	,              
                     inner_pack	                    = P_inner_pack,	              
                     new_pack_quantity	            = P_new_pack_quantity,	                   
                     updated_by                     = P_updated_by   
                  WHERE
                rule_line_id = p_rule_line_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Lines :' || sqlerrm;
    END;

    PROCEDURE hbg_co_line_actions_create (   
  p_rule_line_id    IN   NUMBER
 ,p_template_level  IN   VARCHAR2
 ,p_template_name   IN   VARCHAR2
 ,p_template_id     IN   NUMBER
 ,p_hold_flag       IN   VARCHAR2
 ,p_hold_level      IN   VARCHAR2
 ,p_hold_name       IN   VARCHAR2
 ,p_start_date      IN   VARCHAR2
 ,p_end_date        IN   VARCHAR2
 ,P_entered_by      IN   VARCHAR2
 ,p_updated_by      IN   VARCHAR2
 ,p_return_status   OUT  VARCHAR2
    )IS
       
    BEGIN
        IF ( p_rule_line_id IS NULL ) THEN
            p_return_status := ' Rule Line Id cannot be blank';
   
            ELSE
                INSERT INTO hbg_co_line_actions (
				   rule_line_id ,
                   template_level,
                   template_name, 
                   template_id,
                   hold_flag,
                   hold_level,
                   hold_name,
                   start_date  ,
                   end_date    ,
				   entered_by  ,
                   entered_date,                   
                   updated_by,
				   updated_date           
                ) VALUES (
				    p_rule_line_id ,
                    p_template_level,
                    p_template_name ,
                    p_template_id ,
                    p_hold_flag,
					p_hold_level,
					p_hold_name   ,
					to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Line Actions :' || sqlerrm;
    END;
	
	PROCEDURE hbg_co_line_actions_update ( 
  p_line_action_id  IN   NUMBER  
 ,p_rule_line_id    IN   NUMBER
 ,p_template_level  IN   VARCHAR2
 ,p_template_name   IN   VARCHAR2
 ,p_template_id     IN   NUMBER
 ,p_hold_flag       IN   VARCHAR2
 ,p_hold_level      IN   VARCHAR2
 ,p_hold_name       IN   VARCHAR2
 ,p_start_date      IN   VARCHAR2
 ,p_end_date        IN   VARCHAR2
 ,p_updated_by      IN   VARCHAR2
 ,p_return_status   OUT  VARCHAR2
    ) AS 
	    BEGIN
        IF p_line_action_id IS NOT NULL THEN

            UPDATE hbg_co_line_actions
            SET
                rule_line_id             = p_rule_line_id,
                template_level           = p_template_level,
                template_name            = p_template_name,
                template_id              = p_template_id,
				hold_flag                = p_hold_flag,
				hold_level               = p_hold_level,
				hold_name                = p_hold_name,
				start_date               = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date                 = to_date(p_end_date, 'YYYY-MM-DD'),
                updated_by               = p_updated_by,
                updated_date             = sysdate
            WHERE
                line_action_id = p_line_action_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Line Actions :' || sqlerrm;
    END;
	
	
	

END;

/

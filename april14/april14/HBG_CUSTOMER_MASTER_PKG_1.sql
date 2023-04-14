--------------------------------------------------------
--  DDL for Package Body HBG_CUSTOMER_MASTER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_CUSTOMER_MASTER_PKG" AS

    PROCEDURE hbg_client_info_create (
        cust_owner                  IN VARCHAR2,
        owner_description           IN VARCHAR2,
        account_type                IN VARCHAR2,
        account_type_description    IN VARCHAR2,
        created_by                  IN VARCHAR2,
        last_updated_by             IN VARCHAR2,
        default_account_type        IN VARCHAR2,
        default_account_type_owners IN VARCHAR2,
        operation_account_type      IN VARCHAR2,
        reporting_group             IN VARCHAR2,
        reporting_group_description IN VARCHAR2,
        category1                   IN VARCHAR2,
        category1_description       IN VARCHAR2,
        category2                   IN VARCHAR2,
        category2_description       IN VARCHAR2,
        cust_format                 IN VARCHAR2,
        format_description          IN VARCHAR2,
        sub_format                  IN VARCHAR2,
        sub_format_description      IN VARCHAR2,
        customer_account            IN VARCHAR2,
        cust_account_id             IN NUMBER,
        p_return_status             OUT VARCHAR2
    ) AS
    BEGIN
        IF cust_owner IS NULL THEN
            p_return_status := 'Owner field cannot be blank';
        ELSE
            INSERT INTO hbg_client_info_tbl (
                client_info_id,
                cust_owner,
                owner_description,
                account_type,
                account_type_description,
                created_by,
                last_updated_by,
                creation_date,
                last_update_date,
                default_account_type,
                default_account_type_owners,
                operation_account_type,
                reporting_group,
                reporting_group_description,
                category1,
                category1_description,
                category2,
                category2_description,
                cust_format,
                format_description,
                sub_format,
                sub_format_description,
                customer_account,
                cust_account_id
            ) VALUES (
                hbg_client_info_tbl_seq.NEXTVAL,
                cust_owner,
                owner_description,
                account_type,
                account_type_description,
                created_by,
                last_updated_by,
                sysdate,
                sysdate,
                default_account_type,
                default_account_type_owners,
                operation_account_type,
                reporting_group,
                reporting_group_description,
                category1,
                category1_description,
                category2,
                category2_description,
                cust_format,
                format_description,
                sub_format,
                sub_format_description,
                customer_account,
                cust_account_id
            );

        END IF;

        COMMIT;
        p_return_status := 'SUCCESS';
    END hbg_client_info_create;

    PROCEDURE hbg_client_info_upd (
        p_client_info_id              IN NUMBER,
        p_cust_owner                  IN VARCHAR2,
        p_owner_description           IN VARCHAR2,
        p_account_type                IN VARCHAR2,
        p_account_type_description    IN VARCHAR2,
        p_last_updated_by             IN VARCHAR2,
        p_default_account_type        IN VARCHAR2,
        p_default_account_type_owners IN VARCHAR2,
        p_operation_account_type      IN VARCHAR2,
        p_reporting_group             IN VARCHAR2,
        p_reporting_group_description IN VARCHAR2,
        p_category1                   IN VARCHAR2,
        p_category1_description       IN VARCHAR2,
        p_category2                   IN VARCHAR2,
        p_category2_description       IN VARCHAR2,
        p_cust_format                 IN VARCHAR2,
        p_format_description          IN VARCHAR2,
        p_sub_format                  IN VARCHAR2,
        p_sub_format_description      IN VARCHAR2,
        p_customer_account            IN VARCHAR2,
        p_cust_account_id             IN NUMBER,
        p_return_status               OUT VARCHAR2
    ) AS
    BEGIN
        IF p_client_info_id IS NOT NULL THEN
            UPDATE hbg_client_info_tbl a
            SET
                a.cust_owner = p_cust_owner,
                a.owner_description = p_owner_description,
                a.account_type = p_account_type,
                a.account_type_description = p_account_type_description,
                a.last_updated_by = p_last_updated_by,
                a.last_update_date = sysdate,
                a.default_account_type = p_default_account_type,
                a.default_account_type_owners = p_default_account_type_owners,
                a.operation_account_type = p_operation_account_type,
                a.reporting_group = p_reporting_group,
                a.reporting_group_description = p_reporting_group_description,
                a.category1 = p_category1,
                a.category1_description = p_category1_description,
                a.category2 = p_category2,
                a.category2_description = p_category2_description,
                a.cust_format = p_cust_format,
                a.format_description = p_format_description,
                a.sub_format = p_sub_format,
                a.sub_format_description = p_sub_format_description,
                a.customer_account = p_customer_account,
                a.cust_account_id = p_cust_account_id
            WHERE
                a.client_info_id = p_client_info_id;

        END IF;

        COMMIT;
        p_return_status := 'SUCCESS';
    END;

   PROCEDURE hbg_cust_account_type_create (
        
        p_customer_name        IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_name         IN VARCHAR2,
        p_cust_accnt_id        IN NUMBER,
        p_party_id             IN VARCHAR2,
        p_default_account_type IN VARCHAR2,
        p_account_type_desc    IN VARCHAR2,
        p_entered_by           IN VARCHAR2,
        p_entered_date         IN DATE,
        p_updated_by           IN VARCHAR2,
        p_updated_date         IN DATE,
        p_registry_id          IN NUMBER,
        p_organization_name    IN VARCHAR2,
        p_site_number          IN VARCHAR2,
        p_site_name            IN VARCHAR2,
        p_country              IN VARCHAR2,
        p_address              IN VARCHAR2,
        p_city                 IN VARCHAR2,
        p_state                IN VARCHAR2,
        p_postal_code          IN VARCHAR2,
        p_san                  IN VARCHAR2,
        p_lookup               IN Varchar2,
        p_return_status     OUT VARCHAR2
    )IS
    BEGIN
        IF ( p_customer_name IS NULL ) THEN
            p_return_status := 'customer_name cannot be blank';
        ELSE
        INSERT INTO hbg_cust_account_type (
            customer_name,
            account_number,
            account_name,
            cust_accnt_id,
            party_id,
            default_account_type,
            account_type_desc,
            entered_by,
            entered_date,
            updated_by,
            updated_date,
            registry_id,
            organization_name,
            site_number,
            site_name,
            country,
            address,
            city,
            state,
            postal_code,
            san,
            lookup
        ) VALUES (
            p_customer_name,
            p_account_number,
            p_account_name,
            p_cust_accnt_id,
            p_party_id,
            p_default_account_type,
            p_account_type_desc,
            p_entered_by,
            sysdate,
            p_updated_by,
            sysdate,
            p_registry_id,
            p_organization_name,
            p_site_number,
            p_site_name,
            p_country,
            p_address,
            p_city,
            p_state,
            p_postal_code,
            p_san,
            p_lookup
        );

        
	 END IF;

        COMMIT;
        p_return_status := 'SUCCESS';
    END hbg_cust_account_type_create;

    
    PROCEDURE hbg_cust_account_type_update (
        p_acc_typ_id           IN NUMBER,
        p_customer_name        IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_name         IN VARCHAR2,
        p_cust_accnt_id        IN NUMBER,
        p_party_id             IN VARCHAR2,
        p_default_account_type IN VARCHAR2,
        p_account_type_desc    IN VARCHAR2,
        p_entered_by           IN VARCHAR2,
        p_entered_date         IN DATE,
        p_updated_by           IN VARCHAR2,
        p_updated_date         IN DATE,
        p_registry_id          IN NUMBER,
        p_organization_name    IN VARCHAR2,
        p_site_number          IN VARCHAR2,
        p_site_name            IN VARCHAR2,
        p_country              IN VARCHAR2,
        p_address              IN VARCHAR2,
        p_city                 IN VARCHAR2,
        p_state             IN VARCHAR2,
        p_postal_code          IN VARCHAR2,
        p_san                  IN VARCHAR2,
        p_lookup               IN Varchar2,
		p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_acc_typ_id IS NOT NULL THEN
            UPDATE hbg_cust_account_type
            SET
            customer_name = p_customer_name,
            account_number = p_account_number,
            account_name = p_account_name,
            cust_accnt_id = p_cust_accnt_id,
            party_id = p_party_id,
            default_account_type = p_default_account_type,
            account_type_desc = p_account_type_desc,
            entered_by = p_entered_by,
            entered_date = sysdate,
            updated_by = p_updated_by,
            updated_date = sysdate,
            registry_id = p_registry_id,
            organization_name = p_organization_name,
            site_number = p_site_number,
            site_name = p_site_name,
            country = p_country,
            address = p_address,
            city = p_city,
            state = p_state,
            postal_code = p_postal_code,
            san = p_san,
            lookup = p_lookup
		 WHERE
                acc_typ_id = p_acc_typ_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;

		
    END hbg_cust_account_type_update;

    PROCEDURE hbg_co_template_lines_create (
        p_template_id       IN NUMBER,
        p_sequence          IN NUMBER,
        p_category_code     IN VARCHAR2,
        p_category_name     IN VARCHAR2,
        p_instructions_text IN VARCHAR2,
        p_entered_by        IN VARCHAR2,
        p_updated_by        IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_template_id IS NULL ) THEN
            p_return_status := ' Template Header Id cannot be blank';
        ELSE
            INSERT INTO hbg_co_template_lines (
                template_id,
                sequence,
                category_code,
                category_name,
                instructions_text,
                entered_by,
                entered_date,
                updated_by,
                updated_date
            ) VALUES (
                p_template_id,
                p_sequence,
                p_category_code,
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
    END hbg_co_template_lines_create;



        PROCEDURE xxhbg_inv_type_mapping_tbl_create (	
        p_inventory_type                      IN   VARCHAR2,
        p_inventory_type_preference           IN   VARCHAR2,
        p_owner                               IN   VARCHAR2,
		p_owner_description                   IN   VARCHAR2,
		p_reporting_group                     IN   VARCHAR2,
		p_reporting_group_description         IN   VARCHAR2,
	    p_category_1                          IN   VARCHAR2,
		p_category_1_description              IN   VARCHAR2,		
		p_category_2                          IN   VARCHAR2,
		p_category_2_description              IN   VARCHAR2,
		p_format                              IN   VARCHAR2,
		p_format_description                  IN   VARCHAR2,
		p_sub_format                          IN   VARCHAR2,
		p_sub_format_description              IN   VARCHAR2,
		p_party_number                        IN   VARCHAR2,
		p_cust_account_id                     IN   VARCHAR2,
        p_notes                               IN   VARCHAR2,
        p_entered_by                          IN   VARCHAR2,
        p_updated_by                          IN   VARCHAR2,
        p_return_status                       OUT  VARCHAR2
    ) IS 
	  BEGIN
        IF ( p_inventory_type IS NULL OR p_inventory_type_preference IS NULL ) THEN
            p_return_status := 'Inventory Type, Inventory Type preference cannot be null';
        ELSE
		
		    INSERT INTO xxhbg_inv_type_mapping_tbl (
                    inventory_type              
					,inventory_type_preference   
					,owner                       
					,owner_description           
					,reporting_group             
					,reporting_group_description
					,category_1                  
					,category_1_description     
					,category_2                  
					,category_2_description 
					,format                      
					,format_description          
					,sub_format                  
					,sub_format_description  
					,party_number                
					,cust_account_id             
					,notes                       
				    ,entered_by
                    ,entered_date
                    ,updated_by
                    ,updated_date               					
                ) VALUES (				
				p_inventory_type              
				,p_inventory_type_preference   
				,p_owner                       
				,p_owner_description           
				,p_reporting_group             
				,p_reporting_group_description
				,p_category_1                  
				,p_category_1_description    
				,p_category_2                  
				,p_category_2_description      
				,p_format                      
				,p_format_description          
				,p_sub_format                  
				,p_sub_format_description    
				,p_party_number                
				,p_cust_account_id             
				,p_notes                       
			    ,p_entered_by
                ,sysdate
                ,p_updated_by
                ,sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
	    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Inventory Type mapping :' || sqlerrm;
    END;

     PROCEDURE xxhbg_inv_type_mapping_tbl_update (
        p_inv_id			                  IN   NUMBER,
        p_inventory_type                      IN   VARCHAR2,
        p_inventory_type_preference           IN   VARCHAR2,
        p_owner                               IN   VARCHAR2,
		p_owner_description                   IN   VARCHAR2,
		p_reporting_group                     IN   VARCHAR2,
		p_reporting_group_description         IN   VARCHAR2,
	    p_category_1                          IN   VARCHAR2,
		p_category_1_description              IN   VARCHAR2,		
		p_category_2                          IN   VARCHAR2,
		p_category_2_description              IN   VARCHAR2,
		p_format                              IN   VARCHAR2,
		p_format_description                  IN   VARCHAR2,
		p_sub_format                          IN   VARCHAR2,
		p_sub_format_description             IN   VARCHAR2,
		p_party_number                        IN   VARCHAR2,
		p_cust_account_id                     IN   VARCHAR2,
        p_notes                               IN   VARCHAR2,
        p_updated_by                          IN   VARCHAR2,
        p_return_status                       OUT  VARCHAR2
    ) IS 
	  BEGIN
        IF ( p_inventory_type IS NULL OR p_inventory_type_preference IS NULL ) THEN
            p_return_status := 'Inventory Type, Inventory Type preference cannot be null';
        ELSE
			
		    UPDATE xxhbg_inv_type_mapping_tbl
            SET
                 inventory_type              = p_inventory_type             
				,inventory_type_preference   = p_inventory_type_preference  
				,owner                       = p_owner                      
				,owner_description           = p_owner_description          
				,reporting_group             = p_reporting_group            
				,reporting_group_description = p_reporting_group_description
				,category_1                  = p_category_1                 
				,category_1_description      = p_category_1_description     
				,category_2                  = p_category_2                 
				,category_2_description      = p_category_2_description     
				,format                      = p_format                     
				,format_description          = p_format_description         
				,sub_format                  = p_sub_format                 
				,sub_format_description      = p_sub_format_description   
				,party_number                = p_party_number               
				,cust_account_id             = p_cust_account_id            
				,notes                       = p_notes                      
				,updated_by                  = p_updated_by   
				,updated_date                = sysdate					
            WHERE
                inv_id = p_inv_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;    
	    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Inventory Type mapping :' || sqlerrm;
    END;

END hbg_customer_master_pkg;

/

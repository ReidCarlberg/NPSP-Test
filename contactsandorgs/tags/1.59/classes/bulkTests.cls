/**
 * These bulk tests are not included in the package but are here to test the code in batches of 200
 */
@isTest
private class bulkTests {

    static testMethod void insertPrivate()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
	        Contact con = new Contact(
	        	FirstName=newContactfirstName,
	        	LastName=newContactLastName,
	        	Private__c=true
	        );
	        cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Test.stopTest();
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id IN :cons];
		
		//contact should have no AccountId
		system.assertEquals(conCount,insertedContacts.size());
		//contact should have no AccountId
		system.assertEquals(null,insertedContacts[conCount-1].AccountId);
    
    }
    
    static testMethod void insertOneToOne()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	String newContactMailingStreet = '123 Elm St';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
    	
	    	Contact con = new Contact(
	        	FirstName=newContactfirstName,
	        	LastName=newContactLastName,
	        	MailingStreet = newContactMailingStreet,
	        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
	        );
	        cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Test.stopTest();
        
        Contact[] insertedContacts = [Select FirstName, LastName, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Account.BillingStreet,Organization_Type__c,Account.SYSTEMIsIndividual__c  from Contact where id IN :cons];
		
		//one contact should have been created
		system.assertEquals(conCount,insertedContacts.size());
		//the account should have the right type
		system.assertEquals(Constants.ONE_TO_ONE_ORGANIZATION_TYPE,insertedcontacts[0].Organization_Type__c);
		//the account should be flagged as an individual
		system.assertEquals(true,insertedcontacts[0].Account.SYSTEMIsIndividual__c );
		//the account should have been named correctly
		system.assertEquals(newContactfirstName + ' ' + newContactLastName,insertedcontacts[0].Account.Name);
		//relationship should be bi-directional
		system.assertEquals(insertedcontacts[0].id,insertedcontacts[0].Account.npe01__One2OneContact__c);
		//addresses should be sync'd
		system.assertEquals(newContactMailingStreet,insertedcontacts[0].Account.BillingStreet);
		system.assertEquals(insertedcontacts[0].MailingStreet,insertedcontacts[0].Account.BillingStreet);
		
		
    }
    
    static testMethod void updateOneToOne()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	String newContactMailingStreet = '123 Elm St';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
    	
	    	Contact con = new Contact(
	        	FirstName=newContactfirstName,
	        	LastName=newContactLastName,
	        	MailingStreet = newContactMailingStreet,
	        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
	        );
	        cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select FirstName, LastName, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Account.BillingStreet,Organization_Type__c,Account.SYSTEMIsIndividual__c  from Contact where id IN :cons];
		
		String updatedContactLastName = 'Contact_forTestsChange';
		String updatedOtherCity = 'Seattle';
		
		for(Contact thisContact : insertedContacts){			
			thisContact.LastName=updatedContactLastName;
			thisContact.OtherCity = updatedOtherCity;
		}
		
		
        update insertedContacts;
        Test.stopTest();
		
		Contact[] updatedContacts = [Select FirstName, LastName, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,OtherCity,Account.BillingStreet,Account.ShippingCity from Contact where id IN :insertedContacts];
		
		system.assertEquals(conCount,updatedContacts.size());
		//the account should have been named correctly
		system.assertEquals(updatedContacts[0].firstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
		//relationship should be bi-directional
		system.assertEquals(updatedContacts[0].id,updatedContacts[0].Account.npe01__One2OneContact__c);
		//addresses should be sync'd
		system.assertEquals(newContactMailingStreet,updatedContacts[0].MailingStreet);
		system.assertEquals(updatedOtherCity,updatedContacts[0].Account.ShippingCity);
		system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
		system.assertEquals(updatedContacts[0].OtherCity,updatedContacts[0].Account.ShippingCity);
		
    }
    
     static testMethod void detachOneToOne()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
	        Contact con = new Contact(
	        	FirstName=newContactfirstName,
	        	LastName=newContactLastName,
	        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
	        );
	        cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id IN :cons];		
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        for(Contact thisContact : insertedContacts){	
	        thisContact.AccountId = null;
	        thisContact.LastName = updatedContactLastName;
        }
        update insertedContacts;
        Test.stopTest();
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c from Contact where id IN :cons];
		
		system.assertEquals(conCount,updatedContacts.size());
		//AccountId of updated contact should match the orignial Account
		system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
	
    }
    
     static testMethod void editContactDuringDetachOneToOne()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	String newContactMailingStreet = '123 Elm St';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
	        Contact con = new Contact(
	        	FirstName=newContactfirstName,
	        	LastName=newContactLastName,
	        	MailingStreet = newContactMailingStreet,
	        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
	        );
	        cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id IN :cons];		
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        String updateContactMailingStreet = '234 Oak St';
        for(Contact thisContact : insertedContacts){	
	    
	        thisContact.AccountId = null;
	        thisContact.LastName = updatedContactLastName;
	        thisContact.MailingStreet = updateContactMailingStreet;
        }
        update insertedContacts;
        Test.stopTest();
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Organization_Type__c,Account.BillingStreet from Contact where id IN :cons];
		
		system.assertEquals(conCount,updatedContacts.size());
		//AccountId of updated contact should match the orignial Account
		system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
		
		//org type should be set correctly
		system.assertEquals(Constants.ONE_TO_ONE_ORGANIZATION_TYPE,updatedContacts[0].Organization_Type__c);
		
		//the account should have been named correctly
		system.assertEquals(updatedContacts[0].FirstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
		
		//addresses should be sync'd
		system.assertEquals(updateContactMailingStreet,updatedContacts[0].MailingStreet);
		system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
        
    }
    
    static testMethod void attachToIndividualAccount()
    {
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
        	Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR);
        	cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Test.stopTest();
        Contact[] insertedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id IN :cons];
		
		system.assertEquals(conCount,insertedContacts.size());
		//the contact should have the right type
		system.assertEquals(Constants.BUCKET_ORGANIZATION_TYPE,insertedcontacts[0].Organization_Type__c);
		//the account should have been named correctly
		system.assertEquals(Constants.BUCKET_ACCOUNT_NAME,insertedcontacts[0].Account.Name);
        
    }
    
   
}
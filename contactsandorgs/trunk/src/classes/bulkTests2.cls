/**
 * These bulk tests are not included in the package but are here to test the code in batches of 200
 */
@isTest
private class bulkTests2 {
    /*
 static testMethod void detachIndividualAccount()
    {
    	Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.BUCKET_PROCESSOR));
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(FirstName='test', LastName='contact');
            cons.add(con);
        }
        Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id IN :cons];
        
        Id AccountId = insertedContacts[0].AccountId;
        for(Contact thisContact : insertedContacts){            
            thisContact.AccountId = null;
        }
        update insertedContacts;
        Test.stopTest();
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id IN :cons];
        
        system.assertEquals(conCount,updatedContacts.size());
        //the contact should have the right type
        system.assertEquals(Constants.BUCKET_ORGANIZATION_TYPE,updatedContacts[0].Organization_Type__c);
        //the account should have been named correctly
        system.assertEquals(Constants.BUCKET_ACCOUNT_NAME,updatedContacts[0].Account.Name);
        //the account should have the correct AccountId
        system.assertEquals(AccountId,updatedContacts[0].AccountId);        
        
    }
    
    /// <name> detachFromNormalAccountToBucket </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in the bucket account. </summary>
    static testMethod void detachFromNormalAccountToBucket()
    {
    	Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.BUCKET_PROCESSOR));
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].SystemIsIndividual__c);
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(FirstName='test', LastName='contact678', AccountId = acct.id);
            cons.add(con);
        }
        Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select Account.Name,Account.SystemIsIndividual__c,AccountId,Organization_Type__c from Contact where id IN :cons];
        
        //the contact should be connected to the account
        system.assertEquals(acct.id,insertedContacts[0].AccountId);
        //the account should not be an individual account
        system.assert(!insertedContacts[0].Account.SystemIsIndividual__c);
        for(Contact thisContact : insertedContacts){
            thisContact.AccountId = null;
        }
        update insertedContacts;
        Test.stopTest();
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.SystemIsIndividual__c,Organization_Type__c from Contact where id IN :cons];
        
        //the account should be an individual account
        system.assert(updatedContacts[0].Account.SystemIsIndividual__c);
        //the account should not be the one we started with
        system.assertNotEquals(acct.id,updatedContacts[0].AccountId);  
              
        
    }
    
    /// <name> detachFromNormalAccountToOneToOne </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in a one-to-one account. </summary>
    static testMethod void detachFromNormalAccountToOneToOne()
    {
    	Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].SystemIsIndividual__c);
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(FirstName='test', LastName='contact678', AccountId = acct.id);
            cons.add(con);
        }
        Test.startTest();
        insert cons;
        
        Contact[] insertedContacts = [Select Account.Name,Account.SystemIsIndividual__c,AccountId,Organization_Type__c from Contact where id IN :cons];
        
        //the contact should be connected to the account
        system.assertEquals(acct.id,insertedContacts[0].AccountId);
        //the account should not be an individual account
        system.assert(!insertedContacts[0].Account.SystemIsIndividual__c);
        for(Contact thisContact : insertedContacts){
            thisContact.AccountId = null;
        }
        
        update insertedContacts;
        Test.stopTest();
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.SystemIsIndividual__c,Organization_Type__c from Contact where id IN :cons];
        
        //the account should be an individual account
        system.assert(updatedContacts[0].Account.SystemIsIndividual__c);
        //the account should not be the one we started with
        system.assertNotEquals(acct.id,updatedContacts[0].AccountId);  
              
        
    }
    */
}
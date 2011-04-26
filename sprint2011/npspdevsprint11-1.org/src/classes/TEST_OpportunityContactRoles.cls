/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TEST_OpportunityContactRoles {
 
    /// <name> createOrUpdateCR </name>
    /// <summary> test creation or upate of contact role  </summary>
    static testMethod void createOrUpdateCR() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
        
        Account acc = new Account(Name='test77');
        insert acc;
        
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            AccountId = acc.Id,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = acc.Id,
            CloseDate = date.today(), StageName = 'Closed Won'
        );
        insert opp1;
        
        //Make sure that we haven't created a contact role yet.
        OpportunityContactRole[] result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        system.assertEquals(0, result.size());
        
        //Insert the contact role with a blank Role field.
        OpportunityContactRole cr = new OpportunityContactRole (OpportunityId = opp1.Id, ContactId = con.Id, IsPrimary = true);
        insert cr;
        
        result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        system.assertEquals(con.Id, result[0].ContactId);
        
        //Now we make a direct call to simulate the trigger firing for a user interface entry.
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity> {opp1.Id => opp1};
        OpportunityContactRoles testCR = new OpportunityContactRoles(oppMap);

        result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        system.assertEquals(donorRoleforTest, result[0].Role);

        //Now simulate import of an opp record with a contact ID.
        Opportunity opp2 = new Opportunity(
            Name = 'Apex Test Opp2',
            AccountId = acc.Id,
            Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(), StageName = 'Closed Won'
        );
        insert opp2;

        result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp2.Id];
        system.assertEquals(con.Id, result[0].ContactId);
        system.assertEquals(donorRoleforTest, result[0].Role);
    }
    
    static testMethod void oppCRTriggerTurnedOff() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = false, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
          
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(0, result.size());
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should have the contact's one to one account
       system.assertEquals(null, oppResult[0].AccountId);
    }
    
    static testMethod void oppRolesForOneToOneContact() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
                
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should have the contact's one to one account
       system.assertEquals(createdContacts[0].AccountId, oppResult[0].AccountId);
    }
    
    static testMethod void oppRolesForIndividualContact() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.BUCKET_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
              
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary,Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be one role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should be null account
       system.assertEquals(null, oppResult[0].AccountId);

    }
    
    static testMethod void oppRolesForOneToOneAccount() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
                
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            AccountId = createdContacts[0].AccountId,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();
        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be a contact role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
    }
    
    static testMethod void oppRolesForIndividualAccount() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.BUCKET_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
              
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Contact_Id_for_Role__c = con.Id,
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        insert opp1;
        Test.stopTest();

        OpportunityContactRole[] result = [select OpportunityId, ContactId, isPrimary,Role from OpportunityContactRole where OpportunityId = :opp1.Id];
        //should be one role
        system.assertEquals(1, result.size());
        system.assertEquals(donorRoleforTest, result[0].Role);
        system.assertEquals(true, result[0].isPrimary);
        
       Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
       //should be null account
       system.assertEquals(null, oppResult[0].AccountId);

    }
    
    static testMethod void oppRolesForBadId() {
        String donorRoleforTest = 'Donor';
        Contacts_and_Orgs_Settings__c testSettings = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,Enable_Opportunity_Contact_Role_Trigger__c = true, Opportunity_Contact_Role_Default_role__c = donorRoleforTest));
        
        Account acc = new Account(Name='test77');
        insert acc;
        
        String title = 'CEO';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            Title=title,
            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] createdContacts = [select AccountId from Contact where Id = :con.id];

        //Simulate user interface creation of opp from button on contact screen, 
        //i.e. Role field is blank in the new contact role.
        Opportunity opp1 = new Opportunity(
            Name = 'Apex Test Opp1',
            Contact_Id_for_Role__c = 'junk',
            CloseDate = date.today(),
            StageName = 'Closed Won'
        );
        Test.startTest();
        try {
            insert opp1;            
            
            OpportunityContactRole[] result = [select OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId = :opp1.Id];
            //shouldn't be a contact role
            system.assertEquals(0, result.size());
            
            Opportunity[] oppResult = [select AccountId from Opportunity where Id = :opp1.Id];
            //shouldn't be an account
            system.assertEquals(null, oppResult[0].AccountId);
        } catch (exception e) {
            system.assert(e.getMessage().contains(Label.Opportunity_Contact_Role_Error_Bad_Contact_Id));
        }
        Test.stopTest();
    }    
}
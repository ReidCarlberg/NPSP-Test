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
private class TEST_HouseholdOpportunity_bulk {

      /// <name> newIndContactAllContactsProcessor </name>
    /// <summary> test insert individual with all contacts processor </summary>
    static testMethod void newOpps() {
    	
    	Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(new Households_Settings__c (Household_Rules__c = Households.ALL_PROCESSOR));
        
        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
                
        String street = '2345 Elm St.';
        String city = 'Seattle';
        String state = 'WA';
        String zip = '88777';
        String country = 'US';
        String lastname = 'SmithForTest99';
        
        List<Contact> cons = new List<contact>();
        Integer conCount = 200;
        for(Integer i=0;i<conCount;i++){
            Contact con = new Contact(
                FirstName='test',
                LastName=lastname,
                MailingStreet = street,
                MailingCity = city,
                MailingState = state,
                MailingPostalCode = zip,
                MailingCountry = country,
                SystemHouseholdProcessor__c = 'All New or Edited Contacts'
            );
            cons.add(con);
        }
        
        insert cons;
        Contact[] createdContacts = [select AccountId,Household__c,
        Household__r.MailingStreet__c, Household__r.MailingCity__c,
        Household__r.MailingState__c, Household__r.MailingPostalCode__c,
        Household__r.MailingCountry__c, Household__r.Name from Contact where id IN :cons];
        
        List<Opportunity> opps = new List<Opportunity>();
        
        for(Contact myContact : createdContacts){
            Opportunity opp = new Opportunity(
                Name='opp1',
                closeDate=System.today(),
                StageName='closed won',
                AccountId= myContact.AccountId
            );
            opps.add(opp);
        }
        
        Id firstHouseholdId = createdContacts[0].Household__c;
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
        system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
        Test.startTest();
        //blank out the HH
        for(Contact thisContact : createdContacts){
            thisContact.Household__c = null;
        }
        update createdContacts;
        Test.stopTest();
        createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        system.assertNotEquals(firstHouseholdId,createdContacts[0].Household__c);
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
        system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
    }
}
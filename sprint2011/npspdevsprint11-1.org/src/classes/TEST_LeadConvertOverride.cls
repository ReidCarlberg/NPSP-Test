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
private class TEST_LeadConvertOverride {

    //tests if the company is called Self. End point depends on the model
    public static testMethod void newLeadConversion_Test() {
        
        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Constants.setIndividualAccountForTests(Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
 
        String companyName = 'Individual';
        
        companyName = 'Self';           
        String leadFirstName = '';
        String leadLastName = 'lead for tests_987';
        Lead l = new Lead();
        l.FirstName = leadFirstName;
        l.LastName = leadLastName;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        
        //pass the controller into the extension
        LeadConvertOverride ext = new LeadConvertOverride(sc); 
        
        //this should NOT convert the lead - because it is one to one
        PageReference landingPage = ext.convertLead();
        system.assert(landingPage == null);
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(2, ext.conList.size());
        ext.getlcStatuses();
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';
        
        ext.convertOneToOne();
        
        if (Constants.isOneToOne()){                
            Contact[] convertedContacts = [select id, firstname, lastname,Account.Systemisindividual__c from Contact where lastname = :leadLastName];
            //one contact should have been created
            system.assertEquals(1,convertedContacts.size());
            //the account for this contact should be an individual account, no matter the model
            system.assertEquals(true,convertedContacts[0].Account.Systemisindividual__c);
            String accountName = convertedContacts[0].FirstName + ' ' + convertedContacts[0].lastname;
            
            List<Account> createdAccount2 = [select id from Account where name = :accountName];
            system.assertEquals(1,createdAccount2.size());
        } else {
            system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
        }

    }

    //tests if the company is called Self. End point depends on the model
    public static testMethod void newLeadConversionMerge_Test() {

        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Constants.setIndividualAccountForTests(Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
 
        String companyName = 'Individual';

        companyName = 'Self'; 
        
        // create a contact to merge into
        contact c = new contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
        	LastName=Constants.CONTACT_LASTNAME_FOR_TESTS
        );          
        insert c;
        
        Lead l = new Lead();
        l.FirstName = Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        
        //pass the controller into the extension
        LeadConvertOverride ext = new LeadConvertOverride(sc); 
        
        //this should NOT convert the lead - because it is one to one
        PageReference landingPage = ext.convertLead();
        system.assert(landingPage == null);
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(3, ext.conList.size());
        ext.getlcStatuses();
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the Merge to <contact> option in the Contact box
        ext.con = c.id;
        
        ext.convertOneToOne();
        
        if (Constants.isOneToOne()){                
            Contact[] convertedContacts = [select id, firstname, lastname,Account.Systemisindividual__c from Contact where lastname = :Constants.CONTACT_LASTNAME_FOR_TESTS];
            lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
            //no lead still unconverted             
            system.assertEquals(0,unconvertedLeads.size());
            //one contact should have been created
            system.assertEquals(1,convertedContacts.size());
            //the account for this contact should be an individual account, no matter the model
            system.assertEquals(true,convertedContacts[0].Account.Systemisindividual__c);
        } else {
            system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
        }

    }

    //tests if it's a regular lead conversion in either model
    public static testMethod void newLeadConversionNamedCompany_Test() {

        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Constants.setIndividualAccountForTests(Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
        
        companyName = 'Junky company for tests';

        Lead l = new Lead();
        l.FirstName = Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        //pass the controller into the extension
        LeadConvertOverride ext = new LeadConvertOverride(sc); 
        PageReference landingPage = ext.convertLead();
        system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    
     //tests if it's a regular lead conversion in either model
    public static testMethod void newLeadConversionNamedCompanyNoFirstName_Test() {

        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Constants.setIndividualAccountForTests(Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride')); 
        
        String companyName = 'Individual';
        
        
        companyName = 'Junky company for tests';

        Lead l = new Lead();
        l.FirstName = Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        //pass the controller into the extension
        LeadConvertOverride ext = new LeadConvertOverride(sc); 
        PageReference landingPage = ext.convertLead();
        system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    
    //tests if the company has the exact same name as the lead. End point depends on the model
    public static testMethod void newLeadWithCompanyMatchingLeadName_Test() {
        
        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        Constants.setIndividualAccountForTests(Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
        
        companyName = 'test lead for tests_989';

        Lead l = new Lead();
        l.FirstName = Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        //pass the controller into the extension
        LeadConvertOverride ext = new LeadConvertOverride(sc); 
        PageReference landingPage = ext.convertLead();
        
    }
    
}
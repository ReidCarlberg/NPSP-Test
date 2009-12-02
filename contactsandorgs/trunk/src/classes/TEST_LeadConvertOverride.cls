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

        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
 
 		String companyName = 'Individual';
 		String AccountProcessorValue = Constants.BUCKET_PROCESSOR;
		
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
			PageReference landingPage = ext.convertLead();
			if (Constants.isOneToOne()){				
				Contact[] convertedContacts = [select id, firstname, lastname,Account.Systemisindividual__c from Contact where lastname = :leadLastName];
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

        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
 		String AccountProcessorValue = Constants.BUCKET_PROCESSOR;
		
		
		companyName = 'Junky company for tests';
        String leadFirstName = 'test';
        String leadLastName = 'lead for tests_989';
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
		PageReference landingPage = ext.convertLead();
		system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    
     //tests if it's a regular lead conversion in either model
    public static testMethod void newLeadConversionNamedCompanyNoFirstName_Test() {

        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
 		String AccountProcessorValue = Constants.BUCKET_PROCESSOR;
		
		
		companyName = 'Junky company for tests';
        String leadFirstName = '';
        String leadLastName = 'lead for tests_989';
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
		PageReference landingPage = ext.convertLead();
		system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    //tests if the company has the exact same name as the lead. End point depends on the model
    public static testMethod void newLeadWithCompanyMatchingLeadName_Test() {
        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
 		Constants.ONE_TO_ONE_ACCOUNT_MODEL = true;
		
		companyName = 'test lead for tests_989';
        String leadFirstName = 'test';
        String leadLastName = 'lead for tests_989';
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
		PageReference landingPage = ext.convertLead();
		
    }
    
}
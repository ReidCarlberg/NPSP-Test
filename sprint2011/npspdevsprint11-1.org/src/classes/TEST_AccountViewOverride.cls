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
private class TEST_AccountViewOverride {

    //can't test very well because of the way the page redirect is built
    public static testMethod void accountViewOverride() {
        
        Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR));
        
        Test.setCurrentPageReference(new PageReference('Page.AccountViewOverride'));
        
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=Constants.CONTACT_LASTNAME_FOR_TESTS,
            MailingStreet = newContactMailingStreet,
        	WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
        
        Account newAccount = [select id from Account where id=:insertedContacts[0].AccountId];
        
        system.currentPageReference().getParameters().put('id', newAccount.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(newAccount);
        //pass the controller into the extension
        AccountViewOverride ext = new AccountViewOverride(sc); 
        ext.getAccount();

    }
    
    
    public static testMethod void noAccount() {

        
        Test.setCurrentPageReference(new PageReference('Page.AccountViewOverride'));
        
        Account newAccount = new Account();
        
        system.currentPageReference().getParameters().put('id', '');
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(newAccount);
        //pass the controller into the extension
        AccountViewOverride ext = new AccountViewOverride(sc); 
        ext.getAccount();
    }
}
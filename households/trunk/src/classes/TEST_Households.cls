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
private class TEST_Households {

    /// <name> Households_Test </name>
    /// <summary> test default constructor </summary>
    static testMethod void Households_Test() {
        Households testHouseholds = new Households();
    }


    /// <name> insertHousehold_Test </name>
    /// <summary> test method for InsertHousehold function </summary>
    static testMethod void insertHousehold_Test() {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemHouseholdProcessor__c = 'test');
        insert con;

		con.Household__c = null;
		update con;

		Account acc = new Account(Name='test');
		insert acc;

        Contact con2 = new Contact(FirstName='test', LastName='contact', AccountId=acc.Id, SystemHouseholdProcessor__c = 'All Individual Contacts');
        insert con2;
        
        con2.Household__c = null;
        con2.SystemHouseholdProcessor__c = 'All New or Edited Contacts';
        update con2;
    }


    /// <name> evaluateContacts_Test </name>
    /// <summary> test method for evaluateContacts function </summary>
    static testMethod void evaluateContacts_Test() {
		Account a = new Account(Name='test',npe01__SYSTEMIsIndividual__c = true);
		insert a;
		
		//AccountId = null
		Contact c = new Contact(LastName='test',Household__c=null,npe01__SystemAccountProcessor__c='None',SystemHouseholdProcessor__c='All Individual Contacts');
		insert c;
		
		c.Household__c = null;
		update c;

		//AccountId != null
		Contact c2 = new Contact(LastName='test',Household__c=null,AccountId=a.Id,SystemHouseholdProcessor__c='All Individual Contacts');
		insert c2;

    }

    /// <name> deleteHousehold_Test </name>
    /// <summary> test method for deleteHousehold function </summary>
    static testMethod void deleteOldHousehold_Test() {
		Household__c h = new Household__c(Name='test');

        Contact con = new Contact(FirstName='test', LastName='contact', SystemHouseholdProcessor__c = 'All New or Edited Contacts', Household__c=h.Id);
        insert con;
        
        Contact con2 = new Contact(FirstName='test', LastName='contact', SystemHouseholdProcessor__c = 'All New or Edited Contacts', Household__c=h.Id);
        insert con2;

		delete con2;
		delete con;
    }


    /// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
	static testMethod void getHouseholdTransactionTotal_test()
	{
		Household__c h = new Household__c(Name='Test Household');
		insert h;
		Contact c = new Contact(FirstName='test',LastName='test',Household__c=h.Id);
		insert c;
		Opportunity o = new Opportunity(Name='test oppty',CloseDate=System.Today(),StageName='Closed Won',Amount=100);
		insert o;
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=c.Id,Role='Test');
		insert ocr;
	}
}
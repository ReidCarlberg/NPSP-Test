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
private class RecurringDonations_TEST {

	/// <name> RecurringDonations_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void RecurringDonations()
	{
  		RecurringDonations testRecurringDonations = new RecurringDonations();
	}


	/// <name> insertOpportunities_Test </name>
	/// <summary> test method for insertOpportunities function </summary>
	static testMethod void insertOpportunities()
	{
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;

		Recurring_Donation__c r0 = new Recurring_Donation__c();
		r0.Name = 'test';
		r0.Installments__c = 3;
		r0.Amount__c = 100;
		r0.Installment_Period__c = 'Yearly';
		r0.Date_Established__c = System.today();
		r0.Schedule_Type__c = 'Multiply By';
		try {
			insert r0;
		} catch (exception e) {
			
		}
		//insert should fail because there is no Contact
		system.assertEquals(null,r0.id);
		

		Recurring_Donation__c r1 = new Recurring_Donation__c();
		r1.Name = 'test';
		r1.Installments__c = 1;
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = 'Yearly';
		r1.Date_Established__c = System.today();
		r1.Schedule_Type__c = 'Multiply By';
		insert r1;
		
		Opportunity[] installments1 = [select amount from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(1,installments1.size());
		system.assertEquals(100,installments1[0].Amount);

		Recurring_Donation__c r2 = new Recurring_Donation__c();
		r2.Name = 'test';
		r2.Installments__c = 3;
		r2.Organization__c = a.Id;
		r2.Amount__c = 100;
		r2.Installment_Period__c = 'Monthly';
		r2.Date_Established__c = System.today();
		r2.Schedule_Type__c = 'Divide By';
		insert r2;
		
		try{
			delete r2;
		} catch (exception e1) {}
		
		//delete should have failed
		Opportunity[] installments2 = [select amount from Opportunity where Recurring_Donation__c = :r2.id];
		system.assertEquals(3,installments2.size());
		system.assertEquals(33.33,installments2[0].Amount);
		
		Recurring_Donation__c r3 = new Recurring_Donation__c();
		r3.Name = 'test';
		r3.Installments__c = 55;
		r3.Organization__c = a.Id;
		r3.Amount__c = 100;
		r3.Installment_Period__c = 'Weekly';
		r3.Date_Established__c = System.today();
		r3.Schedule_Type__c = 'Multiply By';
		try {
			insert r3;
		} catch (exception e) {
			
		}
		//insert should fail because there is no Contact
		system.assertEquals(null,r3.id);
	}
	
	static testMethod void bulkInsertOpportunities()
	{
		Integer contactCount = 20;
		Integer recurringDonationCount = 20;
		Integer opportunityCount = 20;
		
		List<Contact> contacts = new List<Contact>();
		List<Recurring_Donation__c> recurringDonations = new List<Recurring_Donation__c>();
		
		Account a = new Account();
        a.Name = 'test Individual';
        insert a;
		
		for(Integer i=0;i<contactCount;i++){
			Contact c = new Contact();
	        c.FirstName = 'test';
	        c.LastName = 'contact';
	        c.AccountId = a.Id;
	        contacts.add(c);
		}
		insert contacts;
		
		for(Integer i=0;i<recurringDonationCount;i++){
			Recurring_Donation__c r1 = new Recurring_Donation__c();
			r1.Name = 'test';
			r1.Installments__c = opportunityCount;
			r1.Contact__c = contacts[i].Id;
			r1.Amount__c = 100;
			r1.Installment_Period__c = 'Yearly';
			r1.Date_Established__c = System.today();
			r1.Schedule_Type__c = 'Multiply By';
			recurringDonations.add(r1);
		}
		test.startTest();
		insert recurringDonations;
		test.stopTest();
	}
}
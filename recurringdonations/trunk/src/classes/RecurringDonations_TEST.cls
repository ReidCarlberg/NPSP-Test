/*
	Copyright (c) 2009, Salesforce.com Foundation
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* Neither the name of the Salesforce.com Foundation nor the names of
	  its contributors may be used to endorse or promote products derived
  	  from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
	COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
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
		
		Opportunity[] installments1 = [select amount,accountid from Opportunity where Recurring_Donation__c = :r1.id];
		system.assertEquals(1,installments1.size());
		system.assertEquals(100,installments1[0].Amount);
		system.assertEquals(a.id,installments1[0].AccountId);
		
		
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
	
	static testMethod void deleteRecurringDonation()
	{
		Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
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
	}
	
	
}
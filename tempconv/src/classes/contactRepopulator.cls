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
public class contactRepopulator 
{
	public Integer inputContacts {get; set;}

	Integer count = 0;
	public PageReference incrementCounter() 
	{
		count++;
		return null;
	}
	public Integer getCount() 
	{
		return count;
	}

    public contactRepopulator(ApexPages.StandardController controller) 
    {
    }

	public PageReference doPopulate() 
   	{
   		Integer i;
   		Contact[] c = new List<Contact>();
   		
   		if(inputContacts > 1000)
   		{
   			inputContacts = 1000;
   		}
   		if(inputContacts < 1)
   		{
   			inputContacts = 1;
   		}

		for(i=1; i<inputContacts; i=i+1)
		{
			c.add(new Contact(FirstName = 'John' + i, LastName='Doe' + i));
		}

		insert c;
   		return null;
   	}

	public PageReference doPurge() 
   	{
	   	List<Contact> c;
		List<Account> a;
		
		c = [SELECT c.npe6__Step_1_Complete__c, c.npe01__WorkPhone__c, c.npe01__WorkEmail__c, c.npe01__SystemIsIndividual__c, 
			c.npe01__SystemAccountProcessor__c, c.npe01__Secondary_Address_Type__c, c.npe01__Private__c, 
			c.npe01__Primary_Address_Type__c, c.npe01__Preferred_Email__c, c.npe01__PreferredPhone__c, c.npe01__Organization_Type__c, 
			c.npe01__Lifetime_Giving_History_Amount__c, c.npe01__Last_Donation_Date__c, c.npe01__HomeEmail__c, 
			c.npe01__AlternateEmail__c, c.Title, c.SystemModstamp, c.Salutation, c.ReportsToId, c.Phone, c.OwnerId, c.OtherStreet, 
			c.OtherState, c.OtherPostalCode, c.OtherPhone, c.OtherCountry, c.OtherCity, c.Name, c.MobilePhone, c.MasterRecordId, 
			c.MailingStreet, c.MailingState, c.MailingPostalCode, c.MailingCountry, c.MailingCity, c.LeadSource, c.LastName, 
			c.LastModifiedDate, c.LastModifiedById, c.LastCUUpdateDate, c.LastCURequestDate, c.LastActivityDate, c.IsDeleted, 
			c.Id, c.HomePhone, c.FirstName, c.Fax, c.EmailBouncedReason, c.EmailBouncedDate, c.Email, c.Description, c.Department, 
			c.CreatedDate, c.CreatedById, c.Birthdate, c.AssistantPhone, c.AssistantName, c.AccountId 
			FROM Contact c limit 1000];
		
		a = [SELECT a.npe6__Step_2_Complete__c, a.npe6__NumberofLocations__c, a.npe01__One2OneContact__c, 
			a.npe01__LifetimeDonationHistory_Number__c, a.npe01__LifetimeDonationHistory_Amount__c, a.npe01__LastDonationDate__c, 
			a.npe01__FirstDonationDate__c, a.Website, a.Type, a.TickerSymbol, a.SystemModstamp, a.Site, a.Sic, a.ShippingStreet, 
			a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, a.ShippingCity, a.RecordTypeId, a.Rating, a.Phone, a.ParentId, 
			a.Ownership, a.OwnerId, a.NumberOfEmployees, a.Name, a.MasterRecordId, a.LastModifiedDate, a.LastModifiedById, 
			a.LastActivityDate, a.IsDeleted, a.Industry, a.Id, a.Fax, a.Description, a.CreatedDate, a.CreatedById, a.BillingStreet, 
			a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity, a.AnnualRevenue, a.AccountNumber 
			FROM Account a limit 1000];
		
		Database.DeleteResult[] contactDels = Database.delete(c);
		Database.DeleteResult[] accountDels = Database.delete(a);

   		return null;
   	}
}
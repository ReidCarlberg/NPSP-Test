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
public class RecurringDonations {

	/// <name> RecurringDonations </name>
	/// <summary> Default Constructor </summary>
	public RecurringDonations(){}


	/// <name> triggerAction </name>
	/// <summary> contains possible actions for a trigger </summary>
	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}


	/// <name> RecurringDonations </name>
	/// <summary> Overloads the RecurringDonations object constructor to handle RecurringDonation processing </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	/// <param name="oldRecurringDonations"> RecurringDonation object values before trigger event </param>
	/// <param name="ta"> Trigger action that is occuring </param>
	public RecurringDonations(Recurring_Donation__c[] recurringDonations, Recurring_Donation__c[] oldRecurringDonations, triggerAction ta)
	{
		List<Recurring_Donation__c> contactRecDonations = new List<Recurring_Donation__c>();
		List<Recurring_Donation__c> accountRecDonations = new List<Recurring_Donation__c>();
		List<Recurring_Donation__c> recDonationDeletes = new List<Recurring_Donation__c>();

		for(Recurring_Donation__c r : recurringDonations)
		{
			if (ta==triggerAction.beforeInsert)
			{
				if (r.Organization__c == null && r.Contact__c == null)
				{
					r.addError('You must select an Organization or Contact');
				}
				if ( r.Installments__c > 50 )
				{
					r.addError('You must specify fewer than 50 installments.');
				}
			}
			if ( ta==triggerAction.afterInsert )
			{
				if (r.Contact__c != null)
				{
					contactRecDonations.add(r);
				} else
				{
					accountRecDonations.add(r);
				}
			}
			if ( ta==triggerAction.beforeDelete )
			{
				recDonationDeletes.add(r);
			}
		}

		if ( contactRecDonations.size() > 0 )
		{
			insertOpptys(contactRecDonations, 'contact');
		}
		if ( accountRecDonations.size() > 0 )
		{
			insertOpptys(accountRecDonations, 'account');
		}
		if ( recDonationDeletes.size() > 0 )
		{
			deleteRecDonations(recDonationDeletes);
		}
	}

	/// <name> insertContactOpportunities </name>
	/// <summary> Creates new Opportunities when a RecurringDonation is inserted </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	public static void insertOpptys( Recurring_Donation__c[] recurringDonations, String donorType )
	{
		//Lists used for final Insert
		List<Opportunity> opportunityInserts = new List<Opportunity>();
		List<OpportunityContactRole> contactRoleInserts = new List<OpportunityContactRole>();

		//Create a list of ContactIds used in these RecurringDonations
		List<Id> contactIds = new List<Id>();
		Map<Id,Id> recConMap = new Map<Id,Id>();
		for( Recurring_Donation__c r : recurringDonations )
		{
			if ( r.Contact__c != null )
			{
				contactIds.add(r.Contact__c);
				recConMap.put(r.Id,r.Contact__c);
			}
		}

		//Create a Map of Contact Ids and Contact Records
		Map<Id,Contact> contactMap;
		Map<Id,Account> accountMap;
		if ( contactIds.size() > 0 )
		{
			contactMap = new Map<Id,Contact>([Select Id, AccountId from Contact where Id in :contactIds and AccountId != null]);
		}


		//Loop through the Recurring Donations and create the appropriate number of Opportunities
		for(Recurring_Donation__c r : recurringDonations)
		{
			Decimal installs = Decimal.valueOf(r.Installments__c);
			Integer installments = installs.intValue();
				
			for ( Integer j=0;j<installments;j++ )
			{
				Opportunity opp = new Opportunity();
				
				if ( r.Organization__c != null )
				{
					opp.AccountId = r.Organization__c;
				}
				else
				if ( contactMap.containsKey(r.Contact__c) )
				{
					Contact c = contactMap.get(r.Contact__c);
					opp.AccountId = c.AccountId;
				}
				
				if (j + 1 == installments && installments * r.Installment_Amount__c != r.Total__c)
				{
					opp.Amount = r.Total__c - (j * r.Installment_Amount__c);
				} else {
					opp.Amount = r.Installment_Amount__c;
				}
				
				if (r.Installment_Period__c == 'Yearly')
				{
					opp.CloseDate = (r.Date_Established__c).addYears(j);
				} else
				if (r.Installment_Period__c == 'Quarterly')
				{
					opp.CloseDate = (r.Date_Established__c).addMonths(3*j);
				} else
				if (r.Installment_Period__c == 'Monthly')
				{
					opp.CloseDate = (r.Date_Established__c).addMonths(j);
				} else
				if (r.Installment_Period__c == 'Weekly')
				{
					opp.CloseDate = (r.Date_Established__c).addDays(7*j);
				} else
				{
					opp.CloseDate = (r.Date_Established__c);
				}
				
				String oName = '';
				oName += r.Donor_Name__c; 
				oName += ' Donation (';
				oName += j+1;
				oName += ' of ';
				oName += installments;
				oName += ') ';
				oName += (opp.CloseDate).Month();
				oName += '/';
				oName += (opp.CloseDate).Day();
				oName += '/';
				oName += (opp.CloseDate).Year();
				opp.Name = oName;
				
				opp.StageName = 'Pledged';
				opp.Recurring_Donation__c = r.Id;
				opportunityInserts.add(opp);
				if ( opportunityInserts.size() == 100 )
				{
					Database.SaveResult[] lsr = Database.insert(opportunityInserts, false);
					opportunityInserts.clear();
				}
			}
		}
		
		if( opportunityInserts.size() > 0 )
		{
			Database.SaveResult[] lsr = Database.insert(opportunityInserts, false);
			Integer i = 0;
   	        for (Database.SaveResult s : lsr)
       	    {
            	if ( s.isSuccess() == true )
   	        	{
       	    		OpportunityContactRole ocr = new OpportunityContactRole();
           			ocr.OpportunityId = s.getId();
           			ocr.Role = 'Donor';
            		ocr.IsPrimary = true;
					if ( recConMap.containsKey(opportunityInserts[i].Recurring_Donation__c) )
					{
	           			ocr.ContactId = recConMap.get(opportunityInserts[i].Recurring_Donation__c);
   		        		contactRoleInserts.add(ocr);
						if ( contactRoleInserts.size() == 100 )
						{
							Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
							contactRoleInserts.clear();
						}
					}
       	    	}
           		i++;
			}
			if ( contactRoleInserts.size() > 0 )
			{
				Database.SaveResult[] osr = Database.insert(contactRoleInserts, false);
			}
		}
	}


	/// <name> deleteRecDonations </name>
	/// <summary> Validates that a Recurring Donation can be deleted </summary>
	/// <param name="recurringDonations"> RecurringDonation objects that are being triggered </param>
	public static void deleteRecDonations(Recurring_Donation__c[] recurringDonations)
	{
		Map<Id,Id> recDonationMap = new Map<Id,Id>();
		List<Id> recDonationIds = new List<Id>();
		
		for(Recurring_Donation__c r : recurringDonations)
		{
			recDonationIds.add(r.Id);
		}
		for (Opportunity o : [Select Id, Recurring_Donation__c from Opportunity where Recurring_Donation__c in :recDonationIds])
		{
			recDonationMap.put(o.Recurring_Donation__c,o.Id);
		}
		for(Recurring_Donation__c r : recurringDonations)
		{
			if(recDonationMap.containsKey(r.Id))
			{
				r.addError('You must delete the related Donations before you can delete this recurring donation');
			}
		}
	}
		
	
	/// <name> RecurringDonations_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void RecurringDonations_Test()
	{
  		RecurringDonations testRecurringDonations = new RecurringDonations();
	}


	/// <name> insertOpportunities_Test </name>
	/// <summary> test method for insertOpportunities function </summary>
	static testMethod void insertOpportunities_Test()
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
		} catch (exception e) {}

		Recurring_Donation__c r1 = new Recurring_Donation__c();
		r1.Name = 'test';
		r1.Installments__c = 1;
		r1.Contact__c = c.Id;
		r1.Amount__c = 100;
		r1.Installment_Period__c = 'Yearly';
		r1.Date_Established__c = System.today();
		r1.Schedule_Type__c = 'Multiply By';
		insert r1;

		Recurring_Donation__c r2 = new Recurring_Donation__c();
		r2.Name = 'test';
		r2.Installments__c = 3;
		r2.Organization__c = a.Id;
		r2.Amount__c = 100;
		r2.Installment_Period__c = 'Yearly';
		r2.Date_Established__c = System.today();
		r2.Schedule_Type__c = 'Multiply By';
		insert r2;
		
		try{
			delete r2;
		} catch (exception e1) {}
	}


}
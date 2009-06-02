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
global class Households {

    /// <name> Households </name>
    /// <summary> Default Constructor </summary>
    public Households(){}

    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    /// <name> Households </name>
    /// <summary> Overloads the Households object constructor to handle Household processing </summary>
    /// <param name="households"> Household objects that are being triggered </param>
    /// <param name="oldHouseholds"> Household object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    public Households(Contact[] contacts, Contact[] oldContacts, triggerAction ta)
    {
        List<Contact> householdInserts = new List<Contact>();
        List<Contact> contactEvaluations = new List<Contact>();
        List<Contact> householdDeletes = new List<Contact>();

        Integer i = 0;
        for(Contact c : contacts) {
            //AFTER INSERT
            if ( ta==triggerAction.afterInsert )
            {
                if (c.Household__c == null && c.SystemHouseholdProcessor__c == 'All New or Edited Contacts')
                {
                    householdInserts.add(c);
                } else
                if (c.Household__c == null && c.SystemHouseholdProcessor__c == 'All Individual Contacts')
                {
					contactEvaluations.add(c);
	            }
            }

            //AFTER UPDATE
            if ( ta==triggerAction.afterUpdate )
            {
                if (c.Household__c == null && c.SystemHouseholdProcessor__c == 'All New or Edited Contacts')
                {
                    householdInserts.add(c);
                } else
                if (c.Household__c == null && c.SystemHouseholdProcessor__c == 'All Individual Contacts')
                {
					contactEvaluations.add(c);
	            }
			}

            //AFTER DELETE
            if ( ta==triggerAction.afterDelete )
            {
                if (c.Household__c != null )
                {
                    householdDeletes.add(c);
                }
            }

            i += 1;
        }

        if (householdInserts.size() > 0)
        {
            insertHousehold(householdInserts);
        }
        if (contactEvaluations.size() > 0)
        {
            evaluateContacts(contactEvaluations);
        }
        if (householdDeletes.size() > 0)
        {
            deleteHousehold(householdDeletes);
        }

    }


    /// <name> insertHousehold </name>
    /// <summary> Creates a new Household record when a Contact does not have one </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    public static void insertHousehold(Contact[] contacts)
    {
        List<Household__c> householdInserts = new List<Household__c>();
        for(Contact c : contacts)
        {
			Household__c h = new Household__c();
			String hName = c.LastName;
			hName += ' Household';
			h.Name = hName;
			h.MailingStreet__c = c.MailingStreet;
			h.MailingCity__c = c.MailingCity;
			h.MailingState__c = c.MailingState;
			h.MailingPostalCode__c  = c.MailingPostalCode;
			h.MailingCountry__c = c.MailingCountry;
			h.HouseholdPhone__c = c.HomePhone;
			h.HouseholdEmail__c = c.Email;
			householdInserts.add(h);
        }
		List<Contact> contactUpdates = new List<Contact>();
        if (householdInserts.size() > 0)
        {
            Database.SaveResult[] lsr = Database.insert(householdInserts, false);
            Integer i = 0;
            for (Contact c : contacts)
            {
                if (lsr[i].isSuccess() == true)
                {
                    Contact clone = c.Clone(true,false);
                    clone.Household__c = lsr[i].getId();
                    contactUpdates.add(clone);
                }
                i += 1;
            }
        }
        if (contactUpdates.size() > 0)
        {
            Database.SaveResult[] lsr = Database.update(contactUpdates, false);
        }
    }
    

    /// <name> insertHousehold </name>
    /// <summary> Determines if a Contact Should have a household created </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    public static void evaluateContacts(Contact[] contacts)
    {
        List<Contact> householdInserts = new List<Contact>();

        List<Id> accountIds = new List<Id>();
        for(Contact c : contacts)
        {
        	if (c.accountId != null)
        	{
	            accountIds.add(c.AccountId);
        	}
        }

        Map<Id,Account> contactAccountMap = new Map<Id,Account>([Select Id, npe01__SYSTEMIsIndividual__c, Name from Account where Id in :accountIds]);
        for(Contact c : contacts)
        {
            if (c.AccountId != null)
            {
                Account acc = contactAccountMap.get(c.AccountId);
                if (acc.npe01__SYSTEMIsIndividual__c == true)
                {
                    householdInserts.add(c);
                }
            } else
            if (c.AccountId == null)
            {
				householdInserts.add(c);
            }
        }
		if ( householdInserts.size() > 0)
		{
        	insertHousehold(householdInserts);
		}
    }


    /// <name> deleteHousehold </name>
    /// <summary> Deletes a Household record when no Contacts are related to it </summary>
    /// <param name="Contact"> List of contacts meeting trigger criteria </param>
    public static void deleteHousehold(Contact[] contacts)
    {
        List<Id> householdDeletes = new List<Id>();
		Map<Id,Integer> householdCountMap = new Map<Id,Integer>();

		//Generate a list of Household Ids
        for(Contact c : contacts)
        {
        	if (c.Household__c != null)
        	{
				householdCountMap.put(c.Household__c,0);
        	}
        }

		//Loop through all Contacts at one of the Household Ids
        for (Contact c : [Select Id, Household__c from Contact where Household__c in :householdCountMap.keyset()])
        {
			Integer lastCount = householdCountMap.get(c.Household__c);
			lastCount += 1;
			householdCountMap.put(c.Household__c,lastCount);
        }

		//Loop through all the contacts to determine if they can be deleted
		for (Contact c : contacts)
		{
			//If there are no other Contacts on the Account
			if ( householdCountMap.get(c.Household__c) < 1 )
			{
				householdDeletes.add(c.Household__c);
			}
		}

        if (householdDeletes.size() > 0)
        {
            Database.DeleteResult[] lsr = Database.delete(householdDeletes, false);           
        }
    }


    /// <name> getHouseholdLastTransaction </name>
    /// <summary>  </summary>
    webservice static String getHouseholdLastTransaction(Id householdId)
	{
		List<Id> contactIds = new List<Id>();
		List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
		for (contact c : contacts)
		{
			contactIds.add(c.Id);
		}
		Double total = 0;
		List<OpportunityContactRole> ocr = [Select Opportunity.Amount, Opportunity.CloseDate from OpportunityContactRole where ContactId in :contactIds Order By Opportunity.CloseDate DESC];
		if (ocr.size() > 0)
		{
			Date lastTransaction = ocr[0].Opportunity.CloseDate;
			return String.valueOf(lastTransaction);
		}
		return null;
	}


    /// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
	webservice static String getHouseholdTransactionTotal(Id householdId)
	{
		List<Id> contactIds = new List<Id>();
		List<Contact> contacts = [Select Id from Contact where Household__c = :householdId];
		for (contact c : contacts)
		{
			contactIds.add(c.Id);
		}
		Double total = 0;
		for( OpportunityContactRole ocr : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where ContactId in :contactIds])
		{
			if ( ocr.Opportunity.Amount != null )
			{
				total += ocr.Opportunity.Amount;
			}
		}
		String totalString = '$';
		Decimal totalFormat = Decimal.valueOf(total).setScale(2);
		totalString += totalFormat;
		return String.valueOf(totalString);
	}


///////////////////////////// TEST METHODS /////////////////////////////


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
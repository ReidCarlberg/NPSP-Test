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
global class IndividualAccounts
{

    /// <name> IndividualAccounts </name>
    /// <summary> Default Constructor </summary>
    public IndividualAccounts(){}

    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    /// <name> IndividualAccounts </name>
    /// <summary> Overloads the IndividualAccounts object constructor to handle Contact processing </summary>
    /// <param name="contacts"> Contact objects that are being triggered </param>
    /// <param name="oldContacts"> Contact object values before trigger event </param>
    /// <param name="ta"> Trigger action that is occuring </param>
    public IndividualAccounts(Contact[] contacts, Contact[] oldContacts, triggerAction ta)
    {
        List<Contact> individualInserts = new List<Contact>();
        List<Contact> individualUpdates = new List<Contact>();
        List<Contact> contactDeletes = new List<Contact>();
        List<Contact> bucketContacts = new List<Contact>();
        Map<Id,Id> accountUpdates = new Map<Id,Id>();
        
        Integer i = 0;
        for(Contact c : contacts)
        {
            //BEFORE INSERT
            if ( ta==triggerAction.beforeInsert )
            {
            	/*one-to-one account should be created if:
            		1. The account isn't set by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The one-to-one model is chosen in the SystemAccountProcessor__c
            	*/
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                	//flag this contact as an indivudual--Why?
                    c.SystemIsIndividual__c = true;
                    individualInserts.add(c);
                }
                /*contact should be connected to the bucket account if:
            		1. The account isn't set by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The Individual model is chosen in the SystemAccountProcessor__c
            	*/
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'Individual')
                {
                    c.SystemIsIndividual__c = true;
                    bucketContacts.add(c);
                }
            }

            //AFTER INSERT
            if ( ta==triggerAction.afterInsert )
            {
            	/*grab the Accounts that need to have the newly assigned Contact Id to them if:
            		1. If the contact is connected to an Account
            		2. The Contact is flagged as an individual
            		3. The one-to-one model is chosen in the SystemAccountProcessor__c
            	*/
                if ( c.AccountId != null && c.SystemIsIndividual__c == true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                	//contacts are connected to Accounts, make the connection in the other direction
                    accountUpdates.put(c.AccountId, c.Id);
                }
                
                //there is no after insert processing for the bucket account model
            }

            //BEFORE UPDATE
            if ( ta==triggerAction.beforeUpdate )
            {
            	/*one-to-one account should be created if:
            		1. The account has been blanked out by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The one-to-one model is chosen in the SystemAccountProcessor__c
            	*/
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                    individualInserts.add(c);
                }          
                /*contact should be connected to the bucket account if:
            		1. The account has been blanked out by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The Individual model is chosen in the SystemAccountProcessor__c
            	*/ 
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'Individual')
                {
                    c.SystemIsIndividual__c = true;
                    bucketContacts.add(c);
                }
            }

            //AFTER UPDATE
            if ( ta==triggerAction.afterUpdate )
            {
            	/*if the contact is in the one-to-one model, changes to fields on the Contact
	            will require data changes on the Account to keep some fields in sync
            	*/
                if (c.Organization_Type__c == 'One-to-One Individual')
                {
                    if (
                        c.FirstName != oldContacts[i].FirstName ||
                        c.LastName != oldContacts[i].LastName ||
                        c.MailingStreet != oldContacts[i].MailingStreet ||
                        c.MailingCity != oldContacts[i].MailingCity ||
                        c.MailingState != oldContacts[i].MailingState ||
                        c.MailingPostalCode != oldContacts[i].MailingPostalCode ||
                        c.MailingCountry != oldContacts[i].MailingCountry ||
                        c.OtherStreet != oldContacts[i].OtherStreet ||
                        c.OtherCity != oldContacts[i].OtherCity ||
                        c.OtherState != oldContacts[i].OtherState ||
                        c.OtherPostalCode != oldContacts[i].OtherPostalCode ||
                        c.OtherCountry != oldContacts[i].OtherCountry ||
                        c.Phone != oldContacts[i].Phone ||
                        c.Fax != oldContacts[i].Fax
                    ) {
                        individualUpdates.add(c);
                    }
                }
            }
            i += 1;
        }
        if (individualInserts.size() > 0)
        {
        	//add the newly created or updated Contacts that need a new individual account
            insertIndividualAccount(individualInserts);
        }
        if (bucketContacts.size() > 0)
        {
        	//add the newly created or updated Contact to the bucket account
            attachToIndividualAccount(bucketContacts);
        }
        if (individualUpdates.size() > 0)
        {
        	//contacts in the one-to-one model that are changing for syncing with account
            updateIndividualAccount(individualUpdates);
        }
        if (accountUpdates.size() > 0)
        {
        	//update Accounts that have newly created Contacts connected to them
            updateAccounts(accountUpdates);
        }

    }

    /// <name> updateAccounts </name>
    /// <summary> Updates Accounts with the correct Individual Contact Id</summary>
    /// <param name="accounts"> Map of account Ids </param>
    public static void updateAccounts(Map<Id, Id> accounts)
    {
        List<Account> accountUpdates = new List<Account>(); 
        for (Id i : accounts.keySet())
        {
            Account a = new Account(Id=i,One2OneContact__c=accounts.get(i));
            accountUpdates.add(a);
        }
        if (accountUpdates.size() > 0)
        {
            Database.SaveResult[] lsr = Database.update(accountUpdates, false);
        }
    }


    /// <name> attachToIndividualAccount </name>
    /// <summary> Updates Contacts to relate to a single Individual Account</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public static void attachToIndividualAccount(Contact[] contacts)
    {
    	//grab the first Account that is named Individual
		List<Account> individuals = [Select Id from Account where name = 'Individual' ORDER BY CreatedDate Desc Limit 1];
		if (individuals.size() > 0)
		{
			for(Contact c : contacts)
			{
				//connect all Contacts to the bucket Account
				c.AccountId = individuals[0].Id;
			}
		} else
		{
			//if there is no bucket Account, the bucket model won't function unless we create one
            Account individual = new Account();
   	        individual.Name = 'Individual';
   	        //flag the account as an individual account
   	        individual.SYSTEMISINDIVIDUAL__c = true;
           	individual.Type = 'Bucket Individual';
            insert individual;

            for(Contact c : contacts)
   	        {
   	        	//connect Contact to bucket Account
       	        c.AccountId = individual.Id;
           	}
    	}
    }


    /// <name> insertIndividualAccount </name>
    /// <summary> Inserts a new Individual Account for an Individual Contact</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public static void insertIndividualAccount(Contact[] contacts)
    {
    	List<Id> contactIds = new List<Id>();
    	Map<Id,Id> conAccMap = new Map<Id,Id>();
		for (Contact c : contacts)
		{
			//make sure we're only working with Contacts that have already been inserted
			if (c.Id != null)
			{
				contactIds.add(c.Id);
			}
		}
		//get all the Accounts that are connected to the Contacts
    	for (Account acc : [Select Id, One2OneContact__c from Account where One2OneContact__c in :contactIds])
    	{
    		conAccMap.put(acc.One2OneContact__c,acc.Id);
    	}
    	
        List<Contact> contactUpdates = new List<Contact>();
        List<Account> accountInserts = new List<Account>();

        for(Contact c : contacts)
        {
        	//if we found an Account already connected to this Contact, connect the Contact to that Account
			if (conAccMap.containsKey(c.Id))
			{
				//if a user has blanked out the Account for a Contact, this will put it right back
				c.AccountId = conAccMap.get(c.Id);
			} else
			{
				//construct the individul account for the Contact
	            Account a = new Account();
    	        String aName = '';
        	    if (c.FirstName != null)
            	{
	            	aName += c.FirstName;
    	        	aName += ' ' ;
        	    }
	            aName += c.LastName; 
    	        a.Name = aName;
    	        //connect the Account to the Contact
        	    if (c.Id != null) {
	        	    a.One2OneContact__c = c.Id;
	            }
    	        a.Phone = c.Phone;
        	    a.Fax = c.Fax;
            	a.BillingStreet = c.MailingStreet;
	            a.BillingCity = c.MailingCity;
    	        a.BillingState = c.MailingState;
        	    a.BillingPostalCode = c.MailingPostalCode;
            	a.BillingCountry = c.MailingCountry;
	            a.ShippingStreet = c.OtherStreet;
    	        a.ShippingCity = c.OtherCity;
        	    a.ShippingState = c.OtherState;
            	a.ShippingCountry = c.OtherCountry;
            	//flag the account as an individual account
	            a.Type = 'One-to-One Individual';
    	        a.SYSTEMISINDIVIDUAL__c = true;
        	    accountInserts.add(a);
	        }
        }
        if (accountInserts.size() > 0) {
            Database.SaveResult[] lsr = Database.insert(accountInserts, false);
            Integer i = 0;
            for (Contact c : contacts)
            {
            	//for each success, write the new AccountId to the Contact. These 
                if (lsr[i].isSuccess() == true)
                {
                    c.AccountId = lsr[i].getId();
                }
                i += 1;
            }
        }
    }


    /// <name> updateIndividualAccount </name>
    /// <summary> Updates an Individual Account for an Individual Contact</summary>
    /// <param name="contacts"> Contacts meeting the trigger criteria</param>
    public void updateIndividualAccount(Contact[] contacts)
    {
    	Map<Id,Contact> accConMap = new Map<Id,Contact>();
		for (Contact c : contacts)
		{
			accConMap.put(c.AccountId,c);

		}
		//get the corresponding Accounts
		List<Account> accts = [Select a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, 
        a.ShippingCity, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity
        From Account a where a.Id IN :accConMap.keyset()];
    	
        List<Account> accountUpdates = new List<Account>();
        
        for(Account a : accts){     	
			Contact c = accConMap.get(a.Id);
			//if any address data has changed on the contact, push it all to the Account
            if (
	            c != null && (
	            c.MailingStreet != a.BillingStreet ||
	            c.MailingCity != a.BillingCity ||
	            c.MailingState != a.BillingState ||
	            c.MailingPostalCode != a.BillingPostalCode ||
	            c.MailingCountry != a.BillingCountry ||
	            c.OtherStreet != a.ShippingStreet ||
	            c.OtherCity != a.ShippingCity ||
	            c.OtherState != a.ShippingState ||
	            c.OtherPostalCode != a.ShippingPostalCode ||
	            c.OtherCountry != a.ShippingCountry)
            ) {
            	// Update Account fields
                a.BillingStreet = c.MailingStreet;
                a.BillingCity = c.MailingCity;
                a.BillingState = c.MailingState;
                a.BillingPostalCode = c.MailingPostalCode;
                a.BillingCountry = c.MailingCountry;
                a.ShippingStreet = c.OtherStreet;
                a.ShippingCity = c.OtherCity;
                a.ShippingState = c.OtherState;
                a.ShippingPostalCode = c.OtherPostalCode;
                a.ShippingCountry = c.OtherCountry;
            	
            	accountUpdates.add(a);
            }
		}	

        if ( accountUpdates.size() > 0 )
        {
            Database.SaveResult[] lsr = Database.update(accountUpdates, false);
        }
    }

	/// <name> getContactDonationHistory </name>
	/// <summary> Called by sControl to display total giving amount </summary>
	webservice static decimal getContactDonationHistory(Id contactId){
		Decimal sum = 0;
		for (OpportunityContactRole o : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId]) 
		{
			sum += o.Opportunity.Amount;
		}
		return sum;
	}


	/// <name> getContactLastDonation </name>
	/// <summary> Called by sControl to display last donation date </summary>
		webservice static String getContactLastDonation(Id contactId){
		Date lastDonation = null;
		List<OpportunityContactRole> ocr = [Select Opportunity.CloseDate, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId ORDER BY Opportunity.CloseDate DESC Limit 100]; 
		if ( ocr.size() > 0)
		{
			return String.ValueOf(ocr[0].Opportunity.CloseDate);
		}
		else
		{
			return '';
		}
	}

/* TESTS -------------------------------------------------------------------------------*/

	/// <name> IndividualAccounts_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void IndividualAccounts_Test() {
  		IndividualAccounts testIndividualAccounts = new IndividualAccounts();
	}


    /// <name> updateAccounts_Test </name>
    /// <summary> Test Method for updateAccounts</summary>
    static testMethod void updateAccounts_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact');
        insert con;
        
        con.AccountId = null;
        update con;
        
        delete con;
    }


    /// <name> attachToIndividualAccount_Test </name>
    /// <summary> Test Method for attachToIndividualAccount</summary>
    static testMethod void attachToIndividualAccount_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'Individual');
        insert con;
    }

    /// <name> insertIndividualAccount_Test </name>
    /// <summary> Test Method for insertIndividualAccount</summary>
    static testMethod void insertIndividualAccount_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'One-to-One');
        insert con;

		con.LastName='Doe';
		update con;
    }

    /// <name> updateIndividualAccount_Test </name>
    /// <summary> Test Method for updateIndividualAccount</summary>
    static testMethod void updateIndividualAccount_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'Individual');
        insert con;
        
        con.MailingCity = 'San Francisco';       
        con.AccountId = null;
        update con;
        
    }
    
    /// <name> updateIndividualAccount_Test </name>
    /// <summary> Test Method for updateIndividualAccount</summary>
    static testMethod void updateIndividualAccountAddress_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'One-to-One');
        insert con;
        
        con.MailingCity = 'San Francisco';       
        update con;
        
        List<Account> acct = [Select a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, 
        a.ShippingCity, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity
        From Account a where a.One2OneContact__c = :con.Id];
        
        if(acct.size() > 0 && acct[0].BillingCity.equals('San Francisco'))acct[0].BillingCity = 'Atlanta';
        update acct;
        
        
    }

    /// <name> getContactDonationHistory_Test </name>
    /// <summary> Test Method for getContactDonationHistory</summary>
    static testMethod void getContactDonationHistory_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'One-to-One');
        insert con;

		Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed/Won',CloseDate=System.today());
		insert o;
		
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
		insert ocr;

		Decimal sum = getContactDonationHistory(con.id);
    }

    /// <name> getContactLastDonation_Test </name>
    /// <summary> Test Method for getContactLastDonation</summary>
    static testMethod void getContactLastDonation_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = 'One-to-One');
        insert con;

		Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed/Won',CloseDate=System.today());
		insert o;
		
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
		insert ocr;

		String sum = getContactLastDonation(con.id);
    }

}
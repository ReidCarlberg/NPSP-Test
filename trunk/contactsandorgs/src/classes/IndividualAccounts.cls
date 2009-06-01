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
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == Constants.ONE_TO_ONE_PROCESSOR)
                {

                    individualInserts.add(c);
                }
                /*contact should be connected to the bucket account if:
            		1. The account isn't set by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The Individual model is chosen in the SystemAccountProcessor__c
            	*/
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == Constants.BUCKET_PROCESSOR)
                {

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
                if ( c.AccountId != null && c.Private__c != true && c.SystemAccountProcessor__c == Constants.ONE_TO_ONE_PROCESSOR && c.Type_of_Account__c=='Individual')
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
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == Constants.ONE_TO_ONE_PROCESSOR)
                {
                    individualInserts.add(c);
                }          
                /*contact should be connected to the bucket account if:
            		1. The account has been blanked out by the user
            		2. The Private__c checkbox isn't set by the user
            		3. The Individual model is chosen in the SystemAccountProcessor__c
            	*/ 
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == Constants.BUCKET_PROCESSOR)
                {

                    bucketContacts.add(c);
                }
            }

            //AFTER UPDATE
            if ( ta==triggerAction.afterUpdate )
            {
            	/*if the contact is in the one-to-one model, changes to fields on the Contact
	            will require data changes on the Account to keep some fields in sync
            	*/
            	
                if (c.Organization_Type__c == Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
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
		List<Account> individuals = [Select Id from Account where name = :Constants.BUCKET_ACCOUNT_NAME ORDER BY CreatedDate Desc Limit 1];
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
   	        individual.Name = Constants.BUCKET_ACCOUNT_NAME;
   	        //flag the account as an individual account
   	        individual.SYSTEMISINDIVIDUAL__c = true;
           	individual.Type = Constants.BUCKET_ORGANICATION_TYPE;
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
	            a.Type = Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
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
		List<Account> accts = [Select a.name,a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, 
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
	            c.OtherCountry != a.ShippingCountry ||
	            c.FirstName + ' ' + c.LastName != a.Name)
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
                a.Name = c.FirstName + ' ' + c.LastName;
            	
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

/* TESTING CONTACT AND ACCOUNT PLUMBING ------------------------------------------------*/

	/// <name> IndividualAccounts_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void IndividualAccounts_Test() {
  		IndividualAccounts testIndividualAccounts = new IndividualAccounts();
	}

 	/// <name> insertPrivate_Test </name>
    /// <summary> Test Method for inserting a Contact that should get no account </summary>
    static testMethod void insertPrivate_Test()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
        Contact con = new Contact(
        	FirstName=newContactfirstName,
        	LastName=newContactLastName,
        	Private__c=true
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
		
		//contact should have no AccountId
		system.assertEquals(null,insertedContacts[0].AccountId);
    
    }

 	/// <name> insertUpdateOneToOne_Test </name>
    /// <summary> Test Method for inserting and updating a Contact in the One-to-One model</summary>
    static testMethod void insertUpdateOneToOne_Test()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
        	FirstName=newContactfirstName,
        	LastName=newContactLastName,
        	MailingStreet = newContactMailingStreet,
        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        Contact[] insertedContacts = [Select FirstName, LastName, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Account.BillingStreet,Organization_Type__c,Account.SYSTEMIsIndividual__c  from Contact where id=:con.id];
		
		//one contact should have been created
		system.assertEquals(1,insertedContacts.size());
		//the account should have the right type
		system.assertEquals(Constants.ONE_TO_ONE_ORGANIZATION_TYPE,insertedcontacts[0].Organization_Type__c);
		//the account should be flagged as an individual
		system.assertEquals(true,insertedcontacts[0].Account.SYSTEMIsIndividual__c );
		//the account should have been named correctly
		system.assertEquals(newContactfirstName + ' ' + newContactLastName,insertedcontacts[0].Account.Name);
		//relationship should be bi-directional
		system.assertEquals(insertedcontacts[0].id,insertedcontacts[0].Account.npe01__One2OneContact__c);
		//addresses should be sync'd
		system.assertEquals(newContactMailingStreet,insertedcontacts[0].Account.BillingStreet);
		system.assertEquals(insertedcontacts[0].MailingStreet,insertedcontacts[0].Account.BillingStreet);
		
		String updatedContactLastName = 'Contact_forTestsChange';
		String updatedOtherCity = 'Seattle';
		con.LastName=updatedContactLastName;
		con.OtherCity = updatedOtherCity;
		update con;
		
		Contact[] updatedContacts = [Select FirstName, LastName, Account.Name,Account.npe01__One2OneContact__c,MailingStreet,OtherCity,Account.BillingStreet,Account.ShippingCity from Contact where id=:con.id];
		
		//the account should have been named correctly
		system.assertEquals(updatedContacts[0].firstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
		//relationship should be bi-directional
		system.assertEquals(updatedContacts[0].id,updatedContacts[0].Account.npe01__One2OneContact__c);
		//addresses should be sync'd
		system.assertEquals(newContactMailingStreet,updatedContacts[0].MailingStreet);
		system.assertEquals(updatedOtherCity,updatedContacts[0].Account.ShippingCity);
		system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
		system.assertEquals(updatedContacts[0].OtherCity,updatedContacts[0].Account.ShippingCity);
		
    }
    /// <name> detachOneToOne_Test </name>
    /// <summary> Test Method for separating a Contact from it's One-to-One account</summary>
    static testMethod void detachOneToOne_Test()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
        Contact con = new Contact(
        	FirstName=newContactfirstName,
        	LastName=newContactLastName,
        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id=:con.id];		
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        
        con.AccountId = null;
        con.LastName = updatedContactLastName;
        update con;
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c from Contact where id=:con.id];
		
		//AccountId of updated contact should match the orignial Account
		system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
		
        delete con;
    }
    
    /// <name> editContactDuringDetachOneToOne_Test </name>
    /// <summary> Test Method for editing a contact while it is being detached from it's One-to-One Account. This was a bug (#37)</summary>
    static testMethod void editContactDuringDetachOneToOne_Test()
    {
    	String newContactfirstName = 'test';
    	String newContactLastName = 'Contact_forTests';
    	String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
        	FirstName=newContactfirstName,
        	LastName=newContactLastName,
        	MailingStreet = newContactMailingStreet,
        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        Contact[] insertedContacts = [Select AccountId from Contact where id=:con.id];		
        
        Id originalAccountId = insertedContacts[0].AccountId;
        
        String updatedContactLastName = 'Contact_forTestsChange';
        String updateContactMailingStreet = '234 Oak St';
        
        con.AccountId = null;
        con.LastName = updatedContactLastName;
        con.MailingStreet = updateContactMailingStreet;
        update con;
        
        Contact[] updatedContacts = [Select FirstName, LastName, AccountId,Account.Name,Account.npe01__One2OneContact__c,MailingStreet,Organization_Type__c,Account.BillingStreet from Contact where id=:con.id];
		
		//AccountId of updated contact should match the orignial Account
		system.assertEquals(originalAccountId,updatedContacts[0].AccountId);
		
		//org type should be set correctly
		system.assertEquals(Constants.ONE_TO_ONE_ORGANIZATION_TYPE,updatedContacts[0].Organization_Type__c);
		
		//the account should have been named correctly
		system.assertEquals(updatedContacts[0].FirstName + ' ' + updatedContacts[0].LastName,updatedContacts[0].Account.Name);
		
		//addresses should be sync'd
		system.assertEquals(updateContactMailingStreet,updatedContacts[0].MailingStreet);
		system.assertEquals(updatedContacts[0].MailingStreet,updatedContacts[0].Account.BillingStreet);
        
        delete con;
    }

    /// <name> attachToIndividualAccount_Test </name>
    /// <summary> Test Method for a new Contact in the Bucket Individual model </summary>
    static testMethod void attachToIndividualAccount_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR);
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id=:con.id];
		//the contact should have the right type
		system.assertEquals(Constants.BUCKET_ORGANICATION_TYPE,insertedcontacts[0].Organization_Type__c);
		//the account should have been named correctly
		system.assertEquals(Constants.BUCKET_ACCOUNT_NAME,insertedcontacts[0].Account.Name);
        
    }
    
    /// <name> detachIndividualAccount_Test </name>
    /// <summary> Test Method for detaching a Contact from the bucket individual account </summary>
    static testMethod void detachIndividualAccount_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR);
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id=:con.id];
		
		Id AccountId = insertedContacts[0].AccountId;
		     
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Organization_Type__c from Contact where id=:con.id];
        
        //the contact should have the right type
		system.assertEquals(Constants.BUCKET_ORGANICATION_TYPE,updatedContacts[0].Organization_Type__c);
		//the account should have been named correctly
		system.assertEquals(Constants.BUCKET_ACCOUNT_NAME,updatedContacts[0].Account.Name);
		//the account should have the correct AccountId
		system.assertEquals(AccountId,updatedContacts[0].AccountId);        
        
    }

	/// <name> detachFromNormalAccountToBucket_Test </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in the bucket account. </summary>
    static testMethod void detachFromNormalAccountToBucket_Test()
    {
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].SystemIsIndividual__c);
        
        Contact con = new Contact(FirstName='test', LastName='contact678', AccountId = acct.id,SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR);
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.SystemIsIndividual__c,AccountId,Organization_Type__c from Contact where id=:con.id];
		
		//the contact should be connected to the account
		system.assertEquals(acct.id,insertedContacts[0].AccountId);
		//the account should not be an individual account
		system.assert(!insertedContacts[0].Account.SystemIsIndividual__c);
		     
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.SystemIsIndividual__c,Organization_Type__c from Contact where id=:con.id];
        
        //the account should be an individual account
		system.assert(updatedContacts[0].Account.SystemIsIndividual__c);
		//the account should not be the one we started with
		system.assertNotEquals(acct.id,updatedContacts[0].AccountId);  
		      
        
    }
    
    /// <name> detachFromNormalAccountToOneToOne_Test </name>
    /// <summary> Test Method for detaching a Contact from a normal account. It should land in a one-to-one account. </summary>
    static testMethod void detachFromNormalAccountToOneToOne_Test()
    {
        Account acct = new Account(Name='Test Account 876');
        insert acct;
        
        Account[] insertedAccount = [select SystemIsIndividual__c from Account where id = :acct.id];
        
        //the account should not be an individual one
        system.assert(!insertedAccount[0].SystemIsIndividual__c);
        
        Contact con = new Contact(FirstName='test', LastName='contact678', AccountId = acct.id,SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR);
        insert con;
        
        Contact[] insertedContacts = [Select Account.Name,Account.SystemIsIndividual__c,AccountId,Organization_Type__c from Contact where id=:con.id];
		
		//the contact should be connected to the account
		system.assertEquals(acct.id,insertedContacts[0].AccountId);
		//the account should not be an individual account
		system.assert(!insertedContacts[0].Account.SystemIsIndividual__c);
		     
        con.AccountId = null;
        update con;
        
        Contact[] updatedContacts = [Select Account.Name,AccountId,Account.SystemIsIndividual__c,Organization_Type__c from Contact where id=:con.id];
        
        //the account should be an individual account
		//system.assert(updatedContacts[0].Account.SystemIsIndividual__c);
		//the account should not be the one we started with
		system.assertNotEquals(acct.id,updatedContacts[0].AccountId);  
		      
        
    }
    
/* TESTING PHONE NUMBER WORKFLOW -------------------------------------------------------*/
 
    /// <name> createContactWithPhoneNoPref_Test </name>
    /// <summary> Test Method for creating a contact with a phone number and no preferences set. </summary>
    static testMethod void createContactWithPhoneNoPref_Test()
    {
    	//with no other prefs, phone should land in workphone__c and set PreferredPhone__c to 'work'.
    	String newPhone = '206-777-7777';
    	String preferredPhone = null;
    	String workPhoneString = 'Work';
    	Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,workPhone__c,PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newPhone,insertedContacts[0].WorkPhone__c);
        system.assertEquals(workPhoneString,insertedContacts[0].PreferredPhone__c);
        
    }
    
    /// <name> createContactWithPhoneNoPrefAlsoHomePhone_Test </name>
    /// <summary> Test Method for creating a contact with a phone number and a home number. </summary>
    static testMethod void createContactWithPhoneNoPrefAlsoHomePhone_Test()
    {
    	//with pref set to Home, HomePhone should land in Phone and set PreferredPhone__c to 'home'.
    	//currently Phone data is lost. See issue #46
    	String newPhone = '206-777-7777';
    	String newHomePhone = '888-898-9999';
    	String preferredPhone = 'Home';
    	Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,HomePhone=newHomePhone,PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,workPhone__c,HomePhone,PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
        system.assertEquals(newHomePhone,insertedContacts[0].HomePhone);
        system.assertEquals(null,insertedContacts[0].WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts[0].PreferredPhone__c);
        
    }
    
    /// <name> createContactWithPhonePrefSet_Test </name>
    /// <summary> Test Method for creating a contact with a phone number in Phone and the preferred phone set. </summary>
    static testMethod void createContactWithPhonePrefSet_Test()
    {
    	//with pref set to Home, HomePhone should land in Phone and set PreferredPhone__c to 'home'.
    	//these are currently commented out because it's not supported. See #47.
    	String newPhone = '206-777-7777';
    	String preferredPhone = 'Home';
    	Contact con = new Contact(FirstName='test', LastName='contact678',phone=newPhone,PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(newPhone,insertedContacts[0].Phone);
       //system.assertEquals(newPhone,insertedContacts[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts[0].PreferredPhone__c);
        
        //test work phone
        preferredPhone = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,PreferredPhone__c=preferredPhone);
        insert con1;
        
        Contact[] insertedContacts1 = [Select phone,WorkPhone__c,PreferredPhone__c from Contact where id=:con1.id];
        
        system.assertEquals(newPhone,insertedContacts1[0].Phone);
        //system.assertEquals(newPhone,insertedContacts1[0].WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts1[0].PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,PreferredPhone__c=preferredPhone);
        insert con2;
        
        Contact[] insertedContacts2 = [Select phone,MobilePhone,PreferredPhone__c from Contact where id=:con2.id];
        
        system.assertEquals(newPhone,insertedContacts2[0].Phone);
        //system.assertEquals(newPhone,insertedContacts2[0].MobilePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        
        Contact con3 = new Contact(FirstName='test', LastName='contact678',phone=newPhone,PreferredPhone__c=preferredPhone);
        insert con3;
        
        Contact[] insertedContacts3 = [Select phone,OtherPhone,PreferredPhone__c from Contact where id=:con3.id];
        
        system.assertEquals(newPhone,insertedContacts3[0].Phone);
        //system.assertEquals(newPhone,insertedContacts3[0].OtherPhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].PreferredPhone__c);
        
    }
    
    /// <name> createContactWithNumberAndPrefSet_Test </name>
    /// <summary> Test Method for creating a contact with a phone number in the correct field
    /// and the preferred phone set. </summary>
    static testMethod void createContactWithNumberAndPrefSet_Test()
    {
    	//with pref set to Home, HomePhone should land in Phone and set PreferredPhone__c to 'home'.
    	//these are currently commented out because it's not supported. See #47.
    	String newPhone = '206-777-7777';
    	String preferredPhone = 'Home';
    	Contact con = new Contact(FirstName='test', LastName='contact678',HomePhone=newPhone,PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,PreferredPhone__c from Contact where id=:con.id];
        
        //system.assertEquals(newPhone,insertedContacts[0].Phone);
		system.assertEquals(newPhone,insertedContacts[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts[0].PreferredPhone__c);
        
        //test work phone
        preferredPhone = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',WorkPhone__c=newPhone,PreferredPhone__c=preferredPhone);
        insert con1;
        
        Contact[] insertedContacts1 = [Select phone,WorkPhone__c,PreferredPhone__c from Contact where id=:con1.id];
        
        //system.assertEquals(newPhone,insertedContacts1[0].Phone);
        system.assertEquals(newPhone,insertedContacts1[0].WorkPhone__c);
        system.assertEquals(preferredPhone,insertedContacts1[0].PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',MobilePhone=newPhone,PreferredPhone__c=preferredPhone);
        insert con2;
        
        Contact[] insertedContacts2 = [Select phone,MobilePhone,PreferredPhone__c from Contact where id=:con2.id];
        
       // system.assertEquals(newPhone,insertedContacts2[0].Phone);
        system.assertEquals(newPhone,insertedContacts2[0].MobilePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        
        Contact con3 = new Contact(FirstName='test', LastName='contact678',OtherPhone=newPhone,PreferredPhone__c=preferredPhone);
        insert con3;
        
        Contact[] insertedContacts3 = [Select phone,OtherPhone,PreferredPhone__c from Contact where id=:con3.id];
        
       // system.assertEquals(newPhone,insertedContacts3[0].Phone);
        system.assertEquals(newPhone,insertedContacts3[0].OtherPhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].PreferredPhone__c);
        
    }
    
    /// <name> updateContactWithNumberAndPref_Test </name>
    /// <summary> Test Method for updating a contact with a phone number in the correct field
    /// and the preferred phone set. </summary>
    static testMethod void updateContactWithNumberAndPref_Test()
    {
    	//with pref set to Home, HomePhone should land in Phone and set PreferredPhone__c to 'home'.
    	//these are currently commented out because it's not supported. See #47.
    	String newPhone = '206-777-7777';
    	String preferredPhone = 'Home';
    	Contact con = new Contact(FirstName='test', LastName='contact678',HomePhone=newPhone,PreferredPhone__c=preferredPhone);
        insert con;
        
        Contact[] insertedContacts = [Select phone,HomePhone,PreferredPhone__c from Contact where id=:con.id];
        
        //test work phone
        preferredPhone = 'Work';
        String workPhone = '206-888-8888';
        
        con.WorkPhone__c = workPhone;
        con.PreferredPhone__c = preferredPhone;
        update con;
        
        Contact[] insertedContacts1 = [Select phone,HomePhone,WorkPhone__c,PreferredPhone__c from Contact where id=:con.id];
        
        system.assertEquals(workPhone,insertedContacts1[0].Phone);
        system.assertEquals(workPhone,insertedContacts1[0].WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts1[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts1[0].PreferredPhone__c);
        
        //test mobile phone
        preferredPhone = 'Mobile';
        String mobilePhone = '206-999-9999';
        
        con.MobilePhone = mobilePhone;
        con.PreferredPhone__c = preferredPhone;
        update con;
        
        Contact[] insertedContacts2 = [Select phone,HomePhone,WorkPhone__c,MobilePhone,PreferredPhone__c from Contact where id=:con.id];
        
       	system.assertEquals(mobilePhone,insertedContacts2[0].Phone);
       	system.assertEquals(mobilePhone,insertedContacts2[0].MobilePhone);
       	system.assertEquals(workPhone,insertedContacts2[0].WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts2[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts2[0].PreferredPhone__c);
        
        //test other phone
        preferredPhone = 'Other';
        String otherPhone = '206-666-6666';
        
        con.OtherPhone = otherPhone;
        con.PreferredPhone__c = preferredPhone;
        update con;
        
        Contact[] insertedContacts3 = [Select phone,HomePhone,WorkPhone__c,MobilePhone,OtherPhone,PreferredPhone__c from Contact where id=:con.id];
        
       	system.assertEquals(otherPhone,insertedContacts3[0].Phone);
       	system.assertEquals(otherPhone,insertedContacts3[0].OtherPhone);
       	system.assertEquals(mobilePhone,insertedContacts3[0].MobilePhone);
       	system.assertEquals(workPhone,insertedContacts3[0].WorkPhone__c);
        system.assertEquals(newPhone,insertedContacts3[0].HomePhone);
        system.assertEquals(preferredPhone,insertedContacts3[0].PreferredPhone__c);
        
    }
    

/* TESTING EMAIL WORKFLOW --------------------------------------------------------------*/
    /// <name> createContactWithEmailNoPref_Test </name>
    /// <summary> Test Method for creating a contact with an email and no preferences set. </summary>
    static testMethod void createContactWithEmailNoPref_Test()
    {
    	//with no other prefs, email should land in workemail__c and set Preferred_Email__c to 'work'.
    	String newEmail = 'joe@testforemail.com';
    	String preferredEmail = null;
    	String workEmailString = 'Work';
    	Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,workEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
        system.assertEquals(newEmail,insertedContacts[0].workEmail__c);
        system.assertEquals(workEmailString,insertedContacts[0].Preferred_Email__c);
        
    }
    
    /// <name> createContactWithEmailNoPrefAlsoPersonalEmail_Test </name>
    /// <summary> Test Method for creating a contact with a email and a personal email. </summary>
    static testMethod void createContactWithEmailNoPrefAlsoPersonalEmail_Test()
    {
    	//with pref set to Home, Personal email should land in email and set Preferred_Email__c to 'home'.

    	String newEmail = 'joe@testforemail.com';
    	String newPersonalEmail = 'j@testemail.net';
    	String preferredEmail = 'Personal';
    	Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,HomeEmail__c=newPersonalEmail,Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,workEmail__c,HomeEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
        system.assertEquals(newPersonalEmail,insertedContacts[0].HomeEmail__c);
        system.assertEquals(null,insertedContacts[0].workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].Preferred_Email__c);
        
    }
    
    /// <name> createContactWithEmailPrefSet_Test </name>
    /// <summary> Test Method for creating a contact with an email in email and the preferred email set. </summary>
    static testMethod void createContactWithEmailPrefSet_Test()
    {
    	//with pref set to Home, Personal Email should land in email and set Preferred_Email__c to 'Personal'.
		//commented out until #49 is fixed
    	String newEmail = 'joe@testforemail.com';
    	String preferredEmail = 'Personal';
    	Contact con = new Contact(FirstName='test', LastName='contact678',email=newEmail,Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,HomeEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
       	//system.assertEquals(newEmail,insertedContacts[0].HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].Preferred_Email__c);
        
        //test work email
        preferredEmail = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',email=newEmail,Preferred_Email__c=preferredEmail);
        insert con1;
        
        Contact[] insertedContacts1 = [Select email,workEmail__c,Preferred_Email__c from Contact where id=:con1.id];
        
        system.assertEquals(newEmail,insertedContacts1[0].email);
        //system.assertEquals(newEmail,insertedContacts1[0].workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].Preferred_Email__c);
        
        //test alternate email
        preferredEmail = 'Alternate';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',email=newEmail,Preferred_Email__c=preferredEmail);
        insert con2;
        
        Contact[] insertedContacts2 = [Select email,AlternateEmail__c,Preferred_Email__c from Contact where id=:con2.id];
        
        system.assertEquals(newEmail,insertedContacts2[0].email);
        //system.assertEquals(newEmail,insertedContacts2[0].AlternateEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].Preferred_Email__c);
      
    }
    
    /// <name> createContactWithEmailAndPrefSet_Test </name>
    /// <summary> Test Method for creating a contact with a email in the correct field
    /// and the preferred email set. </summary>
    static testMethod void createContactWithEmailAndPrefSet_Test()
    {
    	//with pref set to Home, Personal Email should land in email and set Preferred_Email__c to 'Personal'.
    	//these are currently commented out because it's not supported. See #47.
    	String newEmail = 'joe@testforemail.com';
    	String preferredEmail = 'Personal';
    	Contact con = new Contact(FirstName='test', LastName='contact678',HomeEmail__c=newEmail,Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,HomeEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(newEmail,insertedContacts[0].email);
		system.assertEquals(newEmail,insertedContacts[0].HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts[0].Preferred_Email__c);
        
        //test work email
        preferredEmail = 'Work';
        
        Contact con1 = new Contact(FirstName='test', LastName='contact678',workEmail__c=newEmail,Preferred_Email__c=preferredEmail);
        insert con1;
        
        Contact[] insertedContacts1 = [Select email,workEmail__c,Preferred_Email__c from Contact where id=:con1.id];
        
        system.assertEquals(newEmail,insertedContacts1[0].email);
        system.assertEquals(newEmail,insertedContacts1[0].workEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].Preferred_Email__c);
        
        //test mobile email
        preferredEmail = 'Alternate';
        
        Contact con2 = new Contact(FirstName='test', LastName='contact678',AlternateEmail__c=newEmail,Preferred_Email__c=preferredEmail);
        insert con2;
        
        Contact[] insertedContacts2 = [Select email,AlternateEmail__c,Preferred_Email__c from Contact where id=:con2.id];
        
       	system.assertEquals(newEmail,insertedContacts2[0].email);
        system.assertEquals(newEmail,insertedContacts2[0].AlternateEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].Preferred_Email__c);
       
        
    }
    
    /// <name> updateContactWithEmailAndPref_Test </name>
    /// <summary> Test Method for updating a contact with a email in the correct field
    /// and the preferred email set. </summary>
    static testMethod void updateContactWithEmailAndPref_Test()
    {
    	//with pref set to Personal, Personal email should land in email and set Preferred_Email__c to 'Personal'.
    	
    	String newEmail = 'joe@testforemail.com';
    	String preferredEmail = 'Personal';
    	Contact con = new Contact(FirstName='test', LastName='contact678',HomeEmail__c=newEmail,Preferred_Email__c=preferredEmail);
        insert con;
        
        Contact[] insertedContacts = [Select email,HomeEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        //test work email
        preferredEmail = 'Work';
        String workEmail = 'jd@email.net';
        
        con.workEmail__c = workEmail;
        con.Preferred_Email__c = preferredEmail;
        update con;
        
        Contact[] insertedContacts1 = [Select email,HomeEmail__c,workEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
        system.assertEquals(workEmail,insertedContacts1[0].email);
        system.assertEquals(workEmail,insertedContacts1[0].workEmail__c);
        system.assertEquals(newEmail,insertedContacts1[0].HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts1[0].Preferred_Email__c);
        
        //test mobile email
        preferredEmail = 'Alternate';
        String alternateEmail = 'jdc@testemail.net';
        
        con.alternateEmail__c = alternateEmail;
        con.Preferred_Email__c = preferredEmail;
        update con;
        
        Contact[] insertedContacts2 = [Select email,HomeEmail__c,workEmail__c,alternateEmail__c,Preferred_Email__c from Contact where id=:con.id];
        
       	system.assertEquals(alternateEmail,insertedContacts2[0].email);
       	system.assertEquals(alternateEmail,insertedContacts2[0].alternateEmail__c);
       	system.assertEquals(workEmail,insertedContacts2[0].workEmail__c);
        system.assertEquals(newEmail,insertedContacts2[0].HomeEmail__c);
        system.assertEquals(preferredEmail,insertedContacts2[0].Preferred_Email__c);
      
        
    }

/* TESTING DONATION HISTORY WEBSERVICES ------------------------------------------------*/

    /// <name> getContactDonationHistory_Test </name>
    /// <summary> Test Method for getContactDonationHistory</summary>
    static testMethod void getContactDonationHistory_Test()
    {
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR);
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
        Contact con = new Contact(FirstName='test', LastName='contact', SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR);
        insert con;

		Opportunity o = new Opportunity(Amount=500,Name='test',StageName='Closed/Won',CloseDate=System.today());
		insert o;
		
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=con.Id,isPrimary=true,role='Donor');
		insert ocr;

		String sum = getContactLastDonation(con.id);
    }

}
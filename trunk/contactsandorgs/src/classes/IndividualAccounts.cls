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
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                    c.SystemIsIndividual__c = true;
                    individualInserts.add(c);
                }
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'Individual')
                {
                    c.SystemIsIndividual__c = true;
                    bucketContacts.add(c);
                }
            }

            //AFTER INSERT
            if ( ta==triggerAction.afterInsert )
            {
                if ( c.AccountId != null && c.SystemIsIndividual__c == true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                    accountUpdates.put(c.AccountId, c.Id);
                }
            }

            //BEFORE UPDATE
            if ( ta==triggerAction.beforeUpdate )
            {
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'One-to-One')
                {
                    individualInserts.add(c);
                }           
                if (c.AccountId == null && c.Private__c != true && c.SystemAccountProcessor__c == 'Individual')
                {
                    c.SystemIsIndividual__c = true;
                    bucketContacts.add(c);
                }
            }

            //AFTER UPDATE
            if ( ta==triggerAction.afterUpdate )
            {
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
            insertIndividualAccount(individualInserts);
        }
        if (bucketContacts.size() > 0)
        {
            attachToIndividualAccount(bucketContacts);
        }
        if (individualUpdates.size() > 0)
        {
            updateIndividualAccount(individualUpdates);
        }
        if (accountUpdates.size() > 0)
        {
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
		List<Account> individuals = [Select Id from Account where name = 'Individual' ORDER BY CreatedDate Desc Limit 1];
		if (individuals.size() > 0)
		{
			for(Contact c : contacts)
			{
				c.AccountId = individuals[0].Id;
			}
		} else
		{
            Account individual = new Account();
   	        individual.Name = 'Individual';
   	        individual.SYSTEMISINDIVIDUAL__c = true;
           	individual.Type = 'Bucket Individual';
            insert individual;

            for(Contact c : contacts)
   	        {
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
			if (c.Id != null)
			{
				contactIds.add(c.Id);
			}
		}
    	for (Account acc : [Select Id, One2OneContact__c from Account where One2OneContact__c in :contactIds])
    	{
    		conAccMap.put(acc.One2OneContact__c,acc.Id);
    	}
    	
        List<Contact> contactUpdates = new List<Contact>();
        List<Account> accountInserts = new List<Account>();

        for(Contact c : contacts)
        {
			if (conAccMap.containsKey(c.Id))
			{
				c.AccountId = conAccMap.get(c.Id);
			} else
			{
	            Account a = new Account();
    	        String aName = '';
        	    if (c.FirstName != null)
            	{
	            	aName += c.FirstName;
    	        	aName += ' ' ;
        	    }
	            aName += c.LastName; 
    	        a.Name = aName;
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
		
		List<Account> accts = [Select a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry, 
        a.ShippingCity, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity
        From Account a where a.Id IN :accConMap.keyset()];
    	
        List<Account> accountUpdates = new List<Account>();
        
        for(Account a : accts){     	
			Contact c = accConMap.get(a.Id);
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
                        	// Update contact fields
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
	/// <summary> Called by sControl </summary>
	webservice static decimal getContactDonationHistory(Id contactId){
		Decimal sum = 0;
		for (OpportunityContactRole o : [Select Opportunity.Amount, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and Opportunity.Amount != null and ContactId = :contactId]) 
		{
			sum += o.Opportunity.Amount;
		}
		return sum;
	}


	/// <name> getContactLastDonation </name>
	/// <summary> Called by sControl </summary>
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
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
global class templateConversion_WebServices 
{
    public Id accountId{get; set;}
    public String accountName{get; set;}
    public Integer cCount{get; set;}
    public String contactCount{get; set;}
    public Integer oCount{get; set;}
    public String opptyCount{get; set;}
    public String queryTerm{get; set;}
    public String tooManyWarning{get; set;}
    public List<Account> searchResults{get; set;}
    public List<Account> accountDetails{get; set;}
	public Boolean isWorking{get; set;}

    // <name> query </name>
    // <summary> Search for brokerages or locations or Brokers based on the search crtieria. </summary>
    public PageReference query()
    {
        accountId = null;
        searchResults = null;
        if ( queryTerm.trim().length() < 1)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'At least three characters are required for searching');
            ApexPages.addMessage(myMsg);
        } 
        else 
        {
            String tempQueryTerm = '%' + queryTerm.Trim() + '%';
            searchResults = [Select Id, Name, Type, Owner.Name From Account where Name LIKE :tempQueryTerm limit 100];
        }
            return null;
    }

    public static integer getRecordCount(Id aId, String t, Integer maxRecords)
    {
        if ( maxRecords == null )
        {
            maxRecords = limits.getLimitQueryRows() / 10;
        } else
        if ( maxRecords > 4999 )
        {
        	maxRecords = 4999;
        }
        Integer results = 0;
        if (t == 'Contact')
        {
            results = [select count() from Contact where AccountId = :aId limit :maxRecords];
        }
        else
        if (t == 'Opportunity')
        {
            results = [select count() from Opportunity where AccountId = :aId limit :maxRecords];
        }
        return results;
    }
    
    public void validateContactCount()
    {
        if ( cCount == 4999 )
        {
            contactCount = '> ';
        }
        if ( cCount > 1000 )
        {
            tooManyWarning = 'WARNING: You have more than 1000 child records on this Organization (Account), you must run this conversion process more than once';
        }
    }
    
    public void validateOpportunityCount()
    {
        if ( oCount == 4999 )
        {
            opptyCount = '> ';
        }
        if ( oCount > 1000 )
        {
            tooManyWarning = 'WARNING: You have more than 1000 child records on this Organization (Account), you must run this conversion process more than once';
        }
    }
    
    public Integer getMaxRecordsLimit(Integer maxRecords)
    {
        if ( maxRecords == 500 )
        {
            maxRecords = 10;
        }
        return maxRecords;
    }
    
    //<summary>Action method to set the brokerage and broker on record based on the user selection.</summary>
    //<return>PageReference</return>
    public PageReference selectAccount()
    {   
        Integer maxRecords = limits.getLimitQueryRows();
        maxRecords = getMaxRecordsLimit(maxRecords);
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        accountName = ApexPages.currentPage().getParameters().get('accountName');
        cCount = 0;
        contactCount = '';
        oCount = 0;
        opptyCount = '';
        cCount = getRecordCount(accountId,'Contact',maxRecords);
        validateContactCount();
        contactCount += string.ValueOf(cCount);
        oCount = getRecordCount(accountId,'Opportunity',maxRecords);
        validateOpportunityCount();
        opptyCount += string.ValueOf(oCount);
        return null;
    }

    //<summary>Action method to convert Contacts.</summary>
    //<return>PageReference</return>
    public PageReference convertContacts()
    {   
    	isWorking = true;
        Integer maxRecords = limits.getLimitQueryRows();
        maxRecords = getMaxRecordsLimit(maxRecords);
        step1(accountId,1000);
        step2(accountId,1000);
        cCount = getRecordCount(accountId,'Contact',maxRecords);
        contactCount = '';
        validateContactCount();
        contactCount += string.ValueOf(cCount);
        return null;
    }

    //<summary>Action method to convert Opportunities.</summary>
    //<return>PageReference</return>
    public PageReference convertOpptys()
    {   
    	isWorking = true;
        Integer maxRecords = limits.getLimitQueryRows();
        maxRecords = getMaxRecordsLimit(maxRecords);
        step3(accountId,1000);
        oCount = getRecordCount(accountId,'Opportunity',maxRecords);
        opptyCount = '';
        validateOpportunityCount();
        opptyCount += string.ValueOf(oCount);
        return null;
    }

    // <name> getShowTable </name>
    // <summary> Find the search results table can eb displayed. </summary>
    // <returns> True if there are search results. False otherwise </returns>
    public Boolean getShowTable()
    {
        if (searchResults != null && searchResults.size() > 0)
        {
            return true;
        }
        return false;
    }

    public Boolean getShowNoRecFound()
    {
        if (queryTerm != null && queryTerm.length() > 0 && !getShowTable())
        {
            return true;
        } 
        return false;
    }

    public Boolean getAccountNotSelected()
    {
        if (accountId == null)
        {
            return true;
        } 
        return false;
    }

    public Boolean getAccountSelected()
    {
        if (accountId != null)
        {
            return true;
        } 
        return false;
    }

    webservice static integer createAccounts(Id accountId)
    {
        step1(accountId,1000);
        return null;
    }   

    public static void step1(Id accountId, Integer maxRows)
    {
        List<Account> accountInserts = new List<Account>();
        List<Contact> contactUpdates = new List<Contact>();

        Map<Id,Id> conAccMap = new Map<Id,Id>();

        for (Contact c : [SELECT id, name, phone, fax, mailingstreet, mailingcity, mailingstate, mailingpostalcode, mailingcountry FROM contact WHERE npe6__Step_1_Complete__c = false and accountid = :accountId limit :maxRows])
        {
            Account a = new Account();
            a.Name = c.Name;
            a.npe01__One2OneContact__c = c.Id;
            if (c.phone != null) {
                a.Phone = c.phone;
            }
            if (c.fax != null) {
                a.Fax = c.fax;
            }
            if (c.mailingstreet != null) {
                a.BillingStreet = c.mailingstreet;
            }
            if (c.mailingcity != null) {
                a.Billingcity = c.mailingcity;
            }
            if (c.mailingstate != null) {
                a.Billingstate = c.mailingstate;
            }
            if (c.mailingpostalcode != null) {
                a.Billingpostalcode = c.mailingpostalcode;
            }
            if (c.mailingcountry != null) {
                a.Billingcountry = c.mailingcountry;
            }
            accountInserts.add(a);
            c.npe6__Step_1_Complete__c = true;
            contactUpdates.add(c);
        }
        if (accountInserts.size() > 0)
        {
            Database.SaveResult[] lsr1 = Database.insert(accountInserts, false);
	        if ( contactUpdates.size() > 0 && lsr1.size() > 0 )
    	    {
        	    Database.SaveResult[] lsr2 = Database.update(contactUpdates, false);
        	}
        }

    }


    webservice static integer updateContacts(Id accountId)
    {
        step2(accountId,1000);
        return null;
    }

    public static void step2(Id accountId, Integer maxRows)
    {
        List<Contact> contactUpdates = new List<Contact>();
        List<Account> accountUpdates = new List<Account>();
		Set<Id> accountIds = new Set<Id>();
        for (Account a : [SELECT Id, npe01__One2OneContact__c from Account where npe01__One2OneContact__c != null and npe6__Step_2_Complete__c = false limit :maxRows])
        {
            Contact c = new Contact(Id = a.npe01__One2OneContact__c, AccountId = a.Id, npe01__SystemIsIndividual__c=true, npe01__SystemAccountProcessor__c='One-to-One');
            contactUpdates.add(c);

            a.npe6__Step_2_Complete__c = true;
			if ( !accountIds.contains(a.Id) )
			{
	            accountUpdates.add(a);
	            accountIds.add(a.Id);
			}
        }
        if (accountUpdates.size() > 0)
        {
            Database.SaveResult[] lsr1 = Database.update(contactUpdates, false);
	        if (contactUpdates.size() > 0 && lsr1.size() > 0)
    	    {
        	    Database.SaveResult[] lsr2 = Database.update(accountUpdates, false);
        	}
        }           
    }
    
    webservice static integer updateOpportunities(Id accountId)
    {
        step3(accountId,1000);
        return null;
    }

    public static void step3(Id accountId, Integer maxRows)
    {
        List<Opportunity> opportunityUpdates = new List<Opportunity>();

        for (OpportunityContactRole ocr : [Select OpportunityId, ContactId, Contact.AccountId From OpportunityContactRole where IsPrimary = true and Opportunity.AccountId = :accountId limit :maxRows])
        {
            Opportunity o = new Opportunity(Id=ocr.OpportunityId,AccountId=ocr.Contact.AccountId);
            opportunityUpdates.add(o);
        }
        if (opportunityUpdates.size() > 0)
        {
            Database.SaveResult[] lsr = Database.update(opportunityUpdates, false);
        }
    }
}
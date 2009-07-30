public class ContactMergeController {
	
	public ContactMergeController(){
		searchText='';
		searchResults = new List<contactWrapper>();
		thisMerge = new mergeSet();
		displaySelected = false;
		contactFields = Schema.SObjectType.Contact.fields.getMap();
	}
	public Boolean displaySelected { get { return displaySelected; } set { displaySelected = value; } }
	
	public String searchText { get { return searchText; } set { searchText = value; } }
	
	public List<contactWrapper> searchResults { get { return searchResults; } set { searchResults = value; } }
	
	private Integer mergeLimit = 3;

	public mergeSet thisMerge { get { return thisMerge; } set { thisMerge = value; } }
	
	public Map<String,Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap(); 
	
	//public Boolean housholdingInstalled { get { return housholdingInstalled; } set { housholdingInstalled = value; } }
	
	public Boolean successfulMerge { get { return successfulMerge; } set { successfulMerge = value; } }
	
	public class contactWrapper
    {
        public Contact con {get; set;}
        public Boolean selected {get; set;}
        public contactWrapper(Contact c)
        {
            con = c;
            selected = false;
        }
    }
    
    public class mergeSet
    {
        public List<Contact> selectedContacts {get; set;}
        
        public Boolean firstIsWinner {get; set;}
        public Boolean secondIsWinner {get; set;}
        public Boolean thirdIsWinner {get; set;}
        
        public Boolean displayFirst {get; set;}
        public Boolean displaySecond {get; set;}
        public Boolean displayThird {get; set;}

        
        public Contact firstContact = new Contact();
        public Contact getfirstContact(){
    		if(selectedContacts.size()>0){
    			firstContact = selectedContacts[0];
    			return firstContact;    			
    		} else {
    			return null;
    		}
        }
        public Contact secondContact = new Contact();
        public Contact getSecondContact(){
    		if(selectedContacts.size()>1){
    			secondContact = selectedContacts[1];
    			return secondContact;
    		} else {
    			return null;
    		}
        }
        public Contact thirdContact = new Contact();
        public Contact getThirdContact(){
    		if(selectedContacts.size()>2){
    			thirdContact = selectedContacts[2];
    			return thirdContact;
    		} else {
    			return null;
    		}
        }
        
        public Contact winner {get; set;}
        public List<Contact> losers {get; set;}
        
        
        
        public mergeSet() {
			selectedContacts = new List<Contact>();
			losers = new List<Contact>();
			winner = new Contact();
			
			firstIsWinner = false;
        	secondIsWinner = false;
        	thirdIsWinner = false;

        }
    }
    
    public void selectFirstContact() {
		thisMerge.firstIsWinner = true;
    	thisMerge.secondIsWinner = false;
    	thisMerge.thirdIsWinner = false;
    	thisMerge.winner = thisMerge.firstContact;
    	thisMerge.losers.clear();
    	if(thisMerge.secondContact.Id!=null){
    		thisMerge.losers.add(thisMerge.secondContact);
    	}
    	if(thisMerge.thirdContact.Id!=null){
    		thisMerge.losers.add(thisMerge.thirdContact);
    	}
    	system.debug('Winner: ' + thisMerge.winner);
    	system.debug('Losers: ' + thisMerge.losers);
    	system.debug('Winner: ' + thisMerge.winner.Id);
    	system.debug('Losers: ' + thisMerge.losers[0].id);
	}

	public void selectSecondContact() {
		thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = true;
    	thisMerge.thirdIsWinner = false;
    	thisMerge.winner = thisMerge.secondContact;
    	system.debug('SecondContact: ' + thisMerge.secondContact);
    	thisMerge.losers.clear();
    	if(thisMerge.firstContact!=null){
    		thisMerge.losers.add(thisMerge.firstContact);
    	}
    	if(thisMerge.thirdContact!=null){
    		thisMerge.losers.add(thisMerge.thirdContact);
    	}
	
	}

	public void selectThirdContact() {
		thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = false;
    	thisMerge.thirdIsWinner = true;
    	thisMerge.winner = thisMerge.thirdContact;
    	thisMerge.losers.clear();
    	if(thisMerge.firstContact!=null){
    		thisMerge.losers.add(thisMerge.firstContact);
    	}
    	if(thisMerge.secondContact!=null){
    		thisMerge.losers.add(thisMerge.secondContact);
    	}
    	
	
	}
	
	public void search() {
		thisMerge.selectedContacts.clear();
		searchResults.clear();
		displaySelected = false;
		successfulMerge = false;
		
		String qs = '';         
		Set<String> fields = contactFields.keySet(); 
		Boolean firstField = true;               
		for(String field : Fields){        	
			if(!firstField) // if it's the last field don't append a comma        		
				qs += ',' + field;        	
			else        		
				qs += field;
				firstField = false;
		}                
 

		String searchquery = 'FIND \'' + searchText + '\' IN ALL FIELDS RETURNING Contact(' + qs +') LIMIT 20';
		//String searchquery = 'FIND \'' + searchText + '\' IN ALL FIELDS RETURNING Contact(id,Name,phone,email,accountid,private__c) LIMIT 20'; 
		List<List<SObject>> searchList = search.query(searchquery);
		for (SObject returnedObject : searchList[0]){
			//if the returned object is a contact, add it to the Contact list
			if(returnedObject.getSObjectType() == Contact.sObjectType){
				contactWrapper thisResult = new contactWrapper((Contact) returnedObject);
				
				searchResults.add(thisResult);	
			}
		}
	}
	
	public void getSelected()
    {
        thisMerge.selectedContacts.clear();
        for(contactWrapper conWrapper : searchResults) {
        	if(conWrapper.selected == true) {
        		thisMerge.selectedContacts.add(conWrapper.con);
        	}
        }
        if(thisMerge.selectedContacts.size()>mergeLimit){
        	//report an error that you can only select 3 or fewer
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You can only merge up to 3 contacts at a time.');
        	ApexPages.addMessage(myMsg);
        	displaySelected = false;
        } else {
        	
        	if (thisMerge.selectedContacts.size()>0){
        		displaySelected = true;
        	} else {
        		displaySelected = false;
        	}
        	
        	if(thisMerge.selectedContacts.size()==0){
        		thisMerge.displayFirst = false;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	} else if(thisMerge.selectedContacts.size()==1){
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	} else if(thisMerge.selectedContacts.size()==2){
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = true;
        		thisMerge.displayThird = false;
        	} else if(thisMerge.selectedContacts.size()==3){
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = true;
        		thisMerge.displayThird = true;
        	}
        }
        //return null;
    }

	 public boolean isOneToOne() {
    	boolean isOneToOneModel;
    	isOneToOneModel = false;
    	Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npe01__SystemAccountProcessor__c; 
		List<Schema.PicklistEntry> P = F.getPicklistValues();
		for(Schema.PicklistEntry pe : P){
			if (pe.isDefaultValue()){
				if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){
					isOneToOneModel = true;
				}
			}
		}
		
    	return isOneToOneModel;
    }

	
	public void mergeContacts() {
		
		system.debug('thisMergeWinner: ' + thisMerge.winner);
		system.debug('thisMergeLosers: ' + thisMerge.losers);
		
		List<Account> winnerAccount = new List<Account>();
		Set<Id> loserAccountIds = new Set<Id>();
		List<Account> loserAccounts = new List<Account>();
		List<Account> loserAccountsToBeMerged = new List<Account>();
		
		Id winningAccountId;
		
		//get winner contact Account
		if (thisMerge.winner.AccountId!=null){
			winnerAccount = [Select Id,SYSTEMIsIndividual__c,Name from Account where SYSTEMIsIndividual__c=true and Name!='Individual' and Id=:thisMerge.winner.accountid];
		}
		system.debug('Winner Account: ' + winnerAccount);
		
		if (winnerAccount.size()>0) {
			for(Contact thisloserContact : thisMerge.losers){
				if (thisloserContact.id!=null && thisloserContact.AccountId!=thisMerge.winner.AccountId){
					loserAccountIds.add(thisloserContact.AccountId);
				}
			}
			
			system.debug('Loser Account Ids: ' + loserAccountIds);
			//get loser contact Accounts
			loserAccountsToBeMerged = [Select Id,SYSTEMIsIndividual__c,Name from Account where Id IN :loserAccountIds and SYSTEMIsIndividual__c=true and Name<>'Individual'];
			system.debug('Loser Accounts to be merged: ' + loserAccountsToBeMerged);
			//merge the accounts that need merging
			if(loserAccountsToBeMerged.size()>0){
				system.debug('Winner Account: ' + winnerAccount[0]);
				system.debug('Loser Accounts: ' + loserAccountsToBeMerged);
				
				merge winnerAccount[0] loserAccountsToBeMerged;
				winningAccountId = winnerAccount[0].Id;
			}
		}	
		//merge the contacts
		system.debug('Winner contact: ' + thisMerge.winner);
		system.debug('Loser Contacts: ' + thisMerge.losers);
		
		Contact winnerMakePrivate = new Contact();
		winnerMakePrivate = new Contact(Id = thisMerge.winner.id);
		
		List<Contact> losersMakePrivate = new List<Contact>();
		for(Contact contactForUpdate : thisMerge.losers){
			Contact loserMakePrivate = new Contact(id=contactForUpdate.id);
			losersMakePrivate.add(loserMakePrivate);
		}
		system.debug('Loser Contacts before nulling: ' + losersMakePrivate);
		
		if (winningAccountId!=null){
			winnerMakePrivate.AccountId = null;
			winnerMakePrivate.Private__c = true;
			update winnerMakePrivate;
			system.debug('Winner contact after nulling: ' + winnerMakePrivate);
			
			
			for(Contact contactForUpdateAgain : losersMakePrivate){
				contactForUpdateAgain.AccountId = null;
				contactForUpdateAgain.Private__c = true;
			}
			system.debug('Loser Contacts before nulling again: ' + losersMakePrivate);
			if(losersMakePrivate.size()>0){
				update losersMakePrivate;
			}
		}
		
	//	system.debug('Winner contact after nulling: ' + winnerMakePrivate);
	//	system.debug('Loser Contacts after nulling: ' + losersMakePrivate);
		merge winnerMakePrivate losersMakePrivate;
		
		if (winnerMakePrivate.Id != null){
			winnerMakePrivate.AccountId = winningAccountId;
			winnerMakePrivate.Private__c = false;
			update winnerMakePrivate;
		}
		
		
		successfulMerge = true;
	}


}
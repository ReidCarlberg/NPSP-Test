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
public class ContactMergeController {
	
	public ContactMergeController(){
		searchText='';
		searchResults = new List<contactWrapper>();
		thisMerge = new mergeSet();
		displaySelected = false;
		tooManyContactsSelected = false;
		tooFewContactsSelected = true;
		displaySearchResults = false;
		contactFields = Schema.SObjectType.Contact.fields.getMap();
	}
	public Boolean displaySelected { get { return displaySelected; } set { displaySelected = value; } }
	public Boolean displaySearchResults { get { return displaySearchResults; } set { displaySearchResults = value; } }
	
	private Integer numberOfContactsSelected = 0;
	public Boolean tooManyContactsSelected { get { return tooManyContactsSelected; } set { tooManyContactsSelected = value; } }
	public Boolean tooFewContactsSelected { get { return tooFewContactsSelected; } set { tooFewContactsSelected = value; } }
	
	public String searchText { get { return searchText; } set { searchText = value; } }
	
	public List<contactWrapper> searchResults { get { return searchResults; } set { searchResults = value; } }
	
	private final Integer MERGE_MINIMUM = 2;
	private final Integer MERGE_LIMIT = 3;

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
    	if(tooFewContactsSelected){
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Please select at least ' + MERGE_MINIMUM + ' contacts to merge.');
    		ApexPages.addMessage(myMsg);
        	displayPopup = true;
    	} else {
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
    	}

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
		if (searchResults.size()>0){
			displaySearchResults = true;
		}
	}
	
	public void getSelected()
    {
        thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = false;
    	thisMerge.thirdIsWinner = false;
        
        thisMerge.selectedContacts.clear();
        for(contactWrapper conWrapper : searchResults) {
        	if(conWrapper.selected == true) {
        		thisMerge.selectedContacts.add(conWrapper.con);
        	}
        }
        numberOfContactsSelected = thisMerge.selectedContacts.size();
        if(numberOfContactsSelected>MERGE_LIMIT){
        	//report an error that you can only select 3 or fewer
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You can only merge up to 3 contacts at a time.');
        	ApexPages.addMessage(myMsg);
        	displayPopup = true;
        	tooManyContactsSelected = true;
        	tooFewContactsSelected = false;
        } else {
        	tooManyContactsSelected = false;
        	if(numberOfContactsSelected<MERGE_MINIMUM){
        		tooFewContactsSelected = true;
        	} else {
        		tooFewContactsSelected = false;
        	}
        	if (numberOfContactsSelected>0){
        		displaySelected = true;
        	} else {
        		displaySelected = false;
        	}
        	
        	if(numberOfContactsSelected==0){
        		thisMerge.displayFirst = false;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	} else if(numberOfContactsSelected==1){
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	} else if(numberOfContactsSelected==2){
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = true;
        		thisMerge.displayThird = false;
        	} else if(numberOfContactsSelected==3){
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
		displayPopup = false;
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
	
	

	public boolean displayPopup {get; set;}
 
    public void cancelPopup() {
        displayPopup = false;

    }
 
    public void showPopup() {
    	if(tooFewContactsSelected){
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'Please select at least ' + MERGE_MINIMUM + ' contacts to merge.');
    		ApexPages.addMessage(myMsg);
    	} else {
	    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'Merging Contacts may result in the loss of data. Make sure the Contact you choose as the winner has all the data you want. You may need to copy data from one Contact to another before you merge the records.');
	        ApexPages.addMessage(myMsg);
    	}
        displayPopup = true;
    }
}
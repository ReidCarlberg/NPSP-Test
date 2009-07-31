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
	//boolean used to render the selected Contacts pane
	public Boolean displaySelected { get { return displaySelected; } set { displaySelected = value; } }
	
	//boolean used to render the search results pane
	public Boolean displaySearchResults { get { return displaySearchResults; } set { displaySearchResults = value; } }
	
	//integer for recording how many contacts have been selected from the search results
	private Integer numberOfContactsSelected = 0;
	
	//boolean used to display too many contacts error
	public Boolean tooManyContactsSelected { get { return tooManyContactsSelected; } set { tooManyContactsSelected = value; } }
	
	//boolean used to display too few contacts error
	public Boolean tooFewContactsSelected { get { return tooFewContactsSelected; } set { tooFewContactsSelected = value; } }
	
	//string of search text entered by user
	public String searchText { get { return searchText; } set { searchText = value; } }
	
	//list of contactWrapper objects for display in search results pane
	public List<contactWrapper> searchResults { get { return searchResults; } set { searchResults = value; } }
	
	//min number of contacts that can be merged
	private final Integer MERGE_MINIMUM = 2;
	
	//max number of contacts that can be merged
	private final Integer MERGE_LIMIT = 3;
	
	//max number of Contacts returned by a query
	private final Integer SOSL_LIMIT = 20;
	
	//singleton to hold the merging contacts and relevant info
	public mergeSet thisMerge { get { return thisMerge; } set { thisMerge = value; } }
	
	//field map for SOSLing so we can return all fields
	public Map<String,Schema.SObjectField> contactFields = Schema.SObjectType.Contact.fields.getMap(); 
	
	//boolean used to display winning record pane
	public Boolean successfulMerge { get { return successfulMerge; } set { successfulMerge = value; } }
	
	
	//class to hold a contact and checkbox so we can select each contact
	public class contactWrapper {
    	//the contact
        public Contact con {get; set;}
        //the checkbox variable
        public Boolean selected {get; set;}
        
        //constructor for contactWrapper class
        public contactWrapper(Contact c) {
            con = c;
            selected = false;
        }
    }
    //class to hold the merging contacts and relevant info
    public class mergeSet {
    	//a list of all selected contacts for merging
        public List<Contact> selectedContacts {get; set;}
        
        //booleans to flag which of the 3 contacts has been chosen as the users
        public Boolean firstIsWinner {get; set;}
        public Boolean secondIsWinner {get; set;}
        public Boolean thirdIsWinner {get; set;}
        
        //booleans to control display of the contact panes
        public Boolean displayFirst {get; set;}
        public Boolean displaySecond {get; set;}
        public Boolean displayThird {get; set;}
        
		//the first contact selected        
        public Contact firstContact = new Contact();
        
        //getter for first contact
        public Contact getfirstContact(){
        	//always get it if at least one contact has been selected
    		if(selectedContacts.size()>0){
    			firstContact = selectedContacts[0];
    			return firstContact;    			
    		} else {
    			return null;
    		}
        }
        //the second contact selected
        public Contact secondContact = new Contact();
        
        //getter for second contact
        public Contact getSecondContact(){
        	//always get it if at least two contacts have been selected
    		if(selectedContacts.size()>1){
    			secondContact = selectedContacts[1];
    			return secondContact;
    		} else {
    			return null;
    		}
        }
        //the third contact selected
        public Contact thirdContact = new Contact();
        
        //getter for third contact
        public Contact getThirdContact(){
        	//always get it if at least three contacts have been selected
    		if(selectedContacts.size()>2){
    			thirdContact = selectedContacts[2];
    			return thirdContact;
    		} else {
    			return null;
    		}
        }
        
        //contact for the winning record
        public Contact winner {get; set;}
        
        //List for the losing records
        public List<Contact> losers {get; set;}
        
        //constructor for mergeSet class
        public mergeSet() {
			selectedContacts = new List<Contact>();
			losers = new List<Contact>();
			winner = new Contact();
			
			//set all the winner booleans to false as none has been selected yet
			firstIsWinner = false;
        	secondIsWinner = false;
        	thirdIsWinner = false;
        }
    }
    //method for selecting first contact, called when user chooses the first as the winner
    public void selectFirstContact() {
    	//show error message if this is the only contact in the merge set
    	if(tooFewContactsSelected){
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,system.label.Contact_Merge_Error_Too_Few_Contacts);
    		ApexPages.addMessage(myMsg);
        	displayMessagePopup = true;
    	} else {
    		//first is winner
			thisMerge.firstIsWinner = true;
			thisMerge.winner = thisMerge.firstContact;
			//others are not
	    	thisMerge.secondIsWinner = false;
	    	thisMerge.thirdIsWinner = false;
	    		    	
	    	thisMerge.losers.clear();
	    	//add all non-empty contacts to losers
	    	if(thisMerge.secondContact.Id!=null){
	    		thisMerge.losers.add(thisMerge.secondContact);
	    	}
	    	if(thisMerge.thirdContact.Id!=null){
	    		thisMerge.losers.add(thisMerge.thirdContact);
	    	}
    	}

	}
	//method for selecting second contact, called when user chooses the second as the winner
	public void selectSecondContact() {
		//second is winner
		thisMerge.secondIsWinner = true;
		thisMerge.winner = thisMerge.secondContact;
		//others are not
		thisMerge.firstIsWinner = false;    	
    	thisMerge.thirdIsWinner = false;
    	
		thisMerge.losers.clear();
		//add all non-empty contacts to losers
    	if(thisMerge.firstContact!=null){
    		thisMerge.losers.add(thisMerge.firstContact);
    	}
    	if(thisMerge.thirdContact!=null){
    		thisMerge.losers.add(thisMerge.thirdContact);
    	}
	
	}
	//method for selecting third contact, called when user chooses the thirs as the winner
	public void selectThirdContact() {
		//third is winner
		thisMerge.thirdIsWinner = true;
		thisMerge.winner = thisMerge.thirdContact;
		//others are not
		thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = false;    	
    	
    	thisMerge.losers.clear();
    	//add all non-empty contacts to losers
    	if(thisMerge.firstContact!=null){
    		thisMerge.losers.add(thisMerge.firstContact);
    	}
    	if(thisMerge.secondContact!=null){
    		thisMerge.losers.add(thisMerge.secondContact);
    	}
	}
	//search for contacts
	public void search() {
		//empty any previous results
		thisMerge.selectedContacts.clear();
		searchResults.clear();
		//reset booleans that control display of results elements
		displaySelected = false;
		successfulMerge = false;
		
		String fieldsForReturn = '';         
		//get all fields from the Contact record and put in string for dynamic SOSL call
		Set<String> fields = contactFields.keySet(); 
		Boolean firstField = true;               
		for(String field : Fields){        	
			if(!firstField) // if it's the last field don't append a comma        		
				fieldsForReturn += ',' + field;        	
			else        		
				fieldsForReturn += field;
				firstField = false;
		}                
 
		//build the SOSL query and execute
		String searchquery = 'FIND \'' + searchText + '\' IN ALL FIELDS RETURNING Contact(' + fieldsForReturn +') LIMIT ' + SOSL_LIMIT;
		
		List<List<SObject>> searchList = search.query(searchquery);
		
		//loop through the contacts putting them in an array of wrappers
		for (SObject returnedObject : searchList[0]){
			//if the returned object is a contact, add it to the Contact list
			if(returnedObject.getSObjectType() == Contact.sObjectType){
				contactWrapper thisResult = new contactWrapper((Contact) returnedObject);				
				searchResults.add(thisResult);	
			}
		}
		//if we got a result back, show the search results pane
		if (searchResults.size()>0){
			displaySearchResults = true;
		}
	}
	//method that is run when a Contact checkbox is clicked in the search results.
	//contacts are collected and put in the pane for display
	public void getSelected()
    {
    	//reset all the winner booleans so the checkboxes will reset
        thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = false;
    	thisMerge.thirdIsWinner = false;
    	
        //empty the list of selected contacts so we can repopulate it
        thisMerge.selectedContacts.clear();
        
        for(contactWrapper conWrapper : searchResults) {
        	if(conWrapper.selected == true) {
        		thisMerge.selectedContacts.add(conWrapper.con);
        	}
        }
        
        numberOfContactsSelected = thisMerge.selectedContacts.size();
        
        if(numberOfContactsSelected>MERGE_LIMIT){
        	//report an error that you can only select 3 or fewer
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,system.label.Contact_Merge_Error_Too_Many_Contacts);
        	ApexPages.addMessage(myMsg);
        	
        	tooManyContactsSelected = true;
        	displayMessagePopup = true;
        	
        	tooFewContactsSelected = false;
        } else {
        	tooManyContactsSelected = false;
        	//set the boolean for potential error reporting if the Users tries to merge just one record
        	if(numberOfContactsSelected<MERGE_MINIMUM){
        		tooFewContactsSelected = true;
        	} else {
        		tooFewContactsSelected = false;
        	}
        	//display the selected contacts pane if there are any to show
        	if (numberOfContactsSelected>0){
        		displaySelected = true;
        	} else {
        		displaySelected = false;
        	}
        	//display the individual Contact panes
        	if(numberOfContactsSelected==0){
        		thisMerge.displayFirst = false;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	} else {        		
        		thisMerge.displayFirst = true;
        		thisMerge.displaySecond = false;
        		thisMerge.displayThird = false;
        	}
        	
        	if(numberOfContactsSelected>1){
        		thisMerge.displaySecond = true;
        	}
        	
        	if(numberOfContactsSelected>2){
        		thisMerge.displayThird = true;
        	}
        }
    }
	//method to merge the winner and losers
	public void mergeContacts() {
		displayMessagePopup = false;
		system.debug('thisMergeWinner: ' + thisMerge.winner);
		system.debug('thisMergeLosers: ' + thisMerge.losers);
		
		List<Account> winnerAccount = new List<Account>();
		Set<Id> loserAccountIds = new Set<Id>();
		List<Account> loserAccounts = new List<Account>();
		List<Account> loserAccountsToBeMerged = new List<Account>();
		
		Id winningAccountId;
		
		//get winner contact Account
		if (thisMerge.winner.AccountId!=null){
			winnerAccount = [Select Id,SYSTEMIsIndividual__c,Name from Account where SYSTEMIsIndividual__c=true and Name!=:Constants.BUCKET_ACCOUNT_NAME and Id=:thisMerge.winner.accountid];
		}
		system.debug('Winner Account: ' + winnerAccount);
		
		if (winnerAccount.size()>0) {
			for(Contact thisloserContact : thisMerge.losers){
				//don't try to merge null Accounts or Accounts that are the same as the winner's Account
				if (thisloserContact.id!=null && thisloserContact.AccountId!=thisMerge.winner.AccountId){
					loserAccountIds.add(thisloserContact.AccountId);
				}
			}
			
			system.debug('Loser Account Ids: ' + loserAccountIds);
			//get loser contact Accounts
			loserAccountsToBeMerged = [Select Id,SYSTEMIsIndividual__c,Name from Account where Id IN :loserAccountIds and SYSTEMIsIndividual__c=true and Name<>:Constants.BUCKET_ACCOUNT_NAME];
			system.debug('Loser Accounts to be merged: ' + loserAccountsToBeMerged);
			//one-to-one contacts each have an Account, so when merging Contacts we have to merge Accounts as well
			//we merge the Accounts first, if there are any one-to-one Accounts in the mix
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
		//there is a Contact delete trigger that deletes the one-to-one Account of a Contact after it is deleted
		//merge deletes the losing Contacts, so their Accounts get deleted, which causes errors
		//to get around this, we detach the Contacts for their Accounts before we merge
		
		//create new contacts for updating as the SOSL returned contacts have read-only fields on them
		Contact winnerMakePrivate = new Contact();
		winnerMakePrivate = new Contact(Id = thisMerge.winner.id);
		
		List<Contact> losersMakePrivate = new List<Contact>();
		
		for(Contact contactForUpdate : thisMerge.losers){			
			Contact loserMakePrivate = new Contact(id=contactForUpdate.id);
			losersMakePrivate.add(loserMakePrivate);
		}
		system.debug('Loser Contacts before nulling: ' + losersMakePrivate);
		
		//set the account to null and mark private so that trigger won't reset the Account
		if (winningAccountId!=null){
			winnerMakePrivate.AccountId = null;
			winnerMakePrivate.Private__c = true;
			update winnerMakePrivate;
			
			system.debug('Winner contact after nulling: ' + winnerMakePrivate);
			//do the same for the losers
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
		
		//set the contact Account Id back to the winning Account Id
		if (winnerMakePrivate.Id != null){
			winnerMakePrivate.AccountId = winningAccountId;
			winnerMakePrivate.Private__c = false;
			update winnerMakePrivate;
		}		
		successfulMerge = true;
	}
	
	public boolean displayMessagePopup {get; set;}
 
    public void cancelMessagePopup() {
        displayMessagePopup = false;

    }
 
    public void showMessagePopup() {
    	if(!tooFewContactsSelected){
	    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,system.label.Contact_Merge_Error_Confirm_Message);
	        ApexPages.addMessage(myMsg);
    	}
        displayMessagePopup = true;
    }
}
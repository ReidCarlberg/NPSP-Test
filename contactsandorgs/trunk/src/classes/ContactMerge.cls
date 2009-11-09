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
public class ContactMerge {

	//This class handles the heavy lifting of merging contacts. It can be called
	//from the VisualForce page for contact merge, or elsewhere.

	//min number of contacts that can be merged
	public final Integer MERGE_MINIMUM = 2;
	
	//max number of contacts that can be merged
	public final Integer MERGE_LIMIT = 3;
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
        
        public void selectFirstContact() {
        	//first is winner
			firstIsWinner = true;
			winner = firstContact;
			//others are not
	    	secondIsWinner = false;
	    	thirdIsWinner = false;
	    		    	
	    	losers.clear();
	    	//add all non-empty contacts to losers
	    	if(secondContact.Id!=null){
	    		losers.add(secondContact);
	    	}
	    	if(thirdContact.Id!=null){
	    		losers.add(thirdContact);
	    	}
        }
        //method for selecting second contact, called when user chooses the second as the winner
		public void selectSecondContact() {
			//second is winner
			secondIsWinner = true;
			winner = secondContact;
			//others are not
			firstIsWinner = false;    	
	    	thirdIsWinner = false;
	    	
			losers.clear();
			//add all non-empty contacts to losers
	    	if(firstContact.Id!=null){
	    		losers.add(firstContact);
	    	}
	    	if(thirdContact.Id!=null){
	    		losers.add(thirdContact);
	    	}		
		}
		//method for selecting third contact, called when user chooses the thirs as the winner
		public void selectThirdContact() {
			//third is winner
			thirdIsWinner = true;
			winner = thirdContact;
			//others are not
			firstIsWinner = false;
	    	secondIsWinner = false;    	
	    	
	    	losers.clear();
	    	//add all non-empty contacts to losers
	    	if(firstContact.Id!=null){
	    		losers.add(firstContact);
	    	}
	    	if(secondContact.Id!=null){
	    		losers.add(secondContact);
	    	}
		}
		
	//method to merge the winner and losers
	public boolean mergeContacts() {
		boolean successfulMerge = false;
		List<Account> winnerAccount = new List<Account>();
		Set<Id> loserAccountIds = new Set<Id>();
		List<Account> loserAccounts = new List<Account>();
		List<Account> loserAccountsToBeMerged = new List<Account>();
		List<Account> loserAccountsToBeDeleted = new List<Account>();
	
		Id winningAccountId = null;
		Boolean winnerAccountIsOneToOne = false;
		
		//get winner contact Account if it's one-to-one
		if (winner.AccountId!=null){
			winnerAccount = [Select Id,SYSTEMIsIndividual__c,Name from Account where Id=:winner.accountid];
		}
			
		if (winnerAccount.size()>0) {
			winnerAccountIsOneToOne = true;
			winningAccountId = winnerAccount[0].Id;
		}	
		
		for(Contact thisloserContact : losers){
			//don't try to merge null Accounts or Accounts that are the same as the winner's Account
			if (thisloserContact.id!=null && thisloserContact.AccountId!=winner.AccountId){
				loserAccountIds.add(thisloserContact.AccountId);
			}
		}
		
		//get loser contact Accounts
		loserAccountsToBeMerged = [Select Id,SYSTEMIsIndividual__c,Name from Account where Id IN :loserAccountIds and SYSTEMIsIndividual__c=true and Name<>:Constants.BUCKET_ACCOUNT_NAME];
		
		if(winnerAccountIsOneToOne){
			//one-to-one contacts each have an Account, so when merging Contacts we have to merge Accounts as well
			//we merge the Accounts first, if there are any one-to-one Accounts in the mix
			if(loserAccountsToBeMerged.size()>0){			
				merge winnerAccount[0] loserAccountsToBeMerged;
			}
		} else {
			for(Account accountForDeletion : loserAccountsToBeMerged){
				loserAccountsToBeDeleted.add(accountForDeletion);
			}
		}
		//merge the contacts
		
		//there is a Contact delete trigger that deletes the one-to-one Account of a Contact after it is deleted
		//merge deletes the losing Contacts, so their Accounts get deleted, which causes errors
		//to get around this, we detach the Contacts for their Accounts before we merge
		
		//create new contacts for updating as the SOSL returned contacts have read-only fields on them
		Contact winnerMakePrivate = new Contact();
		if(winnerAccountIsOneToOne){			
			winnerMakePrivate = new Contact(Id = winner.id,AccountId = null,Private__c=true);
		} else {
			winnerMakePrivate = new Contact(Id = winner.id);
		}
		List<Contact> losersMakePrivate = new List<Contact>();
		
		for(Contact contactForUpdate : losers){			
			Contact loserMakePrivate = new Contact(id=contactForUpdate.id,accountId=null,Private__c=true);
			losersMakePrivate.add(loserMakePrivate);
		}
			
		//set the account to null and mark private so that trigger won't reset the Account
		if (winningAccountId!=null && winnerAccountIsOneToOne){			
			update winnerMakePrivate;			
		}
		
		if(losersMakePrivate.size()>0){
			update losersMakePrivate;
		}

		merge winnerMakePrivate losersMakePrivate;
		
		//set the contact Account Id back to the winning Account Id
		if (winnerAccountIsOneToOne){
			winnerMakePrivate.AccountId = winningAccountId;
			winnerMakePrivate.Private__c = false;
			update winnerMakePrivate;
		}		
		system.debug('loserAccounts: ' + loserAccountsToBeDeleted);
		if(loserAccountsToBeDeleted.size()>0){
			//delete loserAccountsToBeDeleted;
		}
		successfulMerge = true;
		return successfulMerge;
	}
		
    //constructor for mergeSet class
    public ContactMerge() {
		selectedContacts = new List<Contact>();
		losers = new List<Contact>();
		winner = new Contact();
		
		//set all the winner booleans to false as none has been selected yet
		firstIsWinner = false;
    	secondIsWinner = false;
    	thirdIsWinner = false;
    }        
    
}
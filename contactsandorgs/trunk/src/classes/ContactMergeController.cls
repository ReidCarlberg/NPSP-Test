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
		thisMerge = new ContactMerge();
		displaySelected = false;
		tooManyContactsSelected = false;
		tooFewContactsSelected = true;
		displaySearchResults = false;
		displayMergeButton = false;
		fieldsForReturn = getContactFields();
		contactFields = Schema.SObjectType.Contact.fields.getMap();
	}
	//boolean used to render the selected Contacts pane
	public Boolean displaySelected { get { return displaySelected; } set { displaySelected = value; } }
	
	//string for all the Contact fields
	public String fieldsForReturn { get { return fieldsForReturn; } set { fieldsForReturn = value; } }
	
	//List for SOSL results
	public List<List<SObject>> searchList { get { return searchList; } set { searchList = value; } }
	
	//boolean used to render the search results pane
	public Boolean displaySearchResults { get { return displaySearchResults; } set { displaySearchResults = value; } }
	
	//boolean used to render the display button
	public Boolean displayMergeButton { get { return displayMergeButton; } set { displayMergeButton = value; } }
	
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
	
	//max number of Contacts returned by a query
	private final Integer SOSL_LIMIT = 20;
	
	//singleton to hold the merging contacts and relevant info
	public ContactMerge thisMerge { get { return thisMerge; } set { thisMerge = value; } }
	
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
    
    //method for selecting first contact, called when user chooses the first as the winner
    public void selectFirstContact() {
    	//show error message if this is the only contact in the merge set
    	if(tooFewContactsSelected){
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,system.label.Contact_Merge_Error_Too_Few_Contacts);
    		ApexPages.addMessage(myMsg);
        	displayMessagePopup = true;
        	displayMergeButton = false;
    	} else {
    		thisMerge.selectFirstContact();
	    	displayMergeButton = true;
    	}

	}
	//method for selecting second contact, called when user chooses the second as the winner
	public void selectSecondContact() {
		//second is winner
		thisMerge.selectSecondContact();
    	displayMergeButton = true;
	
	}
	//method for selecting third contact, called when user chooses the thirs as the winner
	public void selectThirdContact() {
		//third is winner
		thisMerge.selectThirdContact();    	
    	displayMergeButton = true;
	}
	//search for contacts
	public void search() {
		
		if(searchText.length()>0){
			
			//reset booleans that control display of results elements
			displaySelected = false;
			successfulMerge = false;
			displaySearchResults = false;

			mySOSL();
			searchResults = wrapSOSLResults(searchList);

			//if we got a result back, show the search results pane
			if(searchResults.size()>0){
				displaySearchResults = true;
			}
		}
	}
	
	
	//separate method so these fields are only described once--called from constructor
	public String getContactFields(){
		String fieldString = '';
		
		//get all fields from the Contact record and put in string for dynamic SOSL call
		Set<String> fields = contactFields.keySet(); 
		Boolean firstField = true;               
		for(String field : Fields){        	
			if(!firstField) // if it's not the first prepend a comma        		
				fieldString += ',' + field;        	
			else        		
				fieldString += field;
				firstField = false;
		}  
		return fieldString;
	}
	//run the SOSL
	public void mySOSL()
	{
		//empty any previous results
		thisMerge.selectedContacts.clear();
		searchResults.clear();    
		
		//build the SOSL query and execute
		String searchquery = 'FIND \'' + searchText + '\' IN ALL FIELDS RETURNING Contact(' + fieldsForReturn +' ORDER BY LastName LIMIT ' + SOSL_LIMIT + ')';
		
		searchList = search.query(searchquery);
		//List<List<SObject>> searchList = new List<List<SObject>>();
		
		
	}
	//wrap the SOSL results
	public List<contactWrapper> wrapSOSLResults(List<List<SObject>> mySearchList){
		
		//loop through the contacts putting them in an array of wrappers
		if(mySearchList.size()>0){
			for (SObject returnedObject : mySearchList[0]){
				//if the returned object is a contact, add it to the Contact list
				if(returnedObject.getSObjectType() == Contact.sObjectType){
					contactWrapper thisResult = new contactWrapper((Contact) returnedObject);				
					searchResults.add(thisResult);	
				}
			}
		}
		return searchResults;		
	}
	//method that is run when a Contact checkbox is clicked in the search results.
	//contacts are collected and put in the pane for display
	public void getSelected()
    {
    	//reset all the winner booleans so the checkboxes will reset
        thisMerge.firstIsWinner = false;
    	thisMerge.secondIsWinner = false;
    	thisMerge.thirdIsWinner = false;
    	
    	displayMergeButton = false;
    	
        //empty the list of selected contacts so we can repopulate it
        thisMerge.selectedContacts.clear();
        
        for(contactWrapper conWrapper : searchResults) {
        	if(conWrapper.selected == true) {
        		thisMerge.selectedContacts.add(conWrapper.con);
        	}
        }
        
        numberOfContactsSelected = thisMerge.selectedContacts.size();
        
        if(numberOfContactsSelected>thisMerge.MERGE_LIMIT){
        	//report an error that you can only select 3 or fewer
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,system.label.Contact_Merge_Error_Too_Many_Contacts);
        	ApexPages.addMessage(myMsg);
        	
        	tooManyContactsSelected = true;
        	displayMessagePopup = true;
        	
        	tooFewContactsSelected = false;
        } else {
        	tooManyContactsSelected = false;
        	//set the boolean for potential error reporting if the Users tries to merge just one record
        	if(numberOfContactsSelected<thisMerge.MERGE_MINIMUM){
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
		if(thisMerge.mergeContacts()){
			successfulMerge = true;
			displaySearchResults = false;
			displaySelected = false;
		}
	}
	
	public boolean displayMessagePopup {get; set;}
 
    public void cancelMessagePopup() {
        displayMessagePopup = false;

    }
 
    public void showMessagePopup() {
    	if(!tooFewContactsSelected){
	    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,system.label.Contact_Merge_Error_Confirm_Message + ' ' + system.label.Contact_Merge_Error_Confirm_Message_Households);
	        ApexPages.addMessage(myMsg);
    	}
        displayMessagePopup = true;
    }
    
}
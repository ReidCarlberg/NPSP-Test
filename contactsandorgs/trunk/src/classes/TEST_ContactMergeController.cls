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
@isTest
private class TEST_ContactMergeController {
/*
	Cases:
	
	Different kinds of contact+orgs:
	* private
	* one-to-one
	* Individual
	* Org
	
	that yields 16 different tests.
	
	Additional tests:
	* three contacts
	* UI
		* merge button should be invisible until a winner from the selected contacts is chosen
		* 
*/
	

    static testMethod void exerciseUI() {

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
        
        String secondContactfirstName = 'test';
    	String secondContactLastName = 'Contact_forTests2';
    	String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
        	FirstName=secondContactfirstName,
        	LastName=secondContactLastName,
        	MailingStreet = secondContactMailingStreet,
        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        String thirdContactfirstName = 'test';
    	String thirdContactLastName = 'Contact_forTests3';
    	String thirdContactMailingStreet = '123 Elm St';
        Contact con3 = new Contact(
        	FirstName=thirdContactfirstName,
        	LastName=thirdContactLastName,
        	MailingStreet = thirdContactMailingStreet,
        	SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con3;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
		
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
		Id[] fixedSearchResults=new Id[3]; 
		fixedSearchResults[0]=con.Id; 
		fixedSearchResults[1]=con2.Id; 
		fixedSearchResults[2]=con3.Id; 
		
		Test.setFixedSearchResults(fixedSearchResults); 
		
        controller.search();
       
		system.assertEquals(3,controller.searchResults.size());
		
		controller.searchResults[0].selected = true;
		controller.searchResults[1].selected = true;
		controller.getSelected();
		//two contacts should be returned
		system.assertEquals(2,controller.thisMerge.selectedContacts.size());
		
		controller.searchResults[0].selected = false;
		controller.searchResults[2].selected = true;
		controller.getSelected();
		//two contacts should be returned
		system.assertEquals(2,controller.thisMerge.selectedContacts.size());
		
		controller.searchResults[0].selected = true;
		controller.getSelected();
		//three contacts should be returned
		system.assertEquals(3,controller.thisMerge.selectedContacts.size());
		system.assert(!controller.tooManyContactsSelected);
		system.assert(!controller.tooFewContactsSelected);
		
		
		system.assertEquals(con.id,controller.thisMerge.selectedContacts[0].id);
		
		system.assert(!controller.displayMergeButton);
		
		controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
		controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
		controller.thisMerge.thirdContact = controller.thisMerge.selectedContacts[2];
		
		controller.selectFirstContact();
		//booleans should show first is chosen
		system.assert(controller.thisMerge.firstIsWinner);
		system.assert(!controller.thisMerge.secondIsWinner);
		system.assert(!controller.thisMerge.thirdIsWinner);
		
		//winner and losers should be right
		system.assertEquals(con.id,controller.thisMerge.winner.id);
		system.assertEquals(con2.id,controller.thisMerge.losers[0].id);
		system.assertEquals(con3.id,controller.thisMerge.losers[1].id);
		
		//booleans for display should be true
		system.assert(controller.thisMerge.displayFirst);
		system.assert(controller.thisMerge.displaySecond);
		system.assert(controller.thisMerge.displayThird);
		
		system.assert(controller.displayMergeButton);
		
		//booleans should show second is chosen
		controller.selectSecondContact();
		system.assert(!controller.thisMerge.firstIsWinner);
		system.assert(controller.thisMerge.secondIsWinner);
		system.assert(!controller.thisMerge.thirdIsWinner);
		
		//booleans should show second is chosen
		controller.selectThirdContact();
		system.assert(!controller.thisMerge.firstIsWinner);
		system.assert(!controller.thisMerge.secondIsWinner);
		system.assert(controller.thisMerge.thirdIsWinner);
		
		system.assertEquals(con.id,controller.thisMerge.firstContact.id);
		
    }
}
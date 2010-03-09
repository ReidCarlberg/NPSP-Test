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
/*
    static testMethod void soslTest() {
        Account thisAccount = new Account(name='junk');
        insert thisAccount;
       Id [] fixedSearchResults= new Id[1];
       fixedSearchResults[0] = thisAccount.id;
       Test.setFixedSearchResults(fixedSearchResults);
       List<List<SObject>> searchList = [FIND 'test' 
                                         IN ALL FIELDS RETURNING 
                                            Account(id, name WHERE name = 'test' LIMIT 1)];
    }
    */
@isTest
private class TEST_ContactMergeController {


    
    //exercise the many UI variables
    static testMethod void exerciseUI() {
        
        //set up 3 contacts for the merge interface to work with
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        String thirdContactfirstName = 'test';
        String thirdContactLastName = '3Contact_forTests_Merge';
        String thirdContactMailingStreet = '123 Elm St';
        Contact con3 = new Contact(
            FirstName=thirdContactfirstName,
            LastName=thirdContactLastName,
            MailingStreet = thirdContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con3;
        
        Test.startTest();
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();

        controller.searchText = 'test';
        
		controller.search();
		
		//search results should be displayed
        system.assert(!controller.displaySearchResults);

        Id[] fixedSearchResults=new Id[3]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        fixedSearchResults[2]=con3.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        
        //call the search method, which will return the bogus SOSL results
        
        controller.search();
        
		//if we got a result back, show the search results pane
		if(controller.searchResults.size()>0){
			controller.displaySearchResults = true;
		}
        //search results should be displayed
        system.assert(controller.displaySearchResults);
        
        //there should be 3 Contacts returned
        system.assertEquals(3,controller.searchResults.size());
        //we haven't selected a contact yet     
        system.assertEquals(null,controller.thisMerge.getFirstContact());
        
        controller.getSelected();
        //one contact should be returned
        system.assertEquals(0,controller.thisMerge.selectedContacts.size());
        
        controller.searchResults[0].selected = true;        
        controller.getSelected();
        //one contact should be returned
        system.assertEquals(1,controller.thisMerge.selectedContacts.size());
        //we've only selected one contact
        system.assertNotEquals(null,controller.thisMerge.getFirstContact());
        system.assertEquals(null,controller.thisMerge.getSecondContact());
        system.assertEquals(null,controller.thisMerge.getThirdContact());
        
        controller.searchResults[0].selected = false;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.getSelected();
        //two contacts should be returned
        system.assertEquals(2,controller.thisMerge.selectedContacts.size());
        //there should be a second contact now
        system.assertNotEquals(null,controller.thisMerge.getSecondContact());
        
        controller.searchResults[0].selected = true;
        controller.getSelected();
        //three contacts should be returned
        system.assertEquals(3,controller.thisMerge.selectedContacts.size());
        system.assert(!controller.tooManyContactsSelected);
        system.assert(!controller.tooFewContactsSelected);
        system.debug(controller.thisMerge.selectedContacts[0].id);
        system.debug(controller.thisMerge.selectedContacts[1].id);
        system.debug(controller.thisMerge.selectedContacts[2].id);
        system.assertEquals(con.id,controller.thisMerge.selectedContacts[0].id);
        //the merge button should be visible
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
        
        controller.showMessagePopup();
        system.assert(controller.displayMessagePopup);
        controller.cancelMessagePopup();
        system.assert(!controller.displayMessagePopup);
        
        Test.stopTest();
        
    }
   
    static testMethod void tooFewContactsSelected() {
        //set up 3 contacts for the merge interface to work with
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value      
        Id[] fixedSearchResults=new Id[1]; 
        fixedSearchResults[0]=con.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //call the search method, which will return the bogus SOSL results
        controller.search();
        
        controller.searchResults[0].selected = true;        
        controller.getSelected();
        
        //selection of this contact should be a too few selected error
        controller.selectFirstContact();
        //should display selected contacts
        system.assert(controller.displaySelected);
        
        system.assert(controller.tooFewContactsSelected);
    }
    static testMethod void tooManyContactsSelected() {
        //set up 3 contacts for the merge interface to work with
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        String thirdContactfirstName = 'test';
        String thirdContactLastName = '3Contact_forTests_Merge';
        String thirdContactMailingStreet = '123 Elm St';
        Contact con3 = new Contact(
            FirstName=thirdContactfirstName,
            LastName=thirdContactLastName,
            MailingStreet = thirdContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con3;
        
        String fourthContactfirstName = 'test';
        String fourthContactLastName = '4Contact_forTests_Merge';
        String fourthContactMailingStreet = '123 Elm St';
        Contact con4 = new Contact(
            FirstName=fourthContactfirstName,
            LastName=fourthContactLastName,
            MailingStreet = fourthContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con4;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        
        Id[] fixedSearchResults=new Id[4]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        fixedSearchResults[2]=con3.Id; 
        fixedSearchResults[3]=con4.Id;
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //call the search method, which will return the bogus SOSL results
        controller.search();
        
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.searchResults[3].selected = true;
        
        controller.getSelected();
        //should be a too many selected error
        system.assert(controller.tooManyContactsSelected);
    }
    //test the visibilty of the popup messages
    static testMethod void popupVisibility() {
        //point to the VF page
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        //instantiate the controller
        ContactMergeController controller = new ContactMergeController();
        //call methods
        controller.showMessagePopup();
        //the popup should be displayed
        system.assert(controller.displayMessagePopup);
        controller.cancelMessagePopup();
        //the popup should be hidden
        system.assert(!controller.displayMessagePopup);
    }
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    static testMethod void merge2OneToOne() {

        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectSecondContact();
        //merge them
        controller.mergeContacts();
        
        //first contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:secondId]);
        system.assertEquals(0,[select count() from Contact where id=:firstId]);
        //first contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(0,[select count() from Account where id=:firstAccountId]);
        //Second contact's account id should not have changed
        system.assertEquals(secondAccountId,[select AccountId from Contact where id=:secondId].AccountId);
    }
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org shouldn't be deleted because it has open opportunities
    static testMethod void merge2OneToOneOpps() {

        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
      
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        Opportunity o = new Opportunity(AccountId=firstAccountId,Amount=500,Name='test',StageName='Closed Won',CloseDate=System.today());
		insert o;
        
        //select the first as winner
        controller.selectSecondContact();
        
        //merge them
        controller.mergeContacts();
        
        //first contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:secondId]);
        system.assertEquals(0,[select count() from Contact where id=:firstId]);
        //first contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(0,[select count() from Account where id=:firstAccountId]);
        //Second contact's account id should not have changed
        system.assertEquals(secondAccountId,[select AccountId from Contact where id=:secondId].AccountId);
    }
    
    //merge a one-to-one contact with one in a normal organzation
    //the organization shouldn't be deleted
    static testMethod void merge2Organizations() {
        
        Account acc = new Account(
            Name = 'Test Account 1'
        );
        insert acc;
        
        Account acc2 = new Account(
            Name = 'Test Account 2'
        );
        insert acc2;

        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            AccountId = acc.id
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            AccountId = acc2.id
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account should not be deleted
        system.assertEquals(1,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    //merge two private contacts
    //the organization shouldn't be deleted
    static testMethod void merge2PrivateContacts() {
        
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            Private__c = true
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            Private__c = true
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //First contact's account id should not have changed
        system.assertEquals(null,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted
    static testMethod void merge2Individuals() {
        
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account should not be deleted
        system.assertEquals(1,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static testMethod void merge1Individual1OneToOne() {
        
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests2_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account should not be deleted
        system.assertEquals(1,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static testMethod void merge1OneToOne1Individual() {
        
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.BUCKET_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests2_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account should be deleted
        system.assertEquals(0,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static testMethod void merge1Org1OneToOne() {
        
        Account acc = new Account(
            Name = 'Test Account 1'
        );
        insert acc;
        
        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            AccountId = acc.id          
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account should be deleted
        system.assertEquals(0,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
    
    static testMethod void merge3OneToOne() {

        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        String thirdContactfirstName = 'test';
        String thirdContactLastName = '3Contact_forTests_Merge';
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
        
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.getSelected();
        
        system.assertNotEquals(null,controller.thisMerge.getThirdContact());
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        controller.thisMerge.thirdContact = controller.thisMerge.selectedContacts[2];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        Id thirdId = controller.thisMerge.thirdContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        Id thirdAccountId = controller.thisMerge.thirdContact.AccountId;
        
        //select the first as winner
        controller.selectThirdContact();
        //merge them
        controller.mergeContacts();
        
        //first and second contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:thirdId]);
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(0,[select count() from Contact where id=:firstId]);
        //first and second contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:thirdAccountId]);
        system.assertEquals(0,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(0,[select count() from Account where id=:firstAccountId]);
        //Third contact's account id should not have changed
        system.assertEquals(thirdAccountId,[select AccountId from Contact where id=:thirdId].AccountId);
    }
    
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    static testMethod void merge2OneToOneInSameAccount() {

        String newContactfirstName = 'test';
        String newContactLastName = '1Contact_forTests_Merge';
        String newContactMailingStreet = '123 Elm St';
        Contact con = new Contact(
            FirstName=newContactfirstName,
            LastName=newContactLastName,
            MailingStreet = newContactMailingStreet,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con;
        
        Id conAccountId = [select accountId from Contact where id=:con.id].accountId;
        
        String secondContactfirstName = 'test';
        String secondContactLastName = '2Contact_forTests_Merge';
        String secondContactMailingStreet = '123 Elm St';
        Contact con2 = new Contact(
            FirstName=secondContactfirstName,
            LastName=secondContactLastName,
            MailingStreet = secondContactMailingStreet,
            AccountId = conAccountId,
            SystemAccountProcessor__c = Constants.ONE_TO_ONE_PROCESSOR
        );
        insert con2;
        
        Test.setCurrentPageReference(new PageReference('Page.ContactMerge'));
        
        ContactMergeController controller = new ContactMergeController();
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.getSelected();
        //put them in the contact records
        controller.thisMerge.firstContact = controller.thisMerge.selectedContacts[0];
        controller.thisMerge.secondContact = controller.thisMerge.selectedContacts[1];
        
        //grab their Ids
        Id firstId = controller.thisMerge.firstContact.Id;
        Id secondId = controller.thisMerge.secondContact.Id;
        //grab their AccountIds
        Id firstAccountId = controller.thisMerge.firstContact.AccountId;
        Id secondAccountId = controller.thisMerge.secondContact.AccountId;
        
        //select the first as winner
        controller.selectFirstContact();
        //merge them
        controller.mergeContacts();
        
        system.assert(controller.successfulMerge);
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:secondId]);
        system.assertEquals(1,[select count() from Contact where id=:firstId]);
        //second contact's account shouldn't be deleted
        system.assertEquals(0,[select count() from Account where id=:secondAccountId]);
        system.assertEquals(1,[select count() from Account where id=:firstAccountId]);
        //First contact's account id should not have changed
        system.assertEquals(firstAccountId,[select AccountId from Contact where id=:firstId].AccountId);
    }
  
}
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

/*This controller supports a page that overrides the Contact Delete standard method.
It's intent is to remove one-to-one Accounts when a contact is deleted. It won't delete
Accounts that have opportunities.

Because this delete override is a VF page and not a trigger, it will not be invoked from the API
*/
public class ContactDeleteOverride
{
	private final Contact c;

    public ContactDeleteOverride(ApexPages.StandardController controller)
    {
        this.c = (Contact) controller.getRecord();
    }    

    public Boolean getDeleteAccount()
    { 
		PageReference newPage; 
		Boolean canDelete = true;
		system.debug('contact record: ' + c);
		//we need to requery c to get AccountId
		Contact[] pulledC = [select id, accountid from Contact where id=:c.id];
		if (pulledC.size()>0){
	        if ( pulledC[0].AccountId != null )
	        {
	        	Account a = [Select Id, Type from Account where Id = :pulledC[0].AccountId limit 1];
	        	system.debug('account record: ' + a);
	        	if ( a.Type == Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
	        	{
	        		//one-to-one accounts can be deleted
	        		
	        		//if there are Opportunities for this Account, don't delete it
	        		for (Opportunity o : [Select Id, AccountId from Opportunity where AccountId = :a.Id limit 1])
	        		{
	        			canDelete = false;
	        		}
	        	} else
	        	{
	        		//don't delete a regular account or the bucket account
	        		canDelete = false;
	        	}
	        } else
	        {
	        	//don't delete a null account
	        	canDelete = false;
	        }
	        
		} else {
			canDelete= false;
		}
		
        return canDelete;
    }

    private final ApexPages.StandardController controller;   
    /*
    THESE TESTS ARE ASSUMING THE CODE IS TRIGGER BASED - MAY COME IN HELPFUL WHEN THAT IS CHANGED
    /// <name> deleteContactOneToOne </name>
    /// <summary> Test Method for deleting a Contact in the One-to-One model</summary>
    static testMethod void deleteContactOneToOne()
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
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
		
		Id createdAccountId = insertedContacts[0].AccountId;
	
		delete con;
		
		Account[] oneToOneAccount = [Select Id from Account where id=:createdAccountId];
		
		//the account should be gone
		system.assertEquals(0,oneToOneAccount.size());
		
    }
    
        /// <name> deleteContactOneToOneWithOpp </name>
    /// <summary> Test Method for deleting a Contact in the One-to-One model when the Account has an Opp</summary>
    static testMethod void deleteContactOneToOneWithOpp()
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
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
		
		Id createdAccountId = insertedContacts[0].AccountId;
		
		Opportunity opp = new Opportunity(
			Amount=500,
			AccountId=createdAccountId,
			Name='test',
			StageName='Closed/Won',
			CloseDate=System.today()
		);
		insert opp;
	
		delete con;
		
		Account[] oneToOneAccount = [Select Id from Account where id=:createdAccountId];
		
		//the account should be gone
		system.assertEquals(1,oneToOneAccount.size());
		
    }
    */
    public static testMethod void deleteContactNoOpp() {

        
        Test.setCurrentPageReference(new PageReference('Page.ContactDeleteOverride'));
        
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
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
		
		Id createdAccountId = insertedContacts[0].AccountId;
       
       
		
		//system.currentPageReference().getParameters().put('id', con.id);
		
		//pass contact into the controller
		ApexPages.StandardController sc = new ApexPages.standardController(con);
		//pass the controller into the extension
		ContactDeleteOverride ext = new ContactDeleteOverride(sc); 
		
		system.assert(ext.getDeleteAccount());

    }
    public static testMethod void deleteContactWithOpp() {

        
        Test.setCurrentPageReference(new PageReference('Page.ContactDeleteOverride'));
        
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
        
        Contact[] insertedContacts = [Select FirstName, LastName, AccountId  from Contact where id=:con.id];
		
		Id createdAccountId = insertedContacts[0].AccountId;
       
       Opportunity opp = new Opportunity(
			Amount=500,
			AccountId=createdAccountId,
			Name='test',
			StageName='Closed/Won',
			CloseDate=System.today()
		);
		insert opp;
		
		//pass contact into the controller
		ApexPages.StandardController sc = new ApexPages.standardController(con);
		//pass the controller into the extension
		ContactDeleteOverride ext = new ContactDeleteOverride(sc); 
		
		system.assert(!ext.getDeleteAccount());

    }
    

}
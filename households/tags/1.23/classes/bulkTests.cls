/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class bulkTests {

     /// <name> newIndContactAllContactsProcessor </name>
    /// <summary> test insert individual with all contacts processor </summary>
    static testMethod void newIndContactAllContactsProcessor() {
    	String street = '2345 Elm St.';
    	String city = 'Seattle';
    	String state = 'WA';
    	String zip = '88777';
    	String country = 'US';
    	String lastname = 'SmithForTest99';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				MailingStreet = street,
				MailingCity = city,
				MailingState = state,
				MailingPostalCode = zip,
				MailingCountry = country,
				SystemHouseholdProcessor__c = 'All New or Edited Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        Id firstHouseholdId = createdContacts[0].Household__c;
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
        
        //blank out the HH
        for(Contact thisContact : createdContacts){
        	thisContact.Household__c = null;
        }
        update createdContacts;
        Test.stopTest();
        createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        system.assertNotEquals(firstHouseholdId,createdContacts[0].Household__c);
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
    }

    /// <name> newIndContactIndividualsProcessor </name>
    /// <summary> test insert individual with individuals processor </summary>
    static testMethod void newIndContactIndividualsProcessor() {
		String street = '2345 Elm St.';
    	String city = 'Seattle';
    	String state = 'WA';
    	String zip = '88777';
    	String country = 'US';
    	String lastname = 'SmithForTest99';
    	
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				MailingStreet = street,
				MailingCity = city,
				MailingState = state,
				MailingPostalCode = zip,
				MailingCountry = country,
				SystemHouseholdProcessor__c = 'All Individual Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        Id firstHouseholdId = createdContacts[0].Household__c;
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
        
        //blank out the HH
        for(Contact thisContact : createdContacts){
        	thisContact.Household__c = null;
        }
        update createdContacts;
        Test.stopTest();
        createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        system.assertNotEquals(firstHouseholdId,createdContacts[0].Household__c);
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
    }
    
    /// <name> newOrgContactAllContactsProcessor </name>
    /// <summary> test insert org contact with all contacts processor </summary>
    static testMethod void newOrgContactAllContactsProcessor() {
		Account acct = new Account(
			Name = 'Test Organization 888'
		);
        insert acct;
		
		String street = '2345 Elm St.';
    	String city = 'Seattle';
    	String state = 'WA';
    	String zip = '88777';
    	String country = 'US';
    	String lastname = 'SmithForTest99';
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				MailingStreet = street,
				MailingCity = city,
				MailingState = state,
				MailingPostalCode = zip,
				MailingCountry = country,
				AccountId = acct.id,
				SystemHouseholdProcessor__c = 'All New or Edited Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        Id firstHouseholdId = createdContacts[0].Household__c;
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
        
        //blank out the HH
        for(Contact thisContact : createdContacts){
        	thisContact.Household__c = null;
        }
        update createdContacts;
        Test.stopTest();
        createdContacts = [select Household__r.Name,Household__r.MailingStreet__c,Household__r.MailingCity__c,Household__r.MailingState__c,Household__r.MailingPostalCode__c,Household__r.MailingCountry__c,Household__c from Contact where id IN :cons];
        
        system.assertNotEquals(firstHouseholdId,createdContacts[0].Household__c);
        system.assertEquals(street,createdContacts[0].Household__r.MailingStreet__c);
       	system.assertEquals(city,createdContacts[0].Household__r.MailingCity__c);
        system.assertEquals(state,createdContacts[0].Household__r.MailingState__c);
        system.assertEquals(zip,createdContacts[0].Household__r.MailingPostalCode__c);
        system.assertEquals(country,createdContacts[0].Household__r.MailingCountry__c);
        system.assertEquals(lastname + ' Household',createdContacts[0].Household__r.Name);
    }

    /// <name> newOrgContactIndividualsProcessor </name>
    /// <summary> test insert org contact with Individuals processor </summary>
    static testMethod void newOrgContactIndividualsProcessor() {
		Account acct = new Account(
			Name = 'Test Organization 888'
		);
        insert acct;
		
		String street = '2345 Elm St.';
    	String city = 'Seattle';
    	String state = 'WA';
    	String zip = '88777';
    	String country = 'US';
    	String lastname = 'SmithForTest99';
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				MailingStreet = street,
				MailingCity = city,
				MailingState = state,
				MailingPostalCode = zip,
				MailingCountry = country,
				AccountId = acct.id,
				SystemHouseholdProcessor__c = 'All Individual Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__c from Contact where id IN :cons];
        
        system.assertEquals(null,createdContacts[0].Household__c);
        
        //blank out the HH
        for(Contact thisContact : createdContacts){
        	thisContact.MailingStreet = 'test';
        }
        update createdContacts;
        Test.stopTest();
        createdContacts = [select Household__c from Contact where id IN :cons];
        
        system.assertEquals(null,createdContacts[0].Household__c);
    }

    /// <name> contactDeleteWithOwnHousehold </name>
    /// <summary> test delete a contact that has it's own household </summary>
    static testMethod void contactDeleteWithOwnHousehold() {
    	String lastname = 'SmithForTest99';
    	List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				SystemHouseholdProcessor__c = 'All Individual Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__c from Contact where id IN :cons];
        List<id> householdIds = new List<id>();
        for(Contact thiscontact : createdContacts){
        	householdIds.add(createdContacts[0].Household__c);
        }
        
        delete cons;
        Test.stopTest();
        Household__c[] deletedHousehold = [select id from Household__c where id IN :householdIds];
        system.assert(deletedHousehold.size()==0);
    }
    
    /// <name> contactDeleteWithSharedHousehold </name>
    /// <summary> test delete a contact that has shared household </summary>
    static testMethod void contactDeleteWithSharedHousehold() {
		String lastname = 'SmithForTest99';
		List<Contact> cons = new List<contact>();
    	Integer conCount = 200;
    	for(Integer i=0;i<conCount;i++){
			Contact con = new Contact(
				FirstName='test',
				LastName=lastname,
				SystemHouseholdProcessor__c = 'All Individual Contacts'
			);
			cons.add(con);
    	}
    	Test.startTest();
        insert cons;
        Contact[] createdContacts = [select Household__c from Contact where id IN :cons];
        
        List<id> householdIds = new List<id>();
        for(Contact thiscontact : createdContacts){
        	householdIds.add(thiscontact.Household__c);
        }
        List<Contact> cons2 = new List<contact>();
        for(Integer i=0;i<conCount;i++){
	        Contact con2 = new Contact(
				FirstName='test again',
				LastName=lastname,
				Household__c = householdIds[i],
				SystemHouseholdProcessor__c = 'All Individual Contacts'
			);
			cons2.add(con2);
        }
        insert cons2;
        
        delete cons;
        Test.stopTest();
        Household__c[] remainingHousehold = [select id from Household__c where id IN :householdIds];
        system.assertEquals(conCount,remainingHousehold.size());
    }

    /// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
	static testMethod void getHouseholdTransactionTotal_test()
	{
		Household__c h = new Household__c(Name='Test Household');
		insert h;
		Contact c = new Contact(FirstName='test',LastName='test',Household__c=h.Id);
		insert c;
		Opportunity o = new Opportunity(Name='test oppty',CloseDate=System.Today(),StageName='Closed Won',Amount=100);
		insert o;
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=c.Id,Role='Test');
		insert ocr;
		system.assertEquals('$100.00',Households.getHouseholdTransactionTotal(h.id));
	}
	
	/// <name> getHouseholdTransactionTotal </name>
    /// <summary>  </summary>
	static testMethod void getHouseholdLastTransaction_test()
	{
		Integer year = 2005;
		Integer month = 10;
		Integer day = 10;
		Household__c h = new Household__c(Name='Test Household');
		insert h;
		Contact c = new Contact(FirstName='test',LastName='test',Household__c=h.Id);
		insert c;
		Opportunity o = new Opportunity(Name='test oppty',CloseDate=date.newInstance(year,month,day),StageName='Closed Won',Amount=100);
		insert o;
		OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=o.Id,ContactId=c.Id,Role='Test');
		insert ocr;
		system.assertEquals(String.valueOf(year)+'-'+String.valueOf(month)+'-'+String.valueOf(day),Households.getHouseholdLastTransaction(h.id));
	}
	

}
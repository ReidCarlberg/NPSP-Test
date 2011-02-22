/**
 * @author Salesforce.com Foundation 
 * @date 02/07/2010
 * @description Provides batch wrapper for opportunity rollups
 */
global class BATCH_OppRollup implements Database.Batchable<SObject> {
// batch apex class to rollup opportunities
	
	public String query { get; set; }
	
	/**    
    * @author Salesforce.com Foundation
    * @date 02/07/2010
    * @description Constructor
    * @param Contains query string 
    */
	public BATCH_OppRollup(string q) {    
		query = q; 
	}
		
	/**    
    * @author Salesforce.com Foundation
    * @date 02/07/2010
    * @description Start method for batch apex query locator
    * @param bc contains context 
    */
	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	
	/**    
    * @author Salesforce.com Foundation
    * @date 02/07/2010
    * @description execute method of batch
    * @param bc Contains results of the query locater
    * @param result a list of sobjects 
    */
	global public void execute(Database.BatchableContext bc, Sobject[] result) {
		
		// run rollups for this batch		
		OpportunityRollups rg = new OpportunityRollups();
		
 		if (result[0].getSObjectType() == Account.sObjectType) { 
			rg.RollupAccounts((list<account>)result);
 		} else {
			rg.RollupHouseholds((list<household__c>)result);
 		}
 		
	}
    /**    
    * @author Salesforce.com Foundation
    * @date 02/07/2010
    * @description finish method of batch  
    * @param a batchable context for processing finish.    
    */
	global void finish(Database.BatchableContext bc) {
	}
    
    /**    
    * @author Salesforce.com Foundation
    * @date 02/07/2010
    * @description test method     
    */
	public static testMethod void testBatch() {
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		if(giftRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = true,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = null,
					Membership_Record_Types__c = null
				));
	        
	        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
	        	npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
	        	npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
	        	npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
	        ));
			
			Date datClose = System.Today();
				
			// create & insert contact(s)
			Contact[] TestCons = new contact[]{ new contact(
				FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
	            LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
	            npe01__Private__c=false,
	            npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
	            npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
	            npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
	            npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
			) };
			insert TestCons;
			
			Contact insertedContact = [select accountid from Contact where id IN :TestCons];

			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
			String contactAccountId = insertedContact.accountid;
		
			BATCH_OppRollup batch = new BATCH_OppRollup(
				'SELECT id FROM account where Id =\'' + contactAccountId + '\' limit 200'
			);
			
			Test.StartTest(); 
			id batchProcessId = database.executeBatch(batch);
			Test.StopTest(); 
		}
	}
}
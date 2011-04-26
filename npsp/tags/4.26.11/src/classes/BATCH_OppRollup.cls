global class BATCH_OppRollup implements Database.Batchable<SObject> {
// batch apex class to rollup opportunities
	
	public String query { get; set; }
	
	// constructors
	public BATCH_OppRollup(string q) {  
		query = q; 
	}
	
	global database.Querylocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);		 
	}
	
	global public void execute(Database.BatchableContext bc, Sobject[] result) {
		
		// run rollups for this batch		
		OpportunityRollups rg = new OpportunityRollups();
		
 		if (result[0].getSObjectType() == Account.sObjectType) { 
			rg.RollupAccounts((list<account>)result);
 		} else {
			rg.RollupHouseholds((list<household__c>)result);
 		}
 		
	}

	global void finish(Database.BatchableContext bc) {
	}

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
	        
	        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
	        	Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
	        	Enable_Opportunity_Contact_Role_Trigger__c = true,
	        	Opportunity_Contact_Role_Default_role__c = 'Donor'
	        ));
			
			Date datClose = System.Today();
				
			// create & insert contact(s)
			Contact[] TestCons = new contact[]{ new contact(
				FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS,
	            LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
	            Private__c=false,
	            WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
	            Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
	            WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
	            PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
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
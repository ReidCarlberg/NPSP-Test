public class OpportunityRollups {

	// settings
	boolean triggerRollupEnabled = true;
	boolean alwaysRollupToPrimaryContact = false; 
	set<id> recordTypesToExcludeAccts = new set<id>();
	set<id> recordTypesToExcludeCons = new set<id>();
	set<id> mbrRecordTypes = new set<id>();	
	set<string> oppTypesToExcludeAccts = new set<string>();
	set<string> oppTypesToExcludeCons = new set<string>();	
	
	static boolean recordTypesOnOpps;
	
	public static boolean areRecordTypesOnOpps(){
		if (recordTypesOnOpps==null){

			String giftRt = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
			if (giftRt!=null&&giftRt!=''){
				recordTypesOnOpps = true;
			} else {
				recordTypesOnOpps = false;
			}
		}
		return recordTypesOnOpps;
	}

	static boolean isTest = false; 

	// constructor
	public OpportunityRollups() {

		// load settings
        Households_Settings__c rollupSettings = Households.getHouseholdsSettings();

		if (rollupSettings != null) {
			if (rollupSettings.Excluded_Contact_Opp_Rectypes__c != null) {
				set<string> rtNamesToExclude = new set<string>(rollupSettings.Excluded_Contact_Opp_Rectypes__c.split(';'));
				recordTypesToExcludeCons = RecordTypes.GetRecordTypeIdSet('Opportunity', rtNamesToExclude);
			}
			if (rollupSettings.Excluded_Account_Opp_Rectypes__c != null) {
				set<string> rtNamesToExclude = new set<string>(rollupSettings.Excluded_Account_Opp_Rectypes__c.split(';'));
				recordTypesToExcludeAccts = RecordTypes.GetRecordTypeIdSet('Opportunity', rtNamesToExclude);
			}
			if (rollupSettings.Excluded_Contact_Opp_Types__c != null) {
				oppTypesToExcludeCons = new set<string>(rollupSettings.Excluded_Contact_Opp_Types__c.split(';'));
			}
			if (rollupSettings.Excluded_Account_Opp_Types__c != null) {
				oppTypesToExcludeAccts = new set<string>(rollupSettings.Excluded_Contact_Opp_Types__c.split(';'));
			}
			if (rollupSettings.Membership_Record_Types__c != null) {
				set<string> mbrRecordTypeNames = new set<string>(rollupSettings.Membership_Record_Types__c.split(';'));
				mbrRecordTypes = RecordTypes.GetRecordTypeIdSet('Opportunity', mbrRecordTypeNames);
			}
			if (rollupSettings.Enable_Opp_Rollup_Triggers__c == false && !isTest)
				triggerRollupEnabled = false;
			if (rollupSettings.Always_Rollup_to_Primary_Contact__c == true)
				alwaysRollupToPrimaryContact = true;
		}
		/*
		if (isTest) {
			oppTypesToExcludeCons.add('In Kind');
			mbrRecordTypes.add(RecordTypes.GetRecordTypeId('Opportunity', 'Membership'));
		}
		*/
	}			

	public void rollupAccount( id aid ) {
	// roll up a single account's opps
		
		map<id, account> amap = new map<id, account>(
			[select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastNDays__c, 
				npo02__TotalMembershipOppAmount__c, npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c  
				from account where id = : aid AND npo02__NumberOfClosedOpps__c < 3000]);
		
		if (!amap.isEmpty()) 
			rollupAccounts( amap );
	}

	@future
	public static void rollupAccountsFuture( set<id> acctIds ) {
	// roll up a single account's opps
		
		if (acctIds != null && !acctIds.isEmpty()) { 
			map<id, account> amap = new map<id, account>(
				[select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastNDays__c, 
					npo02__TotalMembershipOppAmount__c, npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c  
					from account where id in :acctIds AND npo02__NumberOfClosedOpps__c < 3000 ]);
			
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupAccounts( amap );
		}
	}

	public void rollupAccounts( list<account> accts ) {
	// roll up opps for a set of accounts

		if (accts != null && !accts.isEmpty()) {
			rollupAccounts( new map<id, account>(accts) );
		}
	}

	public void rollupAccounts( map<id, account> amap ) {
	// roll up opps for a map of accounts
	// only accounts that have changed will get updated 

		// copy the accounts to a map of zerod out versions
		map<id, account> accountsToUpdate = new map<id, account>();
		set<id> allAccts = amap.keyset();
		for (id aid : allAccts) {
		 	accountsToUpdate.put(aid, new Account(id = aid, npo02__TotalOppAmount__c = 0, npo02__AverageAmount__c = 0, 
				npo02__SmallestAmount__c = 0, npo02__LargestAmount__c = 0, npo02__FirstCloseDate__c = null,
				npo02__LastCloseDate__c = null, npo02__NumberOfClosedOpps__c = 0, npo02__OppAmountThisYear__c = 0, 
				npo02__OppsClosedThisYear__c = 0, npo02__OppAmountLastYear__c = 0, npo02__OppsClosedLastYear__c = 0,
				npo02__OppsClosed2YearsAgo__c = 0, npo02__OppAmount2YearsAgo__c = 0,
				npo02__OppsClosedLastNDays__c = 0, npo02__OppAmountLastNDays__c = 0, 
//				Membershipnpo02__OppsClosedThisYear__c = 0, Membershipnpo02__OppAmountLastYear__c = 0, Membershipnpo02__OppsClosedLastYear__c = 0,
//				Membershipnpo02__OppsClosed2YearsAgo__c = 0, Membershipnpo02__OppAmount2YearsAgo__c = 0, 
				npo02__TotalMembershipOppAmount__c = 0, npo02__NumberOfMembershipOpps__c = 0, 				
	        	npo02__LastMembershipDate__c = null, npo02__LastMembershipAmount__c = 0, 				
	        	npo02__LastMembershipLevel__c = null, npo02__LastMembershipOrigin__c = null, 				
	        	npo02__MembershipJoinDate__c = null, npo02__MembershipEndDate__c = null,
	        	npo02__LastOppAmount__c = null  				
			));
		}

		// copy all the rollups from each result row into the account objects
		integer startYear = system.today().year() - 2;
		/*
		for (sobject r : 
			[SELECT accountId, Calendar_Year(CloseDate) CalendarYr,
	        	SUM(Amount) TotalOppAmount, AVG(Amount) AverageAmount, MIN(Amount) SmallestAmount,
				MAX(Amount) LargestAmount, MIN(CloseDate) FirstCloseDate, MAX(CloseDate) LastCloseDate, 
				COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(npo02__CombinedRollupFieldset__c) RollupFieldset 
				FROM Opportunity
	    		WHERE isWon=true 
	    		AND (Amount > 0 OR Amount < 0) 
		    	AND RecordTypeId NOT IN : recordTypesToExcludeAccts
		    	AND Type NOT IN : oppTypesToExcludeAccts
		    	AND accountId IN : allAccts
				GROUP BY ROLLUP (accountId, Calendar_Year(closeDate))
	    		HAVING ( Calendar_Year(closeDate) = null OR Calendar_Year(closeDate) >= : startYear )
	    		AND accountId != null ] ) {
	    			*/
		String soqlStatement = 'SELECT accountId, Calendar_Year(CloseDate) CalendarYr, ';
    	soqlStatement += 'SUM(Amount) TotalOppAmount, AVG(Amount) AverageAmount, MIN(Amount) SmallestAmount, ';
		soqlStatement += 'MAX(Amount) LargestAmount, MIN(CloseDate) FirstCloseDate, MAX(CloseDate) LastCloseDate, '; 
		soqlStatement += 'COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(npo02__CombinedRollupFieldset__c) RollupFieldset '; 
		soqlStatement += 'FROM Opportunity ';
		soqlStatement += 'WHERE isWon=true '; 
		soqlStatement += 'AND (Amount > 0 OR Amount < 0) '; 
		if(areRecordTypesOnOpps()){
    		soqlStatement += 'AND RecordTypeId NOT IN : recordTypesToExcludeAccts ';
		}
    	soqlStatement += 'AND Type NOT IN : oppTypesToExcludeAccts ';
    	soqlStatement += 'AND accountId IN : allAccts ';
		soqlStatement += 'GROUP BY ROLLUP (accountId, Calendar_Year(closeDate)) ';
		soqlStatement += 'HAVING ( Calendar_Year(closeDate) = null OR Calendar_Year(closeDate) >= : startYear ) ';
		soqlStatement += 'AND accountId != null';
		
	    for (sobject r : Database.query(soqlStatement)){
	    			
	    			
	    			
			//system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);

			// get the account id for this result row
			id aid = (id)(r.get('accountId'));
	
			// copy all the rollups from this result row into the account object	
			updateRollupFromResult((sobject)(accountsToUpdate.get(aid)), r);
		}

		// also do rollups for last N days
		soqlStatement = 'SELECT accountId, '; 
		soqlStatement += 'SUM(Amount) TotalOppAmount, COUNT_DISTINCT(Id) NumberOfClosedOpps '; 
		soqlStatement += 'FROM Opportunity  '; 
		soqlStatement += 'WHERE isWon=true  '; 
		soqlStatement += 'AND (Amount > 0 OR Amount < 0) '; 
		if(areRecordTypesOnOpps()){ 
			soqlStatement += 'AND RecordTypeId NOT IN : recordTypesToExcludeAccts '; 
		}
		soqlStatement += 'AND Type NOT IN : oppTypesToExcludeAccts '; 
		soqlStatement += 'AND accountId IN : allAccts '; 
		soqlStatement += 'AND closeDate >= LAST_N_DAYS:365 '; 
		soqlStatement += 'GROUP BY accountId '; 
		soqlStatement += 'HAVING accountId != null';
		
		for (sobject r : Database.query(soqlStatement) ) {
			//system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
			
			// get the ids
			id aid = (id)(r.get('accountId'));
				
			// process the result row, copying it into the contact record(s)
			updateRollupFromResultLastNDays((sobject)(accountsToUpdate.get(aid)), r);
		}

		if (!mbrRecordTypes.isEmpty()) {
			// also roll up memberships
			// uncomment if you are doing annual membership totals
			soqlStatement = 'SELECT accountId, ';
					//Calendar_Year(CloseDate) CalendarYr, SUM(Opportunity.Total_Unpaid__c) TotalUnpaid,
		    soqlStatement += 'SUM(Amount) TotalOppAmount, '; 
		        	//SUM(Total_Unpaid__c) TotalUnpaid, MAX(Amount) LargestAmount, 
		        	//AVG(Amount) AverageAmount, MIN(Amount) SmallestAmount,
			soqlStatement += 'MAX(CloseDate) LastCloseDate, ';
			soqlStatement += 'MIN(npe01__membership_start_date__c) FirstStartDate, MAX(npe01__membership_start_date__c) LastEndDate,  ';
			soqlStatement += 'COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(npo02__CombinedRollupFieldset__c) RollupFieldset  ';
			soqlStatement += 'FROM Opportunity ';
		    soqlStatement += 'WHERE isWon=true  ';
		    soqlStatement += 'AND (Amount > 0 OR Amount < 0)  ';
		    if(areRecordTypesOnOpps()){
				soqlStatement += 'AND RecordTypeId IN : mbrRecordTypes ';
		    }
			soqlStatement += 'AND Type NOT IN : oppTypesToExcludeAccts ';
			soqlStatement += 'AND accountId IN : allAccts ';
			soqlStatement += 'GROUP BY ROLLUP (accountId, Calendar_Year(closeDate)) ';
		    soqlStatement += 'HAVING  ';
		    		// ( Calendar_Year(closeDate) = null OR Calendar_Year(closeDate) >= : startYear ) AND
		    soqlStatement += 'accountId != null';
		    		
			for (sobject r : Database.query(soqlStatement) ) {
				//system.debug('ROLLUP ROW: ' + r);
	
				// get the account id for this result row
				id aid = (id)(r.get('accountId'));
		
				// copy all the rollups from this result row into the account object	
				updateRollupFromResultMembership((sobject)(accountsToUpdate.get(aid)), r);
			}
		}

		// remove any records that have not changed
		for (id aid : allAccts) {
			account a1 = amap.get(aid);
			account a2 = accountsToUpdate.get(aid);
			if (a1.npo02__TotalOppAmount__c == a2.npo02__TotalOppAmount__c && 
					a1.npo02__OppAmountThisYear__c == a2.npo02__OppAmountThisYear__c &&
					a1.npo02__OppAmountLastNDays__c == a2.npo02__OppAmountLastNDays__c &&
					a1.npo02__TotalMembershipOppAmount__c == a2.npo02__TotalMembershipOppAmount__c &&
					a1.npo02__LastCloseDate__c == a2.npo02__LastCloseDate__c)
				accountsToUpdate.remove(aid);
		}
		
		// update all the accounts from this batch 
		update accountsToUpdate.values();
	}

	public void rollupContact( id cid ) {
		// roll up opps for one contact
		list<contact> cc = [select id, household__c, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, 
				npo02__OppAmountLastNDays__c, npo02__TotalMembershipOppAmount__c, 
				household__r.npo02__TotalOppAmount__c, household__r.npo02__OppAmountThisYear__c, 
				household__r.npo02__OppAmountLastNDays__c, household__r.npo02__TotalMembershipOppAmount__c,
				household__r.npo02__LastCloseDate__c, household__r.npo02__NumberOfClosedOpps__c,
				npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c	from contact where id = :cid ];
	
		if (!cc.isEmpty()) { 
			map<id, household__c> hhmap = new map<id, household__c>();
			if (cc[0].household__c != null) 
				hhmap.put(cc[0].household__c, cc[0].household__r);
		
			rollupContacts( new map<id, contact>( cc ), hhmap );
		}
	}
	
	public void rollupHousehold( id hhid ) {
		// roll up opps for one household
		list<household__c> hhs = [select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, 
			npo02__OppAmountLastNDays__c, npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c, npo02__TotalMembershipOppAmount__c
			from household__c where id = :hhid ];
		
		if (!hhs.isEmpty()) 
			rollupHouseholds( hhs );
	}	
	
	public void rollupHouseholds( list<household__c> hhs ) {
	// roll up opps for households

		if (hhs != null && !hhs.isEmpty()) {
			
			map<id, household__c> hhmap = new map<id, household__c>( hhs );
		
			// get household contacts
			map<id, contact> cmap = new map<id, contact>([select id, household__c, npo02__LastCloseDate__c, 
				npo02__OppAmountThisYear__c, npo02__NumberOfClosedOpps__c, npo02__TotalOppAmount__c, npo02__TotalMembershipOppAmount__c,
				npo02__OppAmountLastNDays__c from contact where household__c in :hhmap.keyset() ]);
			
			// roll up totals
			rollupContacts( cmap, hhmap );
		}
	}
	
	@future
	public static void rollupHouseholdsFuture( set<id> modifiedContactOpps ) {	
		
		map<id, contact> cmap = new map<id, contact>();
		map<id, household__c> hhmap = new map<id, household__c>();
		
		// use the contact roles to find the contacts and households
			if (!modifiedContactOpps.isEmpty()) {
				
				for (OpportunityContactRole r : 
					[SELECT contactId, contact.household__c,
						contact.npo02__TotalOppAmount__c, contact.npo02__OppAmountThisYear__c, contact.npo02__OppAmountLastNDays__c, 
						contact.npo02__LastCloseDate__c, contact.npo02__NumberOfClosedOpps__c, contact.npo02__TotalMembershipOppAmount__c,
						contact.household__r.npo02__TotalOppAmount__c, contact.household__r.npo02__OppAmountThisYear__c, 
						contact.household__r.npo02__OppAmountLastNDays__c, contact.household__r.npo02__TotalMembershipOppAmount__c, 
						contact.household__r.npo02__LastCloseDate__c, contact.household__r.npo02__NumberOfClosedOpps__c
				    	FROM OpportunityContactRole WHERE Opportunity.Id In : modifiedContactOpps and isPrimary = true ALL ROWS ] ) {		
					
					cmap.put(r.contactId, r.contact);
					if (r.contact.household__c != null) {
						hhmap.put(r.contact.household__c, r.contact.household__r);
					}
				}
					
			}
			
			// roll up totals
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContacts( cmap, hhmap );

	}

	public void rollupContacts( map<id, contact> cmap, map<id, household__c> hhmap ) {
	// roll up opps for a list of contacts and their households

		set<id> conIds = cmap.keySet();
		set<id> hhIds = hhmap.keySet();

		// copy the contacts and households to a map of zerod out versions
		map<id, contact> contactsToUpdate = new map<id, contact>();
		map<id, household__c> householdsToUpdate = new map<id, household__c>();
		for (id cid : conIds) {
		 	contactsToUpdate.put(cid, new Contact(id = cid, npo02__TotalOppAmount__c = 0, npo02__AverageAmount__c = 0, 
				npo02__SmallestAmount__c = 0, npo02__LargestAmount__c = 0, npo02__FirstCloseDate__c = null, 
				npo02__LastCloseDate__c = null, npo02__NumberOfClosedOpps__c = 0, npo02__OppAmountThisYear__c = 0, 
				npo02__OppsClosedThisYear__c = 0, npo02__OppAmountLastYear__c = 0, npo02__OppsClosedLastYear__c = 0,
				npo02__OppsClosed2YearsAgo__c = 0, npo02__OppAmount2YearsAgo__c = 0, 
				npo02__OppsClosedLastNDays__c = 0, npo02__OppAmountLastNDays__c = 0,
//				Membershipnpo02__OppsClosedThisYear__c = 0, Membershipnpo02__OppAmountLastYear__c = 0, Membershipnpo02__OppsClosedLastYear__c = 0,
//				Membershipnpo02__OppsClosed2YearsAgo__c = 0, Membershipnpo02__OppAmount2YearsAgo__c = 0, 
				npo02__TotalMembershipOppAmount__c = 0, npo02__NumberOfMembershipOpps__c = 0, 				
	        	npo02__LastMembershipDate__c = null, npo02__LastMembershipAmount__c = 0, 				
	        	npo02__LastMembershipLevel__c = null, npo02__LastMembershipOrigin__c = null, 				
	        	npo02__MembershipJoinDate__c = null, npo02__MembershipEndDate__c = null, 				
				npo02__LastOppAmount__c = null
			));
		}
		for (id hhid : hhIds) {
		 	householdsToUpdate.put(hhid, new household__c(id = hhid, npo02__TotalOppAmount__c = 0, npo02__AverageAmount__c = 0, 
				npo02__SmallestAmount__c = 0, npo02__LargestAmount__c = 0, npo02__FirstCloseDate__c = null, 
				npo02__LastCloseDate__c = null, npo02__NumberOfClosedOpps__c = 0, npo02__OppAmountThisYear__c = 0,
				npo02__OppsClosedThisYear__c = 0, npo02__OppAmountLastYear__c = 0, npo02__OppsClosedLastYear__c = 0,
				npo02__OppsClosed2YearsAgo__c = 0, npo02__OppAmount2YearsAgo__c = 0, 
				npo02__OppsClosedLastNDays__c = 0, npo02__OppAmountLastNDays__c = 0,
//				Membershipnpo02__OppsClosedThisYear__c = 0, Membershipnpo02__OppAmountLastYear__c = 0, Membershipnpo02__OppsClosedLastYear__c = 0,
//				Membershipnpo02__OppsClosed2YearsAgo__c = 0, Membershipnpo02__OppAmount2YearsAgo__c = 0, 
				npo02__TotalMembershipOppAmount__c = 0, npo02__NumberOfMembershipOpps__c = 0, 				
	        	npo02__LastMembershipDate__c = null, npo02__LastMembershipAmount__c = 0, 				
	        	npo02__LastMembershipLevel__c = null, npo02__LastMembershipOrigin__c = null, 				
	        	npo02__MembershipJoinDate__c = null, npo02__MembershipEndDate__c = null, 				
				npo02__LastOppAmount__c = null
			));
		}

		// copy all the rollups from each result row into the contact objects
		integer startYear = system.today().year() - 2; 
		
		if (alwaysRollupToPrimaryContact) {
			String soqlStatement = 'SELECT contact.household__c hhid, contactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';
			soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
			soqlStatement += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
			soqlStatement += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
			soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
			soqlStatement += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
			soqlStatement += 'FROM OpportunityContactRole  ';
			soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
			soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
			if(areRecordTypesOnOpps()){
				soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
			}
			soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons  ';
			soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
			soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Calendar_Year(opportunity.closeDate)) ';
			soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null)';
	    	
			for (sobject r : Database.query(soqlStatement) ) {
				
				// system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
	
				// get the ids
				id cid = (id)(r.get('contactId'));
				id hhid = (id)(r.get('hhid'));
					
				// process the result row, copying it into the contact record(s)
				// MS: we only want to fully calc the row if it is from the last few years - older years are only for calcing Best Year for contacts
				integer yr = (integer)r.get('CalendarYr');
				if (cid == null) { 
					if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r);
					// after doing regular processing, calc Best Contact Year stuff
					// the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
					decimal yrAmt = (decimal)r.get('TotalOppAmount');
					household__c HH = householdsToUpdate.get(hhid);
	
				} else {
					// contact row
					if ( yr >= startYear || yr==null) {
						updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r);
					}
					// after doing regular processing, calc Best Contact Year stuff
					// the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
					decimal yrAmt = (decimal)r.get('TotalOppAmount');
					Contact con = contactsToUpdate.get(cid);
				}
			}
				
			// also do rollups for last N days
			soqlStatement = 'SELECT contact.household__c hhid, contactId, ';
			soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps ';
			soqlStatement += 'FROM OpportunityContactRole  ';
			soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true  ';
			soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0)  ';
			if(areRecordTypesOnOpps()){
				soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
			}
			soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
			soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
			soqlStatement += 'AND opportunity.closeDate >= LAST_N_DAYS:365 ';
			soqlStatement += 'GROUP BY ROLLUP(contact.household__c, contactId) ';
			soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null)  ';
			
			for (sobject r : Database.query(soqlStatement)) {
	
				//system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
				
				// get the ids
				id cid = (id)(r.get('contactId'));
				id hhid = (id)(r.get('hhid'));
					
				// process the result row, copying it into the contact record(s)
				if (cid == null) { 
					if (hhid != null)
						updateRollupFromResultLastNDays((sobject)(householdsToUpdate.get(hhid)), r);
				} else {
					// contact row	
					updateRollupFromResultLastNDays((sobject)(contactsToUpdate.get(cid)), r);
				}
			}
	
			if (!mbrRecordTypes.isEmpty()) {
				// also do rollups for membership
				// if you need annual rollups for membership, uncomment the commented bits
				soqlStatement = 'SELECT contact.household__c hhid, contactId, ';
				soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
				soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate,  ';
				soqlStatement += 'MIN(Opportunity.npe01__membership_start_date__c) FirstStartDate, '; 
				soqlStatement += 'MAX(Opportunity.npe01__Membership_End_Date__c) LastEndDate,  ';
				soqlStatement += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
				soqlStatement += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
				soqlStatement += 'FROM OpportunityContactRole  ';
				soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
				soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
				if(areRecordTypesOnOpps()){
					soqlStatement += 'AND Opportunity.RecordTypeId IN : mbrRecordTypes ';
				}
				soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
				soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			    soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
				soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId) ';
				soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) '; 
				
				for (sobject r : Database.query(soqlStatement)) {
		    				
					// get the ids
					id cid = (id)(r.get('contactId'));
					id hhid = (id)(r.get('hhid'));
						
					// process the result row, copying it into the contact record(s)
					if (cid == null) { 
						if (hhid != null)
							updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r);
					} else {
						// contact row	
						updateRollupFromResultMembership((sobject)(contactsToUpdate.get(cid)), r);
					}
		    	}
			}
		} else {
			String soqlStatement = 'SELECT contact.household__c hhid, contactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';
			soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
			soqlStatement += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
 			soqlStatement += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
			soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
			soqlStatement += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
			soqlStatement += 'FROM OpportunityContactRole  ';
			soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
			soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
			if(areRecordTypesOnOpps()){
				soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
			}
			soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
			soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.npe01__SYSTEMIsIndividual__c = true) ';   
			soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
			soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Calendar_Year(opportunity.closeDate)) ';
			soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
			
			for (sobject r : Database.query(soqlStatement)) {
				
				// system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
	
				// get the ids
				id cid = (id)(r.get('contactId'));
				id hhid = (id)(r.get('hhid'));
					
				// process the result row, copying it into the contact record(s)
				// MS: we only want to fully calc the row if it is from the last few years - older years are only for calcing Best Year for contacts
				integer yr = (integer)r.get('CalendarYr');
				if (cid == null) { 
					if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r);
					// after doing regular processing, calc Best Contact Year stuff
					// the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
					decimal yrAmt = (decimal)r.get('TotalOppAmount');
					household__c HH = householdsToUpdate.get(hhid);
	
				} else {
					// contact row
					if ( yr >= startYear || yr==null) {
						updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r);
					}
					// after doing regular processing, calc Best Contact Year stuff
					// the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
					decimal yrAmt = (decimal)r.get('TotalOppAmount');
					Contact con = contactsToUpdate.get(cid);
				}
			}
				
			// also do rollups for last N days
			soqlStatement = 'SELECT contact.household__c hhid, contactId, ';
			soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps ';
			soqlStatement += 'FROM OpportunityContactRole  ';
			soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true  ';
			soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
			if(areRecordTypesOnOpps()){
				soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
			}
			soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
			soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.npe01__SYSTEMIsIndividual__c = true) ';   
			soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
			soqlStatement += 'AND opportunity.closeDate >= LAST_N_DAYS:365 ';
			soqlStatement += 'GROUP BY ROLLUP(contact.household__c, contactId) ';
			soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
			
			for (sobject r : Database.query(soqlStatement)) {
	
				//system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
				
				// get the ids
				id cid = (id)(r.get('contactId'));
				id hhid = (id)(r.get('hhid'));
					
				// process the result row, copying it into the contact record(s)
				if (cid == null) { 
					if (hhid != null)
						updateRollupFromResultLastNDays((sobject)(householdsToUpdate.get(hhid)), r);
				} else {
					// contact row	
					updateRollupFromResultLastNDays((sobject)(contactsToUpdate.get(cid)), r);
				}
			}
	
			if (!mbrRecordTypes.isEmpty()) {
				// also do rollups for membership
				// if you need annual rollups for membership, uncomment the commented bits
				soqlStatement = 'SELECT contact.household__c hhid, contactId, ';
				soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
				soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate,  ';
				soqlStatement += 'MIN(Opportunity.npe01__membership_start_date__c) FirstStartDate, '; 
				soqlStatement += 'MAX(Opportunity.npe01__Membership_End_Date__c) LastEndDate,  ';
				soqlStatement += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
				soqlStatement += 'MAX(Opportunity.npo02__CombinedRollupFieldset__c) RollupFieldset ';
				soqlStatement += 'FROM OpportunityContactRole  ';
				soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
				soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
				if(areRecordTypesOnOpps()){
					soqlStatement += 'AND Opportunity.RecordTypeId IN : mbrRecordTypes ';
				}
				soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
				soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.npe01__SYSTEMIsIndividual__c = true)  '; 
			    soqlStatement += 'AND (contact.household__c IN : hhIds OR  ';
			    soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
				soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId) ';
				soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
				
				for (sobject r : Database.query(soqlStatement)) {
		    				
					// get the ids
					id cid = (id)(r.get('contactId'));
					id hhid = (id)(r.get('hhid'));
						
					// process the result row, copying it into the contact record(s)
					if (cid == null) { 
						if (hhid != null)
							updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r);
					} else {
						// contact row	
						updateRollupFromResultMembership((sobject)(contactsToUpdate.get(cid)), r);
					}
		    	}
			}
		}

		// remove any records that have not changed
		for (id cid : conIds) {
			contact c1 = cmap.get(cid);
			contact c2 = contactsToUpdate.get(cid);
			if (c1.npo02__TotalOppAmount__c == c2.npo02__TotalOppAmount__c && 
					c1.npo02__OppAmountLastNDays__c == c2.npo02__OppAmountLastNDays__c &&
					c1.npo02__OppAmountThisYear__c == c2.npo02__OppAmountThisYear__c &&
					c1.npo02__TotalMembershipOppAmount__c == c2.npo02__TotalMembershipOppAmount__c &&
					c1.npo02__LastCloseDate__c == c2.npo02__LastCloseDate__c)
				contactsToUpdate.remove(cid);
		}
		for (id hhid : hhIds) {
			household__c hh1 = hhmap.get(hhid); 
			household__c hh2 = householdsToUpdate.get(hhid);
			if (hh1.npo02__TotalOppAmount__c == hh2.npo02__TotalOppAmount__c && 
					hh1.npo02__OppAmountLastNDays__c == hh2.npo02__OppAmountLastNDays__c &&
					hh1.npo02__OppAmountThisYear__c == hh2.npo02__OppAmountThisYear__c &&
					hh1.npo02__TotalMembershipOppAmount__c == hh2.npo02__TotalMembershipOppAmount__c &&
					hh1.npo02__LastCloseDate__c == hh2.npo02__LastCloseDate__c)
				householdsToUpdate.remove(hhid);
		}

		// update all the contacts from this batch 
		if (!contactsToUpdate.isEmpty()) update contactsToUpdate.values();				
		if (!householdsToUpdate.isEmpty()) update householdsToUpdate.values();				
	}
	
	public void rollupForOppTrigger( map<id, opportunity> newOpps, map<id, opportunity> oldOpps ) {
	// find contacts and accounts affected and then roll them up

		if (triggerRollupEnabled) {
			
			set<id> modifiedContactOpps = new set<id>();
			set<id> acctsToReroll = new set<id>(); 
			
			boolean includedRecordType = false;
			Boolean recordTypeChanged = false;
			if (newOpps == null) {
	
				// it is a delete
				for (id oid : oldOpps.keySet()) {
					opportunity o = oldOpps.get(oid);
					
					
					if (o.isWon && (o.Amount > 0 || o.Amount < 0)) {
						includedRecordType = false;
						if (areRecordTypesOnOpps()){
							includedRecordType = mbrRecordTypes.contains((id)o.get('recordTypeId')) ||
								!recordTypesToExcludeCons.contains((id)o.get('recordTypeId'));
						} else {
							includedRecordType = true;
						}
						if ((o.npe01__Is_Opp_From_Individual__c == 'true' || o.accountid == null) &&
							includedRecordType &&
							(!oppTypesToExcludeCons.contains(o.type))) {
						
							modifiedContactOpps.add(o.id);
						}
						if (areRecordTypesOnOpps()){
							includedRecordType = false;
							includedRecordType = mbrRecordTypes.contains((id)o.get('recordTypeId')) ||
								!recordTypesToExcludeAccts.contains((id)o.get('recordTypeId'));
						} else {
							includedRecordType = true;
						}
						if (o.accountId != null && includedRecordType && (!oppTypesToExcludeAccts.contains(o.type))) {								
							acctsToReroll.add(o.accountId);
						}
					}
				}
			} else if (oldOpps == null) {
				// for insert, find the closed opps that qualify
				for (id oid : (newOpps.keySet())) {
					opportunity o = newOpps.get(oid);
					
					if (o.isWon && (o.Amount > 0 || o.Amount < 0)) {
						if (areRecordTypesOnOpps()){
							includedRecordType = false;
							includedRecordType = !mbrRecordTypes.contains((id)o.get('recordTypeId')) ||
								!recordTypesToExcludeCons.contains((id)o.get('recordTypeId'));
						} else {
							includedRecordType = true;
						}
						if ((o.npe01__Is_Opp_From_Individual__c == 'true' || o.accountid == null) && includedRecordType
							 && (!oppTypesToExcludeCons.contains(o.type))) {
						 
							modifiedContactOpps.add(o.id);
						}
						if (areRecordTypesOnOpps()){
							includedRecordType = false;
							includedRecordType = !mbrRecordTypes.contains((id)o.get('recordTypeId')) ||
								!recordTypesToExcludeAccts.contains((id)o.get('recordTypeId'));
						} else {
							includedRecordType = true;
						}
						if (o.accountId != null && includedRecordType && (!oppTypesToExcludeAccts.contains(o.type))) {

							acctsToReroll.add(o.accountId);
						}
					}
				}
				
			} else {
				system.debug('In the Update block');
				// for update, find the opps that are changed in any important way
				for (id oid : (newOpps.keySet())) {
					
					// compare old and new
					opportunity o = newOpps.get(oid);
					opportunity oldOpp = oldOpps.get(oid);
					
					
					if (areRecordTypesOnOpps()){
						recordTypeChanged = false;
						recordTypeChanged = ((id)o.get('recordTypeId') != (id)oldOpp.get('recordTypeId'));
					}
					// look for opps that have changed in any important way
					if (o.isWon != oldOpp.isWon || (o.isWon && 
						((o.Amount != oldOpp.Amount) ||
						recordTypeChanged || 
						(o.type != oldOpp.type) ||
						(o.closeDate != oldOpp.closeDate) ||
						(o.accountId != oldOpp.accountId)))) { 
						system.debug('Passed Opp Change Check');
						if (o.npe01__Is_Opp_From_Individual__c == 'true' || o.accountid == null) {
							modifiedContactOpps.add(o.id);
//							system.debug('Added to Cons to Update List' + o);
						}
						if (o.accountId != null) {
							acctsToReroll.add(o.accountId); 
						}
					}		
				}			
			}	
			
//			system.debug('Modified Contact Opps' + modifiedContactOpps);
			
			// use the contact roles to find the contacts and households
			if (!modifiedContactOpps.isEmpty()) {

				if ((Limits.getLimitFutureCalls() - Limits.getFutureCalls()) > 5) {
//					system.debug('Passed limit check for con rollup update');
					rollupHouseholdsFuture(modifiedContactOpps);
					
				} else {
					system.debug(Logginglevel.WARN, Label.Opportunity_Rollup_Future_Call_Limit);
				}
			}

			// roll them up
			if (!acctsToReroll.isEmpty()) {
				
				boolean rollupNow = false;
				map<id, account> amap;
				if (acctsToReroll.size() == 1) {
					amap = new map<id, account>(
						[select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastNDays__c, 
						npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c, npo02__TotalMembershipOppAmount__c 
						from account where id in :acctsToReroll ]);
					decimal oppCount = amap.values()[0].npo02__NumberOfClosedOpps__c;
					//rollupNow = (oppCount == null || oppCount < 200);
				}
						
				// for a single account with fewer than 200 opps, roll up immediately - otherwise future
				if (rollupNow)
					rollupAccounts( amap );
				else if ((Limits.getLimitFutureCalls() - Limits.getFutureCalls()) > 5)
					rollupAccountsFuture( acctsToReroll );
				else
					system.debug(Logginglevel.WARN, Label.Opportunity_Rollup_Future_Call_Limit);				
			}
		}	
	}

	public void rollupAll() {
		rollupAllAccounts();
		rollupAllContacts();
	}	

	public void rollupAllAccounts() {

		// we can handle up to 10000 query rows total, which is about 3000 opps in a batch
		// this calculation very conservatively reduces batch size to avoid hitting the limit
		integer batchSize = 200;
		list<account> topAccount = [select npo02__NumberOfClosedOpps__c from account 
			where npo02__NumberOfClosedOpps__c != null 
			order by npo02__NumberOfClosedOpps__c desc limit 1];
		if (!topAccount.isEmpty()) {
			decimal highestCount = topAccount[0].npo02__NumberOfClosedOpps__c;
			if (highestCount > 15) {
				batchSize = (3000 / highestCount).intValue() + 1;
			}
		}

		// start the batch to roll up all accounts
		BATCH_OppRollup batch = new BATCH_OppRollup( 'SELECT id, npo02__TotalOppAmount__c, ' +
			'npo02__OppAmountThisYear__c, npo02__TotalMembershipOppAmount__c, ' +
			'npo02__OppAmountLastNDays__c, npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c FROM account' + 
			(isTest ? ' WHERE name like \'%test%\' LIMIT 200' : '') );
		id batchProcessId = database.executeBatch(batch, batchSize);		
	}	
		
	public void rollupAllContacts() {

		// we can handle up to 10000 query rows total, which is about 3000 opps in a batch
		// this calculation very conservatively reduces batch size to avoid hitting the limit
		integer batchSize = 200;
		list<household__c> topHousehold = [select npo02__NumberOfClosedOpps__c from household__c 
			where npo02__NumberOfClosedOpps__c != null 
			order by npo02__NumberOfClosedOpps__c desc limit 1];
		if (!topHousehold.isEmpty()) {
			decimal highestCount = topHousehold[0].npo02__NumberOfClosedOpps__c;
			if (highestCount > 15) {
				batchSize = (3000 / highestCount).intValue() + 1;
			}
		}

		BATCH_OppRollup batch = new BATCH_OppRollup( 'SELECT id, npo02__TotalOppAmount__c, ' +
			'npo02__OppAmountThisYear__c, npo02__TotalMembershipOppAmount__c, ' +
			'npo02__OppAmountLastNDays__c, npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c FROM household__c' + 
			(isTest ? ' WHERE lastname like \'%doppleganger%\' LIMIT 200' : '') );
		id batchProcessId = database.executeBatch(batch, batchSize);		
	}

	public static void updateRollupFromResult(sobject obj, sobject r) {
	// used for single and batch rollups, this maps query results to the right fields

		// get the fiscal year, total amount, and opp count for this result row		
		integer fy = (integer)(r.get('CalendarYr'));
		decimal amt = (decimal)(r.get('TotalOppAmount'));
		integer cnt = (integer)(r.get('NumberOfClosedOpps'));				
		
		// split the special field to get the last opp id and amount
		string[] rcf = ((string)(r.get('RollupFieldset'))).split(';\\|;',-4);
		decimal lastAmt = (rcf.size() > 0 && rcf[1] != null) ? decimal.valueOf(rcf[1]) : null;
		
		// check if this is an annual total or account total
		if (fy != null) {

			// put the fiscal year total in the right fields
			integer thisYear = system.today().year();
			if (fy == thisYear) {
				obj.put('npo02__OppAmountThisYear__c', amt); 
				obj.put('npo02__OppsClosedThisYear__c', cnt); 
			} else if (fy == (thisYear - 1)) {
				obj.put('npo02__OppAmountLastYear__c', amt); 
				obj.put('npo02__OppsClosedLastYear__c', cnt); 
			} else if (fy == (thisYear - 2) ) {
				obj.put('npo02__OppAmount2YearsAgo__c', amt); 
				obj.put('npo02__OppsClosed2YearsAgo__c', cnt); 
			} 
				
		} else {

			// fill in summary totals
			obj.put('npo02__TotalOppAmount__c', amt);
	        obj.put('npo02__NumberOfClosedOpps__c', cnt); 				
	        obj.put('npo02__LastOppAmount__c', lastAmt); 				
	        obj.put('npo02__AverageAmount__c', (decimal)(r.get('AverageAmount'))); 
	        obj.put('npo02__SmallestAmount__c', (decimal)(r.get('SmallestAmount'))); 
	        obj.put('npo02__LargestAmount__c', (decimal)(r.get('LargestAmount'))); 
	        obj.put('npo02__FirstCloseDate__c', (date)(r.get('FirstCloseDate'))); 
	        obj.put('npo02__LastCloseDate__c', (date)(r.get('LastCloseDate'))); 
		}
	}

	public static void updateRollupFromResultLastNDays(sobject obj, sobject r) {
	// used for single and batch rollups, this maps query results to the right fields
		
		// get the fiscal year, total amount, and opp count for this result row		
		decimal amt = (decimal)(r.get('TotalOppAmount'));
		integer cnt = (integer)(r.get('NumberOfClosedOpps'));				
		
		// fill in totals
        obj.put('npo02__OppAmountLastNDays__c', amt); 				
		obj.put('npo02__OppsClosedLastNDays__c', cnt);
	}

	public static void updateRollupFromResultMembership(sobject obj, sobject r) {
	// used for single and batch rollups, this maps query results to the right fields
		
		// get the fiscal year, total amount, and opp count for this result row		
		//integer fy = (integer)(r.get('CalendarYr'));
		decimal amt = (decimal)(r.get('TotalOppAmount'));
		integer cnt = (integer)(r.get('NumberOfClosedOpps'));				

		// split the special field to get the last opp id and amount
		string[] rcf = ((string)(r.get('RollupFieldset'))).split(';\\|;',-4);
		decimal lastAmt = (rcf.size() > 1 && rcf[1] != null) ? decimal.valueOf(rcf[1]) : null;
		string lastMemberLevel = (rcf.size() > 2) ? rcf[2] : null;
		string lastMemberOrigin = (rcf.size() > 3) ? rcf[3] : null;
		
		// check if this is an annual total or account total
/* ADD FIELDS AND UNCOMMENT IF YOU NEED ANNUAL MEMBERSHIP TOTAL BREAKOUT
		if (fy != null) {

			// put the fiscal year total in the right fields
			integer thisYear = system.today().year();
			
			if (fy == thisYear) {
				obj.put('Membershipnpo02__OppAmountThisYear__c', amt); 
				obj.put('MembershipOppsThisYear__c', cnt); 
			} else if (fy == (thisYear - 1)) {
				obj.put('Membershipnpo02__OppAmountLastYear__c', amt); 
				obj.put('MembershipOppsLastYear__c', cnt); 
			} else if (fy == (thisYear - 2) ) {
				obj.put('Membershipnpo02__OppAmount2YearsAgo__c', amt); 
				obj.put('MembershipOpps2YearsAgo__c', cnt); 
			} 
		} else {
*/				
			// fill in summary totals
			obj.put('npo02__TotalMembershipOppAmount__c', amt);
	        obj.put('npo02__NumberOfMembershipOpps__c', cnt); 				
	        obj.put('npo02__LastMembershipDate__c', (date)(r.get('LastCloseDate'))); 				
	        obj.put('npo02__LastMembershipAmount__c', lastAmt); 				
	        obj.put('npo02__LastMembershipLevel__c', lastMemberLevel); 				
	        obj.put('npo02__LastMembershipOrigin__c', lastMemberOrigin); 				
	        obj.put('npo02__MembershipJoinDate__c', (date)(r.get('FirstStartDate'))); 
	        obj.put('npo02__MembershipEndDate__c', (date)(r.get('LastEndDate'))); 				
//		}
	}

	/************ TESTS ***************/
	
	static testMethod void testGivingRollup () {
		isTest = true;
		
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		//if(giftRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
	
			// insert the opp(s)
			Test.StartTest();
			insert newOpps;
			Test.StopTest();
			
			//now test that a contact has received the proper member stats from the trigger
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
	
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			//also exercise the non-future methods to make sure the code runs
			Household__c[] hhs = [SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Household__c WHERE id = :UpdatedCon.Household__r.id LIMIT 1];
			rg = new OpportunityRollups();
			rg.rollupHousehold(hhs[0].id);
			rg = new OpportunityRollups();
			rg.rollupHouseholds(hhs);
	
			//make sure the values are still right
			UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
		//}
	}
	
	static testMethod void testGivingRollupIndividual () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = null,
					Membership_Record_Types__c = null
				));
	        
	        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
	        	npe01__Account_Processor__c = npe01.Constants.BUCKET_PROCESSOR,
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
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
	
			// insert the opp(s)
			Test.StartTest();
			insert newOpps;
			Test.StopTest();
			
			//now test that a contact has received the proper member stats from the trigger
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
	
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			//also exercise the non-future methods to make sure the code runs
			Household__c[] hhs = [SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Household__c WHERE id = :UpdatedCon.Household__r.id LIMIT 1];
			rg = new OpportunityRollups();
			rg.rollupHousehold(hhs[0].id);
			rg = new OpportunityRollups();
			rg.rollupHouseholds(hhs);
	
			//make sure the values are still right
			UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
		
	}
	
	static testMethod void testGivingRollupExcludedRT () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		if(giftRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = giftRecordTypeNameForTests,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = giftRecordTypeNameForTests,
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
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
	
			// insert the opp(s)
			Test.StartTest();
			insert newOpps;
			Test.StopTest();
			
			//now test that a contact has received the proper member stats from the trigger
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 0 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 0 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountThisYear__c);
	
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			//also exercise the non-future methods to make sure the code runs
			Household__c[] hhs = [SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Household__c WHERE id = :UpdatedCon.Household__r.id LIMIT 1];
			rg = new OpportunityRollups();
			rg.rollupHousehold(hhs[0].id);
			rg = new OpportunityRollups();
			rg.rollupHouseholds(hhs);
	
			//make sure the values are still right
			UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 0 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 0 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
		}
	}
	
	
	static testMethod void testGivingRollupAlwaysPrimary () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
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
			// create account
			account testacct = new account(name='testacct');
			insert testacct;
			// create & insert contact(s)
			Contact[] TestCons = new contact[]{ new contact(
				FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
	            LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
	            npe01__Private__c=false,
	            AccountId = testacct.id,
	            npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
	            npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
	            npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
	            npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
			) };
			insert TestCons;
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
	
			// insert the opp(s)
			Test.StartTest();
			insert newOpps;
			Test.StopTest();
			
			//now test that a contact has received the proper member stats from the trigger
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
	
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			//also exercise the non-future methods to make sure the code runs
			Household__c[] hhs = [SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Household__c WHERE id = :UpdatedCon.Household__r.id LIMIT 1];
			rg = new OpportunityRollups();
			rg.rollupHousehold(hhs[0].id);
			rg = new OpportunityRollups();
			rg.rollupHouseholds(hhs);
	
			//make sure the values are still right
			UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, household__c, household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
	
			System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.household__r.npo02__TotalOppAmount__c );		
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
		
	}
	
	static testMethod void testMemberRollup () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
		if(membershipRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = null,
					Membership_Record_Types__c = membershipRecordTypeNameForTests
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
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList (
				TestCons,
				null,
				UnitTestData.getClosedWonStage(),
				datClose,
				100,
				householdSettingsForTests.Membership_Record_Types__c,
				null
			);
	
			system.debug(newOpps);
			
			// insert the opp(s)
			Test.StartTest();
			newOpps[0].npe01__Membership_Origin__c = 'Renewal';
			insert newOpps;
			Test.StopTest();
			
			//now test that a contact has received the proper member stats from the trigger
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT id, npo02__TotalMembershipOppAmount__c,npo02__LastMembershipOrigin__c,
				npo02__LastMembershipAmount__c, npo02__LastMembershipDate__c 
				from contact where id =: firstconid];
			System.AssertEquals ( 100 , updatedcon.npo02__TotalMembershipOppAmount__c );		
			System.AssertEquals ( 100 , updatedcon.npo02__LastMembershipAmount__c );		
			System.AssertEquals ( 'Renewal' , updatedcon.npo02__LastMembershipOrigin__c );		
			System.AssertEquals ( system.today() , updatedcon.npo02__LastMembershipDate__c );	
		}	
	}
	
	static testMethod void testGivingRollupAcct () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');

			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
	
			// create account
			account testacct = new account(name='testacct');
			insert testacct;
			opportunity newOpp =
				 new opportunity (
				 	name = 'testopp',
				 	accountid = testacct.id, 
				 	stagename=UnitTestData.getClosedWonStage(),
				 	closedate=datClose, amount=33333
				 );
			if(areRecordTypesOnOpps()){
				newOpp.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
			}
			// insert the opp(s)
			Test.StartTest();
			insert newOpp;
			Test.StopTest();
			
			// test whether the trigger worked		
			account updatedAcct = [select id, npo02__TotalOppAmount__c from account where id =: testacct.id];		
			System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );		
	
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupAccount(testacct.id);
	
			updatedAcct = [select id, npo02__TotalOppAmount__c from account where id =: testacct.id];
			System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );			
		
	}	

	static testMethod void testGivingRollupAcctMembership () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
		if(membershipRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = true,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = null,
					Membership_Record_Types__c = membershipRecordTypeNameForTests
				));
				
			npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
	        	npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
	        	npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
	        	npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
	        ));
	        
			Date datClose = System.Today();
	
			// create account
			account testacct = new account(name='testacct');
			insert testacct;
			opportunity newOpp =
				 new opportunity (name = 'testopp', accountid = testacct.id, 
				 					npe01__member_level__c = 'Gold', npe01__membership_origin__c = 'New',
				 					stagename=UnitTestData.getClosedWonStage(), closedate=datClose, amount=33333);
			newOpp.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', householdSettingsForTests.Membership_Record_Types__c));
			// insert the opp(s)
			Test.StartTest();
			insert newOpp;
			Test.StopTest();
			// test whether the trigger worked		
			account updatedAcct = [select id, npo02__TotalMembershipOppAmount__c, npo02__LastMembershipDate__c,
				npo02__LastMembershipAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c
				from account where id =: testacct.id];		
			System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );		
			System.AssertEquals ( system.today() , updatedAcct.npo02__LastMembershipDate__c );		
			System.AssertEquals ( 33333 , updatedAcct.npo02__LastMembershipAmount__c );		
			System.AssertEquals ( 'Gold' , updatedAcct.npo02__LastMembershipLevel__c );		
			System.AssertEquals ( 'New' , updatedAcct.npo02__LastMembershipOrigin__c );
			
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupAccount(testacct.id);
	
			updatedAcct = [select id, npo02__TotalMembershipOppAmount__c from account where id =: testacct.id];
			System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );		
		}
	}	

	static testMethod void testGivingRollupBatch () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
			Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 50 ) ;
			insert TestCons;
	
			// create new opps
			Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
	
			account testacct = new account(name='testacct');
			insert testacct;
	
			// test the batch rollup method
			Test.StartTest();
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupAll();
			Test.StopTest();
		
	}	

	static testMethod void OneContactMultipleOpps() {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
		if(membershipRecordTypeNameForTests!=''){
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = null,
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = null,
					Membership_Record_Types__c = membershipRecordTypeNameForTests
				));
				
			npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
	        	npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
	        	npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
	        	npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
	        ));
	        	
			integer howMany = 1;
			Date datToday = System.Today();
			Date dat1YearAgo = Date.newInstance( datToday.year()-1,1,1);
			Date dat2YearAgo = Date.newInstance( datToday.year()-2,1,1);
			Date dat4YearAgo = Date.newInstance( datToday.year()-4,1,1);
				
			// create & insert contact(s)
			Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
			insert TestCons;
			
			test.starttest();
			system.debug ( 'TEST>>>>> inserting gift 1...');
			
			// create a new gift for this yr
			Opportunity[] testGift1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 100 , householdSettingsForTests.Membership_Record_Types__c,null);
			insert testGift1 ;
	
			system.debug ( 'TEST>>>>> inserting gift 2...');
			
			//create a 2nd gift for last yr
			Opportunity[] testGift2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat1YearAgo, 60, householdSettingsForTests.Membership_Record_Types__c,null);
	
			insert testGift2;
			
			test.stopTest();
			
			//now test that the contact has received the proper stats from the trigger
			id ThisConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 160 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );
			System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
	
			system.debug ( 'TEST>>>>> changing gift 1...');
			
			// now chg the amts for both opps (cheapskate!)
			testGift1[0].Amount = 50;
			update TestGift1;
	
			system.debug ( 'TEST>>>>> changing gift 2...');
			
			testGift2[0].Amount=25;
			update TestGift2;
			
			// now roll up manually
			OpportunityRollups rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
	
			ThisConId = TestCons[0].id;
			UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c  FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 75 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			
			system.debug ( 'TEST>>>>> inserting gift 3...');
	
			// now create a gift from 2 yrs ago
			Opportunity[] testGift3 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat2YearAgo, 10 , giftRecordTypeNameForTests,null);
	
			insert testGift3;
			
			// now roll up manually
			rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
	
			ThisConId = TestCons[0].id;
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 85 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
	
			// add another from this year (to test adding)
			system.debug ( 'TEST>>>>> inserting gift 4...');
			Opportunity[] testGift4 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 25 , giftRecordTypeNameForTests,null);
	
			insert testGift4;
			
			// now roll up manually
			rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
	
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 110 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
	
			// TBD add a gift from longer ago
			system.debug ( 'TEST>>>>> inserting gift 5...');
			Opportunity[] testGift5 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat4YearAgo, 200 , giftRecordTypeNameForTests,null);
	
			insert testGift5;
			
			// now roll up manually
			rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			// totals should not have changed, except lifetime & best yr
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 310 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );		
			
			// TBD add non-won gift
			system.debug ( 'TEST>>>>> inserting gift 6...');
			Opportunity[] testGift6 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getOpenStage(), dat4YearAgo, 35 , giftRecordTypeNameForTests,null);
	
			insert testGift6;
			
			// now roll up manually
			rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			// totals should not have changed at all
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 310 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );		
					
			// now delete the 1st gift (now at $50), totals should decrease
			system.debug ( 'TEST>>>>> deleting gift 1...');	
			delete testGift1;
			
			// now roll up manually
			rg = new OpportunityRollups();
			rg.rollupContact(testcons[0].id);
			
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			
			System.AssertEquals ( 260 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );				
			
			/*
			// finally add a larger gift from several yrs ago to test the best gift yr going earlier than other stats
			system.debug ( 'TEST>>>>> inserting gift 7...');
			Opportunity[] testGift7 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday.addYears(-5), 200 , 'Gift',null);
			ONEN_OpportunityContactRoles.haveCheckedContactRoles = false;
			insert testGift7;
	
			UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, Best_Gift_Year__c, Best_Gift_Year_Total__c  FROM Contact WHERE Id = :ThisConId];
			System.AssertEquals ( datToday.addYears(-5).year() , UpdatedCon.Best_Gift_Year__c );
			System.AssertEquals ( 200 , UpdatedCon.Best_Gift_Year_Total__c );
			*/		
		}
	}

	static testMethod void OneContactOneInkind() {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
					Enable_Opp_Rollup_Triggers__c = true,
					Excluded_Account_Opp_Rectypes__c = null,
					Excluded_Account_Opp_Types__c = 'In Kind',
					Excluded_Contact_Opp_Rectypes__c = null,
					Excluded_Contact_Opp_Types__c = 'In Kind',
					Membership_Record_Types__c = null
				));
				
			npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
	        	npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
	        	npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
	        	npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
	        ));
	        
			integer howMany = 1;
			Date datToday = System.Today();
			
			// create & insert contact(s)
			Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
			insert TestCons;
			
			system.debug ( 'TEST>>>>> inserting gift 1...');
			
			// create a new gift for this yr
			Opportunity[] testGift1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 100 , giftRecordTypeNameForTests,'In Kind');
			Test.StartTest();
			insert testGift1 ;
			Test.StopTest();
			
			id ThisConId = TestCons[0].id;
			contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
		
			System.Assert( !(UpdatedCon.npo02__TotalOppAmount__c>0) );
			
			//testGift1[0].Type = 'Cash';
			//update testGift1;
			
			//UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
			//System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
		
	
	}

	static testMethod void testGivingRollupBulk () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
		
			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
	        
			// for a single contact w/ no previous mbrships, add a new membership
			// and test mbr stats are created
			integer howMany = 50;
			Date datClose = System.Today();
				
			// create & insert contact(s)
			Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
			insert TestCons;
			
			// create new opps
			Opportunity[] newOpps1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests,null);
			Opportunity[] newOpps2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-1), 50 , giftRecordTypeNameForTests,null);
	
			// insert the opp(s)
			Test.StartTest();
			insert newOpps1;
	
			insert newOpps2;
	
			Test.StopTest();
			
			id FirstConId = TestCons[10].id;
			Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
			
			System.AssertEquals ( 150 , UpdatedCon.npo02__TotalOppAmount__c );
			System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );		
			System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountLastYear__c );
			System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
		
	}

	static testMethod void testGivingRollupTooManyOpps () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
	        
			// for a single contact w/ no previous mbrships, add a new membership
			// and test mbr stats are created
		
			// create & insert contact(s)
			Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 1 ) ;
			insert TestCons;
			
			// create new opps
			Opportunity[] newOpps1 = new Opportunity[0];
			for (integer n = 0; n < 450; n++) {
				Opportunity newOpp1 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
					name = 'test opp ' + n, 
					stagename = UnitTestData.getClosedWonStage(), closedate = system.today().adddays(-n), amount = 100);
				if(areRecordTypesOnOpps()){
					newOpp1.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
				}
				newOpps1.add( newOpp1);
			}
			
			// insert the opp(s)
			Test.StartTest();
			insert newOpps1;
			Test.StopTest();
			
			id FirstConId = TestCons[0].id;
			Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
			
			System.AssertEquals ( 45000 , UpdatedCon.npo02__TotalOppAmount__c );
		
	} 
	
	static testMethod void testHouseholdStats () {
		isTest = true;
		String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

			Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
				new Households_Settings__c (
					Household_Rules__c = Households.ALL_PROCESSOR,
					Always_Rollup_to_Primary_Contact__c = false,
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
				
			// create & insert contact
			Contact Con1 = new contact(
				FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
	            LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
	            npe01__Private__c=false,
	            npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
	            npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
	            npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
	            npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
			);
			insert Con1;
			
			Contact con = [SELECT Household__r.id FROM Contact WHERE id = :Con1.id LIMIT 1];
			
			// create & insert second household member
			Contact Con2 = new contact(
				FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second',
	            LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
	            npe01__Private__c=false,
	            npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
	            npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
	            npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
	            npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
				Household__c = con.Household__c
			);
			insert Con2;
			
			Contact[] TestCons = new Contact[] {Con1}; 
		
			// create new opps
			Opportunity[] newOpps1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
			Opportunity[] newOpps2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-2), 200 , giftRecordTypeNameForTests ,null);
			Opportunity[] newOpps3 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-3), 75 , giftRecordTypeNameForTests ,null);
	
			Opportunity[] testOpps = new Opportunity[0];
			testOpps.addAll (newOpps1);
			testOpps.addAll (newOpps2);
			testOpps.addAll (newOpps3);
	
			// insert the opp(s)
			Test.StartTest();
			insert testOpps;
			Test.StopTest();
			
			Contact c = [SELECT Id,Total_Household_Gifts__c,OppAmountThisYearHH__c,OppAmountLastYearHH__c,LastCloseDateHH__c
				FROM Contact WHERE LastName=:npe01.Constants.CONTACT_LASTNAME_FOR_TESTS AND FirstName=:npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second' LIMIT 1];
			System.assertEquals (375,c.Total_Household_Gifts__c);
			System.assertEquals (100,c.OppAmountThisYearHH__c);
			System.assertEquals (0,c.OppAmountLastYearHH__c);
			System.assertEquals (datClose,c.LastCloseDateHH__c );
			System.assertEquals (375,c.Total_Household_Gifts__c);
				
	}
}
global virtual class OpportunityRollups {
 
    // settings
    boolean triggerRollupEnabled = true;
    boolean alwaysRollupToPrimaryContact = false;     
    boolean useFiscalYear = false;
    set<id> recordTypesToExcludeAccts = new set<id>();
    set<id> recordTypesToExcludeCons = new set<id>();
    set<id> mbrRecordTypes = new set<id>(); 
    set<string> oppTypesToExcludeAccts = new set<string>();
    set<string> oppTypesToExcludeCons = new set<string>();  
    //Modifiable ndays setting for 2.1    
    string ndayrollup = '365';  //default to original 365 day value
        
    //user defined rollups in list settings
    public static map<string, User_Rollup_Field_Settings__c> userRollups = new map<string, User_Rollup_Field_Settings__c>();
    public boolean hasContactRollups;
    public boolean hasHouseholdRollups;
    public boolean hasAccountRollups;
    
    static boolean recordTypesOnOpps;
    
    //multi-currency vars
    static boolean multiCurrency;
    static SObjectField cfOppty;
    static SObjectField cfAccount;
    static SObjectField cfHousehold;
    static SObjectField cfContact;
    //exchangerate store
    static map<string, decimal> exchangeRates = new map<string,decimal>();
    //corporate currency
    static string currCorporate;  
    
    
    //determines if record types are enabled on opportunities 
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
            if (rollupSettings.Rollup_N_Day_Value__c != null){
            	ndayRollup = string.valueOf(rollupSettings.Rollup_N_Day_Value__c.intValue());
            }
            if (rollupSettings.Membership_Record_Types__c != null) {
                set<string> mbrRecordTypeNames = new set<string>(rollupSettings.Membership_Record_Types__c.split(';'));
                mbrRecordTypes = RecordTypes.GetRecordTypeIdSet('Opportunity', mbrRecordTypeNames);
            }
            if (rollupSettings.Enable_Opp_Rollup_Triggers__c == false && !isTest)
                triggerRollupEnabled = false;
            
            if (rollupSettings.Always_Rollup_to_Primary_Contact__c == true)
                alwaysRollupToPrimaryContact = true;  
        
            //check the settings, if they have the fiscal year set
            //we still need to query to make sure its not a custom fiscal year
            //or else we'll throw errors when calling Fiscal_Year in queries
            if (rollupSettings.Use_Fiscal_Year_for_Rollups__c == true){
            	integer hasCustomFYRecord = [select count() from FiscalYearSettings];
            	
            	//if org has customFY records, disable FY settings
                if (hasCustomFYRecord > 0)
            	   useFiscalYear = false;
            	else
            	   useFiscalYear = true;
            }
        
        }
        
        //load user rollup settings - if they exist        
        userRollups = User_Rollup_Field_Settings__c.getAll().clone(); 
        
        //setup our object bools to demarcate which objects have user defined rollups
        //this will save us some cycles later on
        //also check runtime field validity
        
        for (string s : userRollups.keySet()){
        	User_Rollup_Field_Settings__c urfs = userRollups.get(s);
        	if (urfs.Object_Name__c == 'Contact'){hasContactRollups = true;}      	
        	else if (urfs.Object_Name__c == 'Account'){hasAccountRollups = true;}
        	else if (urfs.Object_Name__c == 'Household__c'){hasHouseholdRollups = true;}
        	else{
        		hasContactRollups = false;
                hasHouseholdRollups = false;
                hasAccountRollups = false;
        	} 
        
            SobjectField targetField;
            SobjectField sourceField;
        
            //check source field
            sourceField = Schema.sObjectType.Opportunity.fields.getMap().get(urfs.Source_Field__c);
            if (sourceField == null) userRollups.remove(s);
                      
            //check target fields            
            if (urfs.Object_Name__c == 'Contact'){
                targetField = Schema.sObjectType.Contact.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) userRollups.remove(s);
            }
            else if (urfs.Object_Name__c == 'Account'){
                targetField = Schema.sObjectType.Account.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) userRollups.remove(s);               
            }
            else if (urfs.Object_Name__c == 'Household__c'){
                targetField = Schema.sObjectType.Household__c.fields.getMap().get(urfs.Target_Field__c); 
                if (targetField == null) userRollups.remove(s);
            }
        }       
    }           

    public void rollupAccount( id aid ) {
    // roll up a single account's opps
        
/*        map<id, account> amap = new map<id, account>(
            [select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c, 
                TotalMembershipOppAmount__c, LastCloseDate__c, NumberOfClosedOpps__c,
                OppsClosedThisYear__c,OppsClosedLastYear__c, OppsClosedLastNDays__c,
                OppsClosed2YearsAgo__c, OppAmountLastYear__c, OppAmount2YearsAgo__c                           
                from account where id = : aid AND NumberOfClosedOpps__c < 3000]);
*/
        // switch to dynamic SOQL for multicurrency
        map<id, account> amap = new map<id, account>((List<Account>)Database.query('select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c,'+ 
                'TotalMembershipOppAmount__c, LastCloseDate__c, NumberOfClosedOpps__c,'+
                'OppsClosedThisYear__c,OppsClosedLastYear__c, OppsClosedLastNDays__c,'+
                'OppsClosed2YearsAgo__c, OppAmountLastYear__c, OppAmount2YearsAgo__c '+
                (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+             
                'from account where id = :aid AND NumberOfClosedOpps__c < 3000'));
      
        if (!amap.isEmpty()) 
            rollupAccounts( amap );
    }

    @future
    public static void rollupAccountsFuture( set<id> acctIds ) {
    // roll up a single account's opps
        
        if (acctIds != null && !acctIds.isEmpty()) { 
   /*         map<id, account> amap = new map<id, account>(
                [select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c, 
                    TotalMembershipOppAmount__c, LastCloseDate__c, NumberOfClosedOpps__c,
                    OppsClosedThisYear__c,OppsClosedLastYear__c, OppsClosedLastNDays__c,
                    OppsClosed2YearsAgo__c, OppAmountLastYear__c, OppAmount2YearsAgo__c  
                    from account where id in :acctIds AND NumberOfClosedOpps__c < 3000 ]); */
        // switch to dynamic SOQL for multicurrency
            map<id, account> amap = new map<id, account>((List<Account>) Database.query('select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c, '+
                    'TotalMembershipOppAmount__c, LastCloseDate__c, NumberOfClosedOpps__c,'+
                    'OppsClosedThisYear__c,OppsClosedLastYear__c, OppsClosedLastNDays__c,'+
                    'OppsClosed2YearsAgo__c, OppAmountLastYear__c, OppAmount2YearsAgo__c '+  
                    (isMultiCurrency() ? ', CurrencyIsoCode ' : '') +  
                    'from account where id in :acctIds AND NumberOfClosedOpps__c < 3000'));           
            
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

        //arg used by multi currency for rollup field currencies
        map<Id,Opportunity> opptyCurrencies;

        // copy the accounts to a map of zerod out versions
        map<id, account> accountsToUpdate = new map<id, account>();
        set<id> allAccts = amap.keyset();
        for (id aid : allAccts) {
            accountsToUpdate.put(aid, new Account(id = aid, TotalOppAmount__c = 0, AverageAmount__c = 0, 
                SmallestAmount__c = 0, LargestAmount__c = 0, FirstCloseDate__c = null,
                LastCloseDate__c = null, NumberOfClosedOpps__c = 0, OppAmountThisYear__c = 0, 
                OppsClosedThisYear__c = 0, OppAmountLastYear__c = 0, OppsClosedLastYear__c = 0,
                OppsClosed2YearsAgo__c = 0, OppAmount2YearsAgo__c = 0,
                OppsClosedLastNDays__c = 0, OppAmountLastNDays__c = 0, 
//              MembershipOppsClosedThisYear__c = 0, MembershipOppAmountLastYear__c = 0, MembershipOppsClosedLastYear__c = 0,
//              MembershipOppsClosed2YearsAgo__c = 0, MembershipOppAmount2YearsAgo__c = 0, 
                TotalMembershipOppAmount__c = 0, NumberOfMembershipOpps__c = 0,               
                LastMembershipDate__c = null, LastMembershipAmount__c = 0,                
                LastMembershipLevel__c = null, LastMembershipOrigin__c = null,                
                MembershipJoinDate__c = null, MembershipEndDate__c = null,
                LastOppAmount__c = null                  
            ));
            
            // map currency across if multicurrency
            if(isMultiCurrency())
                accountsToUpdate.get(aid).put(cfAccount,amap.get(aid).get(cfAccount));
        }

        // copy all the rollups from each result row into the account objects
        integer startYear = system.today().year() - 2;
     
        String soqlStatement = '';
        if (useFiscalYear)
            soqlStatement += 'SELECT accountId, Fiscal_Year(CloseDate) CalendarYr, ';
        else
            soqlStatement += 'SELECT accountID, Calendar_Year(CloseDate) CalendarYr, ';
        
        soqlStatement += 'SUM(Amount) TotalOppAmount, AVG(Amount) AverageAmount, MIN(Amount) SmallestAmount, ';
        soqlStatement += 'MAX(Amount) LargestAmount, MIN(CloseDate) FirstCloseDate, MAX(CloseDate) LastCloseDate, ';
        for (string s : userRollups.keyset()){
        	if (userRollups.get(s).Object_Name__c == 'Account'){
        	   User_Rollup_Field_Settings__c urfs = userRollups.get(s);
        	   soqlStatement += urfs.Field_Action__c + '(' + urfs.Source_Field__c + ') ' + urfs.Name + ', '; 	
        	}        	
        }
        soqlStatement += 'COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(CombinedRollupFieldset__c) RollupFieldset '; 
        soqlStatement += 'FROM Opportunity ';
        soqlStatement += 'WHERE isWon=true '; 
        soqlStatement += 'AND (Amount > 0 OR Amount < 0) '; 
        if(areRecordTypesOnOpps()){
            soqlStatement += 'AND RecordTypeId NOT IN : recordTypesToExcludeAccts ';
        }
        soqlStatement += 'AND Type NOT IN : oppTypesToExcludeAccts ';
        soqlStatement += 'AND accountId IN : allAccts ';
        if (useFiscalYear){
            soqlStatement += 'GROUP BY ROLLUP (accountId, Fiscal_Year(closeDate)) ';
            soqlStatement += 'HAVING ( Fiscal_Year(closeDate) = null OR Fiscal_Year(closeDate) >= : startYear ) ';
        }
        else{
        	soqlStatement += 'GROUP BY ROLLUP (accountId, Calendar_Year(closeDate)) ';
            soqlStatement += 'HAVING ( Calendar_Year(closeDate) = null OR Calendar_Year(closeDate) >= : startYear ) ';
        }
        soqlStatement += 'AND accountId != null';
        
        list<sobject> objectList = Database.query(soqlStatement);

        // invokes code to get the currency of CombinedRollupFieldset__c oppty
        opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
        
        for (sobject r : objectList){
                    
            //system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);

            // get the account id for this result row
            id aid = (id)(r.get('accountId'));
    
            // copy all the rollups from this result row into the account object    
            updateRollupFromResult((sobject)(accountsToUpdate.get(aid)), r, opptyCurrencies);
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
        soqlStatement += 'AND closeDate >= LAST_N_DAYS:' + ndayrollup + ' '; 
        soqlStatement += 'GROUP BY accountId '; 
        soqlStatement += 'HAVING accountId != null';
        
        objectList.clear();
        objectList = database.query(soqlStatement);
        
        
        
        for (sobject r : objectList ) {
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
            soqlStatement += 'MIN(membership_start_date__c) FirstStartDate, MAX(membership_end_date__c) LastEndDate,  ';
            soqlStatement += 'COUNT_DISTINCT(Id) NumberOfClosedOpps, MAX(CombinedRollupFieldset__c) RollupFieldset  ';
            soqlStatement += 'FROM Opportunity ';
            soqlStatement += 'WHERE isWon=true  ';
            soqlStatement += 'AND (Amount > 0 OR Amount < 0)  ';
            if(areRecordTypesOnOpps()){
                soqlStatement += 'AND RecordTypeId IN : mbrRecordTypes ';
            }
            soqlStatement += 'AND Type NOT IN : oppTypesToExcludeAccts ';
            soqlStatement += 'AND accountId IN : allAccts ';
            
            if (useFiscalYear)
                soqlStatement += 'GROUP BY ROLLUP (accountId, Fiscal_Year(closeDate)) ';
            else
                soqlStatement += 'GROUP BY ROLLUP (accountId, Calendar_Year(closeDate)) ';
            soqlStatement += 'HAVING  ';
                    // ( Calendar_Year(closeDate) = null OR Calendar_Year(closeDate) >= : startYear ) AND
            soqlStatement += 'accountId != null';
            
            objectList.clear();
            objectList = database.query(soqlStatement);        
            
            // invokes code to get the currency of CombinedRollupFieldset__c oppty
            opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
            
            for (sobject r : objectList ) {
                //system.debug('ROLLUP ROW: ' + r);
    
                // get the account id for this result row
                id aid = (id)(r.get('accountId'));
                
                // copy all the rollups from this result row into the account object  
                updateRollupFromResultMembership((sobject)(accountsToUpdate.get(aid)), r, opptyCurrencies);
            }
        }

        // remove any records that have not changed
        for (id aid : allAccts) {
            account a1 = amap.get(aid); 
            account a2 = accountsToUpdate.get(aid);
            
            if (a1.TotalOppAmount__c == a2.TotalOppAmount__c &&
                    a1.OppsClosedThisYear__c == a2.OppsClosedThisYear__c &&
                    a1.OppsClosedLastYear__c == a2.OppsClosedLastYear__c &&
                    a1.OppsClosedLastNDays__c == a2.OppsClosedLastNDays__c &&
                    a1.OppsClosed2YearsAgo__c == a2.OppsClosed2YearsAgo__c &&
                    a1.OppAmountLastYear__c == a2.OppAmountLastYear__c &&
                    a1.OppAmount2YearsAgo__c == a2.OppAmount2YearsAgo__c &&                      
                    a1.OppAmountThisYear__c == a2.OppAmountThisYear__c &&
                    a1.OppAmountLastNDays__c == a2.OppAmountLastNDays__c &&
                    a1.TotalMembershipOppAmount__c == a2.TotalMembershipOppAmount__c &&
                    a1.LastCloseDate__c == a2.LastCloseDate__c)
                accountsToUpdate.remove(aid);
        }
        
        // update all the accounts from this batch 
        update accountsToUpdate.values(); 
    }

    public void rollupContact( id cid ) {
        // roll up opps for one contact
 /*       list<contact> cc = [select id, household__c, TotalOppAmount__c, OppAmountThisYear__c, 
                OppAmountLastNDays__c, TotalMembershipOppAmount__c, LastCloseDate__c, 
                NumberOfClosedOpps__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, 
                LastOppAmount__c,  MembershipEndDate__c, Household__r.MembershipEndDate__c,
                MembershipJoinDate__c, Household__r.MembershipJoinDate__c,
                Household__r.OppsClosedThisYear__c, Household__r.OppsClosedLastYear__c, 
                Household__r.OppsClosedLastNDays__c, Household__r.OppsClosed2YearsAgo__c, 
                Household__r.OppAmountLastYear__c, Household__r.OppAmount2YearsAgo__c,
                household__r.TotalOppAmount__c, household__r.OppAmountThisYear__c, 
                household__r.OppAmountLastNDays__c, household__r.TotalMembershipOppAmount__c,
                household__r.LastCloseDate__c, household__r.NumberOfClosedOpps__c
                from contact where id = :cid ]; */
        // switch to dynamic SOQL for multicurrency
        list<contact> cc = Database.query('select id, household__c, TotalOppAmount__c, OppAmountThisYear__c, '+
                'OppAmountLastNDays__c, TotalMembershipOppAmount__c, LastCloseDate__c, '+
                'NumberOfClosedOpps__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, '+
                'LastOppAmount__c, MembershipEndDate__c, Household__r.MembershipEndDate__c, '+ 
                'MembershipJoinDate__c, Household__r.MembershipJoinDate__c, '+
                'household__r.OppsClosedThisYear__c, household__r.OppsClosedLastYear__c, '+
                'household__r.OppsClosedLastNDays__c, household__r.OppsClosed2YearsAgo__c, '+
                'household__r.OppAmountLastYear__c, household__r.OppAmount2YearsAgo__c,'+
                'household__r.TotalOppAmount__c, household__r.OppAmountThisYear__c, '+
                'household__r.OppAmountLastNDays__c, household__r.TotalMembershipOppAmount__c,'+
                'household__r.LastCloseDate__c, household__r.NumberOfClosedOpps__c '+
                (isMultiCurrency() ? ', CurrencyIsoCode , household__r.CurrencyIsoCode ' : '')+  
                'from contact where id = :cid ');     
    
        if (!cc.isEmpty()) { 
            map<id, household__c> hhmap = new map<id, household__c>();
            if (cc[0].household__c != null) 
                hhmap.put(cc[0].household__c, cc[0].household__r);
        
            rollupContacts( new map<id, contact>( cc ), hhmap );
        }
    }
    
    public void rollupHousehold( id hhid ) {
/*        // roll up opps for one household
        list<household__c> hhs = [select id, TotalOppAmount__c, OppAmountThisYear__c, 
            OppAmountLastNDays__c, LastCloseDate__c, NumberOfClosedOpps__c, TotalMembershipOppAmount__c,
            OppsClosedThisYear__c, OppsClosedLastYear__c, 
            OppsClosedLastNDays__c, OppsClosed2YearsAgo__c,
            OppAmountLastYear__c, OppAmount2YearsAgo__c,
            MembershipEndDate__c, MembershipJoinDate__c
            from household__c where id = :hhid ]; */
        // switch to dynamic SOQL for multicurrency
        list<household__c> hhs = Database.query('select id, TotalOppAmount__c, OppAmountThisYear__c,'+ 
            'OppAmountLastNDays__c, LastCloseDate__c, NumberOfClosedOpps__c, TotalMembershipOppAmount__c,'+
            'OppsClosedThisYear__c, OppsClosedLastYear__c,'+ 
            'OppsClosedLastNDays__c, OppsClosed2YearsAgo__c,'+
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, '+
            'MembershipEndDate__c, MembershipJoinDate__c ' +
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+  
            'from household__c where id = :hhid ');
        
        if (!hhs.isEmpty()) 
            rollupHouseholds( hhs );
    }   
    
    public void rollupHouseholds( list<household__c> hhs ) {
    // roll up opps for households

        if (hhs != null && !hhs.isEmpty()) {
            
            map<id, household__c> hhmap = new map<id, household__c>( hhs );
  
            // extract keyset from map, as dynamic SOQL only handles single level binds
            set<id> hhmapids =hhmap.keyset();       
            
            // get household contacts
                        
/*            map<id, contact> cmap = new map<id, contact>([select id, household__c, TotalOppAmount__c, OppAmountThisYear__c, 
                OppAmountLastNDays__c, TotalMembershipOppAmount__c, LastCloseDate__c, 
                NumberOfClosedOpps__c, MembershipEndDate__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipJoinDate__c,
                LastOppAmount__c from contact where household__c in :hhmap.keyset() ]); */            
            // switch to dynamic SOQL for multicurrency
            map<id, contact> cmap = new map<id, contact>((List<contact>) Database.query('select id, household__c, TotalOppAmount__c, OppAmountThisYear__c,'+  
                'OppAmountLastNDays__c, TotalMembershipOppAmount__c, LastCloseDate__c,'+  
                'NumberOfClosedOpps__c, MembershipEndDate__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipJoinDate__c, '+  
                (isMultiCurrency() ? 'CurrencyIsoCode,' : '')+
                'LastOppAmount__c from contact where household__c in :hhmapids '));
            
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
/*[SELECT contactId, contact.household__c,
                        contact.TotalOppAmount__c, contact.OppAmountThisYear__c, contact.OppAmountLastNDays__c, 
                        contact.LastCloseDate__c, contact.NumberOfClosedOpps__c, contact.TotalMembershipOppAmount__c,
                        contact.OppAmountLastYear__c, contact.OppAmount2YearsAgo__c, contact.LastOppAmount__c,          
                        contact.household__r.TotalOppAmount__c, contact.household__r.OppAmountThisYear__c, 
                        contact.household__r.OppAmountLastNDays__c, contact.household__r.TotalMembershipOppAmount__c, 
                        contact.household__r.LastCloseDate__c, contact.household__r.NumberOfClosedOpps__c,
                        contact.household__r.OppsClosedThisYear__c, contact.household__r.OppsClosedLastYear__c, 
                        contact.household__r.OppsClosedLastNDays__c, contact.household__r.OppsClosed2YearsAgo__c,
                        contact.household__r.OppAmountLastYear__c, contact.household__r.OppAmount2YearsAgo__c,
                        contact.MembershipEndDate__c, contact.household__r.MembershipEndDate__c,
                        contact.MembershipJoinDate__c, contact.household__r.MembershipJoinDate__c
                        FROM OpportunityContactRole WHERE Opportunity.Id In : modifiedContactOpps and isPrimary = true ALL ROWS ] ) { */
                        	
                    Database.query('SELECT contactId, contact.household__c, '+
                        'contact.TotalOppAmount__c, contact.OppAmountThisYear__c, contact.OppAmountLastNDays__c, '+
                        'contact.LastCloseDate__c, contact.NumberOfClosedOpps__c, contact.TotalMembershipOppAmount__c, '+
                        'contact.OppAmountLastYear__c, contact.OppAmount2YearsAgo__c, contact.LastOppAmount__c, '+ 
                        'contact.household__r.TotalOppAmount__c, contact.household__r.OppAmountThisYear__c, '+
                        'contact.household__r.OppAmountLastNDays__c, contact.household__r.TotalMembershipOppAmount__c, '+ 
                        'contact.household__r.LastCloseDate__c, contact.household__r.NumberOfClosedOpps__c, '+
                        'contact.household__r.OppsClosedThisYear__c, contact.household__r.OppsClosedLastYear__c, '+ 
                        'contact.household__r.OppsClosedLastNDays__c, contact.household__r.OppsClosed2YearsAgo__c, '+
                        'contact.household__r.OppAmountLastYear__c, contact.household__r.OppAmount2YearsAgo__c, '+
                        'contact.MembershipEndDate__c, contact.household__r.MembershipEndDate__c, ' +  
                        'contact.MembershipJoinDate__c, contact.household__r.MembershipJoinDate__c ' + 
                        (isMultiCurrency() ? ', contact.CurrencyIsoCode, contact.household__r.CurrencyIsoCode ' : '') +
                        'FROM OpportunityContactRole WHERE Opportunity.Id In : modifiedContactOpps and isPrimary = true ALL ROWS ') ) {   
                    
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
        
        //arg used by multi currency for rollup field currencies
        map<Id,Opportunity> opptyCurrencies;

        // copy the contacts and households to a map of zerod out versions
        map<id, contact> contactsToUpdate = new map<id, contact>();
        map<id, household__c> householdsToUpdate = new map<id, household__c>();
        for (id cid : conIds) {
            contactsToUpdate.put(cid, new Contact(id = cid, TotalOppAmount__c = 0, AverageAmount__c = 0, 
                SmallestAmount__c = 0, LargestAmount__c = 0, FirstCloseDate__c = null, 
                LastCloseDate__c = null, NumberOfClosedOpps__c = 0, OppAmountThisYear__c = 0, 
                OppsClosedThisYear__c = 0, OppAmountLastYear__c = 0, OppsClosedLastYear__c = 0,
                OppsClosed2YearsAgo__c = 0, OppAmount2YearsAgo__c = 0, 
                OppsClosedLastNDays__c = 0, OppAmountLastNDays__c = 0,
//              MembershipOppsClosedThisYear__c = 0, MembershipOppAmountLastYear__c = 0, MembershipOppsClosedLastYear__c = 0,
//              MembershipOppsClosed2YearsAgo__c = 0, MembershipOppAmount2YearsAgo__c = 0, 
                TotalMembershipOppAmount__c = 0, NumberOfMembershipOpps__c = 0,               
                LastMembershipDate__c = null, LastMembershipAmount__c = 0,                
                LastMembershipLevel__c = null, LastMembershipOrigin__c = null,                
                MembershipJoinDate__c = null, MembershipEndDate__c = null,                
                LastOppAmount__c = null
            ));
            // map currency across if multicurrency
            if(isMultiCurrency())
                contactsToUpdate.get(cid).put(cfContact,cmap.get(cid).get(cfContact));            
        }
        for (id hhid : hhIds) {
            householdsToUpdate.put(hhid, new household__c(id = hhid, TotalOppAmount__c = 0, AverageAmount__c = 0, 
                SmallestAmount__c = 0, LargestAmount__c = 0, FirstCloseDate__c = null, 
                LastCloseDate__c = null, NumberOfClosedOpps__c = 0, OppAmountThisYear__c = 0,
                OppsClosedThisYear__c = 0, OppAmountLastYear__c = 0, OppsClosedLastYear__c = 0,
                OppsClosed2YearsAgo__c = 0, OppAmount2YearsAgo__c = 0, 
                OppsClosedLastNDays__c = 0, OppAmountLastNDays__c = 0,
//              MembershipOppsClosedThisYear__c = 0, MembershipOppAmountLastYear__c = 0, MembershipOppsClosedLastYear__c = 0,
//              MembershipOppsClosed2YearsAgo__c = 0, MembershipOppAmount2YearsAgo__c = 0, 
                TotalMembershipOppAmount__c = 0, NumberOfMembershipOpps__c = 0,               
                LastMembershipDate__c = null, LastMembershipAmount__c = 0,                
                LastMembershipLevel__c = null, LastMembershipOrigin__c = null,                
                MembershipJoinDate__c = null, MembershipEndDate__c = null,                
                LastOppAmount__c = null
            ));
        // map currency across if multicurrency
            if(isMultiCurrency())
                householdsToUpdate.get(hhid).put(cfHousehold,hhmap.get(hhid).get(cfHousehold));
        }

        // copy all the rollups from each result row into the contact objects
        integer startYear = system.today().year() - 2; 
        
        //generic object list for database query results
        //resolves aggregrate querymore issue
        list<sobject> objectList = new list<sobject>();
        
        
        if (alwaysRollupToPrimaryContact) {
            String soqlStatement = ''; 
            if (useFiscalYear)
                soqlStatement += 'SELECT contact.household__c hhid, contactId, Fiscal_Year(Opportunity.CloseDate) CalendarYr, ';
            else
                soqlStatement += 'SELECT contact.household__c hhid, contactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';
            
            soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
            soqlStatement += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
            soqlStatement += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
            soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            for (string s : userRollups.keyset()){
                if (userRollups.get(s).Object_Name__c == 'Contact' || userRollups.get(s).Object_Name__c == 'Household__c'){
                    User_Rollup_Field_Settings__c urfs = userRollups.get(s);
                    soqlStatement += urfs.Field_Action__c + '(Opportunity.' + urfs.Source_Field__c + ') ' + urfs.Name + ', ';    
                }           
            }            
            soqlStatement += 'MAX(Opportunity.CombinedRollupFieldset__c) RollupFieldset ';
            soqlStatement += 'FROM OpportunityContactRole  ';
            soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
            soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
            if(areRecordTypesOnOpps()){
                soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
            }
            soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons  ';
            soqlStatement += 'AND (contact.household__c IN : hhIds) ';// OR  ';
            //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
            
            if (useFiscalYear)
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Fiscal_Year(opportunity.closeDate)) ';
            else
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Calendar_Year(opportunity.closeDate)) ';
            soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null)';
           
             
            objectList = database.query(soqlStatement);
            
            // invokes code to get the currency of CombinedRollupFieldset__c oppty
            opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
            
            for (sobject r : objectList ) {
                
                // system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
    
                // get the ids
                id cid = (id)(r.get('contactId'));
                id hhid = (id)(r.get('hhid'));
                    
                // process the result row, copying it into the contact record(s)
                // MS: we only want to fully calc the row if it is from the last few years - older years are only for calcing Best Year for contacts
                integer yr = (integer)r.get('CalendarYr');
                if (cid == null) { 
                    /*if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r);*/
                    if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r, opptyCurrencies);
                    // after doing regular processing, calc Best Contact Year stuff
                    // the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
                    decimal yrAmt = (decimal)r.get('TotalOppAmount');
                    household__c HH = householdsToUpdate.get(hhid);
    
                } else {
                    // contact row
                    if ( yr >= startYear || yr==null) {
                        /*updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r);*/
                        updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r, opptyCurrencies);
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
            soqlStatement += 'AND (contact.household__c IN : hhIds) '; //OR  ';
            //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
            soqlStatement += 'AND opportunity.closeDate >= LAST_N_DAYS:' + ndayrollup + ' ';
            soqlStatement += 'GROUP BY ROLLUP(contact.household__c, contactId) ';
            soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null)  ';
            
            objectList.clear();
            objectList = database.query(soqlStatement);
            
            for (sobject r : objectList) {
    
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
                soqlStatement += 'MIN(Opportunity.membership_start_date__c) FirstStartDate, '; 
                soqlStatement += 'MAX(Opportunity.Membership_End_Date__c) LastEndDate,  ';
                soqlStatement += 'MAX(contact.household__r.MembershipEndDate__c) HHMemberEndDate, ';
                soqlStatement += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
                for (string s : userRollups.keyset()){
                    if (userRollups.get(s).Object_Name__c == 'Contact' || userRollups.get(s).Object_Name__c == 'Household__c'){
                        User_Rollup_Field_Settings__c urfs = userRollups.get(s);
                        soqlStatement += urfs.Field_Action__c + '(Opportunity.' + urfs.Source_Field__c + ') ' + urfs.Name + ', ';    
                    }           
                } 
                soqlStatement += 'MAX(Opportunity.CombinedRollupFieldset__c) RollupFieldset ';
                soqlStatement += 'FROM OpportunityContactRole  ';
                soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
                soqlStatement += 'AND (Opportunity.Amount != null) '; 
                if(areRecordTypesOnOpps()){
                    soqlStatement += 'AND Opportunity.RecordTypeId IN : mbrRecordTypes ';
                }
                soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
                soqlStatement += 'AND (contact.household__c IN : hhIds) ';// OR  ';
                //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId) ';
                soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) '; 
                
                objectList.clear();
                objectList = database.query(soqlStatement);
                
                // invokes code to get the currency of CombinedRollupFieldset__c oppty
                opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
              
                for (sobject r : objectList) {
                            
                    // get the ids
                    id cid = (id)(r.get('contactId'));
                    id hhid = (id)(r.get('hhid'));
                        
                    // process the result row, copying it into the contact record(s)
                    if (cid == null) { 
                        if (hhid != null)
                            /*updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r);*/
                            updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r, opptyCurrencies);
                    } else {
                        // contact row  
                        /*updateRollupFromResultMembership((sobject)(contactsToUpdate.get(cid)), r);*/
                        updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r, opptyCurrencies);
                    }
                }
            }
        } else {
            String soqlStatement = '';
            if (useFiscalYear)
                soqlStatement += 'SELECT contact.household__c hhid, contactId, Fiscal_Year(Opportunity.CloseDate) CalendarYr, ';
            else            
                soqlStatement += 'SELECT contact.household__c hhid, contactId, Calendar_Year(Opportunity.CloseDate) CalendarYr, ';
            soqlStatement += 'SUM(Opportunity.Amount) TotalOppAmount,  ';
            soqlStatement += 'AVG(Opportunity.Amount) AverageAmount, MIN(Opportunity.Amount) SmallestAmount, ';
            soqlStatement += 'MAX(Opportunity.Amount) LargestAmount, MIN(Opportunity.CloseDate) FirstCloseDate, '; 
            soqlStatement += 'MAX(Opportunity.CloseDate) LastCloseDate, COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
            for (string s : userRollups.keyset()){
                if (userRollups.get(s).Object_Name__c == 'Contact' || userRollups.get(s).Object_Name__c == 'Household__c'){
                    User_Rollup_Field_Settings__c urfs = userRollups.get(s);
                    soqlStatement += urfs.Field_Action__c + '(Opportunity.' + urfs.Source_Field__c + ') ' + urfs.Name + ', ';    
                }           
            } 
            soqlStatement += 'MAX(Opportunity.CombinedRollupFieldset__c) RollupFieldset ';
            soqlStatement += 'FROM OpportunityContactRole  ';
            soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
            soqlStatement += 'AND (Opportunity.Amount > 0 OR Opportunity.Amount < 0) '; 
            if(areRecordTypesOnOpps()){
                soqlStatement += 'AND Opportunity.RecordTypeId NOT IN : recordTypesToExcludeCons ';
            }
            soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
            soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.SYSTEMIsIndividual__c = true) ';   
            soqlStatement += 'AND (contact.household__c IN : hhIds ) ';// OR  ';
            //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
            if (useFiscalYear)
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Fiscal_Year(opportunity.closeDate)) ';
            else
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId, Calendar_Year(opportunity.closeDate)) ';
            soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
                
            objectList.clear();
            objectList = database.query(soqlStatement);
            
            // invokes code to get the currency of CombinedRollupFieldset__c oppty
            opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
                
            for (sobject r : objectList) {
                
                // system.debug(Logginglevel.WARN, 'ROLLUP ROW: ' + r);
    
                // get the ids
                id cid = (id)(r.get('contactId'));
                id hhid = (id)(r.get('hhid'));
                    
                // process the result row, copying it into the contact record(s)
                // MS: we only want to fully calc the row if it is from the last few years - older years are only for calcing Best Year for contacts
                integer yr = (integer)r.get('CalendarYr');
                if (cid == null) { 
                    /*if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r);*/
                    if (hhid != null && (yr >= startYear || yr==null) ) updateRollupFromResult((sobject)(householdsToUpdate.get(hhid)), r, opptyCurrencies);
                    // after doing regular processing, calc Best Contact Year stuff
                    // the rows are in year order, so just look start w/ the first yr, and increase as needed as we go
                    decimal yrAmt = (decimal)r.get('TotalOppAmount');
                    household__c HH = householdsToUpdate.get(hhid);
    
                } else {
                    // contact row
                    if ( yr >= startYear || yr==null) {
                        /*updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r);*/
                        updateRollupFromResult((sobject)(contactsToUpdate.get(cid)), r, opptyCurrencies);
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
            soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.SYSTEMIsIndividual__c = true) ';   
            soqlStatement += 'AND (contact.household__c IN : hhIds ) ';// OR  ';
            //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
            soqlStatement += 'AND opportunity.closeDate >= LAST_N_DAYS:' + ndayrollup + ' ';
            soqlStatement += 'GROUP BY ROLLUP(contact.household__c, contactId) ';
            soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
            
           objectList.clear();
           objectList = database.query(soqlStatement);
                
           for (sobject r : objectList) {
    
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
                soqlStatement += 'MIN(Opportunity.membership_start_date__c) FirstStartDate, '; 
                soqlStatement += 'MAX(Opportunity.Membership_End_Date__c) LastEndDate,  ';
                soqlStatement += 'MAX(contact.household__r.MembershipEndDate__c) HHMembershipEnddate, ';
                soqlStatement += 'COUNT_DISTINCT(Opportunity.Id) NumberOfClosedOpps, ';
                soqlStatement += 'MAX(Opportunity.CombinedRollupFieldset__c) RollupFieldset ';
                soqlStatement += 'FROM OpportunityContactRole  ';
                soqlStatement += 'WHERE isPrimary=true AND opportunity.isWon=true '; 
                soqlStatement += 'AND (Opportunity.Amount != null) '; 
                if(areRecordTypesOnOpps()){
                    soqlStatement += 'AND Opportunity.RecordTypeId IN : mbrRecordTypes ';
                }
                soqlStatement += 'AND Opportunity.Type NOT IN : oppTypesToExcludeCons ';
                soqlStatement += 'AND (opportunity.accountid = null OR opportunity.account.SYSTEMIsIndividual__c = true)  '; 
                soqlStatement += 'AND (contact.household__c IN : hhIds ) '; //OR  ';
                //soqlStatement += '(contact.household__c = null AND contactid IN :conids)) ';
                soqlStatement += 'GROUP BY CUBE(contact.household__c, contactId) ';
                soqlStatement += 'HAVING (contactId IN : conIds OR contactId = null) ';
               
                objectList.clear();
                objectList = database.query(soqlStatement);
                
                // invokes code to get the currency of CombinedRollupFieldset__c oppty
                opptyCurrencies = (isMultiCurrency() ? rcfFindCurrency(objectList) : null);
                
                for (sobject r : objectList) {
                            
                    // get the ids
                    id cid = (id)(r.get('contactId'));
                    id hhid = (id)(r.get('hhid'));
                        
                    // process the result row, copying it into the contact record(s)
                    if (cid == null) { 
                        if (hhid != null)
                            /*updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r);*/
                            updateRollupFromResultMembership((sobject)(householdsToUpdate.get(hhid)), r, opptyCurrencies);
                    } else {
                        // contact row  
                        /*updateRollupFromResultMembership((sobject)(contactsToUpdate.get(cid)), r);*/
                        updateRollupFromResultMembership((sobject)(contactsToUpdate.get(cid)), r, opptyCurrencies);
                    }
                }
            }
        }

        // remove any records that have not changed
        for (id cid : conIds) {
            contact c1 = cmap.get(cid);
            contact c2 = contactsToUpdate.get(cid);
            if ((c1.TotalOppAmount__c == c2.TotalOppAmount__c &&
                    c1.OppAmountLastYear__c == c2.OppAmountLastYear__c && 
                    c1.OppAmount2YearsAgo__c == c2.OppAmount2YearsAgo__c &&
                    c1.OppAmountLastNDays__c == c2.OppAmountLastNDays__c &&
                    c1.OppAmountThisYear__c == c2.OppAmountThisYear__c &&
                    c1.TotalMembershipOppAmount__c == c2.TotalMembershipOppAmount__c &&
                    c1.LastCloseDate__c == c2.LastCloseDate__c &&
                    c1.MembershipEndDate__c == c2.MembershipEndDate__c &&
                    c1.MembershipJoinDate__c == c2.MembershipJoinDate__c
                    ) && hasContactRollups == false)
                contactsToUpdate.remove(cid);
        }
        for (id hhid : hhIds) {
            household__c hh1 = hhmap.get(hhid); 
            household__c hh2 = householdsToUpdate.get(hhid);
            if ((hh1.TotalOppAmount__c == hh2.TotalOppAmount__c && 
                    hh1.OppAmountLastNDays__c == hh2.OppAmountLastNDays__c &&
                    hh1.OppAmountThisYear__c == hh2.OppAmountThisYear__c &&
                    hh1.OppAmountLastYear__c == hh2.OppAmountLastYear__c &&
                    hh1.OppAmount2YearsAgo__c == hh2.OppAmount2YearsAgo__c &&
                    hh1.TotalMembershipOppAmount__c == hh2.TotalMembershipOppAmount__c &&
                    hh1.LastCloseDate__c == hh2.LastCloseDate__c &&
                    hh1.MembershipEndDate__c == hh2.MembershipEndDate__c && 
                    hh1.MembershipJoinDate__c == hh2.MembershipJoinDate__c
                    ) && hasHouseholdRollups == false)
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
                        if ((o.Is_Opp_From_Individual__c == 'true' || o.accountid == null) &&
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
                        if ((o.Is_Opp_From_Individual__c == 'true' || o.accountid == null) && includedRecordType
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
                        if (o.Is_Opp_From_Individual__c == 'true' || o.accountid == null) {
                            modifiedContactOpps.add(o.id);
//                          system.debug('Added to Cons to Update List' + o);
                        }
                        if (o.accountId != null) {
                            acctsToReroll.add(o.accountId); 
                        }
                    }       
                }           
            }   
            
//          system.debug('Modified Contact Opps' + modifiedContactOpps);
            
            // use the contact roles to find the contacts and households
            if (!modifiedContactOpps.isEmpty()) {

                if ((Limits.getLimitFutureCalls() - Limits.getFutureCalls()) > 5) {
//                  system.debug('Passed limit check for con rollup update');
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
                    /*amap = new map<id, account>(
                        [select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c,                        
                        LastCloseDate__c, NumberOfClosedOpps__c, TotalMembershipOppAmount__c,
                        OppAmountLastYear__c, OppAmount2YearsAgo__c, OppsClosedThisYear__c,
                        OppsClosedLastYear__c, OppsClosedLastNDays__c, OppsClosed2YearsAgo__c 
                        from account where id in :acctsToReroll ]);*/
                    amap = new map<id, account>((list<Account>)Database.query('select id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c,'+ 
                       'LastCloseDate__c, NumberOfClosedOpps__c, TotalMembershipOppAmount__c,'+
                       'OppAmountLastYear__c, OppAmount2YearsAgo__c, OppsClosedThisYear__c,'+
                       'OppsClosedLastYear__c, OppsClosedLastNDays__c, OppsClosed2YearsAgo__c '+
                       (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+             
                       'from account where id in :acctsToReroll'));
                  
                    decimal oppCount = amap.values()[0].NumberOfClosedOpps__c;
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
        list<account> topAccount = [select NumberOfClosedOpps__c from account 
            where NumberOfClosedOpps__c != null 
            order by NumberOfClosedOpps__c desc limit 1];
        if (!topAccount.isEmpty()) {
            decimal highestCount = topAccount[0].NumberOfClosedOpps__c;
            if (highestCount > 15) {
                batchSize = (3000 / highestCount).intValue() + 1;
            }
        }

        // start the batch to roll up all accounts
        BATCH_OppRollup batch = new BATCH_OppRollup( 'SELECT id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastNDays__c, ' +  
        'LastCloseDate__c, NumberOfClosedOpps__c, TotalMembershipOppAmount__c, ' +
        'OppAmountLastYear__c, OppAmount2YearsAgo__c, OppsClosedThisYear__c, ' +
        'OppsClosedLastYear__c, MembershipJoinDate__c, MembershipEndDate__c, OppsClosedLastNDays__c, OppsClosed2YearsAgo__c ' +
        (isMultiCurrency() ? ', CurrencyIsoCode ' : '') + 
        'FROM account' + (isTest ? ' WHERE name like \'%test%\' LIMIT 200' : '') );
        id batchProcessId = database.executeBatch(batch, batchSize);        
    }   
        
    public void rollupAllContacts() {

        // we can handle up to 10000 query rows total, which is about 3000 opps in a batch
        // this calculation very conservatively reduces batch size to avoid hitting the limit
        integer batchSize = 200;
        list<household__c> topHousehold = [select NumberOfClosedOpps__c from household__c 
            where NumberOfClosedOpps__c != null 
            order by NumberOfClosedOpps__c desc limit 1];
        if (!topHousehold.isEmpty()) {
            decimal highestCount = topHousehold[0].NumberOfClosedOpps__c;
            if (highestCount > 15) {
                batchSize = (3000 / highestCount).intValue() + 1;
            }
        }

        BATCH_OppRollup batch = new BATCH_OppRollup( 'SELECT id, TotalOppAmount__c, ' +
            'OppAmountThisYear__c, TotalMembershipOppAmount__c, ' +
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipJoinDate__c, MembershipEndDate__c, ' +
            'OppAmountLastNDays__c, LastCloseDate__c, NumberOfClosedOpps__c ' +
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+              
            ' FROM household__c ' + 
            (isTest ? ' WHERE lastname like \'%doppleganger%\' LIMIT 200' : '') );
        id batchProcessId = database.executeBatch(batch, batchSize);        
    }

    public static void updateRollupFromResult(sobject obj, sobject r, map<id, Opportunity> opptyCurrencies) {
    // used for single and batch rollups, this maps query results to the right fields

        // get the fiscal year, total amount, and opp count for this result row     
        integer fy = (integer)(r.get('CalendarYr'));
        decimal amt = (decimal)(r.get('TotalOppAmount'));
        integer cnt = (integer)(r.get('NumberOfClosedOpps'));               
        
        // split the special field to get the last opp id and amount
        string[] rcf = ((string)(r.get('RollupFieldset'))).split(';\\|;',-4);
        decimal lastAmt = (rcf.size() > 1 && rcf[1] != '') ? decimal.valueOf(rcf[1]) : null;
        
        // calculate amounts into correct currency if needed
        if(isMultiCurrency()){
            amt = ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),amt);
            if(lastAmt != null && rcf.size() > 4 && rcf[4] != '')
                lastAmt = ConvertCurrency((string)opptyCurrencies.get((Id)rcf[4]).get('CurrencyISOCode'),(string)obj.get('CurrencyIsoCode'),lastAmt);           
        }
        
        // check if this is an annual total or account total
        if (fy != null) {

            // put the fiscal year total in the right fields
            integer thisYear = system.today().year();
            if (fy == thisYear) {
                obj.put('OppAmountThisYear__c', amt); 
                obj.put('OppsClosedThisYear__c', cnt); 
            } else if (fy == (thisYear - 1)) {
                obj.put('OppAmountLastYear__c', amt); 
                obj.put('OppsClosedLastYear__c', cnt); 
            } else if (fy == (thisYear - 2) ) {
                obj.put('OppAmount2YearsAgo__c', amt); 
                obj.put('OppsClosed2YearsAgo__c', cnt); 
            } 
                
        } else { 

            // fill in summary totals
            obj.put('TotalOppAmount__c', amt);
            obj.put('NumberOfClosedOpps__c', cnt);               
            obj.put('LastOppAmount__c', lastAmt);
            obj.put('FirstCloseDate__c', r.get('FirstCloseDate')); //date
            obj.put('LastCloseDate__c', r.get('LastCloseDate')); //date
            
            // calculate amounts into correct currency if needed
            if(isMultiCurrency())
            {
               obj.put('AverageAmount__c', ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),(decimal)r.get('AverageAmount'))); 
               obj.put('SmallestAmount__c', ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),(decimal)r.get('SmallestAmount'))); 
               obj.put('LargestAmount__c', ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),(decimal)r.get('LargestAmount'))); 
            }
            else
            {
               obj.put('AverageAmount__c', (decimal)(r.get('AverageAmount'))); 
               obj.put('SmallestAmount__c', (decimal)(r.get('SmallestAmount'))); 
               obj.put('LargestAmount__c', (decimal)(r.get('LargestAmount'))); 
            }
        }
        
        //deal with user rollups
        if (userRollups.size() > 0){
            for (string s : userRollups.keyset()){
                if (obj.getSObjectType().getDescribe().getName() == userRollups.get(s).Object_Name__c){
                	User_Rollup_Field_Settings__c urfs = userRollups.get(s);
                	string x = urfs.Name;
                	if (r.get(x) != null)
                	   obj.put(urfs.Target_Field__c, r.get(x));
                }
            }
        }
    }

    public static void updateRollupFromResultLastNDays(sobject obj, sobject r) {
    // used for single and batch rollups, this maps query results to the right fields
        
        // get the fiscal year, total amount, and opp count for this result row     
        decimal amt = (decimal)(r.get('TotalOppAmount'));
        integer cnt = (integer)(r.get('NumberOfClosedOpps'));               
        
        // calculate amounts into correct currency if needed
        if(isMultiCurrency())
           amt = ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),amt);
        
        // fill in totals
        obj.put('OppAmountLastNDays__c', amt);               
        obj.put('OppsClosedLastNDays__c', cnt);
    }

    public static void updateRollupFromResultMembership(sobject obj, sobject r, map<id, Opportunity> opptyCurrencies) {
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
        // calculate amounts into correct currency if needed
        if(isMultiCurrency()){
           amt = ConvertFromCorporate((string)obj.get('CurrencyIsoCode'),amt);
           if(lastAmt != null && rcf.size() > 4 && rcf[4] != '')
               lastAmt = ConvertCurrency((string)opptyCurrencies.get((Id)rcf[4]).get('CurrencyISOCode'),(string)obj.get('CurrencyIsoCode'),lastAmt);           
        }

        // check if this is an annual total or account total
/* ADD FIELDS AND UNCOMMENT IF YOU NEED ANNUAL MEMBERSHIP TOTAL BREAKOUT
        if (fy != null) {

            // put the fiscal year total in the right fields
            integer thisYear = system.today().year();
            
            if (fy == thisYear) {
                obj.put('MembershipOppAmountThisYear__c', amt); 
                obj.put('MembershipOppsThisYear__c', cnt); 
            } else if (fy == (thisYear - 1)) {
                obj.put('MembershipOppAmountLastYear__c', amt); 
                obj.put('MembershipOppsLastYear__c', cnt); 
            } else if (fy == (thisYear - 2) ) {
                obj.put('MembershipOppAmount2YearsAgo__c', amt); 
                obj.put('MembershipOpps2YearsAgo__c', cnt); 
            } 
        } else {
*/              
            // fill in summary totals
            obj.put('TotalMembershipOppAmount__c', amt);
            obj.put('NumberOfMembershipOpps__c', cnt);               
            obj.put('LastMembershipDate__c', (date)(r.get('LastCloseDate')));                
            obj.put('LastMembershipAmount__c', lastAmt);                 
            obj.put('LastMembershipLevel__c', lastMemberLevel);              
            obj.put('LastMembershipOrigin__c', lastMemberOrigin);                
            obj.put('MembershipJoinDate__c', (date)(r.get('FirstStartDate'))); 
            obj.put('MembershipEndDate__c', (date)(r.get('LastEndDate')));               
//      }
    } 
    
    /*********** Multi-Currency Support Methods ***********/

    //returns a boolean if we are in a multi-currency org or not.
    //on first execution sets up static variables etc
    public static boolean isMultiCurrency(){
    	
        if (multiCurrency==null){
            //create currency field handles for later dynamic dml
            cfOppty = Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode');
            cfAccount = Schema.sObjectType.Account.fields.getMap().get('CurrencyIsoCode');
            cfHousehold = Schema.sObjectType.household__c.fields.getMap().get('CurrencyIsoCode');
            cfContact = Schema.sObjectType.Contact.fields.getMap().get('CurrencyIsoCode');

            String queryExchangeRates = 'select IsoCode,ConversionRate,IsCorporate from CurrencyType';
            SObjectType soCurrencyType = Schema.getGlobalDescribe().get('CurrencyType'); 

            //are we in a multi-currency org?
            if (cfOppty != null && cfAccount != null && cfHousehold != null && cfContact != null && soCurrencyType != null){
                multiCurrency = true;
 
                map<string,SObjectField> ctFields = soCurrencyType.getDescribe().fields.getMap();
                SObjectField ctIsoCode = ctFields.get('IsoCode');
                SObjectField ctConversionRate = ctFields.get('ConversionRate');
                SObjectField ctCorporate = ctFields.get('IsCorporate');

                //iterate over all the currencies in the org (inc. inactive ones as they may have been used previously)
                //this allows us to put them in a map and use the ISO code as key and also set the corporate
                for(sObject ct: Database.query(queryExchangeRates)){
                    exchangeRates.put((string)ct.get(ctIsoCode),(decimal)ct.get(ctConversionRate));
                    if((boolean)ct.get(ctCorporate))currCorporate=(string)ct.get(ctIsoCode);
                }
            }
            else
                multiCurrency = false; 
        }
        
        return multiCurrency;
        }

    //do a conversion from amount in corporate currency to the currency specified by the ISO code
    public static decimal ConvertFromCorporate(String ISO,Decimal amt){
        if(currCorporate == ISO || currCorporate == null) // no need to convert
            return amt;
        else //return value to 2DP
            return (amt * exchangeRates.get(ISO)).setScale(2) ;
    }

    public static decimal ConvertCurrency(String fromISO, String toISO, Decimal amt){
        if(fromISO == toISO) // no need to convert
            return amt;
        else //return value to 2DP
            return ((amt / exchangeRates.get(fromISO)) * exchangeRates.get(toISO)).setScale(2) ;
    }
 
    //takes the Ids of opptys in the CombinedRollupFieldset__c field, and looks up the currency of that record
    //only used in multi currency orgs
    //returns a map of those Ids and the associated oppty
    public map<Id,Opportunity> rcfFindCurrency(list<sobject> objectList){
        //new set to hold the opptys we need to query for
        set<Id> opptysForCurrency = new set<Id>();

        //iterate over objects provided to us
        for (sobject r : objectList){
            //pull Id from rollup field and add to set
            string[] rcf = ((string)(r.get('RollupFieldset'))).split(';\\|;',-4);
            if(rcf.size() > 1 && rcf[1] != '')
                opptysForCurrency.add((Id)rcf[4]);
        }
        
        if (!objectlist.isEmpty()){
            //query for oppty and currencycode for all Ids in set.
            string soqlStatement = 'SELECT Id,CurrencyIsoCode FROM Opportunity WHERE Id in :opptysForCurrency';
            map<Id,Opportunity> opptyCurrencies = new map<Id,Opportunity>((list<Opportunity>)Database.query(soqlStatement));
            return opptyCurrencies;
        }
        else
            return null;
        
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
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
            //add a null amount opp
            
            newOpps.add(new Opportunity(
                Name = 'Test Opp 45',
                CloseDate = datClose,
                StageName = UnitTestData.getClosedWonStage(),
                Contact_Id_for_Role__c = TestCons[0].Id));
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            //also exercise the non-future methods to make sure the code runs
            /*household__c[] hhs = [SELECT id, TotalOppAmount__c, LastCloseDate__c, TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipEndDate__c, MembershipJoinDate__c FROM household__c WHERE id = :UpdatedCon.household__r.id LIMIT 1];*/
            
            id hhid = UpdatedCon.household__r.id;
            
            household__c[] hhs = database.query('SELECT id, TotalOppAmount__c, LastCloseDate__c, '+
            'TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, '+
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipEndDate__c, MembershipJoinDate__c '+
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM household__c WHERE id = :hhid LIMIT 1');

            rg = new OpportunityRollups();
            rg.rollupHousehold(hhs[0].id);
            rg = new OpportunityRollups();
            rg.rollupHouseholds(hhs);
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
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
            
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.BUCKET_PROCESSOR,
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
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c, household__r.MembershipEndDate__c, MembershipJoinDate__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            //also exercise the non-future methods to make sure the code runs
            /*household__c[] hhs = [SELECT MembershipJoinDate__c, MembershipEndDate__c, id, TotalOppAmount__c, LastCloseDate__c, TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM household__c WHERE id = :UpdatedCon.household__r.id LIMIT 1];*/
            
            id hhid = UpdatedCon.household__r.id;
            household__c[] hhs = database.query('SELECT id, TotalOppAmount__c, LastCloseDate__c, '+
            'TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, '+
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipJoinDate__c, MembershipEndDate__c '+
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM household__c WHERE id = :hhid LIMIT 1');
            
            rg = new OpportunityRollups();
            rg.rollupHousehold(hhs[0].id);
            rg = new OpportunityRollups();
            rg.rollupHouseholds(hhs);
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
        
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
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 0 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 0 , UpdatedCon.household__r.TotalOppAmount__c );        
            System.AssertEquals ( 0 , UpdatedCon.OppAmountThisYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            //also exercise the non-future methods to make sure the code runs
            /*household__c[] hhs = [SELECT id, MembershipJoinDate__c, MembershipEndDate__c, TotalOppAmount__c, LastCloseDate__c, TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM household__c WHERE id = :UpdatedCon.household__r.id LIMIT 1];*/
            id hhid = UpdatedCon.household__r.id;
            household__c[] hhs = database.query('SELECT id, TotalOppAmount__c, LastCloseDate__c, '+
            'TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, '+
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipJoinDate__c, MembershipEndDate__c '+
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM household__c WHERE id = :hhid LIMIT 1');
            
            rg = new OpportunityRollups();
            rg.rollupHousehold(hhs[0].id);
            rg = new OpportunityRollups();
            rg.rollupHouseholds(hhs);
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 0 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 0 , UpdatedCon.household__r.TotalOppAmount__c );        
            System.AssertEquals ( 0 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
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
            
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                AccountId = testacct.id,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
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
            Contact UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            //also exercise the non-future methods to make sure the code runs
            /*household__c[] hhs = [SELECT id, TotalOppAmount__c, LastCloseDate__c, TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipEndDate__c, MembershipJoinDate__c FROM household__c WHERE id = :UpdatedCon.household__r.id LIMIT 1];*/
            id hhid = UpdatedCon.household__r.id;
            household__c[] hhs = database.query('SELECT id, TotalOppAmount__c, LastCloseDate__c, '+
            'TotalMembershipOppAmount__c, OppAmountLastNDays__c, OppAmountThisYear__c, '+
            'OppAmountLastYear__c, OppAmount2YearsAgo__c, MembershipEndDate__c, MembershipJoinDate__c '+
            (isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM household__c WHERE id = :hhid LIMIT 1');
            
            rg = new OpportunityRollups();
            rg.rollupHousehold(hhs[0].id);
            rg = new OpportunityRollups();
            rg.rollupHouseholds(hhs);
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, household__c, household__r.TotalOppAmount__c, TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.household__r.TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.OppAmountLastYear__c);
        
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
            newOpps[0].Membership_Origin__c = 'Renewal';
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, TotalMembershipOppAmount__c,LastMembershipOrigin__c,
                LastMembershipAmount__c, LastMembershipDate__c 
                from contact where id =: firstconid];
            System.AssertEquals ( 100 , updatedcon.TotalMembershipOppAmount__c );        
            System.AssertEquals ( 100 , updatedcon.LastMembershipAmount__c );        
            System.AssertEquals ( 'Renewal' , updatedcon.LastMembershipOrigin__c );      
            System.AssertEquals ( system.today() , updatedcon.LastMembershipDate__c );   
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
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
            account updatedAcct = [select id, TotalOppAmount__c from account where id =: testacct.id];       
            System.AssertEquals ( 33333 , updatedAcct.TotalOppAmount__c );       
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAccount(testacct.id);
    
            updatedAcct = [select id, TotalOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.TotalOppAmount__c );           
        
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
    
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            opportunity newOpp =
                 new opportunity (name = 'testopp', accountid = testacct.id, 
                                    member_level__c = 'Gold', membership_origin__c = 'New',
                                    stagename=UnitTestData.getClosedWonStage(), closedate=datClose, amount=33333);
            newOpp.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', householdSettingsForTests.Membership_Record_Types__c));
            // insert the opp(s)
            Test.StartTest();
            insert newOpp;
            Test.StopTest();
            // test whether the trigger worked      
            account updatedAcct = [select id, TotalMembershipOppAmount__c, LastMembershipDate__c,
                LastMembershipAmount__c, LastMembershipLevel__c, LastMembershipOrigin__c
                from account where id =: testacct.id];      
            System.AssertEquals ( 33333 , updatedAcct.TotalMembershipOppAmount__c );     
            System.AssertEquals ( system.today() , updatedAcct.LastMembershipDate__c );      
            System.AssertEquals ( 33333 , updatedAcct.LastMembershipAmount__c );     
            System.AssertEquals ( 'Gold' , updatedAcct.LastMembershipLevel__c );     
            System.AssertEquals ( 'New' , updatedAcct.LastMembershipOrigin__c );
            
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAccount(testacct.id);
    
            updatedAcct = [select id, TotalMembershipOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.TotalMembershipOppAmount__c );     
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
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
            Contact UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 160 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c );
            System.AssertEquals ( 60 , UpdatedCon.OppAmountLastYear__c );
    
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
            UpdatedCon = [SELECT Id, TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c  FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 75 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 50 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            
            system.debug ( 'TEST>>>>> inserting gift 3...');
    
            // now create a gift from 2 yrs ago
            Opportunity[] testGift3 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat2YearAgo, 10 , giftRecordTypeNameForTests,null);
    
            insert testGift3;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
    
            ThisConId = TestCons[0].id;
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 85 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 50 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.OppAmount2YearsAgo__c );
    
            // add another from this year (to test adding)
            system.debug ( 'TEST>>>>> inserting gift 4...');
            Opportunity[] testGift4 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 25 , giftRecordTypeNameForTests,null);
    
            insert testGift4;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
    
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 110 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.OppAmount2YearsAgo__c );
    
            // TBD add a gift from longer ago
            system.debug ( 'TEST>>>>> inserting gift 5...');
            Opportunity[] testGift5 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat4YearAgo, 200 , giftRecordTypeNameForTests,null);
    
            insert testGift5;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            // totals should not have changed, except lifetime & best yr
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 310 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.OppAmount2YearsAgo__c );       
            
            // TBD add non-won gift
            system.debug ( 'TEST>>>>> inserting gift 6...');
            Opportunity[] testGift6 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getOpenStage(), dat4YearAgo, 35 , giftRecordTypeNameForTests,null);
    
            insert testGift6;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            // totals should not have changed at all
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 310 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.OppAmount2YearsAgo__c );       
                    
            // now delete the 1st gift (now at $50), totals should decrease
            system.debug ( 'TEST>>>>> deleting gift 1...'); 
            delete testGift1;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContact(testcons[0].id);
            
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 260 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 25 , UpdatedCon.OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.OppAmount2YearsAgo__c );               
            
            /*
            // finally add a larger gift from several yrs ago to test the best gift yr going earlier than other stats
            system.debug ( 'TEST>>>>> inserting gift 7...');
            Opportunity[] testGift7 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday.addYears(-5), 200 , 'Gift',null);
            ONEN_OpportunityContactRoles.haveCheckedContactRoles = false;
            insert testGift7;
    
            UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c, Best_Gift_Year__c, Best_Gift_Year_Total__c  FROM Contact WHERE Id = :ThisConId];
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
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
            contact UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
        
            System.Assert( !(UpdatedCon.TotalOppAmount__c>0) );
            
            //testGift1[0].Type = 'Cash';
            //update testGift1;
            
            //UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            //System.AssertEquals ( 100 , UpdatedCon.TotalOppAmount__c );
        
    
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
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
            Contact UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
            
            System.AssertEquals ( 150 , UpdatedCon.TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.OppAmountThisYear__c );       
            System.AssertEquals ( 50 , UpdatedCon.OppAmountLastYear__c );
            System.AssertEquals ( 0 , UpdatedCon.OppAmount2YearsAgo__c );
        
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
        
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;
            
            // create new opps
            Opportunity[] newOpps1 = new Opportunity[0];
            for (integer n = 0; n < 450; n++) {
                Opportunity newOpp1 = new opportunity(Contact_Id_for_Role__c = TestCons[0].id,
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
            Contact UpdatedCon = [SELECT Id,  TotalOppAmount__c, OppAmountThisYear__c, OppAmountLastYear__c, OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
            
            System.AssertEquals ( 45000 , UpdatedCon.TotalOppAmount__c );
        
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
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact
            Contact Con1 = new contact(
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            );
            insert Con1;
            
            Contact con = [SELECT household__r.id FROM Contact WHERE id = :Con1.id LIMIT 1];
            
            // create & insert second household member
            Contact Con2 = new contact(
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second',
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                household__c = con.household__c
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
                FROM Contact WHERE LastName=:Constants.CONTACT_LASTNAME_FOR_TESTS AND FirstName=:Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second' LIMIT 1];
            System.assertEquals (375,c.Total_Household_Gifts__c);
            System.assertEquals (100,c.OppAmountThisYearHH__c);
            System.assertEquals (0,c.OppAmountLastYearHH__c);
            System.assertEquals (datClose,c.LastCloseDateHH__c );
            System.assertEquals (375,c.Total_Household_Gifts__c);
                
    }
    
    	
    static testMethod void testUserDefinedRollup() {
        isTest = true;

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
        Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
    
        //need to clear out any existing user fields
        //otherwise we can't insert of stuff referenced by apex
        list<User_Rollup_Field_Settings__c> deleteUserSettings = new list<User_Rollup_Field_Settings__c>();
        deleteUserSettings = [select id from User_Rollup_Field_Settings__c];
        delete deleteUserSettings;
        
        list<User_Rollup_Field_Settings__c> testURFS = new list<User_Rollup_Field_Settings__c>();
                
        User_Rollup_Field_Settings__c testUserRollup1 = new User_Rollup_Field_Settings__c();
        testUserRollup1.Target_Field__c = 'Birthdate'; 
        testUserRollup1.Source_Field__c = 'CloseDate';
        testUserRollup1.Object_Name__c = 'Contact'; 
        testUserRollup1.Field_Action__c = 'MAX';
        testUserRollup1.Name = 'TestRollup1';
        testURFS.add(TestUserRollup1);
        
        User_Rollup_Field_Settings__c TestUserRollup2 = new User_Rollup_Field_Settings__c();
        testUserRollup2.Target_Field__c = 'MembershipEndDate__c'; 
        testUserRollup2.Source_Field__c = 'CloseDate';
        testUserRollup2.Object_Name__c = 'Account'; 
        testUserRollup2.Field_Action__c = 'MAX';
        testUserRollup2.Name = 'TestRollup2';
        testURFS.add(TestUserRollup2);
        
        User_Rollup_Field_Settings__c testUserRollup3 = new User_Rollup_Field_Settings__c();
        testUserRollup3.Target_Field__c = 'LastCloseDate__c'; 
        testUserRollup3.Source_Field__c = 'CloseDate';
        testUserRollup3.Object_Name__c = 'Household__c'; 
        testUserRollup3.Field_Action__c = 'MAX';
        testUserRollup3.Name = 'TestRollup3';
        testURFS.add(TestUserRollup3);
        
        insert testURFS; 
        
        Contact c = new Contact(LastName = 'Lastname', BirthDate = system.today().addDays(-4));
        insert c;
        
        id rtid = RecordTypes.GetRecordTypeId ('Opportunity',RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ',
                Amount = 100,
                CloseDate = system.today().adddays(-2),
                StageName = UnitTestData.getClosedWonStage(),
                Contact_Id_for_Role__c = c.Id                                
            );  
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
         
    Test.StartTest();
    insert newOpp;
    Test.StopTest();     
    
    Contact ct = [select Birthdate, OppAmountThisYearHH__c from Contact where id = :c.id];
    system.assertEquals (100,ct.OppAmountThisYearHH__c);    
    system.assertEquals(system.today().addDays(-2), ct.BirthDate);    
    
    }
    
    static testMethod void testMultiCurrencyMethods(){
    	
    	//exercise internal multicurrency helper methods, check currency conversion    	    	
        decimal d = OpportunityRollups.ConvertFromCorporate('USD', 55.00);    	
    	d = OpportunityRollups.ConvertCurrency('USD', 'USD', 55.00);


        //create & insert second household member
        Contact Con = new contact(
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS                
            );
            insert Con;
            
        Contact[] TestCons = new Contact[] {Con}; 
        
        // create new opps
        Opportunity o = new Opportunity(
            Name = 'MyContactOpportunity',
            StageName = 'Closed Won',
            CloseDate = system.today(),
            Contact_Id_for_Role__c = con.Id  
        );        
        insert o;
        
        list<sobject> sobjectlist = new list<sobject>();
        //sobjectlist.add(o);
        
        OpportunityRollups opproll = new OpportunityRollups();
    	map<Id, Opportunity> omap = opproll.rcfFindCurrency(sobjectList);
    }
    
    static testMethod void testFiscalYearandCustomNDay () {
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
                    Membership_Record_Types__c = null,                     
                    Use_Fiscal_Year_for_Rollups__c = true, 
                    Rollup_N_Day_Value__c = 10
                ));
                
            Contacts_and_Orgs_Settings__c contactSettingsForTests = Constants.getContactsSettingsForTests(new Contacts_and_Orgs_Settings__c (
                Account_Processor__c = Constants.ONE_TO_ONE_PROCESSOR,
                Enable_Opportunity_Contact_Role_Trigger__c = true,
                Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
        
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;
            
            // create 2 new opps
            Opportunity[] newOpps1 = new Opportunity[0];
            
            Opportunity newOpp1 = new opportunity(Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp ', 
                    stagename = UnitTestData.getClosedWonStage(), closedate = system.today(), amount = 100);
               if(areRecordTypesOnOpps())
                    newOpp1.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add( newOpp1);
            
            Opportunity newOpp2 = new opportunity(Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp 2', 
                    stagename = UnitTestData.getClosedWonStage(), closedate = system.today().adddays(-40), amount = 100);
               if(areRecordTypesOnOpps())
                    newOpp2.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add(newOpp2);
           
            // insert the opp(s)
            Test.StartTest();
            insert newOpps1;
            Test.StopTest();
    
            system.assertEquals([select OppAmountLastNDays__c from Contact where id = :TestCons[0].id].OppAmountLastNDays__c, 100);
    
    }
}
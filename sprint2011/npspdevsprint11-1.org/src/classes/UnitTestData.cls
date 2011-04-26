public class UnitTestData { 

// create data for use in unit tests
// should not be referenced by production code
    public static string closedWonStage;
    public static string closedLostStage;
    public static string openStage;
    
    public static String getClosedWonStage(){
        if (closedWonStage == null){
            List<OpportunityStage> closedWonStages = [select masterlabel from opportunitystage where isActive = true and iswon = true];
            
            if(closedWonStages.size()>0){
                closedWonStage = closedWonStages[0].masterlabel;
            } else {
                closedWonStage = '';
            }
        }
        
        return closedWonStage;
    }
    /*
    public static String getClosedLostStage(){
        if (closedLostStage == null){
            List<OpportunityStage> closedLostStages = [select masterlabel from opportunitystage where isActive = true and iswon = false and isClosed = true];
            
            if(closedLostStages.size()>0){
                closedLostStage = closedLostStages[0].masterlabel;
            } else {
                closedLostStage = '';
            }
        }
        
        return closedLostStage;
    }
    */
    public static String getOpenStage(){
        if (openStage == null){
            List<OpportunityStage> openStages = [select masterlabel from opportunitystage where isActive = true and iswon = false];
            
            if(openStages.size()>0){
                openStage = openStages[0].masterlabel;
            } else {
                openStage = '';
            }
        }
        
        return openStage;
    }
    
    Public static list<Contact> CreateMultipleTestContacts (integer n) {
        
        list<contact> ContactsToAdd = New list<contact> ();
        
        for (integer i=0;i<n;i++) {
            Contact newCon = New Contact (
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                OtherCity = 'Seattle'
            );
            ContactsToAdd.add (newCon);
        }
        
        // testing doing the insert in the calling code - will maybe reinstate this
        //insert ContactsToAdd;
        
        return ContactsToAdd;
    }
    /*
    Public static list<Contact> CreateMultipleTestContactsInHouseholds (List<Contact> firstContactList) {
        
        list<contact> ContactsToAdd = New list<contact> ();
        
        for (integer i=0;i<firstContactList.size();i++) {
            Contact newCon = New Contact (
                FirstName= Constants.CONTACT_FIRSTNAME_FOR_TESTS + i,
                LastName= Constants.CONTACT_LASTNAME_FOR_TESTS,
                Private__c=false,
                WorkEmail__c = Constants.CONTACT_EMAIL_FOR_TESTS, 
                Preferred_Email__c = Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                WorkPhone__c = Constants.CONTACT_PHONE_FOR_TESTS,
                PreferredPhone__c = Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                OtherCity = 'Seattle',
                Household__c = firstContactList[i].Household__c
            );
            ContactsToAdd.add (newCon);
        }
        
        // testing doing the insert in the calling code - will maybe reinstate this
        //insert ContactsToAdd;
        
        return ContactsToAdd;
    }
    */
    Public static list<Opportunity> OppsForContactList (list<Contact> Cons, id CampId, string Stage, date Close, double Amt, string rectype, string oppType) {
     
        // given a list of Contacts,
        // add one Opp per contact w/ the specified data
        // TBD should allow specifying rectype (optional)
    
        list<Opportunity> OppsToAdd = new list<Opportunity> ();
        id rtid = RecordTypes.GetRecordTypeId ('Opportunity',rectype);
        system.debug('recordtypeintest: ' + rtid);
        for ( Contact thisCon : Cons ) {
            Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ' + thisCon.FirstName + thisCon.LastName,
                Amount = Amt,
                CloseDate = Close,
                StageName = Stage,
                CampaignId = CampId,
                Contact_Id_for_Role__c = thisCon.Id,
                type = oppType                
            );  
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            OppsToAdd.add (newOpp);
        }
        
        return OppsToAdd;
        
    }
    

/*
    Public static list<Account> CreateMultipleTestAccounts (integer n) {
        
        list<Account> AcctsToAdd = New list<Account> ();
        
        for (integer i=0;i<n;i++) {
            Account newAcct = New Account (
                Name = 'Yet Another Org ' + i
            );
            AcctsToAdd.add (newAcct);
        }
        
        return AcctsToAdd;
    }
  */  
/*
        Public static list<Opportunity> OppsForAccountList (list<Account> Accts, id CampId, string Stage, date Close, double Amt, string rectype) {
    
        // given a list of accounts,
        // add one Opp per acct w/ the specified data
    
        list<Opportunity> OppsToAdd = new list<Opportunity> ();
        
        // look up the id for the specified rectype
        id rtid = RecordTypes.GetRecordTypeId ('Opportunity',rectype);
        
        for ( Account thisAcct : Accts) {
            Opportunity newOpp = New Opportunity (
                AccountId = thisAcct.id,
                Name = 'Test Opp ' + thisAcct.Name,
                Amount = Amt,
                CloseDate = Close,
                StageName = Stage,
                CampaignId = CampId,
                RecordTypeId = rtid
            );  
            OppsToAdd.add (newOpp);
        }
        
        return OppsToAdd;
        
    }
    */
    
    
  /*  
    Public Static CampaignMember CreateCampaignMember (id CampId, id ConId, string CMStatus) {
    
        CampaignMember newCM = new CampaignMember (
            CampaignId = CampId,
            ContactId = ConId,
            Status = CMStatus
        );
        
        insert newCM;
        return newCm;           
    }
*/
}
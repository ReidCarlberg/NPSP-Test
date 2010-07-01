public class UnitTestData { 

// create data for use in unit tests
// should not be referenced by production code

    Public static contact CreateTestContact (integer n) {
        
        // create one contact
        // integer identifies unique set of field values
        
        Contact newCon = New Contact ();
        
        if ( n == 1 ) {
            newCon.FirstName = 'Stringer';
            newCon.LastName = 'Bell';
            newCon.OtherCity = 'Baltimore';
        } else if (n==2) {
            newCon.FirstName = 'Avon';
            newCon.LastName = 'Barksdale';
            newCon.OtherCity = 'Baltimore';
        } else if (n==3) {
            newCon.FirstName = 'Lester';
            newCon.LastName = 'Freamon';
            newCon.OtherCity = 'Baltimore';
        }
        
//      insert newCon;
        return newCon;
    }
    
    Public static list<Contact> CreateMultipleTestContacts (integer n) {
        
        list<contact> ContactsToAdd = New list<contact> ();
        
        for (integer i=0;i<n;i++) {
            Contact newCon = New Contact (
                FirstName = 'Number' + i,
                LastName = 'Doppleganger',
                OtherCity = 'Seattle'
            );
            ContactsToAdd.add (newCon);
        }
        
        // testing doing the insert in the calling code - will maybe reinstate this
        //insert ContactsToAdd;
        
        return ContactsToAdd;
    }
    
    Public static list<Contact> CreateMultipleTestContactsInHouseholds (List<Contact> firstContactList) {
        
        list<contact> ContactsToAdd = New list<contact> ();
        
        for (integer i=0;i<firstContactList.size();i++) {
            Contact newCon = New Contact (
                FirstName = 'Second Number' + i,
                LastName = 'Doppleganger',
                OtherCity = 'Seattle',
                Household__c = firstContactList[i].Household__c
            );
            ContactsToAdd.add (newCon);
        }
        
        // testing doing the insert in the calling code - will maybe reinstate this
        //insert ContactsToAdd;
        
        return ContactsToAdd;
    }
    
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
                npe01__Contact_Id_for_Role__c = thisCon.Id,
                type = oppType                
            );  
            if(rtid != null){
            	newOpp.RecordTypeId = rtid;
            }
            OppsToAdd.add (newOpp);
        }
        
        return OppsToAdd;
        
    }
    


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
    
    
    
    
    Public Static CampaignMember CreateCampaignMember (id CampId, id ConId, string CMStatus) {
    
        CampaignMember newCM = new CampaignMember (
            CampaignId = CampId,
            ContactId = ConId,
            Status = CMStatus
        );
        
        insert newCM;
        return newCm;   
        
    }

}
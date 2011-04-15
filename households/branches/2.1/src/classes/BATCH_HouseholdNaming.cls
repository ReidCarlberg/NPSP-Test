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
global class BATCH_HouseholdNaming implements Database.Batchable<SObject> {
// batch apex class to name households in existing orgs
    
    public String query { get; set; }
    
    // constructors
    public BATCH_HouseholdNaming(string q) {  
    	system.debug('Q is==================' + q);
        query = q; 
    }
    
    global database.Querylocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);      
    }
    
    global public void execute(Database.BatchableContext bc, Sobject[] result) {
        // run rollups for this batch  
        HouseholdProcessControl.inFutureContext = true;     
        HouseholdNaming hn = new HouseholdNaming();
        list<id> hhids = new list<id>();
        for (sobject s : result)
            hhids.add(s.id);
        
        hn.UpdateNames(hhids);
    }

    global void finish(Database.BatchableContext bc) {
    }

    public static testMethod void testBatch() {
        
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
            new Households_Settings__c (
                Household_Rules__c = Households.ALL_PROCESSOR,
                Always_Rollup_to_Primary_Contact__c = true,
                Enable_Opp_Rollup_Triggers__c = true,
                Excluded_Account_Opp_Rectypes__c = null,
                Excluded_Account_Opp_Types__c = null,
                Excluded_Contact_Opp_Rectypes__c = null,
                Excluded_Contact_Opp_Types__c = null,
                Membership_Record_Types__c = null,
                Advanced_Household_Naming__c = true
            ));
            
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
           npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
           npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
           npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
            
                
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
            
        //get the household to be updated
        id hhid = [select Household__r.id from Contact where id = :testcons[0].id].id;                        
        system.debug('ID IS=================='+ hhid);    
        
        BATCH_HouseholdNaming batch = new BATCH_HouseholdNaming(
        'select id from household__c where id = \'' + hhid + '\' limit 200'
        );
            
        Test.StartTest(); 
            id batchProcessId = database.executeBatch(batch);
        Test.StopTest();
    }
    



}
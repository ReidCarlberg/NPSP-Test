public class CTRL_OpportunityRollup {
 
    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public CTRL_OpportunityRollup() {
        batchRunning = false;

        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {     
        }  
        
        if (oid != null) {
            batching = false;           
        } else {
            batching = true;
        }
    }
    
    public PageReference startAction() {
        PageReference ref;
        if (oid != null) {
            
            // run the rollup for the specified object
            OpportunityRollups rg = new OpportunityRollups();
            if (objectId.startsWith('001'))
                rg.RollupAccount(oid);
            else if (objectId.startsWith('003'))
                rg.RollupContact(oid);
            else 
                rg.RollupHousehold(oid);
                 
            ref = new PageReference('/' + oid);
            ref.setRedirect(true);
        }
        return ref;
    }

    public PageReference rollup() {
        
        // run batch rollup
        OpportunityRollups rg = new OpportunityRollups();
        rg.rollupAll();
        
        batchRunning = true;
        return null;                
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

    public static testMethod void testRollup() {
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
            
        // create & insert contact(s)
        Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 50 ) ;
        insert TestCons;

        // create new opps
        Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);

        account testacct = new account(name='testacct');
        insert testacct;

        Test.startTest();

        // create the page 
        PageReference pageRef=Page.OpportunityRollup; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', testcons[3].id);
        
        // instantiate the controller
        CTRL_OpportunityRollup controller=new CTRL_OpportunityRollup();

        // rollup the contact
        pageReference nextref = controller.startAction();       

        system.assert(nextref.getUrl().contains(testcons[3].id));
        
        // roll up everyone
        controller.rollup();
        controller.cancel();
    }

}
public with sharing class householdsSettings {
    
    public Households_Settings__c pageSettings = new Households_Settings__c();
    
    
    public householdsSettings(){
        acctRTs = new List<string>();
        acctTypes = new List<string>();
        contactRTs = new List<string>();
        contactTypes = new List<string>();
        
    }
    
    public Households_Settings__c getSettings() {
        pageSettings = Households.getHouseholdsSettings();
        return pageSettings;
    }
    //we can't do a DML in a getter, so I call it from the action of the page
    public PageReference getSettingsFirstTime() {
        pageSettings = Households.getHouseholdsSettings();
        //set the multi-select fields
        if(pageSettings.npo02__Excluded_Account_Opp_Types__c!=null){
        	acctTypes = pageSettings.npo02__Excluded_Account_Opp_Types__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Contact_Opp_Types__c!=null){
        	contactTypes = pageSettings.npo02__Excluded_Contact_Opp_Types__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Account_Opp_Rectypes__c!=null){
        	acctRTs = pageSettings.npo02__Excluded_Account_Opp_Rectypes__c.split(';',0);
        }
        
         if(pageSettings.npo02__Excluded_Contact_Opp_Rectypes__c!=null){
        	contactRTs = pageSettings.npo02__Excluded_Contact_Opp_Rectypes__c.split(';',0);
        }
        //look for the scheduled job and schedule it if necessary
        scheduleRollups();
            
        return null;
    }
    
    public List<SelectOption> contactRoles = new List<SelectOption>();
    public List<String> acctRTs {get;set;}
    public List<String> acctTypes {get;set;}
    public List<String> contactRTs {get;set;}
    public List<String> contactTypes {get;set;}
    
    public List<SelectOption> getcontactRoles() {
    
        if(contactRoles.size()==0){
            contactRoles.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.OpportunityContactRole.fields.Role; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            for(Schema.PicklistEntry pe : P){
                contactRoles.add(new SelectOption(pe.getLabel(), pe.getLabel()));
            }
        }
        return contactRoles;
    }
    
    List<SelectOption> householdrules;
    List<SelectOption> RTypes;
    List<SelectOption> Types;
    List<SelectOption> oppStages = new List<SelectOption>();
   
    public void scheduleRollups(){
        if(pageSettings.Enable_Opp_Rollup_Triggers__c){
            Integer scheduledJobLimit = 10;
            boolean alreadyScheduled = false;
            
            List<cronTrigger> scheduledRollups = [SELECT Id FROM cronTrigger limit :scheduledJobLimit];
            
            if(pageSettings.Opp_Rollup_Scheduled_Job_Id__c != null){
                for(cronTrigger thisScheduledJob : scheduledRollups){ 
                    if(thisScheduledJob.id == pageSettings.Opp_Rollup_Scheduled_Job_Id__c){
                        alreadyScheduled = true;
                        break;
                    }
                }
            }
            
            if(!alreadyScheduled){
                if(scheduledRollups.size()<scheduledJobLimit){     
                	
                    SCHED_OppRollup rollUp = new SCHED_OppRollup(); 
                    //need to check for already scheduled job
                    String sch='17 11 2 * * ?'; 
                    scheduledRollups.clear();
					scheduledRollups = [SELECT Id FROM cronTrigger where cronExpression = :sch];
					if (scheduledRollups.size()==0){
                    	String jobId = system.schedule('Nightly Opportunity Roll Up', sch ,rollUp);
                    	pageSettings.Opp_Rollup_Scheduled_Job_Id__c = jobId;
	                	
					} else {
						pageSettings.Opp_Rollup_Scheduled_Job_Id__c = scheduledRollups[0].Id;
					}
                    update pageSettings;
                	
                } else {
                    showMsg(Label.Opportunity_Rollup_Scheduling_Error_Text, ApexPages.Severity.FATAL);
                }
            }
        }
    }

    public List<SelectOption> gethouseholdrules() {
        if(householdrules == null){
            householdrules = new List<SelectOption>();
            householdrules.add(new SelectOption(Households.ALL_PROCESSOR, Households.ALL_PROCESSOR));
            householdrules.add(new SelectOption(Households.ALL_INDIVIDUALS_PROCESSOR, Households.ALL_INDIVIDUALS_PROCESSOR));
            householdrules.add(new SelectOption(Households.NO_HOUSEHOLDS_PROCESSOR, Households.NO_HOUSEHOLDS_PROCESSOR));
        }
        return householdrules;
    }
    
     public List<SelectOption> getoppStages() {
        
    
        if(oppStages.size()==0){
            oppStages.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.StageName; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
            for(Schema.PicklistEntry pe : P){
                oppStages.add(new SelectOption(pe.getLabel(), pe.getLabel()));
            }
        }
        return oppStages;
    }
    
     public List<SelectOption> getRTypes() {
        if(RTypes == null){
            RTypes = new List<SelectOption>();
            RTypes.add(new SelectOption(' ','- none -'));
            RTypes.addAll(RecordTypes.getStringRecordTypesForSelectList('Opportunity'));
        }
        return RTypes;
    }
    
    public List<SelectOption> getTypes() {
        if(Types == null){
            Types = new List<SelectOption>();
            Types.add(new SelectOption(' ','- none -'));
            Schema.DescribeFieldResult F = Schema.sObjectType.Opportunity.fields.Type; 
            List<Schema.PicklistEntry> P = F.getPicklistValues();
        
            for (Schema.PicklistEntry plistentry: P) {
                Types.add(new SelectOption(plistentry.getLabel(),plistentry.getLabel()));
            }
            
        }
        return Types;
    }
    
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        String s = '';
        for (String rt : acctRTs) {
            if (rt!=null&&rt!='')
            s += ';' + rt;
        }
        system.debug('s: ' + s);
        if (s != '') pageSettings.Excluded_Account_Opp_Rectypes__c = s.substring(1);
        
        s = '';
        for (String rt : contactRTs) {
            if (rt!=null&&rt!='')
            s += ';' + rt;
        }
        if (s != '') pageSettings.Excluded_Contact_Opp_Rectypes__c = s.substring(1);
        
        
        s = '';
        for (String tp : acctTypes) {
            if (tp!=null&&tp!='')
            s += ';' + tp;
        }
        if (s != '') pageSettings.Excluded_Account_Opp_Types__c = s.substring(1);
        
        s = '';
        for (String tp : contactTypes) {
            if (tp!=null&&tp!='')
            s += ';' + tp;
        }
        if (s != '') pageSettings.Excluded_Contact_Opp_Types__c = s.substring(1);
        update pageSettings;
        showMsg('Households Settings updated',ApexPages.Severity.INFO);
        //schedule the rollup if need be
        scheduleRollups();
    }
    
     public static testMethod void TEST_householdsSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.householdsSettings'));
        
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(new Households_Settings__c (Household_Rules__c = Households.ALL_INDIVIDUALS_PROCESSOR));
        
        //pass the controller into the extension
        householdsSettings controller = new householdsSettings(); 
        controller.getSettingsFirstTime();
        system.assertNotEquals(null,controller.getSettings());
        
        List<SelectOption> householdrules =  controller.gethouseholdrules(); 
        system.assertEquals(3,householdrules.size());
        
        List<SelectOption> oppStages = controller.getoppStages();
        system.assertNotEquals(null,oppStages);
        
        List<SelectOption> conRoles = controller.getcontactRoles();
        system.assertNotEquals(null,conRoles);
        
        List<SelectOption> opptypes = controller.getTypes();
        system.assertNotEquals(null,opptypes);
        
        List<SelectOption> oppRTypes = controller.getRTypes();
        system.assertNotEquals(null,oppRTypes);
        controller.acctRTs.add(RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        controller.contactRTs.add(RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        
        controller.acctTypes.add('In-Kind');
        controller.contactTypes.add('In-Kind');
        controller.pageSettings.Enable_Opp_Rollup_Triggers__c = true;
        controller.updateSettings();
                
    }
    /*
	static testMethod void testFirstRun()
    {
    	//get rid of settings
    	delete [select id from Households_Settings__c limit 100];
    	//get the default value
		String defaultValue;
        boolean aDefaultIsSelected = false;
        Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.SystemHouseholdProcessor__c; 
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for(Schema.PicklistEntry pe : P){
            if (pe.isDefaultValue()){
                    defaultValue = pe.getValue();
                    break;
            }
        }
         Test.setCurrentPageReference(new PageReference('Page.contactSettings'));
        
        //pass the controller into the extension
        householdsSettings controller = new householdsSettings(); 
        controller.getSettingsFirstTime();
		if(defaultValue!=null){
			system.assertEquals(controller.pageSettings.Household_Rules__c,defaultValue);
		} else {
			system.assertEquals(controller.pageSettings.Household_Rules__c,Households.NO_HOUSEHOLDS_PROCESSOR);
		}

    }
    */
    
}
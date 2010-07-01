public with sharing class householdsSettings {
    
    public Households_Settings__c settingsToUpdate;
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
    		RTypes = RecordTypes.getStringRecordTypesForSelectList('Opportunity');
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
    
    private void showInfoMsg(String arg){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        String s = '';
    	for (String rt : acctRTs) {
    		if (rt!=null)
    		s += ';' + rt;
    	}
    	if (s != '') settingsToUpdate.Excluded_Account_Opp_Rectypes__c = s.substring(1);

    	
    	s = '';
    	for (String rt : contactRTs) {
    		if (rt!=null)
    		s += ';' + rt;
    	}
    	if (s != '') settingsToUpdate.Excluded_Contact_Opp_Rectypes__c = s.substring(1);
    	
    	
    	s = '';
    	for (String tp : acctTypes) {
    		if (tp!=null)
    		s += ';' + tp;
    	}
    	if (s != '') settingsToUpdate.Excluded_Account_Opp_Types__c = s.substring(1);
    	
    	s = '';
    	for (String tp : contactTypes) {
    		if (tp!=null)
    		s += ';' + tp;
    	}
    	if (s != '') settingsToUpdate.Excluded_Contact_Opp_Types__c = s.substring(1);
        update pageSettings;
        showInfoMsg('Households Settings updated');
    }
    
     public static testMethod void TEST_householdsSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.householdsSettings'));
        
        //pass the controller into the extension
        householdsSettings controller = new householdsSettings(); 
        controller.getSettingsFirstTime();
        system.assertNotEquals(null,controller.getSettings());
        
        List<SelectOption> householdrules =  controller.gethouseholdrules(); 
        system.assertEquals(3,householdrules.size());
        /*
        List<SelectOption> conRoles = controller.getcontactRoles();
        system.assertNotEquals(null,conRoles);
        */
        controller.updateSettings();
        
    }
    
}
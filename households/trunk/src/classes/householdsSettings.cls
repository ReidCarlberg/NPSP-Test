public with sharing class householdsSettings {
    
    public Households_Settings__c settingsToUpdate;
    public Households_Settings__c pageSettings = new Households_Settings__c();
    
    public householdsSettings(){
        
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
   
   // List<SelectOption> contactRoles = new List<SelectOption>();

    public List<SelectOption> gethouseholdrules() {
        if(householdrules == null){
            householdrules = new List<SelectOption>();
            householdrules.add(new SelectOption(Households.ALL_PROCESSOR, Households.ALL_PROCESSOR));
            householdrules.add(new SelectOption(Households.ALL_INDIVIDUALS_PROCESSOR, Households.ALL_INDIVIDUALS_PROCESSOR));
            householdrules.add(new SelectOption(Households.NO_HOUSEHOLDS_PROCESSOR, Households.NO_HOUSEHOLDS_PROCESSOR));
        }
        return householdrules;
    }
    
    
    private void showInfoMsg(String arg){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        
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
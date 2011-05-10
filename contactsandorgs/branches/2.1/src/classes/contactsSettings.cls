public with sharing class contactsSettings {
    
    public Contacts_and_Orgs_Settings__c settingsToUpdate;
    public Contacts_and_Orgs_Settings__c pageSettings = new Contacts_and_Orgs_Settings__c();
    
    public contactsSettings(){
        
    }
    
    public Contacts_and_Orgs_Settings__c getSettings() {
        pageSettings = Constants.getContactsSettings();
        return pageSettings;
    }
    
    public PageReference onPageLoad(){
        pageSettings = Constants.getContactsSettings();
        
        if(pageSettings.Send_Update_Notifications__c == null || pageSettings.Send_Update_Notifications__c){
            ScheduleUpgradeCheck();
        }
        
        return null;
    }
    
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
    
    List<SelectOption> accountmodels;
   
    List<SelectOption> contactRoles = new List<SelectOption>();

    public List<SelectOption> getaccountmodels() {
        if(accountmodels == null){
            accountmodels = new List<SelectOption>();
            accountmodels.add(new SelectOption('One-to-One', 'One-to-One'));
            accountmodels.add(new SelectOption('Individual', 'Individual'));
        }
        return accountmodels;
    }
    
    private void showMsg(String arg, ApexPages.Severity severity){
        ApexPages.Message myMsg = new ApexPages.Message(severity,arg);
        ApexPages.addMessage(myMsg);
    }
    
    public void updateSettings(){
        
        update pageSettings;
        showMsg('Contacts and Organizations Settings updated',ApexPages.Severity.INFO);
    }
    
     public static testMethod void TEST_contactSettings() {
        
        Test.setCurrentPageReference(new PageReference('Page.contactSettings'));
        
        //pass the controller into the extension
        contactsSettings controller = new contactsSettings(); 
        controller.onPageLoad();
        system.assertNotEquals(null,controller.getSettings());
        
        List<SelectOption> accountModels =  controller.getaccountmodels(); 
        system.assertEquals(2,accountModels.size());
        
        List<SelectOption> conRoles = controller.getcontactRoles();
        system.assertNotEquals(null,conRoles);
        controller.updateSettings();
        
    }
    
    public void ScheduleUpgradeCheck(){
        boolean jobExists = false;
        String jobId = null;
        if(pageSettings.Upgrade_Check_Scheduled_Job_Id__c != null && pageSettings.Upgrade_Check_Scheduled_Job_Id__c != ''){
            jobExists = true;
            jobId = pageSettings.Upgrade_Check_Scheduled_Job_Id__c;
        }    
        //Check for a scheduled job of that id.
        List<CronTrigger> jobs = [SELECT id FROM CronTrigger WHERE id = :jobId];
        if(jobs.size() > 0){
            //We already have the job scheduled, so we don't need to schedule it.  Bail.
            return;
        }
        else if(jobs.size() < 10){
            //We didn't find the job, therefore we need to schedule it.
            String cronExpression = '0 0 12 ? * 4 *';
            
            //TODO: Drop the scheduled job here. 
            try{
            
            }
            catch(Exception e){
                //They have screwed with the setting and we can't do it anymore.
                return;
            }
        }
    }
    
    public void foo(){
        System.debug(Package.Version.1.1);
    }
    
    static testMethod void testFirstRun()
    {
        //get rid of settings
        delete [select id from Contacts_and_Orgs_Settings__c limit 100];
        //get the default value
        String defaultValue;
        boolean aDefaultIsSelected = false;
        Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.SystemAccountProcessor__c; 
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for(Schema.PicklistEntry pe : P){
            if (pe.isDefaultValue()){
                    defaultValue = pe.getValue();
                    break;
            }
        }
         Test.setCurrentPageReference(new PageReference('Page.contactSettings'));
        
        //pass the controller into the extension
        contactsSettings controller = new contactsSettings(); 
        controller.onPageLoad();
        if(defaultValue!=null){
            system.assertEquals(controller.pageSettings.Account_Processor__c,defaultValue);
        } else {
            system.assertEquals(controller.pageSettings.Account_Processor__c,Constants.BUCKET_PROCESSOR);
        }
    }
    

}
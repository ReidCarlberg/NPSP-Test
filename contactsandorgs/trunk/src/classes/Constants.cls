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

/*
    Constants for use in other IndividualAccounts.cls
*/
global class Constants {
    //One-to-One value for system processor field
    public static String ONE_TO_ONE_PROCESSOR = 'One-to-One';
    //One-to-One org type value
    public static String ONE_TO_ONE_ORGANIZATION_TYPE = 'One-to-One Individual';
    
    //Bucket value for system processor field
    public static String BUCKET_PROCESSOR = 'Individual';
    //Buck org type value
    public static String BUCKET_ORGANIZATION_TYPE = 'Bucket Individual';
    //Bucket Account name
    public static String BUCKET_ACCOUNT_NAME = 'Individual';
    
    public static Contacts_and_Orgs_Settings__c ContactsSettings;
    
    public static final string CONTACT_FIRSTNAME_FOR_TESTS = 'test';
    public static final string CONTACT_LASTNAME_FOR_TESTS = 'Contact_forTests';
    
    public static final string CONTACT_EMAIL_FOR_TESTS = 'junk@test.net';
    public static final string CONTACT_PREFERRED_EMAIL_FOR_TESTS = 'Work';
    public static final string CONTACT_PHONE_FOR_TESTS = '206-777-8888';
    public static final string CONTACT_PREFERRED_PHONE_FOR_TESTS = 'Work';
    
    public static final string INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS = 'IndividualAccountNameForTests';
    
    
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static Contacts_and_Orgs_Settings__c getContactsSettings() {
        boolean usedToBeOneToOne = false;
        //if no settings exist, create defaults
        if (ContactsSettings == null) {
            //first see if we already have settings
            ContactsSettings = Contacts_and_Orgs_Settings__c.getOrgDefaults();
            system.debug(Contacts_and_Orgs_Settings__c.getOrgDefaults());
            if (ContactsSettings == null) {
                //get the model they used to be in
                Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.SystemAccountProcessor__c; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                
                for(Schema.PicklistEntry pe : P){
                	system.debug(pe.getValue() + ' : ' + pe.isDefaultValue());
                    if (pe.isDefaultValue()){
                        if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){
                            usedToBeOneToOne = true;
                        }
                    }
                }
                system.debug(usedToBeOneToOne);
                ContactsSettings = new Contacts_and_Orgs_Settings__c();
                //set them up with their old setting in the new settings object
                if(usedToBeOneToOne){
                    ContactsSettings.Account_Processor__c = ONE_TO_ONE_PROCESSOR;
                } else {
                    ContactsSettings.Account_Processor__c = BUCKET_PROCESSOR;
                }
                //set the other settings to reasonable defaults
                ContactsSettings.Enable_Opportunity_Contact_Role_Trigger__c = false;
                //ContactsSettings.Opportunity_Contact_Role_Default_role__c = 'Donor';
                ContactsSettings.Setupownerid = UserInfo.getOrganizationId();
                //this is not allowed...
                insert ContactsSettings;
            }
        }
        return ContactsSettings;
    }
    
    public static Contacts_and_Orgs_Settings__c getContactsSettingsForTests(Contacts_and_Orgs_Settings__c mySettings) {
        
        //clear out whatever settings exist
        delete [select id from Contacts_and_Orgs_Settings__c];
        
        //create our own based on what's passed in from the test
        ContactsSettings = new Contacts_and_Orgs_Settings__c (
            Account_Processor__c = mySettings.Account_Processor__c,
            Enable_Opportunity_Contact_Role_Trigger__c = mySettings.Enable_Opportunity_Contact_Role_Trigger__c,
            Opportunity_Contact_Role_Default_role__c = mySettings.Opportunity_Contact_Role_Default_role__c,
            Disable_Account_Model_Trigger__c = mySettings.Disable_Account_Model_Trigger__c
            );
        insert ContactsSettings;
            
        return ContactsSettings;
    }

    /*
     //method to tell which model we're currently in for Accounts
    public static boolean isOneToOne() {
        boolean isOneToOneModel;
        isOneToOneModel = false;
        Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npe01__SystemAccountProcessor__c; 
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for(Schema.PicklistEntry pe : P){
            if (pe.isDefaultValue()){
                if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){ isOneToOneModel = true;}
            }
        }
        
        return isOneToOneModel;
    }
    */
     public static boolean isOneToOne() {
        
        
        //if no settings exist, create defaults
        if (Constants.getContactsSettings().Account_Processor__c==ONE_TO_ONE_PROCESSOR) {
            return true;
        } else {
            return false;
        }
        
    }
    

}
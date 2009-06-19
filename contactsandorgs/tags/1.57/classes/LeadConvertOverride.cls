public class LeadConvertOverride
{
	private final Lead l;

    public LeadConvertOverride(ApexPages.StandardController controller)
    {
        this.l = (Lead) controller.getRecord();
    }    

	public pageReference convertLead()
	{
		String lId = ApexPages.currentPage().getParameters().get('id');  
		PageReference pageRef;
		//don't test if we're in the bucket model
		if(l.company.toUpperCase() != 'INDIVIDUAL'){
			if (l.company == null || l.company == '' || l.company.toUpperCase() == 'SELF' || l.company.toUpperCase() == l.firstName.toUpperCase() + ' ' + l.lastname.toUpperCase())
			{
				Database.LeadConvert lc = new database.LeadConvert();
				lc.setLeadId(lId);
				lc.setDoNotCreateOpportunity(true);
				LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
				lc.setConvertedStatus(convertStatus.MasterLabel);
				Database.LeadConvertResult lcr = Database.convertLead(lc);
				Contact c = new Contact(Id=lcr.getContactId());
				c.AccountId = null;
				update c;
				Contact[] myconvertedContact = [select id,firstname, lastname, accountid,account.name, SystemAccountProcessor__c from contact where id=:c.Id];
					
				if (lcr.getAccountId() != null)
				{
					if(myconvertedContact.size()>0){
						//if the contact is connected to the Individual account, don't delete it
						if (myconvertedContact[0].account.Name.toUpperCase()!='INDIVIDUAL'){
							Account a = new Account(Id=lcr.getAccountId());
							Database.DeleteResult d = Database.delete(a);
						}						
					}
				}
				pageRef = new PageReference('/' + c.Id);
				pageRef.setRedirect(true);
			}
		} else {
			pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' + lId + '&id=' + lId + '&nooverride=1');
		}
		pageRef.setRedirect(true);
		return pageRef;
	}			
		
    private final ApexPages.StandardController controller;   

	public static testMethod void newLeadConversion_Test() {

        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
 
 		String companyName = 'Individual';
 		String AccountProcessorValue = Constants.BUCKET_PROCESSOR;
		
		Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npe01__SystemAccountProcessor__c; 
		List<Schema.PicklistEntry> P = F.getPicklistValues();
		for(Schema.PicklistEntry pe : P){
			if (pe.isDefaultValue()){
				if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){
					companyName = 'Self';
				
			        
			        String leadFirstName = 'test';
			        String leadLastName = 'lead for tests_987';
			        Lead l = new Lead();
					l.FirstName = leadFirstName;
					l.LastName = leadLastName;
					l.Company = companyName;
					insert l;
					
					system.currentPageReference().getParameters().put('id', l.id);
					
					//pass contact into the controller
					ApexPages.StandardController sc = new ApexPages.standardController(l);
					//pass the controller into the extension
					LeadConvertOverride ext = new LeadConvertOverride(sc); 
					
					ext.convertLead();
					
					Contact[] convertedContacts = [select id, firstname, lastname,Account.Systemisindividual__c from Contact where lastname = :leadLastName];
					//one contact should have been created
					system.assertEquals(1,convertedContacts.size());
					//the account for this contact should be an individual account, no matter the model
					system.assertEquals(true,convertedContacts[0].Account.Systemisindividual__c);
				}
			}
		}
    }
    public static testMethod void newLeadConversionNamedCompany_Test() {

        
        Test.setCurrentPageReference(new PageReference('Page.LeadConvertOverride'));
        
        String companyName = 'Individual';
 		String AccountProcessorValue = Constants.BUCKET_PROCESSOR;
		
		Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npe01__SystemAccountProcessor__c; 
		List<Schema.PicklistEntry> P = F.getPicklistValues();
		for(Schema.PicklistEntry pe : P){
			if (pe.isDefaultValue()){
				if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){
					companyName = 'Self';
			        String leadFirstName = 'test';
			        String leadLastName = 'lead for tests_989';
			        Lead l = new Lead();
					l.FirstName = leadFirstName;
					l.LastName = leadLastName;
					l.Company = companyName;
					insert l;
					
					system.currentPageReference().getParameters().put('id', l.id);
					
					//pass contact into the controller
					ApexPages.StandardController sc = new ApexPages.standardController(l);
					//pass the controller into the extension
					LeadConvertOverride ext = new LeadConvertOverride(sc); 
					
					ext.convertLead();
					
					Contact[] convertedContacts = [select id, firstname, lastname,Account.Systemisindividual__c from Contact where lastname = :leadLastName];
					//one contact should have been created
					system.assertEquals(1,convertedContacts.size());
					//the account for this contact should be an individual account, no matter the model
					system.assertEquals(true,convertedContacts[0].Account.Systemisindividual__c);

    			}
			}
		}
	}
}
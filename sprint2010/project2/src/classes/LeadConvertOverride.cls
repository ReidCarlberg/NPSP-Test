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
		pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' + lId + '&id=' + lId + '&nooverride=1');
		
		//don't test if we're not in the one-to-one model
		if(Constants.ONE_TO_ONE_ACCOUNT_MODEL){
			if (l.company.toUpperCase() != 'INDIVIDUAL' && (l.company == null || l.company == '' || l.company.toUpperCase() == 'SELF' || l.company.toUpperCase() == getFullName(l)))
			{
				Database.LeadConvert lc = new database.LeadConvert();
				lc.setLeadId(lId);
				lc.setDoNotCreateOpportunity(true);
				LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
				lc.setConvertedStatus(convertStatus.MasterLabel);
				Database.LeadConvertResult lcr = Database.convertLead(lc);
				Contact c = new Contact(Id=lcr.getContactId(),AccountId = null);
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
			}
		}
		pageRef.setRedirect(true);
		return pageRef;
	}			
	
	private String getFullName(Lead thisLead){
		String fullName;
		if(thisLead.firstName!=null&&thisLead.firstName!=''){
			fullName = thisLead.firstName.toUpperCase() + ' ';
		}
		fullName += thisLead.lastname.toUpperCase();
		return fullName;
	}
	
    private final ApexPages.StandardController controller;   
}
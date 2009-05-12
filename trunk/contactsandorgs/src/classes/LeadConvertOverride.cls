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
		if ( l.company == 'Individual' || l.company == null || l.company == '' || l.company == 'Self' || l.company == l.name)
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

			if (lcr.getAccountId() != null)
			{
				Account a = new Account(Id=lcr.getAccountId());
				Database.DeleteResult d = Database.delete(a);
			}

			
			pageRef = new PageReference('/' + c.Id);
			pageRef.setRedirect(true);
		} else {
			pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F' + lId + '&id=' + lId);
		}
		pageRef.setRedirect(true);
		return pageRef;
	}			
		
    private final ApexPages.StandardController controller;   

	public static testMethod void testMyController() {
		Lead l = new Lead();
		l.FirstName = 'test';
		l.LastName = 'lead';
		l.Company = 'self';
		insert l;
        PageReference pageRef = Page.LeadConvertOverride;
        Test.setCurrentPage(pageRef);

    }





}
trigger OpportunityAccount on Opportunity (before insert) {
	
	 //Create contact roles as needed for new opps.
    if(Trigger.isBefore && Trigger.isInsert)
    {
        OpportunityContactRoles.opportunityAccounts(Trigger.new); 
    }
	
}
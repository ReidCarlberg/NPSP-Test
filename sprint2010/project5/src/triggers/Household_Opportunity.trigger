trigger Household_Opportunity on Opportunity (after insert) {
	
	if( Trigger.isAfter && Trigger.isInsert ){    	   
        HouseholdOpportunity process = new HouseholdOpportunity(Trigger.new, Trigger.old, IndividualAccounts_Utils.triggerAction.afterInsert);
    }
}
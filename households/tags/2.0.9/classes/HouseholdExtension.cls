public with sharing class HouseholdExtension {
	private final Household__c household;
	public HouseholdExtension(ApexPages.StandardController stdController) {
		this.household = (Household__c)stdController.getRecord();
    }
    public String getLastTransactionDate() {
    	return Households.getHouseholdLastTransactionDate(household.ID);
    }
    public String getHouseholdTransactionTotal() {
    	return Households.getHouseholdTransactionAmount(household.ID);
    }
        
}
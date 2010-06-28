public with sharing class HouseholdTransactionHistory_EXT {
    private final Household__c household;
    public HouseholdTransactionHistory_EXT(ApexPages.StandardController stdController) {
        this.household = (Household__c)stdController.getRecord();
    }
    public String getLastTransactionDate() {
        return Households.getHouseholdLastTransactionDate(household.ID);
    }
    public String getHouseholdTransactionTotal() {
        return Households.getHouseholdTransactionAmount(household.ID);
    }
}
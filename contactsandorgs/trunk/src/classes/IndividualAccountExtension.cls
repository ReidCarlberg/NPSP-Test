public with sharing class IndividualAccountExtension {
	private final Contact contact;
	public IndividualAccountExtension(ApexPages.StandardController stdController) {
		this.contact = (Contact)stdController.getRecord();
    }
    public String getContactLastDonation() {
    	return IndividualAccounts.getContactLastDonationDate(contact.ID);
    }
    public String getContactDonationHistory() {
    	return IndividualAccounts.getContactDonationHistoryAmount(contact.ID);
    }        
}
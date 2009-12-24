public with sharing class ContactDonationCredit_EXT {
	private final Contact contact;
	public ContactDonationCredit_EXT(ApexPages.StandardController stdController) {
		this.contact = (Contact)stdController.getRecord();
    }
    public String getContactLastDonation() {
    	return IndividualAccounts.getContactLastDonationDate(contact.ID);
    }
    public String getContactDonationHistory() {
    	return IndividualAccounts.getContactDonationHistoryAmount(contact.ID);
    }     
}
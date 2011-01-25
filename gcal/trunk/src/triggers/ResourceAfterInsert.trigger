trigger ResourceAfterInsert on Resource__c (after insert) {

	//Create a matching google calendar when a new resource is inserted
	//Need to check that a Google calendar for this resource name does not already exist
	//probably need a before insert on resource to make sure duplicate are not also inserted.
	
	


}
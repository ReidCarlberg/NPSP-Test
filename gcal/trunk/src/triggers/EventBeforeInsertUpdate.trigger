trigger EventBeforeInsertUpdate on Event (before insert, before update) {
/****************************************	*/
/* Kevin Bromer, (c) 2010                	*/
/* Trigger checks to make sure a valid   	*/
/* Google Calendar exists before inserting  */
/* the event and posting to the calendar    */
/********************************************/
	
	//Not a great hack, but will prevent non-bulk load update errors
	if (trigger.isUpdate) //&& (trigger.new[0].Google_Calendar_Name__c != trigger.old[0].Google_Calendar_Name__c))
			trigger.new[0].addError('Updates are not currently supported for the Google Calendar Connector when event triggers are enabled.  Please delete and recreate your event, or check the custom settings for Google Calendar Connector.');
		

	for (Event e : trigger.new){		
		if (e.Google_Calendar_Name__c != null){
			list<string> calList = e.Google_Calendar_Name__c.split(',');
			ResourceCalendarManager rcm = new ResourceCalendarManager();		
			if (!rcm.hasLocalResource(calList))
				e.addError('One or more calendar names do not match existing calendars. Please check your names and try again.');
		}
	}	

}
trigger EventAfterInsertUpdateDelete on Event (after delete, after insert, after update) {
/****************************************************************/
/*	Google Calendar Integration					 				*/
/* 	Written by Kevin Bromer										*/
/* 	This program is released under the GNU General Public 		*/
/* 	License GPL3. http://www.gnu.org/licenses/					*/
/****************************************************************/
	
	//Check to make sure our settings are in place, otherwise, we can't process events
	google_settings__c gs = google_settings__c.getInstance();
	if (gs != null){if (gs.Use_Event_Trigger__c){

	list<Event> triggerList = (trigger.isDelete ? trigger.old : trigger.new);//new list<Event>();
	list<id> dmlList = new list<id>();

	//check if we're in a test and add events with a Google Calendar name to 
	//the dmlList
	boolean isTest = false;
	for (Event e : triggerList){
		if (e.Google_Calendar_Name__c != null){
			dmlList.add(e.id);
			if (e.Google_Calendar_Name__c == 'HOLLA') 
				isTest = true;
		}
	} 
	
	//if we have a valid token and something to insert, do it
	if (!dmlList.isEmpty()){
		if (trigger.isDelete) 
			CalendarAsynchInterface.callOutWrapper('delete', dmlList, isTest);	
		else if (trigger.isInsert)
			CalendarAsynchInterface.callOutWrapper('post', dmlList, isTest);
	}	
	
	//else, proceed as normal since we have nothing to insert to google calendar
	
	}}//close Use Event Settings check - close getInstance() is null check
}
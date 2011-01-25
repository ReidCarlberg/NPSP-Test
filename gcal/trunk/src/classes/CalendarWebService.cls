global without sharing class CalendarWebService {

/****************************************************************/
/*	Google Calendar Integration									*/
/* 	Written by Kevin Bromer										*/
/* 	This program is released under the GNU General Public 		*/
/* 	License GPL3. http://www.gnu.org/licenses/					*/
/****************************************************************/

/****************************************************************/
/* Provides a web service interface for callouts and button    */
/****************************************************************/

public static webservice string getSimultaneousEvents(string EventStartDate, string EventEndDate){
	
	Datetime sdt = DateTime.valueOf(EventStartDate);
	Datetime edt = DateTime.valueOf(EventEndDate);
	string returnString = ''; 
	list<Event> eventList = new list<Event>();
	eventList = [select Subject, StartDateTime, EndDateTime, Google_Calendar_Name__c from Event where
	(StartDateTime < :edt and StartDateTime > :sdt) or
	(EndDateTime < :edt and EndDateTime > :sdt)];   
	
	for (Event e : eventList){
		if (e.Google_Calendar_Name__c != null){
			for (string CalName : e.Google_Calendar_Name__c.split(',')){
				returnString = e.Subject + ' : ' + CalName + '\n'
				+ e.StartDateTime + ' to ' + e.EndDateTime + '\n\n';				
			}	
		}
	}
	
	if (returnString == '')
		returnString = 'No Events in Salesforce at these times';
	
	return returnString;
		
	
}











}
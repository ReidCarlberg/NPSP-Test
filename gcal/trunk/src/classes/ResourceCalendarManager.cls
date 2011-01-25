public with sharing class ResourceCalendarManager {
/****************************************************************/
/*	Google Calendar Integration									*/
/* 	Written by Kevin Bromer										*/
/* 	This program is released under the GNU General Public 		*/
/* 	License GPL3. http://www.gnu.org/licenses/					*/
/****************************************************************/

/****************************************************************/
/* Calling triggers and classes can check API access by getting	*/
/* hasValidToken. If false, the sessionTokenID property will 	*/
/* contain a newly inserted googSession__c for the running user */
/****************************************************************/

private boolean isActiveTest;
private string sessionToken; //will hold the generic system session token if present, otherwise, the user token
public string sessionTokenID{get; set;} //holds the id of the googsession object with the valid token, OR that was inserted on instantiation
public boolean hasValidToken{get; private set;}
public string instancePrefix{get; private set;}
//null constructor to support existing implementations
//isTest prevents http callouts for testing
public ResourceCalendarManager(){this(false, null);}
public ResourceCalendarManager(boolean isTest, google_settings__c testSettings){
	
	//set test context var
	isActiveTest = isTest;
	
	google_settings__c googleSettings = new google_settings__c();
	//try and load custom settings
	if (testSettings == null)
   	    googleSettings = google_settings__c.getInstance();
   	else
   	    googleSettings = testSettings;    
	
	if ((googleSettings  != null) && (googleSettings.Salesforce_Instance__c != null))
		instancePrefix = googleSettings.Salesforce_Instance__c;
	
	//we have a valid google session custom setting, get the default session id;
	if ((googleSettings != null) && (googleSettings.Session_Token__c != null) && (googleSettings.Admin_ID__c != null) && (googleSettings.Administrator_Authentication__c == true)){
		sessionToken = googleSettings.Session_Token__c;
		sessionTokenID = googleSettings.Admin_ID__c;
		hasValidToken = true;
	}	
	// if we don't have a valid setting, try and get a session id utilizing the running user	
	else{
		string currentUserID = UserInfo.getUserId();	
		currentUserID = currentUserID.substring(0, 15);
		system.assertequals(currentUserID.length(), 15);	
		googSession__c gs = new googSession__c();
		list<googSession__c> myAuthSession = new list<googSession__c>{gs};
		myAuthSession = [select id, AuthSubSessionToken__c from googSession__c where Token_User__c = :CurrentUserID and AuthSubSessionToken__c != null and Scope__c = 'http://www.google.com/calendar/feeds/' limit 1];
			
		if (!myAuthSession.isEmpty()){
			sessionToken = myAuthSession[0].AuthSubSessionToken__c;		
			sessionTokenID = myAuthSession[0].id;
			hasValidToken = true; 
		}		
	}
}

//Method to retrieve map of calendar information - map<Name, ID> 
public map<string, string> getCalendarList(){

	map<string, string> calendarInfo = new map<string, string>();	
	CalendarService service = new CalendarService();  
	service.setAuthSubToken(sessionToken);	
	
	if (!isActiveTest){
	GoogleData feed = service.getFeed(CalendarService.allCalendars);       
	list<GoogleData.Calendar> cals = GoogleData.calendarFactory(feed.entries); 

	for (GoogleData.Calendar c : cals)
			calendarInfo.put(c.title, c.id);	
	}	
	return calendarInfo;
}

public boolean createCalendar(string calendarName){return createCalendars(new list<string>{calendarName});}
public boolean createCalendars(list<string> calendarNames){
	boolean isSuccess;

	CalendarService service = new CalendarService();  
	service.setAuthSubToken(sessionToken);	

	for (string CalendarName : calendarNames){
		if (!isActiveTest){	
			try{
				GoogleData.Calendar cal = GoogleData.createCalendarEntry(CalendarName,'');
  				xmldom.element newcal = service.insertCalendar( cal );
 				newcal.dumpall();
 				isSuccess = true;  
			}
			catch (Exception e){system.debug('Something went wrong in calendar creation: ' + e.getMessage()); isSuccess = false;}
			finally{}
		}
	}	
	return isSuccess; 
}
 
public boolean postCalendarEvent(Event calendarEvent){return postCalendarEvents(new list<Event>{calendarEvent});}
public boolean postCalendarEvents(list<Event> calendarEvents){
	boolean isSuccess;
	map<string, list<Event>> eventInsertMap = new map<string, list<Event>>();
		 	 
	CalendarService service = new CalendarService();  
	service.setAuthSubToken(sessionToken);
	
	for (Event e : calendarEvents){		
		
		if ((instancePrefix != null) && (e.Subject != null) && e.Include_SF_Link_in_Subject__c)
			e.Subject = e.Subject + ' &lt;a href=&quot;http://' + instancePrefix + '.salesforce.com/' + e.id + '&quot;&gt;SF Link&lt;/a&gt;';	
		
		for (string gcalName : e.Google_Calendar_Name__c.split(',')){
			if (eventInsertMap.containsKey(gcalName)){
				list<Event> evtsList = eventInsertMap.get(gcalName);
				evtsList.add(e);
				eventInsertMap.put(gcalName, evtsList);
			}
			else{
			list<Event> newList = new list<Event>();
			newList.add(e);
			eventInsertMap.put(gcalName, newList);		
			}	
		}
	}
	
	set<string> eventStringSet = eventInsertMap.keySet();
	list<Resource__c> calList = [select id, name from Resource__c where name IN:eventStringSet];
	
	//create a list of google calendars to get
	if (!isActiveTest){	
		for (Resource__c ro : calList){
			GoogleData.Calendar cal = service.GetCalendarByTitle(ro.name);
			//if we can't get a valid calendar, we'll need to insert one 
			//into google first for the matching resource name, and then
			//try creating the calendar again
			if (cal == null){		
				createCalendar(ro.name);	
				//try to create a calendar again...
				cal = service.GetCalendarByTitle(ro.name);
				//if we still can't find it, toss an error, since we're either
				//not reach google, or it doesn't exist
				if (cal == null){throw new InvalidCalendarException();}					
			}			
			list<Event> eventToInsert = eventInsertMap.get(ro.Name);
			xmldom.element entry = service.insertEvents(cal, eventToInsert);
			entry.dumpAll();
		}	
	}	
	//for debug, just always return true	
	isSuccess = true;	
	return isSuccess;	
}

public boolean deleteCalendarEvent(Event e){return deleteCalendarEvents(new list<Event>{e});}
public boolean deleteCalendarEvents(list<Event> eventsToDelete){
	boolean isSuccess;
	list<id> whatIDList = new list<id>();
	map<string, list<Event>> eventDeleteMap = new map<string, list<Event>>();
	
	CalendarService service = new CalendarService();  
	service.setAuthSubToken(sessionToken);
	
	for (Event e : eventsToDelete){
		for (string gcalName : e.Google_Calendar_Name__c.split(',')){
			if (eventDeleteMap.containsKey(gcalName)){
				list<Event> evtsList = eventDeleteMap.get(gcalName);
				evtsList.add(e);
				eventDeleteMap.put(gcalName, evtsList);
			}
			else{
				list<Event> newList = new list<Event>();
				newList.add(e);
				eventDeleteMap.put(gcalName, newList);		
			}
		}	
	}
	
	//map<id, Resource__c> calendarMap = new map<id, Resource__c>([select Id, Name from Resource__c where Name IN :eventDeleteMap.keyset()]);
	system.debug('eventDeleteMap.keyset size: ' + eventDeleteMap.keyset().size());
		
	if (!isActiveTest){
		for (string mapName : eventDeleteMap.keySet()){		
			GoogleData.Calendar cal = service.getCalendarByTitle(mapName);	
				
			for (Event evt : eventDeleteMap.get(mapName)){		
				GoogleData evs_range = service.getEventsRange(cal, evt.StartDateTime, evt.EndDateTime);
				xmldom.element del = evs_range.entries.remove(0);
				service.removeEvent( del );					
			}
		}
	}
	
	return isSuccess;
}

//used to check valid resource string from any event add 
public boolean hasLocalResource(list<string> calendars){
	boolean hasCalendarMatch = true;
	set<string> calNames = new set<string>();
	list<Resource__c> calCount = [select name from Resource__c where name IN :calendars];
	for (Resource__c r : calCount)
		calNames.add(r.Name);
		
	for (string s : calendars){
		if (!calNames.contains(s))
			hasCalendarMatch = false;		
	}	
	return hasCalendarMatch;
}
/*
public boolean updateCalendarEvent(Event e){return updateCalendarEvents
*/

/*
//return a string of events at the same time as the requesting event
public string otherEventsSameTime(Event eventToCheck){
	boolean isSuccess;
	list<id> whatIDList = new list<id>();
	map<string, string> eventCheckMap = new map<string, string>();
	
	CalendarService service = new CalendarService();  
	service.setAuthSubToken(sessionToken);
	
	eventCheckMap = getCalendarList();
	
	string calendarString;				
	for (string mapName : eventCheckMap.keyset()){
		GoogleData.Calendar cal = service.getCalendarByTitle(mapName);	
		GoogleData evs_range = service.getEventsRange(cal, eventToCheck.StartDateTime, eventToCheck.EndDateTime);
		if (evs_range != null){
			calendarString = evs_range.title + ' ON ' + mapName; 	
		}		
	}
	system.debug('IM RETURNING: ' + calendarString);
	return calendarString;
}*/


/********Exception Classes****************************/
public class NullSessionException extends Exception{}
public class InvalidSessionException extends Exception{}
public class InvalidCalendarException extends Exception{}


/*************ResouceCalendarManager Test Methods**********/
public static testMethod void calendarTest(){

    //Test a null session token
    ResourceCalendarManager testNullSession = new ResourceCalendarManager(true, null);

    googSession__c testAuthSession = new googSession__c(Name = string.valueOf(User.Id), AuthSubSessionToken__c = '123456789WhatIuseinthebattleforthemind');
    insert testAuthSession;
    Resource__c r = new Resource__c(name = 'HOLLA');
    insert r;

    ResourceCalendarManager rcm = new ResourceCalendarManager(true, null);

    google_settings__c gst = new google_settings__c(Session_Token__c = '123456789ABCDEF',
    Admin_ID__c = '987654321ABCDEF', Salesforce_Instance__c = 'na1', Administrator_Authentication__c = true);
        
    ResourceCalendarManager testWithSettings = new ResourceCalendarManager(true, gst);

    //Test getCalendarList method
    map<string, string> tMap = new map<string, string>();

    tMap = rcm.getCalendarList();
    
    //test createCalendar(string)
    boolean testSucces = rcm.createCalendar('TestCal');

    Event e = new Event(Subject = 'TestSubject', Google_Calendar_Name__c = 'HOLLA', StartDateTime = system.now(), EndDateTime = system.now().addHours(1));
    list<Event> eventInsertList = new list<Event>{e};
    Event e1 = new Event(Subject = 'Newsub', Google_Calendar_Name__c = 'HOLLA', StartDateTime = system.now().addHours(2), EndDateTime = system.now().addHours(3));
    eventInsertList.add(e1);
    insert eventInsertList;
    
    boolean testPost = rcm.postCalendarEvent(e);    
    boolean testDelete = rcm.deleteCalendarEvent(e);
    boolean testMultiPost = rcm.postCalendarEvents(eventInsertList);
    boolean testMultidelete = rcm.deleteCalendarEvents(eventInsertList);

    //test hasLocalResource(list<string>)
    list<string> localList = new list<string>{'HOLLA'};
    boolean testCalList = rcm.hasLocalResource(locallist);
    system.assert(testCalList);

    //has local resource with bogus cal name
    list<string> bogusCal = new list<string>{'NOCAL'};
    boolean testbogusCal = rcm.hasLocalResource(bogusCal);
    system.assert(!testbogusCal);
}

}//Close Class
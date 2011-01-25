public with sharing class CalendarDisplayExtension {

/****************************************************************/
/*	Google Calendar Display VF Extension for NPower Seattle 	*/
/* 	Written by Kevin Bromer, copyright (c) 2010 NPower Seattle 	*/
/* 	This program is released under the GNU General Public 		*/
/* 	License GPL3. http://www.gnu.org/licenses/					*/
/****************************************************************/

/*******PUBLICLY AVAILABLE VARS**********/
public boolean noCalendars {get; set;}
public string calSelection {get; set;} //stores value of selected template - referenced in template picklist on page
public string selectCalendarName{get; set;}
public map<string, string> availableCalendars = new map<string, string>(); //Name, ID
public string calFrame {get; set;} //stores the value of the iframe to render
public string resourceStatus {get; set;} //provide feedback to the user on the state of this resource and/or token
public string googDomain {get; set;}  //the domain value fromt the settings
public boolean hasToken {get; set;}
public map<string, string> tokenlist = new map<string, string>();
public boolean needsResource {get; set;}
public boolean needsPrivateToken {get; set;}
public ResourceCalendarManager rcm = new ResourceCalendarManager();
List<Event> events;
//CONSTRUCTOR TIME
public CalendarDisplayExtension.CalendarDisplayExtension(ApexPages.StandardController controller){

	string tempCal;//just a holder while we parse the cal data...
  	string tempCalName = '';//used to retrieve matching resource, if any
  	needsResource = true;
  	needsPrivateToken = false;
  
	//Let's go get our calendar list...
	try{		
			if(rcm.sessionTokenID != null && rcm.hasValidToken == true){
				availableCalendars = rcm.getCalendarList();
				hasToken = true;
			}
			else{
				resourceStatus = 'Invalid Google Session';
				hasToken = false; 
			} 
	}
	catch(Exception e){system.debug('Error Initializing Calendar Manager' + e.getMessage());}
		
	google_settings__c googleSettings = google_settings__c.getInstance();

	if (googleSettings != null)	
		googDomain = googleSettings.Apps_Domain__c;

	if (availableCalendars.isEmpty()){
		noCalendars = true;
		needsResource = true;	
	}
    	
	else{
		noCalendars = false;
		needsResource = false;
		//get private tokens, if any
		list<Resource__c> rlist = [select name, pvttoken__c from Resource__c];
	
		for (Resource__c r : rlist){
			if (r.pvttoken__c != null)
				tokenlist.put(r.name, r.pvttoken__c);			
		}
	
		for (string calName : availableCalendars.keySet()){
			if (tempCal == null){//pre-populate with the default calendar in the map	
				tempCal = availableCalendars.get(calName);
				selectCalendarName = calName;
				tempCalName = calName;	
			}		
		}
		list<string> rs = new list<string>{tempCalName};			
		if (!rcm.hasLocalResource(rs)){
			resourceStatus = 'The selected calendar does not have a matching object in Salesforce.  Adding Events is disabled until an object is added.';
			needsResource = true;	
		}
		else if (!tokenList.containsKey(tempCalName)){
			resourceStatus = 'Some information may not be visible without a private token for this calendar.';
			needsResource = false;
			needsPrivateToken = true;
		}
	
		integer idStartIndex;
		string idSubString; 
		
		if (tempCal.length() > 0){
			idStartIndex = tempCal.lastindexOf('/');	
			idSubString = tempCal.substring(idStartIndex + 1, tempCal.length());
		}
				
		calFrame = 'http://www.google.com/calendar/hosted/' + googDomain + '/embed?src=' + idSubString + '&ctz=America/Los_Angeles&pvttk=' + tokenlist.get(tempcalName) ;
	}
}//close constructor 

public List<SelectOption> getCalList() {
	List<SelectOption> options = new List<SelectOption>();
    
    for (string calName : availableCalendars.keySet()){      
    	//hack for The Vera Project - TO BE REMOVED.
    	if (calName != 'admin@theveraproject.org') 		
    		options.add(new selectOption(availableCalendars.get(calName), calName));
    }	
	return options;
}
    
   
public PageReference updateCalendarVals()

{
/****** URI STRINGS FOR VARIOUS CALENDAR RENDERS, etc., THIS IS THE FORMAT WE'RE TRYING TO EMULATE
http://www.google.com/calendar/hosted/npowerseattle.org/embed?
src=npowerseattle.org_plpgpscgcncro4n0ge6kkd7fuo%40group.calendar.google.com&ctz=America/Los_Angeles
Test2 DOM ID: 
http://www.google.com/calendar/feeds/default/allcalendars/full/npowerseattle.org_plpgpscgcncro4n0ge6kkd7fuo%40group.calendar.google.com
https://www.google.com/calendar/hosted/npowerseattle.org/embed?src=npowerseattle.org_plpgpscgcncro4n0ge6kkd7fuo%40group.calendar.google.com&ctz=America/Los_Angeles&pvttk=a6777bb2ac71d0583fd41d0af616b25e 
*/	
	needsResource = false;
	needsPrivateToken = false;
	integer idStartIndex;
	string idSubString; 
	
	idStartIndex = calSelection.lastindexOf('/');
	idSubString = calSelection.substring(idStartIndex + 1, calSelection.length());

	for (string s : availableCalendars.keySet()){
		if(calSelection.equals(availableCalendars.get(s)))
			selectCalendarName = s;
	}
	
	list<string> rs = new list<string>{selectCalendarName};
	
	if (!rcm.hasLocalResource(rs)){
		resourceStatus = 'The selected calendar does not have a matching object in Salesforce.  Adding Events is disabled until an object is added.' ;
		needsResource = true;
	
	}
	
	else if (!tokenList.containsKey(selectCalendarName)){
		resourceStatus = 'Some information may not be visible without a private token for this calendar.';
		needsPrivateToken = true;
	}
	else
		resourceStatus = '';	
		
	calFrame = 'http://www.google.com/calendar/hosted/' + googDomain + '/embed?src=' + idSubString + '&ctz=America/Los_Angeles&pvttk=' + tokenlist.get(selectCalendarName);
		
	return null;
}

public PageReference addResourceCalendar(){

	Resource__c newResource = new Resource__c();
	newResource.Name = selectCalendarName;
	insert newResource;
	PageReference pg = ApexPages.CurrentPage();
	pg.setRedirect(true);
	return pg;
}

public List<Event> getEvents() {
	if(events == null) events = [select id from Event limit 10];
return events;
}

static testMethod void testController(){
	
	Test.setCurrentPageReference(new PageReference('Page.CalendarDisplayExtension'));
	ApexPages.Standardcontroller st = new ApexPages.StandardController(new Resource__c());
	
    CalendarDisplayExtension controller = new CalendarDisplayExtension(st);
	//controller.METHODSHERE
	
	
}


}
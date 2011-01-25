global without sharing class CalendarAsynchInterface {
/****************************************************************/
/*	Google Calendar Integration									*/
/* 	Written by Kevin Bromer										*/
/* 	This program is released under the GNU General Public 		*/
/* 	License GPL3. http://www.gnu.org/licenses/					*/
/****************************************************************/

/****************************************************************/
/*  Provides an asynchronous interface for callouts from        */
/*  from triggers												*/
/****************************************************************/

@future (callout=true)
public static void callOutWrapper(string callouttype, list<ID> elist, boolean isTest){
	list<Event> eventlist = new list<Event>();
	eventlist = [select WhoId, WhatId, SystemModstamp, Subject, StartDateTime, 
	ShowAs, ReminderDateTime, RecurrenceType, RecurrenceTimeZoneSidKey, 
	RecurrenceStartDateTime, RecurrenceMonthOfYear, RecurrenceInterval, 
	RecurrenceInstance, RecurrenceEndDateOnly, RecurrenceDayOfWeekMask, 
	RecurrenceDayOfMonth, RecurrenceActivityId, OwnerId, Location, LastModifiedDate, 
	LastModifiedById, IsReminderSet, IsRecurrence, IsPrivate, IsGroupEvent, 
	IsDeleted, IsChild, IsArchived, IsAllDayEvent, Id, GroupEventType, 
	Google_Calendar_Name__c, EndDateTime, DurationInMinutes, Description, 
	CreatedDate, CreatedById, ActivityDateTime, ActivityDate, AccountId, Include_SF_Link_in_Subject__c
	From Event e where id IN :elist ALL ROWS];
	
	ResourceCalendarManager rcm = new ResourceCalendarManager(isTest, null);
	
	if (callouttype == 'post')
		rcm.postCalendarEvents(eventList);		
	
	else if (callouttype == 'delete')
		rcm.deleteCalendarEvents(eventList);		
	
			
}




}
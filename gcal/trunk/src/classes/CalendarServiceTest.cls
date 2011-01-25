public class CalendarServiceTest {

    static integer debug=3;
    static final string sessionAuthToken = 'CJ3pqczuBBCpgI2pBw';
 
    public static testMethod void updateEvent() { 
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        // find an event that contains Tennis
        
        // find events yesterday and today
        GoogleData.Calendar cal = service.getCalendarByTitle('force.com Team Demo');
        system.debug(cal);
        GoogleData evs_range = service.getEventsRange( cal,
         system.now().addDays(-1), 
         system.now().addDays(+1) 
         ); 
        for ( xmldom.element e : evs_range.entries ) { 
            system.debug( GoogleData.getTitle(e) ); 
        }
    
        // update one, beware there may be none??
        if ( evs_range.entries.size() > 0 ) { 
            xmldom.element upd = evs_range.entries[0];
            upd.getElementByTagName('title').nodeValue = 'Tennis with Bill';
            service.updateEvent( upd ); 
        } else { 
            System.debug(' no events found to update ');
        }
    }
    
    public static testMethod void removeEvent() { 
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        // find an event that contains Tennis
        
        // find events yesterday
        GoogleData.Calendar cal = service.getCalendarByTitle('force.com Team Demo');
        system.debug(cal);
        GoogleData evs_range = service.getEventsRange( cal,
         system.now().addDays(-1), system.now() 
         ); 
        for ( xmldom.element e : evs_range.entries ) { 
            system.debug( GoogleData.getTitle(e) ); 
        }
    
        // delete one 
        xmldom.element del = evs_range.entries.remove(0);
        service.removeEvent( del );
    
    }
    
    public static testMethod void insertEvent() { 
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        GoogleData feed = service.getOwnCalendarsFeed();  
        list<GoogleData.Calendar> cals = GoogleData.calendarFactory(feed.entries); 
        system.debug( 'found calendars '+cals.size() ); 
        cals[0].dump(); 
        GoogleData.Calendar cal = cals.remove(0);
        
        system.debug( cal.id ); system.debug( 'title :' + cal.title );
        event newEvent = new Event(
            subject = 'Tennis with Beth',
            description = 'Meet for a quick lesson.',
            ActivityDateTime = system.now(),
            DurationInMinutes = 60
            ) ;

        xmldom.element entry = service.insertEvent( cal, newEvent );  
        entry.dumpAll();  
    }   
    
    public static testMethod void insertEventMulti() { 
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        GoogleData feed = service.getOwnCalendarsFeed();  
        list<GoogleData.Calendar> cals = GoogleData.calendarFactory(feed.entries); 
        system.debug( 'found calendars '+cals.size() ); 
        cals[0].dump(); 
        GoogleData.Calendar cal = cals.remove(0);
        system.debug( cal.id ); system.debug( 'title :' + cal.title );
        list<Event> evtList = new list<Event>();
        
        evtList.add(  new Event(
            subject = 'Tennis with Jill',
            description = 'Meet for a quick lesson.',
            ActivityDateTime = system.now(),
            DurationInMinutes = 60
            ) );
        evtList.add(  new Event(
            subject = 'Tennis with Debbie',
            description = 'Meet for a quick lesson.',
            ActivityDateTime = system.now().addHours(1),
            DurationInMinutes = 60
            ) );

        // insert and dump the event entry
        xmldom.element entry = service.insertEvents( cal, evtList );  
        entry.dumpAll();  
    }
        
    public static testMethod  void listCalendars() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData feed = service.getAllCalendarsFeed(); 
        feed.dump();  // works 
    } 
     
    public static testMethod  void listown() { 
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData feed = service.getFeed( CalendarService.ownCalendars );       
        feed.dump();  // works
        list<GoogleData.Calendar> cals = GoogleData.calendarFactory(feed.entries); 
        GoogleData.Calendar cal = cals.remove(0);
        system.debug( cal.id ); system.debug( 'title :' + cal.title );
        system.debug ( 'updated :  ' + cal.updated );
    } 
    
    public static testMethod  void findTitle() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData.Calendar cal = service.getCalendarByTitle('Platform');  
        cal.dump(); 
        system.debug( cal.id ); system.debug( 'title :' + cal.title );
        system.debug ( 'updated :  ' + cal.updated );
        
        // example using a query string to calendar feed
        // q= matches anywhere in the calendar entry
        string query = EncodingUtil.urlEncode('Platform Marketing','UTF-8' ); 
        GoogleData cal2 = service.getFeed( CalendarService.defaultFeed + '?q=' + query );  
        cal2.dump(); 

        query = EncodingUtil.urlEncode('"Team Demo"','UTF-8' );
        cal2 = service.getFeed( CalendarService.defaultFeed + '?q=' + query );  
        cal2.dump();     
    } 

    public static testMethod  void findTitleQuery() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        string query = EncodingUtil.urlEncode('"Team Demo"','UTF-8' ); 
        GoogleData cal2 = service.getFeed( CalendarService.defaultFeed + '?q=' + query );  
        cal2.dump(); 
    }

    public static testMethod  void eventFeed() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData.Calendar cal = service.getCalendarByTitle('Platform');  
        cal.dump(); 
        system.debug( cal.id ); system.debug( 'title :' + cal.title );
        system.debug ( 'updated :  ' + cal.updated );
        
        // all events ( may be large... )
        GoogleData evs = service.getFeed( cal.alternate ); 
        //evs.dump(); 
        
        system.debug( GoogleData.dateTimeToString( system.now() ) );
        system.debug( GoogleData.dateTimeToString( system.now().addMonths(2) ) );
        
        // get feed with date range
        GoogleData evs_range = service.getEventsRange( cal ,
            system.now(), system.now().addMonths(2) ); 
        evs_range.dump();
        system.debug(service.response.getBody()); 
        //  convert events in this feed into System.Events()
        list<Event> systemevents = cal.eventFactory( evs_range.entries ); 
        for( Event eee: systemevents) system.debug( eee ); 
    } 
 
    // Creating new calendars  
    public static testMethod  void newCalendar() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData.Calendar cal = GoogleData.createCalendarEntry('test cal','summary for cal');
        // here you can set the gCal:timezone, gd:where etc.. 
        
        xmldom.element newcal = service.insertCalendar( cal );
        newcal.dumpall();  
    }
    
    // Deleting calendars
    public static testMethod  void Deletingcalendars() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData.Calendar cal = GoogleData.createCalendarEntry('test delete','summary for cal');
        // here you can set the gCal:timezone, gd:where etc.. 
        
        xmldom.element newcal = service.insertCalendar( cal );
        newcal.dumpall();  
        // now delete it
        service.remove(newcal);
    }
    
    // Updating existing calendars
    // CalendarServiceTest.updatingCalendars() ;
     public static testMethod  void updatingCalendars() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData.Calendar gcal = service.getCalendarByTitle('test');
        system.debug(service.response.getBody());
        gcal.dump();
        
        gcal.entry.getElementByTagName('gCal:color').attributes.put('value','#0D7813');
        gcal.entry.getElementByTagName('gCal:selected').attributes.put('value','true');
    
        system.debug( gcal.toXmlString() );
        service.makePutRequest(gcal.edit, gcal.toXmlString()); 
     }
     
     public static testMethod  void fakeCalendar() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData result = new GoogleData( new xmldom(rawCalendar) );
        GoogleData.Calendar cal = new GoogleData.Calendar( result.entries[0]);
        service.removeEvent( new xmldom.element('sdfsdf') );
        service.insertEvent( cal ,  new Event(
            subject = 'Tennis with Beth',
            description = 'Meet for a quick lesson.',
            ActivityDateTime = system.now(),
            DurationInMinutes = 60
            ) 
         );
     } 
     public static testMethod  void testgetEventsRange() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        
        GoogleData result = new GoogleData( new xmldom(rawCalendar) );
        GoogleData.Calendar cal = new GoogleData.Calendar( result.entries[0]);
        service.getEventsRange( cal, system.now(), system.now().addhours(3) );
        
     } 
     public static testMethod  void testremove() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        GoogleData result = new GoogleData( new xmldom(rawCalendar) );
        GoogleData.Calendar cal = new GoogleData.Calendar( result.entries[0]);
        service.remove( result.entries[0]  );
     } 
     public static testMethod  void testupdateevent() {
        CalendarService service = new CalendarService();  
        service.setAuthSubToken(sessionAuthToken); 
        GoogleData result = new GoogleData( new xmldom(rawCalendar) );
        GoogleData.Calendar cal = new GoogleData.Calendar( result.entries[0]);
        service.updateEvent( result.entries[0]  );
     } 
      
     static string rawCalendar = 
     '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:gCal=\'http://schemas.google.com/gCal/2005\' xmlns:gd=\'http://schemas.google.com/g/2005\'>' +
     '<id>http://www.google.com/calendar/feeds/default/allcalendars/full</id><updated>2008-06-18T04:38:55.696Z</updated><title type=\'text\'>Nick Tran\'s Calendar List</title><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/allcalendars/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/allcalendars/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/allcalendars/full\'/><author><name>Nick Tran</name><email>sforcedemos@gmail.com</email></author><generator version=\'1.0\' uri=\'http://www.google.com/calendar\'>Google Calendar</generator><openSearch:startIndex>1</openSearch:startIndex><entry><id>http://www.google.com/calendar/feeds/default/allcalendars/full/sforcedemos%40gmail.com</id><published>2008-06-18T04:38:55.745Z</published><updated>2008-06-18T04:38:07.000Z</updated><title type=\'text\'>force.com Team Demo</title><link rel=\'alternate\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/sforcedemos%40gmail.com/private/full\'/><link rel=\'http://schemas.google.com/acl/2007#accessControlList\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/sforcedemos%40gmail.com/acl/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/allcalendars/full/sforcedemos%40gmail.com\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/allcalendars/full/sforcedemos%40gmail.com\'/><author><name>Nick Tran</name><email>sforcedemos@gmail.com</email></author>'+
     '<gCal:timezone value=\'America/Los_Angeles\'/><gCal:hidden value=\'false\'/><gCal:color value=\'#2952A3\'/><gCal:selected value=\'false\'/><gCal:accesslevel value=\'owner\'/></entry></feed>';
     
}
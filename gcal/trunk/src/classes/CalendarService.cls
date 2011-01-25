public class CalendarService {
  
    GoogleService service = new GoogleService('Calendar');
    public void setAuthSubToken(string t) { service.AuthSubToken = t;   }

    public static final string defaultFeed = 'http://www.google.com/calendar/feeds/default';
    public static final string allCalendars = 'http://www.google.com/calendar/feeds/default/allcalendars/full';
    public static final string ownCalendars = 'http://www.google.com/calendar/feeds/default/owncalendars/full';
    
    public Boolean useClientLogin(String username, String password)
	{
		return service.authenticateWithClientLogin(username, password, 'cl');	
	}
	
    public void makePutRequest( string editUrl, string body) {
        service.makePutRequest( editUrl, body);
    }
    
    public GoogleData getFeed(string url) { return service.getFeed(url); }
    
    public GoogleData getAllCalendarsFeed() {
        return service.getFeed(CalendarService.allCalendars); 
    }
    
    public GoogleData getOwnCalendarsFeed() {
        return service.getFeed(CalendarService.ownCalendars); 
    } 
     
    public GoogleData.Calendar getCalendarByTitle( string title ) {  
        GoogleData feed = service.getFeed(CalendarService.allCalendars);
        for (xmldom.element ee: feed.entries ) { 
            // system.debug ( GoogleData.getTitle(ee) );
            if ( ee.getValue('title').startsWith (title) ) {  
                return new GoogleData.Calendar(ee); 
            }
        } 
        return null; 
    } 
    
    // helper to get events in a range, important if the calendar is large ( many events)
    public GoogleData getEventsRange( GoogleData.Calendar c, datetime min, datetime max) { 
        GoogleData evs_range = service.getFeed( c.alternate + 
             '?start-min='+ GoogleData.dateTimeToString( min ) +
             '&start-max='+  GoogleData.dateTimeToString( max ) + 
             '&orderby=starttime' ); 
         return evs_range;          
    }
    
    //  batch insert
    /* 
    <feed xmlns='http://www.w3.org/2005/Atom' 
      xmlns:batch='http://schemas.google.com/gdata/batch'
      xmlns:gCal='http://schemas.google.com/gCal/2005'>
      <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event' />
      <entry>
        <batch:id>1</batch:id>
        <batch:operation type='insert' />
        <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event' />
        <title type='text'>Event inserted via batch</title>
      </entry>
      <entry>
    */ 
     
    public xmldom.element insertEvents( GoogleData.Calendar c, list<Event> evtList) {
        xmldom.element feed = new xmldom.element('feed'); 
        feed.attributes.put( 'xmlns','http://www.w3.org/2005/Atom');
        feed.attributes.put( 'xmlns:batch','http://schemas.google.com/gdata/batch');
        feed.attributes.put( 'xmlns:gCal','http://schemas.google.com/gCal/2005');
        feed.attributes.put( 'xmlns:gd','http://schemas.google.com/g/2005');
        // <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event' />
        xmldom.element cat =  new xmldom.element('category');
        cat.attributes.put( 'scheme','http://schemas.google.com/g/2005#kind');
        cat.attributes.put( 'term','http://schemas.google.com/g/2005#event');
        feed.appendChild(cat);

        // build an entry for each event in the list
        integer batchid = 1;
        for ( Event e: evtList) {
            xmldom.element entry =new xmldom.element('entry'); 
            entry.appendChild( Googledata.createTextNode ( 'title',e.subject) );
            entry.appendChild( Googledata.createTextNode ( 'content',e.description) );
            // TODO support for recurring events
            
            // construct start and end times
            xmldom.element ewhen = new xmldom.element('gd:when');
            ewhen.attributes.put('startTime',GoogleData.dateTimeToString(e.activityDateTime));
            datetime endtime = e.activityDateTime.addMinutes(e.DurationInMinutes);
            ewhen.attributes.put('endTime',GoogleData.dateTimeToString(endtime));
            entry.appendChild(ewhen); 
            
            //add web links for sf
          //  xmldom.element sflink = new xmldom.element('g')
            
            
            
            // add batch info to the element 
            xmldom.element bid = GoogleData.makeElement( 'batch:id',string.valueof( batchid ) );
            entry.appendchild( bid ); 
            xmldom.element bop =  new xmldom.element('batch:operation');
            bop.attributes.put('type','insert');
            entry.appendChild( bop );
                    
            batchid++; // increment the batch counter
            
            entry.dumpall();
            feed.appendChild( entry ); 
        }
        
        // take the entries list, wrap in a feed
        string body = feed.toXmlString(); 
        service.makePostRequest( c.alternate + '/batch', body );
        return service.responseXml.root; 
    } 
    
    public xmldom.element insertEvent( GoogleData.Calendar c, Event evt) {
        return insertEvents( c, new list<Event>{evt}  );
    }
    
    /*    
    public xmldom.element insertEvent( GoogleData.Calendar c, string body) {
        service.makePostRequest( c.alternate, body );
        return  service.responseXml.root ; // response is an entry, not feed
    } 
    */
    
    public xmldom.element insertCalendar( GoogleData.Calendar c) {
        string body = c.toXmlString(); 
        service.makePostRequest( CalendarService.ownCalendars, c.toXmlString() );
        return  service.responseXml.root ; // response is an entry, not feed
    } 
    
    public void removeEvent( xmldom.element ev ) {
        string editUrl  = GoogleData.getRelLink(ev,'edit');
        if ( editUrl == null ) { system.debug( 'ERROR missing edit url'); return ; }
        service.makeDeleteRequest( editUrl );
    }
    public void remove( xmldom.element obj) {
        string editUrl  = GoogleData.getRelLink(obj,'edit');
        if ( editUrl == null ) { system.debug( 'ERROR missing edit url'); return ; }
        service.makeDeleteRequest( editUrl );
    }
    
    // updates use PUT
    public void updateEvent( xmldom.element ev ) {
        string editUrl  = GoogleData.getRelLink(ev,'edit');
        if ( editUrl == null ) { system.debug( 'ERROR missing edit url'); return ; }
        /*
         * for events, we need to construct the required namespaces on the entry passed in
         * these were on the feed, but here we have only an entry to update, add the 
         * attributes we need looks like this: 
         * <entry xmlns='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'...
         */
        xmldom.element node = ev.getElementByTagName('entry');
        GoogleData.addNameSpace(node); 
        GoogleData.addAPINameSpace(node, 'xmlns:gCal','http://schemas.google.com/gCal/2005');
        string body = ev.toXmlString();
        system.debug( body); 
         
        service.makePutRequest( editUrl, body);
    }
    
    public HttpResponse response { get { return service.response; } } 
         
}
public class GoogleData {

	public xmldom.element feed { get; set ;} 
	public GoogleData(xmldom dom) { feed = dom.getElementByTagName('feed'); 
		if (feed==null)  { 
			// this occurs when we get exactly one record back, rather than a feed of entries
			// seen when fetching one entry from contact api 
			xmldom.element entry = 	dom.getElementByTagName('entry');
			if (entry != null) { // wrapp in a feed
				xmldom tmp = new xmldom('<feed></feed>');
				feed = tmp.getElementByTagName('feed'); 
				feed.appendChild(entry);
			} 
		}
	}
	
	public static string getKey(xmldom.element e) {
		string id = e.getValue('id');
		string[] tt = id.split('/'); 
		return tt[tt.size()-1]; 
	} 
	public string self { get { return GoogleData.getRelLink(feed,'self'); }}
	
	public string postUrl { get { // not all feeds have a post url, do check for null 
		return GoogleData.getRelLink( feed, 'http://schemas.google.com/g/2005#post');
	}}
	
	public static string getRelLink(xmldom.element e, string rtype ) { 
		for (xmldom.element ee: e.getElementsByTagName('link')) {
			if (ee.getAttribute('rel') == rtype ) { 
				return ee.getAttribute('href');
			}
		} return null;
	}
	
	public datetime updated { get { return GoogleData.updated(feed); } } 
 	public static  datetime updated(xmldom.element e) { 
		string up = e.getValue('updated'); 
		return (up==null?null: datetime.valueof(up.replace('T',' ')) );   
 	}
	
	public list<xmldom.element> entries { 
		get {	return feed.getElementsByTagName('entry'); }  
	}
	public list<xmldom.element> getEntries() { 	return entries;	}
	
   	// common properties of a feed   	
	public list<xmldom.element> links { 
		get { return feed.getElementsByTagName('link');} 
	}
	
 	public string id { get { return feed.getValue('id'); } } 
 	public string title { get { return feed.getValue('title'); } } 
			
	public void insertEntry(xmldom.element ent) {
		// add an entry to feed ( is this used ?)
		feed.appendChild( ent ); 
	}
	
	public list<xmldom.element> errors { 
		get { 
			list<xmldom.element> ret = new list<xmldom.element>();
			for (xmldom.element en: entries) {
	   			if (en.getValue('title') == GoogleData.FatalError) 
	   				ret.add( en );	
	   		}
			return ret;
		}  
	} 
	public static string FatalError = 'Fatal Error';
	
	// some static helpers, syntax sweetner for xmldom elements that are 
	// also GooglData Entries
	public static string getTitle(xmldom.element e) { return e.getValue('title'); }
	
	public void dump() { feed.dumpAll(); }


	/* ********************************************
	 Subclass of GoogleData is a spreadsheet cell
	 we use a static factory and a instance of Cell to traverse these details
	 
	 */
	
	
	public class Cell {
		xmldom.element e; 
		public Cell(xmldom.element ee) { e=ee;
			cell = e.getElementByTagName('gs:cell'); 	// for performance fill props now
		 	row = cell.getAttribute('row');			// these will be accessed in a loop 
		 	col = cell.getAttribute('col');
		}
		
		/*  construct a cell in memory, apply the edit url ending with latest,
			assign row and col, user must set content on this cell before passing  
			this cell to updateCells()
			*/
		public Cell(worksheet w, integer newrow, integer newcol ) {
			row = String.valueof(newrow); col = String.valueof(newcol);
			// construct a cell in memory, apply the edit url ending with 'latest'
			// assign row and col
			this.e = new xmldom.element('entry');
			xmldom.element gscell = new xmldom.element('gs:cell');
			gscell.attributes.put('col', col );
			gscell.attributes.put('row', row );
			e.appendChild( gscell );
 	
	 		xmldom.element id = new xmldom.element('id');
			id.nodeValue = w.getCellFeedUrl() + '/' + rowColId();
	 		e.appendChild(id);
	 			 		
	 		xmldom.element link = new xmldom.element('link');
			link.attributes.put('href',w.getCellFeedUrl() + '/'+rowColId() +'/latest');
			link.attributes.put('rel','edit');
			link.attributes.put('type','application/atom+xml');
			
	 		e.appendChild(link);
	 		e.appendChild(new xmldom.element('content'));
			// e is now an empty cell that can be used to overwrite a cell in the worksheet		
		}
		
		public string id { get { return e.getValue('id'); } } 
		public string title { get { return e.getValue('title'); } } 		
		public string col { get; private set; }
		public string row { get; private set; }
		public string edit { get { return GoogleData.getRelLink(e,'edit' ); } }
		public xmldom.element cell { get; private set; }
		public string content { 
			get { content = e.getValue('content');
				return (content==null?  '' : content); 	} 
			set { e.getElementByTagName('content').nodeValue = value; } }

		public string rowColId(){
			return 'R'+row+'C'+col;
		}
		// return the xml needed to update this cell, used in building a batch update
		public string toXmlBatchEntryString() {
			string ret= '<entry>\n' + '<batch:id>R'+row+'C'+col+'</batch:id>\n' ;
			ret += '<batch:operation type="update"/>\n' ;
			ret += '<content type="text">'+this.content+'</content>\n' ;
			ret += '<title type="text">R'+row+'C'+col+'</title>\n' +'<id>'+id+'</id>\n' ;
			ret += '<link rel="edit" type="application/atom+xml" \n   href="'+edit+'"/>\n';
			ret += '<gs:cell row="'+this.row+'" col="'+this.col+ '" inputValue="'+
			this.content+'"/>\n' + '</entry>';
			return ret;	
		}
		
		public void dump() { e.dumpAll(); }	
	}	


	/* ********************************************
	 Subclass of GoogleData is a worksheet within a spreadsheet
	 we use a static factory and an instance of traverse these details
	 
	 */
	public static list<Worksheet> WorksheetFactory(list<xmldom.element> entries) { 
		list<Worksheet> ret = new list<Worksheet>(); 
		for (xmldom.element ee: entries ) { 
			ret.add( new GoogleData.Worksheet(ee) ); 	
		} return ret;
	}
	public class Worksheet {
		xmldom.element w;
		public Worksheet( xmldom.element worksheet) 
		{ 	w=worksheet;
			cells = new list<cell>(); // new worksheet has an empty list of cells
		}
	
		public string id { get { return w.getValue('id'); } } 
		public string title { get { return w.getValue('title'); } 
			set { w.getElementByTagName('title').nodeValue = value; } } 		
		public string totalResults { get { return w.getValue('totalResults'); } }
		public string startIndex { get { return w.getValue('startIndex'); } }
		public string edit { get { return GoogleData.getRelLink(w,'edit' ); } }
		public datetime updated { get { return GoogleData.updated(w); } } 
	
		public void dump() { w.dumpAll(); }	
		public string toXmlString() { 
			xmldom.element node = w.clone(); 
			node.attributes.put( 'xmlns','http://www.w3.org/2005/Atom');
    		node.attributes.put( 'xmlns:gs','http://schemas.google.com/spreadsheets/2006'); 	
			return node.toXmlString(); 
		}
		
		public string makeRange( integer row, integer colcount, integer batchsize) { 
			string r = string.valueof(row); string c = string.valueof(colcount);
			string endrow = string.valueof(row+batchsize);
			/*
			 *  range=A1 and range=R1C1 both specify only cell A1.
   			 * range=D1:F3 and range=R1C4:R3C6 both specify the rectangle of 
   			 cells with corners at D1 and F3.
			*/
			return 'R'+r+'C'+1+':R'+endrow+'C'+c;
		}
		public string getCellFeedUrl() {
 			return GoogleData.getRelLink( w, 
 			'http://schemas.google.com/spreadsheets/2006#cellsfeed');
 		}
	 	public string cellFeedUrl { 
	 		get { return GoogleData.getRelLink( w, 
	 			'http://schemas.google.com/spreadsheets/2006#cellsfeed'); }
	 	} 
	 	public string listFeedUrl { 
	 		get { return GoogleData.getRelLink( w, 
	 			'http://schemas.google.com/spreadsheets/2006#listfeed'); }
	 	} 
	 	public string postUrl { 
	 		get { return GoogleData.getRelLink( w, 
	 			'http://schemas.google.com/g/2005#post'); }
	 	} 

	 	public string editUrl { 
	 		get { return GoogleData.getRelLink( w, 
	 			'edit'); }
	 	}	 	
	 	public list<cell> cells { get ; set; } 
	 	
	 	public list<cell> cellFactory(list<xmldom.element> cellsin) { 
			// clear out the old list?
			cells.clear(); 
			
			for (xmldom.element ee: cellsin) { 
				cells.add( new GoogleData.Cell(ee) ); 	
			} 
			return cells;
		}
		
	 	public Map<String,cell> cellFactoryAsMap(list<xmldom.element> cellsin) { 
			// clear out the old list?
			Map<String,cell> cellMap = new Map<String,cell>(); 
			GoogleData.Cell currCell;
			for (xmldom.element ee: cellsin) { 
				currCell =  new GoogleData.Cell(ee);
				cellMap.put(currCell.rowColId(),currCell); 	
			} 
			return cellMap;
		}

		string escape(string cc) { return cc.replace('&','&amp;'); }
		
		// set a value by using row column numbers
		// this is expensive in script statements, needs to be optmized
		// each invoke is ~ 100 statements, can do better..
		public string getCellContent(integer row,integer col,list<cell> fromlist) {
			string r = string.valueof(row); 
 			string c = string.valueof(col);
 			for( Cell gc: fromlist) {
				if ( gc.row == r && gc.col == c) {
					return gc.content;	
				}
			} return '';
		} 
		public void setCellContent(integer row,integer col,string val) {
 			string r = string.valueof(row); 
 			string c = string.valueof(col);
 			//system.debug( limits.getScriptStatements() + ' ' + limits.getLimitScriptStatements());
 			for( Cell gc: cells) { 
 				//system.debug(gc.row + ' ' + gc.col);
 				//system.debug( 'stmt :'+limits.getScriptStatements());
 				if ( gc.row == r && gc.col == c) {
 					if ( val == null ) val = '';
					system.debug( 'setting content '+'R'+r+' C'+c+ '>'+val); 
					gc.content = escape(val);
					system.debug(gc.content);
					gc.dump();
					return; 		
 				}
 			}
 			//system.debug('did not find '+r + ' '+c);	
 		}
 		public list<cell> getRowCells(integer row) { 
 			list<cell> ret = new list<cell>();
 			string r = string.valueof(row); 
 			for(GoogleData.Cell gc: cells) { 
				if (gc.row == r ) ret.add(gc); 
			} return ret;
 		}

/* requires dynamic apex in the org you are running / installing in
 this is developer preview at this time
 		public void setRowCellsFromQuery( integer row, string fieldnames,	
 												sobject sobj, 
 												Map<String, Schema.SObjectField> M )
 		{
 			integer col = 1; 
 			for (string f : fieldnames.split(',') ) { 
 				// order of columns taken from fields list
				f = f.trim();
				// system.debug(  sobj.get( M.get(f) ) );
				setCellContent(row,col, string.valueof( sobj.get( M.get(f) ) ) );
				col++;
			} 		
 		}
*/ 		
 		// takes every cell in this worksheet ( passed into factory ) and 
 		// generates a batch feed for update
 		public string getBatchFeedBody() { 
		    return getBatchFeedListBody(cells);
		} 
		
		// do only the cells passed in
		public string getBatchFeedListBody(list<GoogleData.Cell> todo) { 
			string 
			ret = '<feed ' + ATOM_NMSPACE + ' ' + GBATCH_NMSPACE + ' ';
			ret += GS_NMSPACE + '>\n<id>'+ w.getValue('id') + '</id>\n' ;
			for(GoogleData.Cell gc: todo) { 
				ret += gc.toXmlBatchEntryString(); 
			}
		    ret += '</feed>\n'; 
		    system.debug(ret);
		    return ret;
		} 

		final String ATOM_NMSPACE='xmlns="http://www.w3.org/2005/Atom"';
		final String GBATCH_NMSPACE='xmlns:batch="http://schemas.google.com/gdata/batch"';
	 	final String GS_NMSPACE='xmlns:gs="http://schemas.google.com/spreadsheets/2006"';
		final String GSX_NMSPACE='xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended"';
		
		
		/*
	
		*/
	}	// end Worksheet class
	
	
	/* 
	
	*/
	
	/* ********************************************

		*/
	
	
	
	/* ********************************************
	Calendar
	*/
	public static list<Calendar> calendarFactory(list<xmldom.element> entries) { 
		list<Calendar> ret = new list<Calendar>(); 
		for (xmldom.element ee: entries ) { 
			ret.add( new GoogleData.Calendar(ee) ); 	
		} return ret; 
	}
	public class Calendar {
		xmldom.element c;
		public void dump() { c.dumpAll(); }	
		public Calendar( xmldom.element ca) { 	c=ca;}
		public string id { get { return c.getValue('id'); } } 
		public string title { get { return c.getValue('title'); } } 		
		public string summary { get { return c.getValue('summary'); } }
		public xmldom.element entry { get {return c;} } 		
		public datetime updated { get { return GoogleData.updated(c); } } 
		public string alternate { get { return GoogleData.getRelLink(c,'alternate' ); } }
		public string edit { get { return GoogleData.getRelLink(c,'edit' ); } }
		public datetime published { get { 
			string up = c.getValue('published'); 
			return (up==null?null: datetime.valueof(up.replace('T',' ')) );   
 		} }
		// todo: add timezone, hidden, color, selected, accesslevel, where
		
	    
		// event factory that produces System.Event() 
		public list<Event> eventFactory(list<xmldom.element> entries) { 
			list<Event> ret = new list<Event>(); 
			for (xmldom.element ee: entries ) { 
				/* fields available in Salesforce
				Select e.WhoId, e.WhatId, e.View_Event__c, e.Url__c, e.Type, 
				e.SystemModstamp, e.Subject, e.StartDateTime, e.ShowAs, e.ReminderDateTime, 
				e.RecurrenceType, e.RecurrenceTimeZoneSidKey, e.RecurrenceStartDateTime, 
				e.RecurrenceMonthOfYear, e.RecurrenceInterval, e.RecurrenceInstance, 
				e.RecurrenceEndDateOnly, e.RecurrenceDayOfWeekMask, e.RecurrenceDayOfMonth, 
				e.RecurrenceActivityId, e.OwnerId, e.Location, e.Link__c, e.LastModifiedDate, 
				e.LastModifiedById, e.IsReminderSet, e.IsRecurrence, e.IsPrivate, e.IsGroupEvent, 
				e.IsDeleted, e.IsChild, e.IsArchived, e.IsAllDayEvent, e.Id, e.GoogleEventId__c, 
				e.Goog_Edit_Link__c, e.Goog_Alternate_Link__c, e.EndDateTime, e.DurationInMinutes,
				e.Description, e.CreatedDate, e.CreatedById, e.ActivityDateTime,
				 e.ActivityDate, e.AccountId From Event e
				*/	
				/* contents from google 
				 id->http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/i5r4ahni72g5sp8hs15n6q5omc {}
			      published->2008-05-12T23:56:37.000Z {}
			      updated->2008-05-12T23:56:37.000Z {}
			      category-> {scheme=http://schemas.google.com/g/2005#kind, term=http://schemas.google.com/g/2005#event}
			      title->Agile 2008 {type=text}
			      content-> {type=text}
			      link-> {href=http://www.google.com/calendar/event?eid=aTVyNGFobmk3Mmc1c3A4aHMxNW42cTVvbWMgZmxjZ3MyN29kYWFkanZudjk3cThvdTJnaTRAZw, rel=alternate, title=alternate, type=text/html}
			      link-> {href=http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/i5r4ahni72g5sp8hs15n6q5omc, rel=self, type=application/atom+xml}
			      link-> {href=http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/i5r4ahni72g5sp8hs15n6q5omc/63346319797, rel=edit, type=application/atom+xml}
			      author-> {}
			        name->Paul Kopacki {}
			          email->pkopacki@gmail.com {}
			      gd:comments-> {}
			      gd:feedLink-> {href=http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/i5r4ahni72g5sp8hs15n6q5omc/comments}
			      gd:eventStatus-> {value=http://schemas.google.com/g/2005#event.confirmed}
			      gd:visibility-> {value=http://schemas.google.com/g/2005#event.default}
			      gd:transparency-> {value=http://schemas.google.com/g/2005#event.transparent}
			      gCal:uid-> {value=i5r4ahni72g5sp8hs15n6q5omc@google.com}
			      gCal:sequence-> {value=0}
			      gd:when-> {endTime=2008-08-05, startTime=2008-08-04}
			      gd:who-> {email=flcgs27odaadjvnv97q8ou2gi4@group.calendar.google.com, rel=http://schemas.google.com/g/2005#event.organizer, valueString=Platform Mktg  Events Universe -- events of interest}
			      gd:where-> {}
				*/
				Event tmp = new Event( subject=ee.getValue('title') );
				tmp.description = ee.getValue('content');
				xmldom.element eventWhen = ee.getElementByTagName('gd:when');
				string startTime = eventWhen.attributes.get('startTime');
        		try { 
        			tmp.ActivityDateTime = stringTodateTime(startTime);
        		} catch (exception e) { 
        			// deal with all day events
        			string s = startTime.replace('T',' ');
        			tmp.ActivityDate= date.valueof(s);	
        			tmp.IsAllDayEvent = true;
        		}
				// TOOD more here
				// need routine to turn google time string into date time
				// calc duration in min also
				// don't fill custom fields at this time
				ret.add(tmp);
			}
			return ret;
		}
		
		
		/* 
		convert a System.Event() into an xml atom entry, used when we want to insert
		events into a calendar
		
		TODO test this
		*/
		public  xmldom.element createEventElement( Event e) { 
			
			xmldom.element entry =new xmldom.element('entry'); 
			GoogleData.addNameSpace(entry); 
			
			xmldom.element cat = new xmldom.element('category');	
			cat.attributes.put('scheme','http://schemas.google.com/g/2005#kind');
			cat.attributes.put('term','http://schemas.google.com/g/2005#event');
			entry.appendChild(cat);
		
			entry.appendChild( Googledata.createTextNode ( 'title',e.subject) );
			entry.appendChild( Googledata.createTextNode ( 'content',e.description) );
			// TODO support for recurring events 
			
			// construct start and end times
			xmldom.element ewhen = new xmldom.element('gd:when');
			ewhen.attributes.put('startTime',dateTimeToString(e.activityDateTime));
			datetime endtime = e.activityDateTime.addMinutes(e.DurationInMinutes);
			ewhen.attributes.put('endTime',dateTimeToString(endtime));
			entry.appendChild(ewhen); 
			
			return entry;
		} 
		
		public string createEventAtom( Event e) {
			return createEventElement(e).toXmlString();
		} 
		public string toXmlString() { 
			xmldom.element node = c.clone(); 
			node.attributes.put( 'xmlns','http://www.w3.org/2005/Atom');
    		node.attributes.put( 'xmlns:gd','http://schemas.google.com/g/2005');
    		node.attributes.put( 'xmlns:gCal','http://schemas.google.com/gCal/2005');  	
			return node.toXmlString(); 
		}
	
	}
	public static xmldom.element createTextNode(string name,string value) { 
		xmldom.element ret = new xmldom.element(name);
		ret.attributes.put('type','text');
		ret.nodeValue = value;
		return ret;
	} 
	public static Calendar createCalendarEntry(string title,string summary) {
		xmldom.element entry =new xmldom.element('entry'); 
		GoogleData.addNameSpace(entry); 
		
		entry.appendChild( Googledata.createTextNode ( 'title',title) );
		entry.appendChild( Googledata.createTextNode ( 'content',summary) );
		
		return new Calendar( entry) ;
	} 	
	
	// Helper for google calendar
    public static string dateTimeToString(datetime t) { 
		return string.valueofgmt(t).replace(' ','T') + '.000Z';
	}
	
	// Convert Retrieved Google Calendar Times to Apex dateTime  
    public static dateTime stringTodateTime(string s) { 
       s = s.replace('T',' ');
       // since google returns this format
       // {endTime=2008-06-14T10:00:00.000-07:00
       // so, don't use the GMT version of this.
       return dateTime.valueof(s);
    }
    
	public static void addNameSpace( xmldom.element node) { 
    	node.attributes.put( 'xmlns','http://www.w3.org/2005/Atom');
    	node.attributes.put( 'xmlns:gd','http://schemas.google.com/g/2005'); 	
	}
	public static void addAPINameSpace( xmldom.element node, string n, string v) {
		node.attributes.put( n,v);
	}
	
	public static xmldom.element makeElement(string name,string val) {
		xmldom.element ret = new xmldom.element(name) ;		
		ret.nodeValue = val;
		return ret;	
	}
	
	/* ********************************************
	Documents
	*/
	
	
	/* ********************************************
	Contacts
	*/
	
	/* 
	Query myQuery = new Query(feedUrl);
	myQuery.setFullTextQuery("Tennis");
	CalendarEventFeed myResultsFeed = myService.query(myQuery, 
	    CalendarEventFeed.class);
    */
	public class Query { // add query params to a query in a standard way
		public string feedUrl {get;set;}
		public Query(string f) {feedUrl=f;}
		public string FullTextQuery {get;set;}
		public integer MaxResults {get;set;}
		public integer StartIndex {get;set;}
		public string url { get  { 
			string tmp = feedUrl;

			if ( FullTextQuery !=null ) 
				tmp = GoogleData.appendQueryArg( tmp, 'q='+FullTextQuery);

			if ( MaxResults !=null ) 
				tmp = GoogleData.appendQueryArg( tmp, 'max-results='+String.valueof(MaxResults));

			if ( StartIndex !=null ) 
				tmp = GoogleData.appendQueryArg( tmp, 'start-index='+String.valueof(StartIndex));
			
			
			return tmp;   	
		} } 
		
		// Author, etc.
	}
	
	public static string appendQueryArg( string url, string param) { 
		string tmp = '';
		if ( url.contains('?') ) { 		tmp = url + '&' + param; }
		else { 							tmp = url + '?' + param; }
		return tmp; 
	}
}
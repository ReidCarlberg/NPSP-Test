public class GoogleDataTest {
    static string contactFeedResponse = 
    '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:gContact=\'http://schemas.google.com/contact/2008\' xmlns:batch=\'http://schemas.google.com/gdata/batch\' xmlns:gd=\'http://schemas.google.com/g/2005\'><id>sforcedemos@gmail.com</id><updated>2008-06-09T21:39:09.406Z</updated><category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/contact/2008#contact\'/><title type=\'text\'>Nick Tran\'s Contacts</title><link rel=\'alternate\' type=\'text/html\' href=\'http://www.google.com/\'/><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full\'/><link rel=\'http://schemas.google.com/g/2005#batch\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full/batch\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full?max-results=25\'/><author><name>Nick Tran</name><email>sforcedemos@gmail.com</email></author><generator version=\'1.0\' uri=\'http://www.google.com/m8/feeds\'>Contacts</generator><openSearch:totalResults>2</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><openSearch:itemsPerPage>25</openSearch:itemsPerPage><entry><id>http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/base/0</id><updated>2008-06-08T17:49:41.995Z</updated><category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/contact/2008#contact\'/><title type=\'text\'>Nick Tran</title><link rel=\'http://schemas.google.com/contacts/2008/rel#edit-photo\' type=\'image/*\' href=\'http://www.google.com/m8/feeds/photos/media/sforcedemos%40gmail.com/0/1B2M2Y8AsgTpgAmY7PhCfg\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full/0\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full/0/1212947381995000\'/><gd:email rel=\'http://schemas.google.com/g/2005#other\' address=\'sforcedemos@gmail.com\' primary=\'true\'/></entry><entry><id>http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/base/6de402568a8ade83</id><updated>2008-06-08T17:51:17.450Z</updated><category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/contact/2008#contact\'/><title type=\'text\'>Phil Deart</title><link rel=\'http://schemas.google.com/contacts/2008/rel#edit-photo\' type=\'image/*\' href=\'http://www.google.com/m8/feeds/photos/media/sforcedemos%40gmail.com/6de402568a8ade83/1B2M2Y8AsgTpgAmY7PhCfg\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full/6de402568a8ade83\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full/6de402568a8ade83/1212947477450000\'/><gd:email rel=\'http://schemas.google.com/g/2005#other\' address=\'info@def.org\' primary=\'true\'/><gd:phoneNumber rel=\'http://schemas.google.com/g/2005#mobile\'>555</gd:phoneNumber></entry></feed>';
   
    public static  testmethod void t1() { 
        xmldom f = new xmldom(contactFeedResponse);
        GoogleData gd = new GoogleData( f);
        system.debug (gd.self); 
        system.assert (gd.self == 'http://www.google.com/m8/feeds/contacts/sforcedemos%40gmail.com/full?max-results=25');
        
        system.debug( GoogleData.getRelLink(gd.feed,'self') );  
        system.assert( gd.self == GoogleData.getRelLink(gd.feed,'self')  );
        system.assert( GoogleData.getRelLink(gd.feed,'bogus') == null  );
        
        system.debug( gd.updated );
        system.assert( gd.updated != null); 
         
        system.debug( gd.entries );
        system.assert( gd.entries.size() > 0); 
        
        system.assert( gd.links.size() > 0 );
        system.assert( gd.entries.size() == gd.getEntries().size() );
        
        system.assert( gd.id != null); 
        
        system.assert( gd.title == GoogleData.getTitle(gd.feed) ); 
        
        gd.insertEntry( new xmldom.element('<id>foo</id>') );
          
        system.assert( gd.errors.size() == 0); 
        gd.insertEntry( new xmldom.element('<title>FatalError</title>') );
        //system.assert( gd.errors.size() == 1);
        
        GoogleData.addNameSpace( gd.entries[0] );
        GoogleData.addAPINameSpace( gd.entries[0] ,'sdf','wer');
    } 
    
    public static string testCellsFeed = 
    '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:gs=\'http://schemas.google.com/spreadsheets/2006\' xmlns:batch=\'http://schemas.google.com/gdata/batch\'><id>http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full</id><updated>2008-06-07T05:05:41.254Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#cell\'/><title type=\'text\'>Sheet1</title><link rel=\'alternate\' type=\'text/html\' href=\'http://spreadsheets.google.com/ccc?key=o12612000142644651407.6804866143906912412\'/><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full\'/><link rel=\'http://schemas.google.com/g/2005#batch\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/batch\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full?range=A2%3Ac2&amp;return-empty=true\'/><author><name>sforcedemos</name><email>sforcedemos@gmail.com</email></author><openSearch:totalResults>3</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><gs:rowCount>68</gs:rowCount><gs:colCount>20</gs:colCount><entry><id>http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C1</id><updated>2008-06-07T05:05:41.254Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#cell\'/><title type=\'text\'>A2</title><content type=\'text\'>003T0000005liESIAY</content><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C1\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C1/y04gv6\'/><gs:cell row=\'2\' col=\'1\' inputValue=\'003T0000005liESIAY\'>003T0000005liESIAY</gs:cell></entry><entry><id>http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C2</id><updated>2008-06-07T05:05:41.254Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#cell\'/><title type=\'text\'>B2</title><content type=\'text\'>Rose</content><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C2\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C2/h7ecv\'/><gs:cell row=\'2\' col=\'2\' inputValue=\'Rose\'>Rose</gs:cell></entry><entry><id>http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C3</id><updated>2008-06-07T05:05:41.254Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#cell\'/><title type=\'text\'>C2</title><content type=\'text\'>Freedom</content><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C3\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full/R2C3/h3riuu\'/><gs:cell row=\'2\' col=\'3\' inputValue=\'Freedom\'>Freedom</gs:cell></entry></feed>';
    
    public static string testWorksheetFeed = 
    '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:gs=\'http://schemas.google.com/spreadsheets/2006\'><id>http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full</id><updated>2008-06-08T02:18:26.708Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#worksheet\'/><title type=\'text\'>Account Summary</title><link rel=\'alternate\' type=\'text/html\' href=\'http://spreadsheets.google.com/ccc?key=o12612000142644651407.6804866143906912412\'/><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full?tfe=\'/><author><name>sforcedemos</name><email>sforcedemos@gmail.com</email></author><openSearch:totalResults>3</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><entry><id>http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od6</id><updated>2008-06-07T05:05:41.254Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#worksheet\'/><title type=\'text\'>Sheet1</title><content type=\'text\'>Sheet1</content><link rel=\'http://schemas.google.com/spreadsheets/2006#listfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/list/o12612000142644651407.6804866143906912412/od6/private/full\'/><link rel=\'http://schemas.google.com/spreadsheets/2006#cellsfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od6/private/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od6\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od6/bxwnl1565s\'/><gs:rowCount>68</gs:rowCount><gs:colCount>20</gs:colCount></entry><entry><id>http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od4</id><updated>2008-06-08T02:18:26.708Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#worksheet\'/><title type=\'text\'>Sheet3</title><content type=\'text\'>Sheet3</content><link rel=\'http://schemas.google.com/spreadsheets/2006#listfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/list/o12612000142644651407.6804866143906912412/od4/private/full\'/><link rel=\'http://schemas.google.com/spreadsheets/2006#cellsfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od4/private/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od4\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od4/0\'/><gs:rowCount>100</gs:rowCount><gs:colCount>20</gs:colCount></entry><entry><id>http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od7</id><updated>2008-06-08T02:18:26.708Z</updated><category scheme=\'http://schemas.google.com/spreadsheets/2006\' term=\'http://schemas.google.com/spreadsheets/2006#worksheet\'/>'+
    '<title type=\'text\'>the second sheet</title><content type=\'text\'>the second sheet</content><link rel=\'http://schemas.google.com/spreadsheets/2006#listfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/list/o12612000142644651407.6804866143906912412/od7/private/full\'/><link rel=\'http://schemas.google.com/spreadsheets/2006#cellsfeed\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/cells/o12612000142644651407.6804866143906912412/od7/private/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od7\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full/od7/0\'/><gs:rowCount>100</gs:rowCount><gs:colCount>20</gs:colCount></entry></feed>';
    
    // HttpRequest :System.HttpRequest[Endpoint=http://spreadsheets.google.com/feeds/spreadsheets/private/full?title=account, Method=GET]
    //<?xml version='1.0' encoding='UTF-8'?><feed xmlns='http://www.w3.org/2005/Atom' xmlns:openSearch='http://a9.com/-/spec/opensearchrss/1.0/'><id>http://spreadsheets.google.com/feeds/spreadsheets/private/full</id><updated>2008-06-09T22:00:50.117Z</updated><category scheme='http://schemas.google.com/spreadsheets/2006' term='http://schemas.google.com/spreadsheets/2006#spreadsheet'/><title type='text'>Available Spreadsheets - sforcedemos@gmail.com</title><link rel='alternate' type='text/html' href='http://docs.google.com'/><link rel='http://schemas.google.com/g/2005#feed' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/spreadsheets/private/full'/><link rel='self' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/spreadsheets/private/full?title=account&amp;tfe='/><openSearch:totalResults>1</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><entry><id>http://spreadsheets.google.com/feeds/spreadsheets/private/full/o12612000142644651407.6804866143906912412</id><updated>2008-06-08T02:18:19.389Z</updated><category scheme='http://schemas.google.com/spreadsheets/2006' term='http://schemas.google.com/spreadsheets/2006#spreadsheet'/><title type='text'>Account Summary</title><content type='text'>Account Summary</content><link rel='http://schemas.google.com/spreadsheets/2006#worksheetsfeed' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/worksheets/o12612000142644651407.6804866143906912412/private/full'/><link rel='alternate' type='text/html' href='http://spreadsheets.google.com/ccc?key=o12612000142644651407.6804866143906912412'/><link rel='self' type='application/atom+xml' href='http://spreadsheets.google.com/feeds/spreadsheets/private/full/o12612000142644651407.6804866143906912412'/><author><name>sforcedemos</name><email>sforcedemos@gmail.com</email></author></entry></feed>
    /*
    //since we're not using the spreadsheets, we'll remove this test...
    public static  testmethod void testCells() { 
        SpreadsheetService service = new SpreadsheetService();     
        string rng = 'A2:c2';
    
        xmldom f = new xmldom(testWorksheetFeed);
        GoogleData worksheetsFeed = new GoogleData( f);
        worksheetsFeed.dump(); 
        
        system.debug( GoogleData.getKey( worksheetsFeed.feed ) );
        
        list<GoogleData.Worksheet> worksheets = 
            GoogleData.WorksheetFactory(worksheetsFeed.getEntries());
        
        GoogleData.Worksheet ws = worksheets[0];
        
        system.debug( ws.id ); 
        system.debug( ws.title );
        system.debug( ws.totalResults );
        system.debug( ws.startIndex );
        system.debug( ws.edit );
        system.debug( ws.updated ); ws.dump(); 
        
        system.assert( ws.toXmlString() != null );
        ws.title = 'foo';
        system.assert( ws.makeRange( 1,1,1) != null ); 
        
        string cellFeedUrl = ws.getCellFeedUrl();
        //GoogleData feed = service.getFeedRange( cellFeedUrl ,'A1:B2');  // specify range to avoid data overflow
        GoogleData cellsf = new GoogleData ( new xmldom(testCellsFeed) );
        cellsf.dump();
        list<GoogleData.Cell> cells = ws.cellFactory(cellsf.getEntries());                    
        for (GoogleData.Cell cel : cells  ) {
            cel.dump(); 
            system.debug ( cel.title + ' ' + cel.content );  
            system.debug ( cel.id + ' ' +cel.row + ' ' + cel.col + ' ' + cel.edit ); 
            system.assert( cel.toXmlBatchEntryString() != null);
            
            
        }
         
        system.debug ( ws.getCellContent(2,2, cells ) );
        system.assert ( ws.getCellContent(2,2, cells ) == 'Rose' );
        
        ws.setCellContent(2,2, '' );
        ws.setCellContent(2222,2222, '' );
        ws.setCellContent(2222,2222, null );
        
        system.debug ( ws.getCellContent(2,2, cells ) );

        ws.setCellContent(2,2, 'Rose Bud' );
        system.assert ( ws.getCellContent(2,2, cells ) == 'Rose Bud' );

        for (GoogleData.Cell cel : cells  ) {   cel.dump(); }
        
        for (GoogleData.Cell cel : ws.getRowCells(2)  ) { cel.dump(); }
        
        system.debug( ws.getBatchFeedBody() );
        system.assert( ws.getBatchFeedBody().startsWith('<feed xmlns="http://www.w3.org/2005/Atom" xmlns:batch="http://schemas.google.com/gdata/batch" xmlns:gs="http://schemas.g'));
        
        system.assert( googledata.makeElement( 'fsdf','sdf') != null ); 
    }
    
    */
    // test GoogleService here as well...
   public static  testmethod void testSrv1() { 
      Map<String, Schema.SObjectField> ss = GoogleService.getFieldsMap('Account');
   }
   public static  testmethod void testSrv2() { 
        GoogleService g = new GoogleService('foo');
        g.AuthSubToken = 'foo'; 
        system.assert( g.AuthSubToken == 'foo');
        g.makePostRequest( 'foo', 'bar');  
        g.gsessionid = 'tmp';
        g.getFeed( 'sdfsdfsdf?');
        g.getFeed( 'sdfsdfsdf');
        Map<String, Schema.SObjectField> ss = GoogleService.getFieldsMap('Account');
        system.assert( ss != null );
        g.getFeedMethod(    'delete', 'fooo','body','application/atom+xml');
        
    }   
    public static  testmethod void testSrv3() { 
        system.assert( googleservice.getSobjectToken( 'Contact') != null); 
    }
    public static  testmethod void auth() { 
        // how to make a more meaningful test, given that we can't callout in a test method
        AuthSubUtil.getTokenInfo('sess');
        GoogleData g = new GoogleData( new xmldom('<entry>fff</entry>') );
        system.assert( GoogleData.stringTodatetime('2008-06-14 10:00:00.000-07:00' ) != null ); 
    }
    
    // calendar
    //  public static list<Calendar> calendarFactory(list<xmldom.element> entries) { 
    static STRING calTest = 
    '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:gCal=\'http://schemas.google.com/gCal/2005\' xmlns:gd=\'http://schemas.google.com/g/2005\'><id>http://www.google.com/calendar/feeds/default/owncalendars/full</id><updated>2008-06-09T23:19:08.964Z</updated><title type=\'text\'>Nick Tran\'s Calendar List</title><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full\'/><author><name>Nick Tran</name><email>sforcedemos@gmail.com</email></author><generator version=\'1.0\' uri=\'http://www.google.com/calendar\'>Google Calendar</generator><openSearch:startIndex>1</openSearch:startIndex><entry><id>http://www.google.com/calendar/feeds/default/owncalendars/full/sforcedemos%40gmail.com</id><published>2008-06-09T23:19:09.301Z</published><updated>2008-06-06T06:53:30.000Z</updated><title type=\'text\'>force.com Team Demo</title><link rel=\'alternate\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/sforcedemos%40gmail.com/private/full\'/><link rel=\'http://schemas.google.com/acl/2007#accessControlList\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/sforcedemos%40gmail.com/acl/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/sforcedemos%40gmail.com\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/sforcedemos%40gmail.com\'/><author><name>Nick Tran</name><email>sforcedemos@gmail.com</email></author><gCal:timezone value=\'America/Los_Angeles\'/><gCal:hidden value=\'false\'/><gCal:color value=\'#2952A3\'/><gCal:selected value=\'true\'/><gCal:accesslevel value=\'owner\'/></entry><entry><id>http://www.google.com/calendar/feeds/default/owncalendars/full/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com</id><published>2008-06-09T23:19:09.347Z</published><updated>2008-05-25T08:33:17.000Z</updated><title type=\'text\'>Platform Mktg  Events Universe -- events of interest</title><summary type=\'text\'>For tracking all platorm-relevant events, regardless of our participation.</summary><link rel=\'alternate\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full\'/><link rel=\'http://schemas.google.com/acl/2007#accessControlList\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/acl/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com\'/><author><name>Platform Mktg  Events Universe -- events of interest</name></author><gCal:timezone value=\'America/Los_Angeles\'/><gCal:hidden value=\'false\'/><gCal:color value=\'#5A6986\'/><gCal:selected value=\'true\'/><gCal:accesslevel value=\'owner\'/><gd:where valueString=\'\'/></entry><entry><id>http://www.google.com/calendar/feeds/default/owncalendars/full/pg00p3n03g90t05kd25ns47ce8%40group.calendar.google.com</id><published>2008-06-09T23:19:09.352Z</published><updated>2008-06-03T15:12:34.000Z</updated><title type=\'text\'>Platform Mktg Events -- commitments</title><summary type=\'text\'>Key events and milestones.  This calendar should be used for itmes to which we are committed or are seriously planning.  The Dev Mktg Events Universe calendar is for events we want to track but may not be directly involved with (e.g., eBay Dev Con, Rail Conference, etc.). </summary><link rel=\'alternate\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/pg00p3n03g90t05kd25ns47ce8%40group.calendar.google.com/private/full\'/><link rel=\'http://schemas.google.com/acl/2007#accessControlList\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/pg00p3n03g90t05kd25ns47ce8%40group.calendar.google.com/acl/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/pg00p3n03g90t05kd25ns47ce8%40group.calendar.google.com\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/pg00p3n03g90t05kd25ns47ce8%40group.calendar.google.com\'/><author><name>Platform Mktg Events -- commitments</name></author><gCal:timezone value=\'America/Los_Angeles\'/><gCal:hidden value=\'false\'/><gCal:color value=\'#528800\'/><gCal:selected value=\'true\'/><gCal:accesslevel value=\'owner\'/><gd:where valueString=\'\'/></entry><entry><id>http://www.google.com/calendar/feeds/default/owncalendars/full/a3mnbukrn91kbuehc71kotjfbg%40group.calendar.google.com</id><published>2008-06-09T23:19:09.309Z</published><updated>2008-06-09T05:20:46.000Z</updated><title type=\'text\'>Platform Mktg PTO</title><summary type=\'text\'>PTO for Adam\'s team</summary><link rel=\'alternate\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/a3mnbukrn91kbuehc71kotjfbg%40group.calendar.google.com/private/full\'/><link rel=\'http://schemas.google.com/acl/2007#accessControlList\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/a3mnbukrn91kbuehc71kotjfbg%40group.calendar.google.com/acl/full\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/a3mnbukrn91kbuehc71kotjfbg%40group.calendar.google.com\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/default/owncalendars/full/a3mnbukrn91kbuehc71kotjfbg%40group.calendar.google.com\'/><author><name>Platform Mktg PTO</name></author><gCal:timezone value=\'America/Los_Angeles\'/><gCal:hidden value=\'false\'/><gCal:color value=\'#B1440E\'/><gCal:selected value=\'false\'/><gCal:accesslevel value=\'owner\'/><gd:where valueString=\'\'/></entry></feed>';
    static string evtest = 
    '<?xml version=\'1.0\' encoding=\'UTF-8\'?><feed xmlns=\'http://www.w3.org/2005/Atom\' xmlns:openSearch=\'http://a9.com/-/spec/opensearchrss/1.0/\' xmlns:batch=\'http://schemas.google.com/gdata/batch\' xmlns:gCal=\'http://schemas.google.com/gCal/2005\' xmlns:gd=\'http://schemas.google.com/g/2005\'><id>http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full</id>'+  
    '<updated>2008-05-25T08:33:17.000Z</updated><category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/g/2005#event\'/><title type=\'text\'>Platform Mktg  Events Universe -- events of interest</title><subtitle type=\'text\'>For tracking all platorm-relevant events, regardless of our participation.</subtitle><link rel=\'alternate\' type=\'text/html\' href=\'http://www.google.com/calendar/embed?src=flcgs27odaadjvnv97q8ou2gi4@group.calendar.google.com\'/><link rel=\'http://schemas.google.com/g/2005#feed\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full\'/><link rel=\'http://schemas.google.com/g/2005#post\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full\'/><link rel=\'http://schemas.google.com/g/2005#batch\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/batch\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full?max-results=25\'/><link rel=\'next\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full?start-index=26&amp;max-results=25\'/><author><name>Kavindra Patel</name><email>kpatel@salesforce.com</email></author>' + 
    '<generator version=\'1.0\' uri=\'http://www.google.com/calendar\'>Google Calendar</generator><openSearch:totalResults>116</openSearch:totalResults><openSearch:startIndex>1</openSearch:startIndex><openSearch:itemsPerPage>25</openSearch:itemsPerPage><gd:where valueString=\'\'/><gCal:timezone value=\'America/Los_Angeles\'/><entry><id>http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/h322i33tt385m1gnjpd4hns42s</id><published>2008-05-13T20:08:36.000Z</published><updated>2008-05-13T20:08:36.000Z</updated><category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/g/2005#event\'/><title type=\'text\'>Always On</title><content type=\'text\'></content><link rel=\'alternate\' type=\'text/html\' href=\'http://www.google.com/calendar/event?eid=aDMyMmkzM3R0Mzg1bTFnbmpwZDRobnM0MnMgZmxjZ3MyN29kYWFkanZudjk3cThvdTJnaTRAZw\' title=\'alternate\'/><link rel=\'self\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/h322i33tt385m1gnjpd4hns42s\'/><link rel=\'edit\' type=\'application/atom+xml\' href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/h322i33tt385m1gnjpd4hns42s/63346392516\'/><author><name>Paul Kopacki</name><email>pkopacki@gmail.com</email></author><gd:comments><gd:feedLink href=\'http://www.google.com/calendar/feeds/flcgs27odaadjvnv97q8ou2gi4%40group.calendar.google.com/private/full/h322i33tt385m1gnjpd4hns42s/comments\'/></gd:comments><gd:eventStatus value=\'http://schemas.google.com/g/2005#event.confirmed\'/><gd:visibility value=\'http://schemas.google.com/g/2005#event.default\'/><gd:transparency value=\'http://schemas.google.com/g/2005#event.transparent\'/>' +
    '<gCal:uid value=\'h322i33tt385m1gnjpd4hns42s@google.com\'/><gCal:sequence value=\'0\'/>'+
    '<gd:when startTime=\'2008-07-22\' endTime=\'2008-07-25\'/><gd:who rel=\'http://schemas.google.com/g/2005#event.organizer\' valueString=\'Platform Mktg  Events Universe -- events of interest\' email=\'flcgs27odaadjvnv97q8ou2gi4@group.calendar.google.com\'/><gd:where valueString=\'\'/></entry></feed>';
    
    public static  testmethod void cal() {
        
        xmldom f = new xmldom(calTest);
        GoogleData calFeed = new GoogleData(    f);
        list<GoogleData.Calendar> cals = GoogleData.calendarFactory( calFeed.entries);
        cals[0].dump(); 
        calFeed.dump();
        GoogleData.Calendar c = cals.remove(0);
        system.debug ( c.id + c.title + c.summary + c.updated ); 
        system.debug (c.edit + c.alternate + c.published );
        
        
        GoogleData evs = new GoogleData ( new xmldom ( evtest) ) ; 
        list<Event> systemevents = c.eventFactory( evs.entries ); 
        for( Event eee: systemevents) system.debug( eee );
         
        system.assert( GoogleData.dateTimeToString( system.now() ) != null );  
   
        string s = c.createEventAtom( new Event(
         DurationInMinutes=60 , activityDateTime=system.now(), 
         subject = 'test', description = 'descrip'
         ) ); 
        system.assert( s != null );
   
    } 
    
    // other..
    public static  testmethod void qry() {
        googledata.query q = new googledata.query('fsdf');
        system.assert( q.feedUrl != null );
        system.assert( q.FullTextQuery == null ); 
        q.FullTextQuery = 'sdf';
        system.assert( q.FullTextQuery != null ); 
        system.assert( q.MaxResults == null ); 
        q.MaxResults = 3;
        system.assert( q.MaxResults != null ); 
        system.assert( q.StartIndex == null ); 
        q.StartIndex = 3;
        system.assert( q.StartIndex != null );  
        system.assert( q.url != null);
        system.assert( googledata.appendQueryArg('/a','b=d') == '/a?b=d');
        system.assert( googledata.appendQueryArg('/a?b','b=c') == '/a?b&b=c');
    }
   
}
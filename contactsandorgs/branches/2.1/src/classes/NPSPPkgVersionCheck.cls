global without sharing class NPSPPkgVersionCheck {
    
    private Contacts_and_Orgs_Settings__c pageSettings;
    private final string ENDPOINT;
    private final string NAMESPACE_TO_CHECK;
    
    public NPSPPkgVersionCheck(string namespace){
        if (pageSettings == null)
            pageSettings = Constants.getContactsSettings();
        
        if (!System.Test.isRunningTest()){
            NAMESPACE_TO_CHECK = namespace;
            ENDPOINT = 'http://foundation.kbromer.cs0.force.com/packages/NPSPVersionCheck?orgid=' + UserInfo.getOrganizationId() + '&pkgname=' + namespace;   
        }
            
        else{    
            pageSettings.Send_Update_Notifications__c = true;
            pageSettings.Enable_Update_Check__c = true;
            pageSettings.Last_Update_Check__c = null;
            NAMESPACE_TO_CHECK = 'test';
            ENDPOINT = 'http://foundation.kbromer.cs0.force.com/packages/NPSPVersionCheck?orgid=' + UserInfo.getOrganizationId() + '&pkgname=test';    
        }
    }
    
    public void NPSPCheckVersion(boolean useSyncCallOut){        
        
        //if manually initiated callout immediately
        if(useSyncCallOut){
            initiateCallout();
        }    
        //if we're due for a checkup, call out async 
        else if (pageSettings.Enable_Update_Check__c && (pageSettings.Last_Update_Check__c == null || pageSettings.Last_Update_Check__c.addDays(integer.valueof(pageSettings.Update_Check_Interval__c.round())) > system.today())){
            NPSPPkgVersionCheck.FutureCallout(NAMESPACE_TO_CHECK);            
        }     
    }

    //async wrapper for a callout, we have to create a duplicate object
    //to get at the private class, but this gives us a single 
    //interaction point for the class    
    
    //IT WILL ALSO RESPECT THE SETTINGS OF THE TIME IT RUNS, WHICH 
    //THEORETICALLY COULD BE DIFFERENT FROM WHEN IT WAS ORIGINALLY CALLED
    //WHICH MEANS: WHEN DO WE TIMESTAMP THE SETTINGS? AFTER A SUCCESSFUL CALLOUT
    @future (callout = true)    
    private static void FutureCallout(string namespace){
        NPSPPkgVersionCheck npvc = new NPSPPkgVersionCheck(namespace);
        npvc.initiateCallout();
    }
    
    private void initiateCallout(){
        string pkgname = NAMESPACE_TO_CHECK;
        string endpoint = ENDPOINT;
        
        HttpRequest req = new HttpRequest();
        req.setEndPoint(constructendpoint(endpoint, pkgname));
        req.setMethod('GET');    
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if (!System.Test.isRunningTest())
            res = http.send(req);
        else{
            string testresponsebody = '';
            testresponsebody += '<?xml version="1.0" encoding="UTF-8"?><pkg><namespace>npsppkgchk</namespace><mypkgver>1.5.5</mypkgver><maxpkgver>2.2</maxpkgver><needsupdate>true</needsupdate><updatelink>http://foundation.force.com/packages/affiliations</updatelink></pkg>';
            res.setBody(testresponsebody);
        }
        system.debug('MY RESPONSE BODY======================' + res.getBody());        
        //<pkg>namespace;yourver;maxver;isupdateable;updateurl</pkg>
   
        //if the callout was successful - send for parsing and updating
        if (res.getBody().length() > 0)
            updatePKGInfo(new NPSPEndPointResponse(res.getBody()));         
    }
    
    //method for adding pkgver param to the defined endpoint
    private string constructendpoint(string endpoint, string namespace){
        
        string newendpoint = endpoint;
        
        if (!system.Test.isRunningTest())
            newendpoint = newendpoint + '&pkgver=' + string.valueOf(Package.Version.Request);
        
        else
            newendpoint = newendpoint + '&pkgver=' + '1.12.0';
            
        return newendpoint;
    }
    
    class NPSPEndPointResponse{
        
        public string namespace {get; private set;}
        public string yourversion {get; private set;}
        public string maxversion {get; private set;}
        public string haspackageupdate {get; private set;}
        public string updateURL {get; private set;}
        
        
        NPSPEndPointResponse(string responsebody){
            updateproperties(parseResponseBody(responsebody));
        }
    
        private map<string, string> parseResponseBody(string bodytext){
            
            map<string, string> endpointText = new map<string, string>();
            system.debug('BODYTEXT: ' + bodytext);
            
            if (bodytext.length() > 0 && bodytext.startsWith('<pkg>') && bodytext.endsWith('</pkg>') && bodytext.contains(';')){

                //the body occasionall contains erroneous html characters that need to be stripped
                bodytext = bodytext.replace('</html>', '');
                bodytext = bodytext.replace('<html>', '');
                
                try{
                    XmlStreamReader xsr = new XmlStreamReader(bodytext);
                    
                    system.debug(xsr.toString());
                }
                
                catch (Exception e){
                	
                
                	
                }    
            }
            
            //malformed return body
            else {
                
            	
            }
            
            
            return endpointText;
        }
        
        private void updateproperties(map<string, string> parsedBody){
       
        
             
        }  
        
    
    }

    private void updatePKGInfo(NPSPEndPointResponse epr){
        
        pagesettings.Has_Package_Update__c = epr.haspackageupdate;
        
        
        update pagesettings;
    }

/*
    private static void CheckVersions(list<string> bodyelements){
    
        //first, we need to cull out the package version numbers
        //for the package we're currently in-        
        string versionstring = string.valueof(Package.Version.Request);
        
        if (System.Test.isRunningTest())
            versionstring = '1.1.0';
        
        list<string> vlist = versionstring.split('\\.');
        
        //if we have fewer than three elements, it means we're
        //not in a proper package, and we have to bail,
        //we'll also turn off future updates to avoid erroneous calls
        if (vlist.size() < 3){
            pageSettings.Send_Update_Notifications__c = false;
            update pageSettings;
        }
        else{
            try{
                integer mymajorver = integer.valueof(vlist[1]);
                integer myminorver = integer.valueof(vlist[2]); 
            
                if (mymajorver < integer.valueof(bodyelements[0]) ||
                      (mymajorver == integer.valueof(bodyelements[0]) &&
                       myminorver < integer.valueof(bodyelements[1]))){
                    sendNotificationEmail(mymajorver, integer.valueof(bodyelements[0]), myminorver, integer.valueof(bodyelements[1]));
                }
            }
        //    catch(Exception e){/* die gracefully & quietly }            
        }
    } */


    //return a three element list that contains first the major version number
    //and then second, the minor version number, and then download endpoint
    //for the update to be included in the email
    private static list<string> parsedBody(string bodyContent){
        
        list<string> returnstring = new list<string>();        
        //first, split on our semicolon delimitor 
        string[] stringlist = bodyContent.split(';');    
        //element one will be the version number for this package, splitting on
        //the period should yield a two or three element list, the first two will be 
        //major, and then minor version
        system.debug('STRINGLIST===================' + stringlist[0]);
        list<string> versionnumbers = stringlist[0].split('\\.');
        
        system.debug('SIZE=============' + versionnumbers.size());
        //now get the URL for the update for this package
        string updateURL = stringlist[1].replace('</html>', '');
        
        returnstring.add(versionnumbers[0]);
        returnstring.add(versionnumbers[1]);
        returnstring.add(updateURL);
        
        return returnstring;    
    }
    
    /*******************TEST METHODS****************************/
    public static testMethod void VersionCheckTest(){
        NPSPPkgVersionCheck.FutureCallout('test');            
        NPSPPkgVersionCheck npvc = new NPSPPkgVersionCheck('test');
        npvc.initiateCallout();
     
    }
}
/*
    Copyright (c) 2008 salesforce.com, inc.
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    
    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. The name of the author may not be used to endorse or promote products
       derived from this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
    THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    
    Utility class for collecting a google auth sub session token for use with all 
    Google Data API's

*/
/*  
  * for inspiration an insight read
  http://code.google.com/apis/gdata/javadoc/com/google/gdata/client/http/AuthSubUtil.html
  */
 
public class AuthSubUtil {
    static string tokenInfo = 'https://www.google.com/accounts/AuthSubTokenInfo';
    static string authRequest = 'https://www.google.com/accounts/AuthSubRequest';
    static string subSession = 'https://www.google.com/accounts/AuthSubSessionToken';
    static string revokeUrl = 'https://www.google.com/accounts/AuthSubRevokeToken';
    
    public static Map<String, String> getTokenInfo(string token) {
        Map<String, String> ret = new Map<String, String> ();

        GoogleService service = new GoogleService('auth'); 
        service.AuthSubToken = token; 
        service.getFeedMethod('GET',tokenInfo, null, null );
        
        string[] lines =  service.response.getBody().split('\n');
        
        try { 
            for (string s: lines) {
                string[] nv = s.split('='); 
                ret.put(nv[0],nv[1]);
            } 
        } catch (exception e) {
            // an error or invalid token...
            system.debug( service.response.getBody() );
        } 
        return ret;
    }
    
    //  Creates the request URL to be used to retrieve an AuthSub token.
    public static String    getRequestUrl(string proto, string host, 
                                            String nextUrl, String scope) {
        // first we need to go thru the Salesforce GoogleAuthSub callback servlet
        // and that (next destination) needs to be encoded
        string encodedNext = proto + '://' + host +     
            '/_ui/core/google/GoogleAuthSubCallback?url=' + 
            EncodingUtil.urlEncode( nextUrl, 'UTF-8' ); 
        
        // then we need to encode again to allow it to pass thru to the google authsub sevlet
        string twiceEncodedNext =  EncodingUtil.urlEncode( encodedNext, 'UTF-8' ) ; 
        
        // finaly construct the first step in the redirect process, send your users to this url
        // must be done by the end user, in a browser...
        return authRequest + '?next='+ twiceEncodedNext + '&scope='+ scope + '&session=1&secure=0'; 
    }
    
    //  Creates the pagereference to be used to retrieve an AuthSub token.
    public static pagereference    getRequestPageReference(string proto, string host, 
                                            String nextUrl, String scope) {
        // first we need to go thru the Salesforce GoogleAuthSub callback servlet
        // and that (next destination) needs to be encoded
        string encodedNext = proto + '://' + host +     
            '/_ui/core/google/GoogleAuthSubCallback?url=' + 
            EncodingUtil.urlEncode( nextUrl, 'UTF-8' ); 
        
        // then we need to encode again to allow it to pass thru to the google authsub sevlet
        //string twiceEncodedNext =  EncodingUtil.urlEncode( encodedNext, 'UTF-8' ) ; 
        
        // finaly construct the first step in the redirect process, send your users to this url
        // must be done by the end user, in a browser...
        return  new PageReference( authRequest + '?next='+ encodedNext + '&scope='+ scope + '&session=1&secure=0'); 
    }

         
    //    Exchanges the one time use token returned in the URL for a session token.
    public static String    exchangeForSessionToken(String onetimeUseToken ) { 
        GoogleService service = new GoogleService('auth'); 
        service.AuthSubToken = onetimeUseToken;
        service.getFeedMethod('GET', subSession, null, GoogleService.CONTENT_TYPE_URL);
        return getTokenFromReply( service.response.getbody());
    }     
    
    // Parses and returns the AuthSub token returned by Google on a successful AuthSub login request.
    public static String    getTokenFromReply(String bodyOrUrl) {
        string[] atoken = bodyOrUrl.split('=');
        if ( atoken.size() != 2) { 
            system.debug( 'invalid token, or response from AuthSubSessionToken, no token');
            return null;
        }
        system.debug('session token is: '+atoken[1].trim());
        return atoken[1].trim();
    }

    public  static void     revokeToken(String token) {
         // Revokes the specified token.
        GoogleService service = new GoogleService('auth'); 
        service.AuthSubToken = token; 
        service.getFeed( revokeUrl ); 
    }
    
    /*  
    static String   getPrivateKeyFromKeystore(String keystore, String keystorePass, String keyAlias, String keyPass)
              Retrieves the private key from the specified keystore.          
    */
    
    /* 
     * test methods below here 
     */
    static final string sessionAuthToken = 'CJ3pqczuBBCpgI2pBw';
    
    public static testMethod void testGetTokenInfo() { 
        system.debug ( AuthSubUtil.getTokenInfo( sessionAuthToken) );
        system.debug ( AuthSubUtil.getTokenInfo( 'badtoken' ) );
    }
    
    public static testMethod void testexchangeForSessionToken() { 
        CalendarService service = new CalendarService();  
        AuthSubUtil.exchangeForSessionToken( 'teststtoken' );
        
    }
    
    public static testMethod void testgetTokenFromReply() { 
        CalendarService service = new CalendarService();  
        AuthSubUtil.getTokenFromReply( 'url=teststtoken' );
        AuthSubUtil.getTokenFromReply( 'urlbadteststtoken' );
    }
    
    public static testMethod void testrevokeToken() { 
        CalendarService service = new CalendarService();  
        AuthSubUtil.revokeToken( 'teststtoken' );
     
    }
    
    public static testMethod void testgetRequestUrl() { 
        string expected = 'https://www.google.com/accounts/AuthSubRequest?next=https%3A%2F%2Ftapp0.salesforce.com%2F_ui%2Fcore%2Fgoogle%2FGoogleAuthSubCallback%3Furl%3D%252Fapex%252Fgsession%253Fid%253Da0AT0000000FO1QMAW&scope=http://www.google.com/calendar/feeds/&session=1&secure=0';
        CalendarService service = new CalendarService();  
        
        string checkUrl =  AuthSubUtil.getRequestUrl( 'https', 'tapp0.salesforce.com', 
            '/apex/gsession?id=a0AT0000000FO1QMAW',  // next  
            'http://www.google.com/calendar/feeds/' );   // scope 
            
        system.debug ( expected ) ; 
        system.debug ( checkUrl );   
        system.assert(  expected == checkUrl , ' mis match request url '); 
    }
    

	public static testMethod void  testgetRequestPageReference(){
    
        String strProto = 'https';
        String strHost = 'na2.salesforce.com';
        String strNextUrl = '/apex/authsub';
        String strScopeUrl = 'http://spreadsheets.google.com/feeds/';
              
       	PageReference p = AuthSubUtil.getRequestPageReference( strProto, strHost, strNextUrl, strScopeUrl);
      	system.debug (p); 
    	
    	STRING expected = 'https://www.google.com/accounts/AuthSubRequest?next=https%3A%2F%2Fna2.salesforce.com%2F_ui%2Fcore%2Fgoogle%2FGoogleAuthSubCallback%3Furl%3D%252Fapex%252Fauthsub&scope=http%3A%2F%2Fspreadsheets.google.com%2Ffeeds%2F&secure=0&session=1';
    	system.assert( expected == p.getUrl() , 'page reference genreated is bad'); 
    }
        
}
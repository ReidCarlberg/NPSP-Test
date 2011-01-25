public class AuthSubController {
    
    public pagereference exchangeRequestToken() {
        if ( ApexPages.currentPage().getParameters().get('token') != null) { 
            string sessToken = 
             AuthSubUtil.exchangeForSessionToken( 
                ApexPages.currentPage().getParameters().get('token'));
            // store the token 
            // this assumes a you store tokens in a custom object
            GoogSession__c session = new googSession__c(id=
                ApexPages.currentPage().getParameters().get('id'),
                 AuthSubSessionToken__c = sessToken );
            
            update session; 
        }
        return null;
    }
    
    public boolean getRequestToken() {
        return (ApexPages.currentPage().getParameters().get('token') == null
        && ApexPages.currentPage().getParameters().get('id') != null);
    }
    
    public static testMethod void t1() {   
   
        PageReference pageRef = Page.authsub;
        Test.setCurrentPage(pageRef);
  
        AuthSubController stc = new AuthSubController( );
        ApexPages.currentPage().getParameters().put('token', 'yyyy');
        ApexPages.currentPage().getParameters().put('id', 'yyyy');
        stc.exchangeRequestToken();
        stc.getRequestToken();
    }
     public static testMethod void t2() {   
   
        PageReference pageRef = Page.authsub;
        Test.setCurrentPage(pageRef);
  
        AuthSubController stc = new AuthSubController( );
        stc.getRequestToken();
        stc.exchangeRequestToken();
        
    }
}
public class LoanAccountControllerExtension {

    private final Loan_Account__c acct;
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public LoanAccountControllerExtension(ApexPages.StandardController stdController) {
        this.acct = (Loan_Account__c)stdController.getRecord();
    }

    public String getGreeting() {
        return 'Hello ' + acct.name + ' (' + acct.id + ')';
    }
}
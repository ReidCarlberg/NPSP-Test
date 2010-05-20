public class MarkTransactions {

    public List<Loan_Transaction__c> selectedPayments;

    public MarkTransactions(ApexPages.StandardSetController controller) {
        this.selectedPayments = (List<Loan_Transaction__c>)controller.getSelected();
    }
    
    public pageReference MarkAsPaid() {
        
        List<Loan_Transaction__c> PaymentsToUpdate = new List<Loan_Transaction__c>();
        for (Loan_Transaction__c payment : selectedPayments) {
            payment = new Loan_Transaction__c (
                id = payment.id,
                Paid_Date__c = Date.Today()
            );
            PaymentsToUpdate.add(payment);
        }
        
        if (PaymentsToUpdate.size() > 0) {
            update PaymentsToUpdate;
        }
        PageReference p = new PageReference(System.currentPageReference().getParameters().get('retURL'));
        p.setRedirect(true);
        return p;
        
    }

    /*

    private static testMethod void TestMarkAsPaid() {
    
    
    //create new opportunity
    Opportunity firstOpp = new Opportunity (
        Name = 'Test first contact opp',
        amount=100,
        StageName=ONEN_Constants.OPP_DEFAULT_STAGE,
        CloseDate=Date.newInstance(2005,10,10)
    );
    insert firstOpp;
    
    //create new payments for opportunity
    OppPayment__c firstPayment = new OppPayment__c (
        Amount__c = 100,
        Date__c = Date.today(),
        IsInstallment__c = true,
        Paid__c = false,
        Opportunity__c = firstOpp.id
    );
    insert firstPayment;
    
    OppPayment__c secondPayment = new OppPayment__c (
        Amount__c = 100,
        Date__c = Date.today(),
        IsInstallment__c = true,
        Paid__c = false,
        Opportunity__c = firstOpp.id
    );
    insert secondPayment;
    
    List<OppPayment__c> selectedPayments = new List<OppPayment__c>();
    
    selectedPayments.add(firstPayment);
    selectedPayments.add(secondPayment);
    
    PageReference p = new PageReference('/' + firstOpp.id + '?retURL=' + firstOpp.id);
    Test.setCurrentPage(p);
    
    //pass selected opportunities into the controller
    ApexPages.StandardSetController sc = new ApexPages.standardSetController(selectedPayments);
    sc.setSelected(selectedPayments);
    //pass the controller into the extension
    ONEN_EXT_MarkPaymentsPaid ext = new ONEN_EXT_MarkPaymentsPaid(sc);
    
    ext.MarkAsPaid();
    
    OppPayment__c[] Payments = [SELECT Name, Paid__c FROM OppPayment__c where id = :firstPayment.id ];
    system.assertEquals(1,Payments.size());
    System.assertEquals(true,Payments[0].Paid__c);
    
    }
*/
}
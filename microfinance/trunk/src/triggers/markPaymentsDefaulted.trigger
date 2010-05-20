trigger markPaymentsDefaulted on Loan_Account__c (after Update) {

    Set<Id> defaultedLoanIds = new Set<Id>();
    for (Loan_Account__c loan : Trigger.new) {
    system.debug('new' + loan.Status__c);
    system.debug('old' + Trigger.oldMap.get(loan.Id).Status__c);
        if (loan.Status__c == 'Defaulted' && Trigger.oldMap.get(loan.Id).Status__c != 'Defaulted') {     
          defaultedLoanIds.add(loan.id);
        }
    }
    system.debug(defaultedLoanIds.size());
    if(defaultedLoanIds.size()>0){
        //query all scheduled transactions
        List<Loan_Transaction__c> defaultedTransactions = new List<Loan_Transaction__c>();
        defaultedTransactions = [select id, default_date__c from Loan_Transaction__c where Loan_Account__c IN :defaultedLoanIds and Paid_date__c = null];
        //mark scheduled transactions as lost
        for(Loan_Transaction__c myTransaction : defaultedTransactions){
            myTransaction.default_date__c = Date.Today();
        }
        system.debug(defaultedTransactions.size());
        if(defaultedTransactions.size()>0){
            update defaultedTransactions;
        }
        
    }
}
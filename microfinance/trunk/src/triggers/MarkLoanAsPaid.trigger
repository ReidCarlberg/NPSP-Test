trigger MarkLoanAsPaid on Loan_Account__c bulk (before update) {

  for (Loan_Account__c loan : Trigger.new) {
    System.debug(loan.Status__c);
    System.debug(loan.Outstanding_Balance__c);

    //TODO: This needs to be figured out
    if (Trigger.oldMap.get(loan.Id).Status__c == loan.Status__c && (loan.Status__c == 'Active' ) && (loan.Outstanding_Balance__c <= 0.0)) {     
      loan.Status__c = 'Paid';
      //update loan;
    }
  }
}
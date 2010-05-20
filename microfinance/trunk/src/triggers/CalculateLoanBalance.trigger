trigger CalculateLoanBalance on Loan_Transaction__c bulk (after insert, after update, after delete) {

    // construct set of unique Loan_Account__c Ids
    Set<Id> loanAcctIds = new Set<Id>();

    if (Trigger.isDelete) {
      for (Loan_Transaction__c trans : Trigger.old) {
        loanAcctIds.add(trans.Loan_Account__c);
      }
    } else {
      for (Loan_Transaction__c trans : Trigger.new) {
        loanAcctIds.add(trans.Loan_Account__c);
      }
    }
    
    LoanUtil loanUtil = new LoanUtil();
    for (Id loanAcctId : loanAcctIds) {
      loanUtil.updateOutstandingBalance_NoCommit(loanAcctId);
    }
}
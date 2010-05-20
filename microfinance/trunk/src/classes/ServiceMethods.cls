global class ServiceMethods
{

  /*
   *   updateOutstandingBalance
   */
  webService static Double updateOutstandingBalance(Id loanAcctId) {
    LoanUtil loanUtil = new LoanUtil();
    Double sum = loanUtil.updateOutstandingBalance_NoCommit(loanAcctId);
    return sum;
  } // updateOutstandingBalance


  /*
   *   generatePaymentSchedule
   */
  webService static void generatePaymentSchedule(Id loanAcctId) {

    Loan_Account__c loanAcct =
             [select Id, Loan_Amount__c, Annual_Interest_Rate__c, Number_of_Installments__c
              from Loan_Account__c
              where Id = :loanAcctId];

    if (loanAcct != null) {
        LoanUtil loanUtil = new LoanUtil();
        loanUtil.generatePayments(loanAcct);
    } else {
      // TO DO throw exception
   }
  } // generatePaymentSchedule

  webService static void markPaid(Id[] loanTransactionIds)
  {
      Date d = System.today();
      Loan_Transaction__c[] transactionsToUpdate = new Loan_Transaction__c[0];
      for (Id loanTransId : loanTransactionIds) {
          transactionsToUpdate .add( new Loan_Transaction__c(Id = loanTransId, Paid_Date__c = d) );
      }
      update transactionsToUpdate;
  }

}
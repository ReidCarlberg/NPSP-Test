trigger ActivateLoanAccount on Loan_Account__c bulk (after insert, after update)
{
	LoanUtil loanUtil = new LoanUtil();
	
	for (Loan_Account__c loan : Trigger.new)
	{
		if (loan.Status__c == 'Approved')
		{
			Loan_Account__c updLoan = new Loan_Account__c(id = loan.Id, Status__c = 'Active-Pending');
			update updLoan;

			loanUtil.generatePayments(loan);

			Loan_Account__c updLoan2 = new Loan_Account__c(id = loan.Id, Status__c = 'Active');
			update updLoan2;        
		}
	}
}
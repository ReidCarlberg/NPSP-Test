public class LoanUtil
{   
    // TO DO convert strings to constants
 
    private Integer PRECISION = 2;
    
    private Id disbursementRecordTypeId;
    private Id interestRecordTypeId;
    private Id scheduledPaymentRecordTypeId;
    
    public LoanUtil()
    {
        disbursementRecordTypeId = MetadataUtil.getRecordTypeId('Loan_Transaction__c', 'Disbursement');
        interestRecordTypeId = MetadataUtil.getRecordTypeId('Loan_Transaction__c', 'Interest'); 
        scheduledPaymentRecordTypeId = MetadataUtil.getRecordTypeId('Loan_Transaction__c', 'Payment');
    }

    /*
     *  function generatePayments_Lookup
     */
    public void generatePayments(Loan_Account__c loanAcct)
    {    
        //Loan_Product__c p = [SELECT Id, Interest_Rate_Type__c, Int_Ded_Disbursement__c FROM Loan_Product__c WHERE Id = :loanAcct.Loan_Product__c];
    
        // ensure safe conversion
        Integer numPeriods = Math.round(Math.floor(loanAcct.Number_of_Installments__c)); 
        Double periodicInterestRate = calculatePeriodicInterestRate(loanAcct.Annual_Interest_Rate__c,
                                                                    loanAcct.Period__c);
        Double paymentAmt;
        Double interest;
        
        if(loanAcct.Interest_at_Disbursement__c == 'Yes' && loanAcct.Interest_Rate_Type__c == 'Flat'){
            paymentAmt = FinCalc.calculatePayment(0, loanAcct.Loan_Amount__c, numPeriods, loanAcct.Interest_Rate_Type__c);
            interest = FinCalc.calculateInterest(periodicInterestRate,loanAcct.Loan_Amount__c, numPeriods);
        }else{
            paymentAmt = FinCalc.calculatePayment(periodicInterestRate , loanAcct.Loan_Amount__c, numPeriods, loanAcct.Interest_Rate_Type__c);        
        }
        
        System.debug('Payment Amount = ' + paymentAmt);
        paymentAmt = decimalRound(paymentAmt, PRECISION); // TO DO get precision from currency
        
        
        //Special handling for 'Interest Only'
        if(loanAcct.Interest_Rate_Type__c == 'Interest Only'){
            interest = decimalRound(paymentAmt * numPeriods,PRECISION); 
        }else{
            interest = decimalRound(paymentAmt * numPeriods - loanAcct.Loan_Amount__c,PRECISION);
        }
        
        createAndInsertTransactionSchedule_NoCommit(
                loanAcct,
                paymentAmt,
                numPeriods,
                interest);                

        // change record type to remove button
        MetadataUtil.updateLoanAccountRecordType_NoCommit(loanAcct.Id, 'Scheduled Loan');

    } // generatePayments
    
    
    public static Double decimalRound(Double amt, Integer decimalPrecision) {      
        Double adjuster = Math.pow(10,decimalPrecision);
        return Math.ceil(amt * adjuster) / adjuster;
    }
    
    static testMethod void testDecimalRound(){
        Double amt = 58.33333333333334;
        amt = decimalRound(amt,2);
        System.assertEquals(amt,58.34);
    }
    
    public static Double calculatePeriodicInterestRate(Double annualRate,
                                                 String period)
    {
        Integer paymentsPerYear;
        if (period == 'Monthly') {
             paymentsPerYear = 12;
        } else if (period == 'Biweekly') {
             paymentsPerYear = 26;
        } else {
             // default: Weekly
             paymentsPerYear = 52;
        }
        
        System.debug('Periodicity = ' + Period + paymentsPerYear);
        
        
        return (annualRate / paymentsPerYear);
    }

    
    private void createAndInsertTransactionSchedule_NoCommit(Loan_Account__c loanAcct,
                                                             Double paymentAmt,
                                                             Integer numPeriods,
                                                             Double interest)
    {
        Loan_Transaction__c[] transactionsToAdd = new Loan_Transaction__c[0];
        
        // record disbursement
        transactionsToAdd.add(
            MetadataUtil.buildTransaction(loanAcct.Id,
                             disbursementRecordTypeId,
                             loanAcct.Loan_Amount__c,
                             loanAcct.Start_Date__c,
                             loanAcct.Payment_Type__c,
                             loanAcct.Grace_Period_Days__c) );
        // record interest                                                                      
        transactionsToAdd.add(
            MetadataUtil.buildTransaction(loanAcct.Id,
                             interestRecordTypeId,
                             interest,
                             null, // ???
                             'N/A',
                             loanAcct.Grace_Period_Days__c) );
                             
        //Special handling for interest at disbursement                     
        if(loanAcct.Interest_at_Disbursement__c == 'Yes'){
            transactionsToAdd.add(
            MetadataUtil.buildTransaction(loanAcct.Id,
                             scheduledPaymentRecordTypeId,
                             interest,
                             loanAcct.Start_Date__c,
                             loanAcct.Payment_Type__c,
                             0) );        
        }
        
            // generate payments
        for (Integer i=0; i < numPeriods; i++) {
            transactionsToAdd.add(
                MetadataUtil.buildTransaction(loanAcct.Id,
                                  scheduledPaymentRecordTypeId,
                                  paymentAmt,
                                  calculateDueDate(loanAcct.Start_Date__c,
                                                   loanAcct.Period__c,
                                                   i+1),
                                  loanAcct.Payment_Type__c,
                                  loanAcct.Grace_Period_Days__c) );
        }  
        
         if(loanAcct.Interest_at_Disbursement__c == 'Yes' && loanAcct.Interest_Rate_Type__c == 'Flat'){
            //generate principal payment to coincide with last interest payment
            transactionsToAdd.add(
                MetadataUtil.buildTransaction(loanAcct.Id,
                                  scheduledPaymentRecordTypeId,
                                  loanAcct.Loan_Amount__c,
                                  calculateDueDate(loanAcct.Start_Date__c,
                                                   loanAcct.Period__c,
                                                   numPeriods),
                                  loanAcct.Payment_Type__c,
                                  loanAcct.Grace_Period_Days__c) );
        
        }
        insert transactionsToAdd;
    }
    
    
    /*
     *  function getDueDate
     *
     *  calculate the due date for a given payment number
     *  - startDate is the date of the disbursement (first payment is due one period after disbursement)
     *  - periodType is 'Monthly', 'Biweekly', or 'Weekly' -- time between payments
     *  - periodNumber is the 1-based index of payment periods
     */
    public static Date calculateDueDate(Date startDate, String periodType, Integer periodNum)
    {
        Date dueDate;
        if (periodType == 'Monthly') {
            dueDate = startDate.addMonths(1 * periodNum);
        } else if (periodType == 'Biweekly') {
            dueDate = startDate.addDays(14 * periodNum);
        } else {
            // default: Weekly
            dueDate = startDate.addDays(7 * periodNum);
        }
        return dueDate;
    } // calculateDueDate
    

    /*
     *  calculateTransactionsSum
     */
    private Double calculateTransactionsSum(Id loanAcctId)
    {
        Double sum = 0;
        for ( Loan_Transaction__c loanTransaction:
                 [SELECT Balance_Adjustment__c
                  FROM Loan_Transaction__c
                  WHERE Loan_Account__c = :loanAcctId
                        AND (Type__c = 'N/A' OR Paid_Date__c != null)])
        {
            sum += loanTransaction.Balance_Adjustment__c;
        }
        return sum;
    } // calculateTransactionsSum


    /*
     *    updateOutstandingBalance_NoCommit
     *    (for use within a trigger)
     */
    public Double updateOutstandingBalance_NoCommit(Id loanAcctId)
    {
        Double sum = calculateTransactionsSum(loanAcctId);

        Loan_Account__c loanAcct = new Loan_Account__c(
            Id = loanAcctId,
            Outstanding_Balance__c = sum
            );
        update loanAcct;
        return sum;
    } // updateOutstandingBalance_NoCommit

} // package
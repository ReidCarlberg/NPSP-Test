public class SavingsUtil{
    private Integer PRECISION = 2; 
    
    public Id depositRecordTypeId;
    public Id interestRecordTypeId;
    public Id withdrawalRecordTypeId;
    
    public SavingsUtil(){
        depositRecordTypeId = MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Deposit');
        interestRecordTypeId = MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Interest');
        withdrawalRecordTypeId = MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Withdrawal');
    }

    public void postInterest(List<Savings_Transaction__c> transactions){
        List<Savings_Transaction__c> inserts = new List<Savings_Transaction__c>(); 
        
        Set<Id> accountIds = new Set<Id>();

        for (Integer i = 0; i < transactions.size(); i++) {
            accountIds.add(transactions[i].Savings_Account__c);
        }

        Map<Id, Savings_Account__c> accts = new Map<Id, Savings_Account__c>(
                           [select Id,Min_Balance_For_Interest__c,Status__c, Activation_Date__c,Account_Balance__c,Interest_Rate_Calculation_Frequency__c,Annual_Interest_Rate__c from Savings_Account__c where id in :accountIds]);
        
        for(Savings_Transaction__c t : transactions){
            Savings_Account__c a = accts.get(t.Savings_Account__c);    
            
            //Verify eligible for interest calculation
            if(a != null && eligibleForInterest(t,a)){
                
                //Post new transaction for interest                
                inserts.add(getInterestTransaction(t,a));                             
            }    
            
            //Revert 'calculating' transaction to 'scheduled' and update with appropriate date 
            Savings_Transaction__c s = t.clone(false,true);
            s.Status__c = 'Scheduled';          
            s.Due_Date__c = LoanUtil.calculateDueDate(s.Due_Date__c, a.Interest_Rate_Calculation_Frequency__c, 1);
            inserts.add(s);
            
            //TODO: Figure out what to do with unscheduled
            t.Status__c = 'Unscheduled';  
            t.Due_Date__c = s.Due_Date__c;          
        }
        
        //TODO: Take care of more than 200 inserts
        if(inserts.size() > 0) insert inserts;
    }
    
    private boolean eligibleForInterest(Savings_Transaction__c t, Savings_Account__c a){
        return 'Active'.equals(a.Status__c) 
                && getBalance(t,a) >= a.Min_Balance_For_Interest__c
                && a.Activation_Date__c != null  && a.Activation_Date__c.daysBetween(Date.today()) >= 0;
    }
    
    private Savings_Transaction__c getInterestTransaction(Savings_Transaction__c t,Savings_Account__c a){
        //Id should not be same. Deep clone because different objects.
        Savings_Transaction__c interest = t.clone(false,true);        
        interest.Status__c = 'Complete';
        interest.Transaction_Date__c = Date.today();
        
        //Calculate and update interest
        Double periodicInterestRate = LoanUtil.calculatePeriodicInterestRate(a.Annual_Interest_Rate__c,
                                                                    a.Interest_Rate_Calculation_Frequency__c);
        
        Double interestAmt = FinCalc.calculateInterest(periodicInterestRate,getBalance(t,a),getPeriodFraction(t,a)); 
        interestAmt = LoanUtil.decimalRound(interestAmt, PRECISION);   
        interest.Amount__c = interestAmt;                                                       
        
        return interest;      
    }
    
    //TODO: Add support for multiple balance types
    private Double getBalance(Savings_Transaction__c t,Savings_Account__c a){
        return a.Account_Balance__c;
    }
        
    //TODO: Based on Activation date, figure out if the interest calculation applies to only a fraction of the period    
    private Double getPeriodFraction(Savings_Transaction__c t,Savings_Account__c a){
        return 1.0;
    }
}
trigger postInterest on Savings_Transaction__c (before insert, before update) {

    List<Savings_Transaction__c> transactions = new List<Savings_Transaction__c>();
    System.debug('In trigger');
    for (Savings_Transaction__c st : Trigger.new){
        if (st.Savings_Account__c != null && st.Status__c == 'Calculating' && st.RecordTypeId == MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Interest')){
            //Add transaction for interest calculation
            transactions.add(st);   
        }
    }
    
    if(transactions.size() > 0) {
        SavingsUtil savingsUtil = new SavingsUtil();    
        savingsUtil.postInterest(transactions);
    }
}
trigger ActivateSavingsAccount on Savings_Account__c bulk (after insert, before update){
    List<Savings_Transaction__c> transactions = new List<Savings_Transaction__c>();
    String interestRecordTypeId = MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Interest');
    
    for (Integer i=0;i < Trigger.new.size();i++){
        Savings_Account__c a = Trigger.new[i];
        if (a.Status__c == 'Active'){
            //If insert OR update and status was recently changed, create interest scheduled right away and set activation date
            if(Trigger.isInsert || (Trigger.isUpdate && Trigger.old[i].Status__c != a.Status__c)){            
                a.Activation_Date__c = Date.today();
                Savings_Transaction__c t = new Savings_Transaction__c(Savings_Account__c = a.Id,Amount__c = 0,Status__c = 'Scheduled');
                //Record Type
                t.RecordTypeId = interestRecordTypeId;
                //Due Date
                t.Due_Date__c = LoanUtil.calculateDueDate(Date.today(), a.Interest_Rate_Calculation_Frequency__c, 1);
                transactions.add(t);               
            }  
        }
    }
    
    if(transactions.size() > 0) insert transactions;
}
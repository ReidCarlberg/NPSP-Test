trigger calcRunningBalance on Savings_Transaction__c (before insert, before update) {        
        
        Set<Id> accountIds = new Set<Id>();

        for (Integer i = 0; i < Trigger.new.size(); i++) {
            accountIds.add(Trigger.new[i].Savings_Account__c);
        }

        Map<Id, Savings_Account__c> accts = new Map<Id, Savings_Account__c>(
                           [select id, Account_Balance__c,Max_Amount_Per_Withdrawal__c from Savings_Account__c where id in :accountIds]);
                                
        for(Savings_Transaction__c t : Trigger.new){
        //TODO: Add any other criteria to check. Consider effect of balance field being a roll-up summary field
        //i.e. delay in calculation
                
            if(t.Status__c == 'Complete' && t.Savings_Account__c != null){
                if(Trigger.isUpdate){
                     t.addError('Completed transactions cannot be modified. Please create new transaction');
                     continue;
                }
            
                if(t.RecordTypeId == MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Deposit') || t.RecordTypeId == MetadataUtil.getRecordTypeId('Savings_Transaction__c', 'Interest')){            
                    t.Running_Balance__c = accts.get(t.Savings_Account__c).Account_Balance__c + t.Amount__c;                    
                }else{
                    /*
                    //Max withdrawal validation
                    if(t.Amount__c > accts.get(t.Savings_Account__c).Max_Amount_Per_Withdrawal__c){
                        t.Amount__c.addError('Max Withdrawal Amount Exceeded');
                    }
                    */
                    t.Running_Balance__c = accts.get(t.Savings_Account__c).Account_Balance__c - t.Amount__c;
                    if(t.Running_Balance__c < 0) t.Amount__c.addError('Not Enough Funds. Please check balance.');
                }
            }          
        }
}
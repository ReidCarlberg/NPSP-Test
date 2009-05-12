trigger RecurringDonations on Recurring_Donation__c (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {

	/// <name> triggerAction </name>
	/// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
 
    if(Trigger.isBefore && Trigger.isInsert){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.beforeInsert);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.beforeUpdate);
    }
    if(Trigger.isBefore && Trigger.isDelete ){
        RecurringDonations process = new RecurringDonations (Trigger.old, null, triggerAction.beforeDelete);
    }
    if(Trigger.isInsert && Trigger.isAfter){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.afterInsert);
    }
    if(Trigger.isUpdate && Trigger.isAfter){
        RecurringDonations process = new RecurringDonations (Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }

}
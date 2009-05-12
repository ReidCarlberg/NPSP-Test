trigger IndividualAccounts on Contact (before insert, before update, after insert, after update) {

    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
 
    if(Trigger.isInsert && Trigger.isBefore){
        IndividualAccounts process = new IndividualAccounts(Trigger.new, Trigger.old, triggerAction.beforeInsert);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        IndividualAccounts process = new IndividualAccounts(Trigger.new, Trigger.old, triggerAction.beforeUpdate);
    }
    if( Trigger.isAfter && Trigger.isInsert ){
        IndividualAccounts process = new IndividualAccounts(Trigger.new, Trigger.old, triggerAction.afterInsert);
    }
    if( Trigger.isAfter && Trigger.isUpdate ){
        IndividualAccounts process = new IndividualAccounts(Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }
}
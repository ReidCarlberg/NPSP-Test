trigger Affiliations on Contact (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {

    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
 
    if( Trigger.isAfter && Trigger.isInsert ){
        Affiliations process = new Affiliations(Trigger.new, Trigger.old, triggerAction.afterInsert);
    }
    if( Trigger.isAfter && Trigger.isUpdate ){
        Affiliations process = new Affiliations(Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }

}
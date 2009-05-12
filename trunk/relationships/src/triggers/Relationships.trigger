trigger Relationships on Relationship__c (before insert, before update, before delete, 
after insert, after update, after delete, after undelete) {

	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
  
    if(Trigger.isInsert && Trigger.isBefore){
        Relationships process = new Relationships(Trigger.new, Trigger.old, triggerAction.beforeInsert);
    }
    if( Trigger.isAfter && Trigger.isInsert ){
        Relationships process = new Relationships(Trigger.new, Trigger.old, triggerAction.afterInsert);
    }
    if(Trigger.isUpdate && Trigger.isBefore){
        Relationships process = new Relationships(Trigger.new, Trigger.old, triggerAction.beforeUpdate);
    }
    if( Trigger.isAfter && Trigger.isUpdate ){
        Relationships process = new Relationships(Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }
    if( Trigger.isAfter && Trigger.isUpdate ){
        Relationships process = new Relationships(Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }
    if( Trigger.isAfter && Trigger.isDelete ){
        Relationships process = new Relationships(Trigger.old, null, triggerAction.afterDelete);
    }   
}
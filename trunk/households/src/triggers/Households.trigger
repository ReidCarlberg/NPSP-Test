trigger Households on Contact (after insert, after update, after delete) {

	/// <name> triggerAction </name>
	/// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
 
    if( Trigger.isAfter && Trigger.isInsert ){
        Households process = new Households(Trigger.new, Trigger.old, triggerAction.afterInsert);
    }
    if( Trigger.isAfter && Trigger.isUpdate ){
        Households process = new Households(Trigger.new, Trigger.old, triggerAction.afterUpdate);
    }
    if( Trigger.isAfter && Trigger.isDelete ){
        Households process = new Households(Trigger.old, null, triggerAction.afterDelete);
    }
     
}
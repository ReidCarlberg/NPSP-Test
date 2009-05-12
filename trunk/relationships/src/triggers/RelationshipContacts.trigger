trigger RelationshipContacts on Contact (after delete) {

	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

    if( Trigger.isAfter && Trigger.isDelete ){
        Relationships.deleteEmptyRelationships();
    }
}
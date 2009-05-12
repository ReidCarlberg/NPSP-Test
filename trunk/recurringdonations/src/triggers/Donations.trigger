trigger Donations on Opportunity (before insert, before update, after insert, after update) {
// *********************************************************************************
// Copyright 2008 MK Partners, Inc. - www.mkpartners.com
// Version 2008-05-05
// *********************************************************************************

	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}

	if(Trigger.isUpdate && Trigger.isAfter){
	//	Donations processDonation = new Donations(Trigger.new, Trigger.old, triggerAction.afterUpdate);
	}

	if(Trigger.isInsert && Trigger.isAfter){
		//Donations processDonation = new Donations(Trigger.new, Trigger.old, triggerAction.afterInsert);
	}
}
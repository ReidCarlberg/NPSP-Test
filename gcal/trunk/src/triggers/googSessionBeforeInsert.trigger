trigger googSessionBeforeInsert on googSession__c (before insert) {
	
	//only do on a single insert
	if (trigger.new.size() == 1){
		//does one already exist for this user and scope?
		list<googSession__c> gs = new list<googSession__c>();		
		string currentUserID = UserInfo.getUserId();	
		currentUserID = currentUserID.substring(0, 15);
		gs = [select id from googSession__c where Token_User__c = :currentUserID and Scope__c = :trigger.new[0].Scope__c];
		if (gs.size() > 0) delete gs;
	
		//set name to the current user id
		trigger.new[0].Token_User__c = currentUserID;
		
	}
	
		
		
	

}
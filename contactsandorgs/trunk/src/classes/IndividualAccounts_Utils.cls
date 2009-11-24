public class IndividualAccounts_Utils {
    /// <name> triggerAction </name>
    /// <summary> contains possible actions for a trigger </summary>
    public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}
    
    public static Id IndividualAccountId; 
    
    //variable for Account Name
	private static String IndividualAccountName = Constants.BUCKET_ACCOUNT_NAME;

	public static id GetIndividualAccountId () {
	
		// look up the ID if we haven't already done it
		if ( IndividualAccountId == null ) {
			List<Account> acct = [select id,SYSTEMISINDIVIDUAL__c,SYSTEM_AccountType__c from account where Name =:IndividualAccountName LIMIT 1];
			if(acct.size()>0){
				
				if(acct[0].SYSTEMISINDIVIDUAL__c==false || acct[0].SYSTEM_AccountType__c<>Constants.BUCKET_ORGANIZATION_TYPE){
					acct[0].SYSTEMISINDIVIDUAL__c = true;
					acct[0].SYSTEM_AccountType__c = Constants.BUCKET_ORGANIZATION_TYPE;
				}
				update acct[0];
				
				IndividualAccountId = acct[0].id;	
			}			
		}
		return IndividualAccountId;
	}
	
	public static Id setIndividualAccountForTests(String accountName) {
		//create a fake Individual Account for tests

		Account individualAccountForTests = new Account(
			Name=accountName,
   	        SYSTEMISINDIVIDUAL__c = true,
   	        SYSTEM_AccountType__c = Constants.BUCKET_ORGANIZATION_TYPE
		);
		
		insert individualAccountForTests;
		
		Constants.BUCKET_ACCOUNT_NAME = accountName;
		IndividualAccountName = accountName;
		
		return individualAccountForTests.id;
		
	}
    
}
public class MetadataUtil
{
	public static Id getRecordTypeId(String objectType, String recordTypeName) {
    	return [SELECT Id FROM RecordType WHERE SobjectType = :objectType AND Name = :recordTypeName LIMIT 1].Id;
	}
   
    /**
  	 *  function updateLoanRecordType_NoCommit
  	 */
  	public static void updateLoanAccountRecordType_NoCommit(Id id, String recordTypeName) {
  		Id updateRecordTypeId = getRecordTypeId('Loan_Account__c', recordTypeName);

		Loan_Account__c updateObj = new Loan_Account__c(
        		Id = id,
			RecordTypeId = updateRecordTypeId
			);
    		update updateObj;  		
	}

	public static Loan_Transaction__c buildTransaction(Id loanAcctId,
  												Id recordTypeId,
  												Double amount,
  												Date dueDate,
  												String paymentType,
                                                Double gracePeriod)
	{
		return new Loan_Transaction__c(
			Loan_Account__c = loanAcctId,
			RecordTypeId = recordTypeId,
			Amount__c = amount,
			Due_Date__c = dueDate,
			Type__c = paymentType,
			Grace_Period_Days__c = gracePeriod
			); 		
  	}
}
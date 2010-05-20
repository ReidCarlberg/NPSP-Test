trigger SetGroupFromClient on Loan_Account__c bulk (before insert, before update)
{
	for (Integer i=0; i < Trigger.new.size(); i++)
	{
		if (Trigger.new[i].Client__c <> null)
		{
			if (Trigger.isInsert || Trigger.new[i].Client__c <> trigger.old[i].Client__c)
			{
				System.debug('select AccountId from Contact where Id = '+Trigger.new[i].Client__c);
				Id accountId = [select AccountId from Contact where Id = :Trigger.new[i].Client__c limit 1].AccountId;

				System.debug('accountId = '+accountId);

				if (accountId <> null)
				{
					Trigger.new[i].Group__c = accountId;
				}
			}
		}    
	}
}
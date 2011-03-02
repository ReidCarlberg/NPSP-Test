trigger FundraisingOpportunity on Opportunity (after insert, after update) 
{
	Map<ID, Opportunity> paymentCreateMap = new Map<ID, Opportunity>();
	Map<ID, Opportunity> paymentPlanCreateMap = new Map<ID, Opportunity>();
	
	//For insert either create one or many payments depending if it is an individual donation or a 
	//payment plan.
	if (Trigger.isInsert)
	{
		for (Opportunity opp : trigger.new)
		{
			//TODO: change out for custom settings.
			//This is the case where a single donation is made and we want the payment to be auto-created
			if (opp.RecordTypeID == Constants.donationOpp)
			{
				if (opp.Type == 'One-time')
				{
					paymentCreateMap.put(opp.ID, opp);
				}
				if (opp.Type == 'Payment Plan')
				{
					paymentPlanCreateMap.put(opp.ID, opp);
				}
			}
		}
		if (paymentCreateMap.keySet().size() > 0)
		{
			//call the method to create one-off Payments
			OpportunityPayments.createOneTimePayment(paymentCreateMap);
		}
		if (paymentPlanCreateMap.keySet().size() > 0)
		{
			//call the method to create all payment plan payments
			OpportunityPayments.createPaymentPlan(paymentPlanCreateMap); 
		}
	}
}
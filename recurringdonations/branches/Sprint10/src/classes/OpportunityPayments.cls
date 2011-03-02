public with sharing class OpportunityPayments {

	public static void createOneTimePayment(Map<ID, Opportunity> paymentCreateMap)
	{
		List<Payment__c> paymentList = new List<Payment__c>();
		
		//Need to iterate through each Opportunity and create a Payment for each.
		for (Opportunity opp : paymentCreateMap.values())
		{
			Payment__c payment = new Payment__c();
			payment.Amount__c = opp.Amount;
			payment.Date__c = opp.CloseDate;
			payment.Opportunity__c = opp.ID;
			payment.Status__c = 'Paid';
			if (opp.Check_Number__c != null)
			{
				payment.Check_Number__c = opp.Check_Number__c;
				payment.Payment_Method__c = 'Check';
			}
			paymentList.add(payment);
		}
		
		if (paymentList.size() > 0)
		{
			insert paymentList;
		}
	}
	
	public static void createPaymentPlan(Map<ID, Opportunity> paymentPlanCreateMap) 
	{
		List<Payment__c> paymentList = new List<Payment__c>();
		Decimal numPayments = 0, amountPerPayment = 0;
		String frequency = null;
		
		//Need to iterate through each Opportunity and create a Payment for each.
		for (Opportunity opp : paymentPlanCreateMap.values())
		{
			numPayments = opp.Number_of_Payments__c;
			frequency = opp.Payment_Frequency__c;
			if (numPayments == 0 || frequency == null || frequency.equals(''))
			{
				continue;
			}
			amountPerPayment = opp.Amount/numPayments;
			for (Integer i = 0; i < numPayments; i++)
			{
				Payment__c payment = new Payment__c();
				payment.Amount__c = amountPerPayment;
				payment.Date__c = getNextDate(opp.CloseDate, frequency, i);
				payment.Opportunity__c = opp.ID;
				//TODO: Make this Status value into a setting
				payment.Status__c = 'Expected';
				paymentList.add(payment);
			}
		}
		
		if (paymentList.size() > 0)
		{
			insert paymentList;
		}
	}
	
	public static Date getNextDate(Date closeDate, String frequency, Integer index)
	{
		if (frequency == 'Yearly')
		{
			return closeDate.addYears(index);
		} else
		if (frequency == 'Quarterly')
		{
			return closeDate.addMonths(3*index);
		} else
		if (frequency == 'Monthly')
		{
			return closeDate.addMonths(index);
		} else
		if (frequency == 'Weekly')
		{
			return closeDate.addDays(7*index);
		} else
		{
			return closeDate;
		}
	}
}
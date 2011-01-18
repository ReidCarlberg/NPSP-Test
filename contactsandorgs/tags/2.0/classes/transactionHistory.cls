public class transactionHistory {
/*
    public String getLifetimeTransactionTotal() {
        Decimal total = 0;
        for (OpportunityContactRole ocr : [Select Opportunity.Amount, Opportunity.Id, OpportunityId From OpportunityContactRole where Opportunity.IsWon = true and ContactId = :System.currentPageReference().getParameters().get('id') Order By Opportunity.CloseDate DESC])
        {
            total += ocr.Opportunity.Amount;
        }
        String totalString = '$';
        Decimal totalFormat = total.setScale(2);
        totalString += string.valueOf(totalFormat);

        return totalString;
    }


    public String getLastTransactionDate() {
        List<OpportunityContactRole> ocrs = [Select Opportunity.IsWon, Opportunity.CloseDate, Opportunity.Id, OpportunityId From OpportunityContactRole where ContactId = :System.currentPageReference().getParameters().get('id') Order By Opportunity.CloseDate DESC];
        if (ocrs.size() > 0)
        {
            Date lastDate = ocrs[0].Opportunity.CloseDate;
            return String.valueOf(lastDate);
        }
        return null;
    }
*/
}
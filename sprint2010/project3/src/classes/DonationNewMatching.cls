public class DonationNewMatching {
/*
    private final String url;

    private final Id rId;

    private final Id cId;
    
    private final Opportunity oppty;
    
    public DonationNewMatching(ApexPages.StandardController controller) {
        this.oppty= (Opportunity)controller.getRecord();

        List <RecordType> rts = [select Id from RecordType where SobjectType = 'Opportunity' and Name = 'Matching Donation' limit 1];
        if (rts.size() > 0)
        {
            rId = rts[0].Id;
        }
        else
        {
            rId = null;
        }

        List<OpportunityContactRole> ocr = [Select id, ContactId from OpportunityContactRole where IsPrimary = true and OpportunityId = :oppty.Id limit 1]; 
        if ( ocr.size() > 0 )
        {
            cId = ocr[0].ContactId;
        }
        else
        {
            cId = null;
        }

        String newurl = '/006/e?retURL=%2F';
        newurl += oppty.Id;

        if (rId != null)
        {
            newurl += '&RecordType=';
            newurl += rId;
        }
        newurl += '&cancelURL=%2F';
        newurl += oppty.Id;
        newurl += '&lookupcmpgn=1';
        newurl += '&accid=';
        newurl += oppty.AccountId;
        if (cId != null)
        {
            newurl += '&conid=';
            newurl += cId;
        }
        newurl += '&ent=Opportunity';
        newurl += '&opp3=';
        newurl += oppty.Name;
        url = newurl;
    }


    public String getUrl()
    {
        return url;
    }

    public Id getrId()
    {
        return rId;
    }

    public Id getcId()
    {
        return cId;
    }

*/
}
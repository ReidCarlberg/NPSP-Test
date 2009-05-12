public class ContactDeleteOverride
{
	private final Contact c;

    public ContactDeleteOverride(ApexPages.StandardController controller)
    {
        this.c = (Contact) controller.getRecord();
    }    

    public Boolean getDeleteAccount()
    { 
		PageReference newPage; 
		Boolean canDelete = true;
        if ( c.AccountId != null )
        {
        	Account a = [Select Id, Type from Account where Id = :c.AccountId limit 1];
        	if ( a.Type == 'One-to-One Individual')
        	{
        		for (Opportunity o : [Select Id, AccountId from Opportunity where AccountId = :a.Id limit 1])
        		{
        			canDelete = false;
        		}
        	} else
        	{
        		canDelete = false;
        	}
        } else
        {
        	canDelete = false;
        }
        if ( canDelete == false)
        {	
			return false;  
        } else
        {
			return true;
        }
    }

    private final ApexPages.StandardController controller;   

}
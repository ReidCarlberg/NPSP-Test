public class AccountViewOverride {

    private final Account account;

    public AccountViewOverride (ApexPages.StandardController controller)
    {
        List <Account> accounts = [select id, one2oneContact__c from Account where id = :ApexPages.currentPage().getParameters().get('id')];
        if (accounts.size() > 0)
        {
            account = accounts[0];
        }
        else
        {
            account = null;
        }
    }

    public Account getAccount()
    {
        return account;
    }

}
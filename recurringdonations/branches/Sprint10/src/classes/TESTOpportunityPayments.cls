/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TESTOpportunityPayments {

    static testMethod void testCreateNewOneTimePayment() {
        Opportunity opp = new Opportunity(Name = 'Test Opp 1');
        opp.Amount = 50;
        opp.StageName = 'Posted';
        opp.CloseDate = System.today();
        opp.Check_Number__c = '123tt';
        opp.RecordTypeId = Constants.donationOpp;
        opp.Type = 'One-time';
        insert opp;
        
        Payment__c testPayment = [select Amount__c, Status__c, Date__c, Check_Number__c, Payment_Method__c
        	from Payment__c where Opportunity__c = :opp.ID limit 1];
        	
        System.assertEquals(testPayment.Amount__c, opp.Amount);
    }
    
    static testMethod void testCreateNewPaymentPlan() {
        Opportunity opp = new Opportunity(Name = 'Test Opp 1');
        opp.Amount = 50;
        opp.StageName = 'Posted';
        opp.CloseDate = System.today();
        opp.RecordTypeId = Constants.donationOpp;
        opp.Type = 'Payment Plan';
        opp.Number_of_Payments__c = 7;
        opp.Payment_Frequency__c = 'Monthly';
        insert opp;
        
        List<Payment__c> paymentList = [select Amount__c, Status__c, Date__c, Check_Number__c, Payment_Method__c
        	from Payment__c where Opportunity__c = :opp.ID order by Date__c asc];
        	
        System.assertEquals(paymentList.size(), 7);
        Integer i = 0;
        for (Payment__c payment : paymentList) 
        {
        	System.assertEquals(payment.Amount__c, opp.Amount/7.0);
        	System.assertEquals(payment.Date__c, OpportunityPayments.getNextDate(opp.CloseDate, opp.Payment_Frequency__c, i));
        	i++; 
        }
    }
}
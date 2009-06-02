/*
	Copyright (c) 2009, Salesforce.com Foundation
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.
	* Neither the name of the Salesforce.com Foundation nor the names of
	  its contributors may be used to endorse or promote products derived
  	  from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
	COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
*/
public class templateConversion_Webservices_Test
{
    public static testmethod void converterTests()
    {
        Account a = new Account();
        a.Name = 'zyzyzyz';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        c.Phone = '415-555-1212';
        c.fax = '415-555-1212';
        c.mailingstreet = '1 Market St';
        c.mailingcity = 'San Francisco';
        c.mailingstate = 'CA';
        c.mailingpostalcode = '94105';
        c.mailingcountry = 'USA';
        insert c;
        
        Opportunity o = new Opportunity();
        o.Name = 'test Opportunity';
        o.Amount = 1;
        o.CloseDate = System.today();
        o.StageName = 'Prospecting';
        o.AccountId = a.Id;
        insert o;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = o.Id;
        ocr.ContactId = c.Id;
        ocr.Role = 'Donor';
        ocr.IsPrimary = true;
        insert ocr;
        
		test.starttest();
		
        //Instantiate and construct the controller class. 
        templateConversion_WebServices controller = new templateConversion_WebServices();

        Integer c1 = templateConversion_WebServices.getRecordCount(a.Id, 'Contact',20);
        Integer o1 = templateConversion_WebServices.getRecordCount(a.Id, 'Opportunity',20);
            
        //Use the PageReference Apex class to instantiate a page
        PageReference testPage = Page.templateConverter;
        Test.setCurrentPage(testPage);

        controller.queryTerm = 'zyzyzyz';
        controller.query();
        
        
        controller.accountId = a.Id;
        controller.accountName = 'zyzyzyz';
        controller.selectAccount();
        controller.convertContacts();
        controller.convertOpptys();

        templateConversion_WebServices.step1(a.Id,20);
        templateConversion_WebServices.step2(a.Id,20);
        templateConversion_WebServices.step3(a.Id,20);
        
        controller.getShowNoRecFound();
        List<Account> lst = new List<Account>();
        lst.add(new Account());
        controller.searchResults = lst;
        controller.getShowTable();
        
        controller.getAccountNotSelected();
        controller.getAccountSelected();
        controller.accountId = a.Id;
        controller.getAccountNotSelected();
        controller.getAccountSelected();
        
        templateConversion_WebServices.createAccounts(a.Id);
        templateConversion_WebServices.updateContacts(a.Id);
        templateConversion_WebServices.updateOpportunities(a.Id);
        templateConversion_WebServices.getRecordCount(a.Id, 'Contact', null);
        
        controller.cCount = 10000;
        controller.validateContactCount();
        controller.cCount = 1001;
        controller.validateContactCount();
    
        controller.oCount = 10000;
        controller.validateOpportunityCount();
        controller.oCount = 1001;
        controller.validateOpportunityCount();

		test.stoptest();
	}

    public static testmethod void badSearchTerm()
    {

		test.starttest();

        //Use the PageReference Apex class to instantiate a page
        PageReference testPage = Page.templateConverter;
        Test.setCurrentPage(testPage);

        //Instantiate and construct the controller class. 
        templateConversion_WebServices controller = new templateConversion_WebServices();

        controller.queryTerm = '';
        controller.query();
        controller.queryTerm = 'te';
        controller.query();
        Boolean showTable = controller.getShowTable();
        Boolean ShowNoRecFound = controller.getShowNoRecFound();
        Boolean AccountNotSelected = controller.getAccountNotSelected();
        Boolean AccountSelected = controller.getAccountSelected();

		test.stoptest();

    }
}
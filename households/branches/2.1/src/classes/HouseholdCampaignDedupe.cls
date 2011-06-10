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
public without sharing class HouseholdCampaignDedupe {
    
    //HH campagin deduplication. Based on base classes by Evan Callahan and Kevin Bromer
    
    public Campaign getCampaign(){return campaign;}
    private final Campaign campaign;
    private string errormsg;
    private string CampaignMailingListReportId;
    private boolean haveReportID;
  
    public HouseholdCampaignDedupe(ApexPages.StandardController controller)
    { 
        
        
        CampaignMailingListReportId = 'mybigid' ;   //NEED TO DECIDE WHERE TO GET ID FROM Main.settings.Household_Mailing_List_Report_ID__c;
        haveReportID = true; 
        
      
        Campaign campaign = (Campaign)controller.getRecord();
      
        if ((CampaignMailingListReportId == null) || (CampaignMailingListReportId == ''))
        {     
            CampaignMailingListReportId = Campaign.Id;
            haveReportID = false;
        }
    
        string urlCampaignID = ApexPages.currentPage().getParameters().get('id');
        campaign = [select id, name from campaign where id = :urlCampaignID];
    
    }  
  
    public PageReference RunReport()
    {
        string ActiveID = campaign.id;
        ActiveID = ActiveID.substring(0,15);
        string newPageUrl;
        integer dupsmarked;
        Schema.DescribeFieldResult HHFieldCheck = Contact.Household__c.getDescribe();
        
        if (HHFieldCheck == null)
        {
            errormsg = 'Error: You do not currently have householding enabled';
            newPageUrl = campaign.id;
        }
        else if (haveReportID != true)
        {
            errormsg = 'Error: Please provide the ID of the mailing list report in the custom settings section';
            newPageUrl = campaign.id;        
        }
    
        else
        {
        dupsmarked = MarkDuplicates();
        newPageUrl = '/' + CampaignMailingListReportId + '?retURL=/' + ActiveID + '&scopeid_lkid=' + ActiveID + '&scope=one&scopeid=' + Campaign.Name;    
        }
  
        PageReference newPage = new PageReference(newPageUrl);       
        return newPage.setRedirect(true);
    }

    private integer MarkDuplicates(){
    // mark duplicate households in campaign membership

        final string DupeText = ' - Household Duplicate';

        //check for the Household Duplicate status values we need
        Map<string, boolean> StatusLabels = new Map<string, boolean>();
        CampaignMemberStatus[] statuses = [select label, hasResponded from CampaignMemberStatus where CampaignId=:campaign.id];
        for (CampaignMemberStatus cms : statuses) StatusLabels.put(cms.label, cms.hasResponded);
        system.debug(StatusLabels);
        integer nextSortOrder = [select sortorder from CampaignMemberStatus where CampaignId=:campaign.Id order by sortorder desc limit 1].SortOrder + 1;
        CampaignMemberStatus[] newStatuses = new CampaignMemberStatus[]{};

        //identify dupes and put them in an array
        //since the results are ordered by Household Id, the dupes will be contiguous
        CampaignMember[] dupeMembers = new CampaignMember[]{};
        id PreviousHousehold;
        integer dupes = 0;
        for (CampaignMember m : [Select Id, ContactId, Contact.Household__c, Status From CampaignMember where CampaignId=:campaign.Id and ContactId != null and Contact.Household__c != null order by Contact.Household__c, contact.CreatedDate]) {

            //do not want null status
            if (m.Status==null) m.Status = statuses[0].label;

            //if this household is already marked, skip it
            if (!m.Status.endsWith(DupeText)) {
                //if the current contact's Household Id == that of the one before it, mark it a dupe
                if (m.Contact.Household__c==PreviousHousehold) {
                    string newStatus =  m.Status + DupeText;
                    dupeMembers.add(new CampaignMember(Id = m.Id, Status = newStatus));
                    if (!StatusLabels.containsKey(newStatus)) {
                        newStatuses.add(new CampaignMemberStatus(label=newStatus, campaignid=campaign.Id, hasResponded=StatusLabels.get(m.Status), sortorder=nextSortOrder));
                        StatusLabels.put(newStatus, StatusLabels.get(m.Status));
                        nextSortOrder++;
                    }
                    //check if we at 1000 dupes -- that's the max apex will allow in a list
                    if (dupeMembers.size()==1000) {
                        if (!newStatuses.isEmpty()) {
                            insert newStatuses;
                            newStatuses.clear();
                        }
                        update dupeMembers;
                        dupeMembers.clear();
                        dupes += 1000;
                    }
                }
                PreviousHousehold=m.Contact.Household__c;
            }
        }
        system.debug(newStatuses);
        if (!newStatuses.isEmpty()) insert newStatuses;
        if (!dupeMembers.isEmpty()) {
            update dupeMembers;
            dupes += dupeMembers.size();
        }
        return (dupes);
    }

    /* BEGIN TESTS */
      
  
  public static testMethod void testCampaignHHReport() {
    // create test data
    Account acct = new Account (
      Name='Test Account'
    );
    insert acct;
    
    Contact con = new Contact (
      FirstName='Kevin',
      LastName='Test',
      AccountId = acct.id,
      email='kevinb@npowerseattle.org'
    );
    insert con;
    
    Contact con2 = new Contact (
      FirstName = 'Amy',
      LastName = 'Test',
      AccountId = acct.id,
      email = 'amyb@npowerseattle.org',
      household__c = con.Household__c
    );
    insert con2;
    
    Campaign camp = new Campaign (
      Name = 'MyCampaign',
      Status = 'Planned'
    );
    insert camp;
    
    CampaignMember campm1 = new CampaignMember(
      CampaignID = camp.id,
      ContactID = con.id
    );
    insert campm1;
    
    CampaignMember campm2 = new CampaignMember(
      CampaignID = camp.id,
      ContactID = con2.id
    );
    insert campm2;
    
           
    Test.startTest();

    // create the page 
    PageReference pageRef;//=Page.HouseholdMailingList;
    Test.setCurrentPage(pageRef); 

    // set the parameter for the campaign
    ApexPages.currentPage().getParameters().put('id', camp.id);
    
    // instantiate the controller
    ApexPages.Standardcontroller CampaignController = new ApexPages.Standardcontroller(camp);
    HouseholdCampaignDedupe controller = new HouseholdCampaignDedupe(CampaignController);
        
    // run the report
    pagereference ref = controller.RunReport();
  
  }
    
    
    
    
    static testMethod void Test_Campaign_Dedupe() {
        // add a campaign w/ default camp. mbr status settings
        Campaign testCamp1 = new Campaign (
            Name = 'Test Campaign 1',
            IsActive = True
        );
        insert testCamp1;
        //create first contact
        Contact firstContact = new Contact (
            FirstName='Joe',
            LastName='Johanssen',
            otherStreet='123 Elm St',
            otherCity='Wauwatosa',
            otherState='WI',
            otherPostalCode='53213',
            otherCountry='USA'
            
        );
        insert firstContact;
        id spouseId = [select id from contact where firstname='Jane' and lastname='Johanssen' limit 1].id;
        //create first contact
        Contact secondContact = new Contact (
            FirstName='Daddy',
            LastName='Warbucks'
        );
        insert secondContact;

        // add to the campaign
        CampaignMember[] members = new CampaignMember[] {
            new CampaignMember(contactid=firstcontact.id, campaignid=testcamp1.id),
            new CampaignMember(contactid=secondcontact.id, campaignid=testcamp1.id, status='Responded'),
            new CampaignMember(contactid=spouseId, campaignid=testcamp1.id, status='Responded')
        };
        insert members;

        integer result;
        
        system.assertEquals ( 1, result);
        CampaignMember m1 = [Select Id, Status, HasResponded FROM CampaignMember WHERE CampaignId = :testCamp1.Id AND ContactId = :spouseId limit 1];
        CampaignMember m2 = [Select Id, Status, HasResponded FROM CampaignMember WHERE CampaignId = :testCamp1.Id AND ContactId = :firstContact.id limit 1];
        CampaignMember m3 = [Select Id, Status, HasResponded FROM CampaignMember WHERE CampaignId = :testCamp1.Id AND ContactId = :secondContact.id limit 1];
        system.assertEquals ( 'Responded - Household Duplicate', m1.status );
        system.assertEquals ( 'Sent', m2.status );
        system.assertEquals ( 'Responded', m3.status );        
    }   
}
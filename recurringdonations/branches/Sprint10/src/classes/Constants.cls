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

/*
	Constants for use in other IndividualAccounts.cls
*/
global class Constants {
	//One-to-One value for system processor field
	public static String ONE_TO_ONE_PROCESSOR = 'One-to-One';
	//One-to-One org type value
    public static String ONE_TO_ONE_ORGANIZATION_TYPE = 'One-to-One Individual';
    
    //Bucket value for system processor field
    public static String BUCKET_PROCESSOR = 'Individual';
    //Buck org type value
    public static String BUCKET_ORGANIZATION_TYPE = 'Bucket Individual';
    //Bucket Account name
    public static String BUCKET_ACCOUNT_NAME = 'Individual';
    
    public static boolean ONE_TO_ONE_ACCOUNT_MODEL = isOneToOne();
    
     //method to tell which model we're currently in for Accounts
    public static boolean isOneToOne() {
    	boolean isOneToOneModel;
    	isOneToOneModel = false;
    	Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.SystemAccountProcessor__c; 
		List<Schema.PicklistEntry> P = F.getPicklistValues();
		for(Schema.PicklistEntry pe : P){
			if (pe.isDefaultValue()){
				if(pe.getValue()==Constants.ONE_TO_ONE_PROCESSOR){ isOneToOneModel = true;}
			}
		}
		
    	return isOneToOneModel;
    }
    
    private static Map<String, Schema.RecordTypeInfo> oppTypeMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
	public static final ID donationOpp = oppTypeMap.get('Donation').getRecordTypeId();
	public static final ID grantOpp = oppTypeMap.get('Grant').getRecordTypeId();
	public static final ID pledgeOpp = oppTypeMap.get('Pledge').getRecordTypeId();

}
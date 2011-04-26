public class HouseholdOpportunity {
    public HouseholdOpportunity(){}    

    public HouseholdOpportunity(Opportunity[] opportunities, Opportunity[] oldOpportunities, Households.triggerAction ta)
    {
        Contacts_and_Orgs_Settings__c ContactsSettings = Constants.getContactsSettings();
        Households_Settings__c currentHouseholdsSettings = Households.getHouseholdsSettings();
        if(currentHouseholdsSettings.Household_Contact_Roles_On__c){
        //get all Opps in the trigger set that are for individual accounts 
        List<Opportunity> oppsForContactRoles = [select Id, AccountId, account.One2OneContact__c,account.SYSTEMIsIndividual__c from Opportunity where Id IN :opportunities AND account.SYSTEMIsIndividual__c = true];
        
        if(oppsForContactRoles.size()>0){
            
            //set of contact Ids on Accounts for Opps in the trigger set
            Set<Id> contactIds = new Set<Id>();         
            
            //real contacts queried from that list of Ids on the Accounts
            List<Contact> individualContacts = new List<Contact>();
            
            //list of contacts queried for households of contacts on the opps
            List<Contact> householdContacts = new List<Contact>();
            
            //map Contacts to Opps
            Map<id,List<Opportunity>> contactIdToOpps = new Map<id,List<Opportunity>>();
            
            //map Household Id to the member Contacts
            Map<id,List<Contact>> householdIdToContact = new Map<id,List<Contact>>();           
            
            //loop throught the Opportunities
            for(Opportunity thisOpp : oppsForContactRoles){ 
                //grab all the contacts off the Accounts
                contactIds.add(thisOpp.account.One2OneContact__c);
                //create the map of contacts to opps
                if(contactIdToOpps.get(thisOpp.account.One2OneContact__c)==null){
                    contactIdToOpps.put(thisOpp.account.One2OneContact__c,new List<Opportunity>());                  
                }
                contactIdToOpps.get(thisOpp.account.One2OneContact__c).add(thisOpp);
            }
            
            //map for contacts to their households because we can't get a query with Opp Id, Contact Id, and Household Id
            Map<Id,Id> contactIdToHouseholdId = new Map<Id,Id>();
            
            //query all contacts to get the Household Ids
            individualContacts = [select id,Household__c from Contact where Id IN :contactIds];
            
            //create a map of contacts and thier Household Ids
            for(Contact myContact : individualContacts){
                if(myContact.Household__c!=null){
                    contactIdToHouseholdId.put(myContact.Id,myContact.Household__c);        
                }       
            }
            
            //query all contacts in all the Households
            householdContacts = [select id,Household__c from Contact where Household__c IN :contactIdToHouseholdId.values()];
            
            //create a map of Household Id to list of member contacts
            for(Contact myContact : householdContacts){
                if(householdIdToContact.get(myContact.Household__c)==null){
                    householdIdToContact.put(myContact.Household__c,new List<Contact>());                   
                }
                householdIdToContact.get(myContact.Household__c).add(myContact);
            }
            
            map <String,Id> contactOppToContactRole = new Map <String,Id> ();
        
            // query for OppConRoles where primary=true and OppID in arg set
            OpportunityContactRole[] conRoles = [select Id,OpportunityId, ContactId From OpportunityContactRole WHERE IsPrimary = true AND Opportunity.Id IN :oppsForContactRoles ];
            String uniqueConRole = '';
            // now loop through the results and build the map
            for (OpportunityContactRole thisCR : conRoles) {
                uniqueConRole = string.valueOf(thisCR.OpportunityId) + string.valueOf(thisCR.ContactId);
                contactOppToContactRole.put(uniqueConRole , thisCR.Id );
            }
            
            //list to hold new contact roles
            List<OpportunityContactRole> contactRolesForCreation = new List<OpportunityContactRole>();
            List<OpportunityContactRole> contactRolesForUpdate = new List<OpportunityContactRole>();
            
            //loop through all contacts that have opps
            for(Id thisContactId : contactIdToOpps.keySet()){
                //loop through all opps
                for(Opportunity thisOpp : contactIdToOpps.get(thisContactId)) {
                    
                    if(contactIdToHouseholdId.get(thisContactId)!=null){
                        //loop through all households members
                        for(Contact householdMember : householdIdToContact.get(contactIdToHouseholdId.get(thisContactId))){
                            
                            //different role for primary donor
                            if(thisContactId==householdMember.Id){
                                uniqueConRole = string.valueOf(thisOpp.Id)+string.valueOf(householdMember.Id);
                                if(contactOppToContactRole.get(uniqueConRole)!=null){
                                    OpportunityContactRole thisRole = new OpportunityContactRole(id=contactOppToContactRole.get(uniqueConRole));
                                    thisRole.Role = ContactsSettings.Opportunity_Contact_Role_Default_role__c;
                                    contactRolesForUpdate.add(thisRole);
                                    
                                } else {
                                    OpportunityContactRole thisRole = new OpportunityContactRole();
                                    thisRole.OpportunityId = thisOpp.Id;
                                    thisRole.ContactId = householdMember.Id;
                                    thisRole.Role = ContactsSettings.Opportunity_Contact_Role_Default_role__c;
                                    thisRole.isPrimary = true;
                                    contactRolesForCreation.add(thisRole);
                                }
                            } else {
                                OpportunityContactRole thisRole = new OpportunityContactRole();
                                thisRole.OpportunityId = thisOpp.Id;
                                thisRole.ContactId = householdMember.Id;
                                thisRole.Role = currentHouseholdsSettings.Household_Member_Contact_Role__c;
                                contactRolesForCreation.add(thisRole);
                            }
                            
                        }
                    }                   
                }
            }
            If(contactrolesforCreation!=null){
                insert contactrolesforCreation;   
            }
            if(contactRolesForUpdate!=null){
                update contactRolesForUpdate;   
            }   
        }
    }
    }
}
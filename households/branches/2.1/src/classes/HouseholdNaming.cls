global virtual without sharing class HouseholdNaming {
    
    @future 
    global static void FutureUpdateNames(list<id> hhids){    	
    	//create a new instance of the HouseholdNaming class -
    	//and pass in our param
    	//this is b/c of the global visibility
    	HouseholdNaming hn = new HouseholdNaming();
    	hn.UpdateNames(hhids);    	
    }
    
    global virtual void UpdateNames(list<id> hhids){
            
        //get all of the contacts and their associated households
        list<Contact> contactlist = [select id, Firstname, Salutation, LastName, Household__r.id, Naming_Exclusions__c from Contact where Household__c IN :hhids];
        list<Household__c> hhupdatelist = [select Name, SYSTEM_CUSTOM_NAMING__c from Household__c where id IN : hhids];
        
        map<id, list<Contact>> hhIDContactMap = new map<id, list<Contact>>();
        
        //sort contacts by household
        for (Contact c : contactlist){        	
        	if(!hhIDContactMap.containskey(c.Household__r.id)){
                hhIDContactMap.put(c.Household__r.id, new list<Contact>{c});
        	}
        	else{
        		list<Contact> clist = hhIDContactMap.get(c.Household__r.id);
        		clist.add(c);
        		
        	}
        }
                
        //loop through the households needing name changes, if necessary, make them.
        for (Household__c h : hhupdatelist){    
        
            string customnameparam = '';
            if (h.SYSTEM_CUSTOM_NAMING__c != null){
            	customnameparam = h.SYSTEM_CUSTOM_NAMING__c;
            }            
            
            if (!customnameparam.contains('Name'))
                h.Name = getHHName(hhIDContactMap.get(h.id));	
        	
            if (!customnameparam.contains('Formal_Greeting__c'))
                h.Formal_Greeting__c = getFormalName(hhIDContactMap.get(h.id));

            if (!customnameparam.contains('Informal_Greeting__c'))
                h.Informal_Greeting__c = getInformalName(hhIDContactMap.get(h.id));
            
        }
        
        if (!hhupdatelist.isEmpty()) Database.update(hhupdatelist, false);
    }
    
    //get generic household name 
    global virtual string getHHName(list<Contact> ContactList){
    	string householdname = '';
    	
    	if(ContactList != null){
    	    //most of our records will be either one or two people per household, so we'll handle
    	    //those cases seperately, process medium size households, then
    	    //go on to larger
    	    
            set<string> commonlastnames = new set<string>(); 
            list<contact> contactnames = new list<contact>();
             
            for (Contact c : ContactList){
                //add valid values to the contactnames and lastnames lists for processing
                if(c.Naming_Exclusions__c == null || !c.Naming_Exclusions__c.contains('Household Name')){
                    contactnames.add(c);
                    
                    if (!commonlastnames.contains(c.LastName))
                        commonlastnames.add(c.LastName);
                }   
            }
            
            //we lost our only contact - he/she's anonymous
    	    if (commonlastnames.isEmpty())
                householdname = 'Anonymous ' + system.label.DefaultHouseholdName;
    	    
    	    //standard hh naming
    	    else if (commonlastnames.size() == 1){    		
    		    Contact c = Contactnames[0];                    		 
                householdname = c.LastName;    		  
                householdname += ' ' + system.label.DefaultHouseholdName;
    	    }
            else if (commonlastnames.size() == 2){            	
            	Contact c1 = Contactnames[0];
            	Contact c2 = Contactnames[1];            	
                householdname = c1.LastName;
                householdname += ' and ' + c2.LastName + ' ' + system.label.DefaultHouseholdName;
            }                	
            else if (commonlastnames.size() > 2 && commonlastnames.size() < 10){
                for (string ln : commonlastnames){
                    if (householdname.length() < 1)
                        householdname = ln;
                    else
                        householdname += ', ' + ln;
                }
                householdname += ' ' + system.label.DefaultHouseholdName;
        	}        	        	
        	//more than 10 DIFFERENT last names, default to family, it can be overwritten in this 
        	//special case
        	else{
        	   householdname = ContactList[0].LastName;
        	   householdname += ' and friends ' + system.label.DefaultHouseholdname;
        	}
    	}
        return householdname;
    }
    
    
    //just pile up first names for qualifying contacts
    global virtual string getInformalName(list<Contact> ContactList){
        string informalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        //remove any excluded contacts
        if (Contactlist != null){
        
        for (Contact c : ContactList){ 
            if(c.FirstName != null && (c.Naming_Exclusions__c == null || !c.Naming_Exclusions__c.contains('Informal Greeting')))
                contactnames.add(c);
        }
        
        integer listsize = 0;
        if (contactnames != null)
            listsize = contactnames.size();
        
        if (listsize == 0)
            informalname = 'Sir or Madame';
        
        else if (listsize == 1)
            informalname = contactnames[0].FirstName;
        
        else if (listsize == 2)
        	informalname = contactnames[0].FirstName + ' and ' + contactnames[1].FirstName;
        
        //more than 2
        else{
        	integer counter = 1;
            for (Contact c : contactnames){
            	
            	//we're at the first name in the group
            	if (counter == 1)
            		informalname += c.FirstName;
            	//if we're at the last name in the group
            	else if (counter == contactnames.size())
                    informalname += ' and ' + c.FirstName;
            	//we're somewhere in the middle of the group
            	else
            		informalname += ', ' + c.Firstname;
            	
                counter++;
            }  
        }
        }
        return informalname;
    }
    
    global virtual string getFormalName(list<Contact> ContactList){
        string formalname = ''; 
       
        list<Contact> contactnames = new list<Contact>();
       
        integer i = 0;
        
        if (Contactlist != null){
        //remove any excluded contacts
        for (Contact c : ContactList){ 
            if(c.Naming_Exclusions__c == null || !c.Naming_Exclusions__c.contains('Formal Greeting'))
                contactnames.add(c);
        }
        
            //chuck all of the last names in a set, lets see how many different ones we have
        set<string> lastnamelist = new set<string>();
        for (Contact c : contactnames)
            lastnamelist.add(c.LastName);  
      
      
        //no non-excluded contact for this household
        if (contactnames.size() == 0){                        
        	formalname += '-'; 
        }
        else if (contactnames.size() > 0 && contactnames.size() < 9){
            
            integer counter = 1;
            for(Contact c : contactnames){    
                    
                if (c.Salutation != null)
                    formalname += c.Salutation + ' ';
                if (c.FirstName != null)
                    formalname += c.FirstName + ' ';                    
                if (lastnamelist.size() != 1 && counter != contactnames.size())
                    formalname += c.LastName;
                    
                //any first name before the last and next to last gets the
                //same treatment, a comma.
                if(counter < (contactnames.size() - 1))
                    formalname += ', ';
                else if (counter == (contactnames.size() -1))
                    formalname += ' and ';	                    	
                //add the family name     
                else
                    formalname += c.LastName;
        
                counter++;
            }            
        }          
        
        //else we have 9 or more people
        else{        
            //some default name here        
            if (contactnames[0].Salutation != null)
                formalname += contactnames[0].Salutation + ' ';
            if (contactnames[0].FirstName != null)
                formalname += contactnames[0].FirstName + ' ';                    
            
            formalname += contactnames[0].LastName + ' and friends';
        }
        }
        return formalname;
    }
    
    
    
    /*** Test Methods ***/
    static testMethod void HouseholdNamingTest(){
      
      //settings
      Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null                    
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
    	
        integer i;
        
        list<Contact> insertlist = new list<Contact>();
    	for (i = 0; i < = 20; i++){
    		Contact c = new Contact(LastName = 'LastName' + i, FirstName = 'FirstName' + i, Salutation = 'Mr.');
    		if (i == 1){
    			c.Naming_Exclusions__c = 'Household Name';
    		}
    		
    		insertlist.add(c);
    	}    	
    	    	
    	insert insertlist;
    	list<id> householdids = new list<id>();
    	
    	list<Contact> clist = [select Household__r.id, Household__r.Name, Household__r.Informal_Greeting__c, Household__r.Formal_Greeting__c from Contact where id IN :insertlist];
    	
    	for (Contact c : clist){
    		if (c.household__r.id != null)
    		  householdids.add(c.Household__r.id);    		
    	}
    	system.assert(householdids.size() > 0);
    	Householdnaming hn = new HouseholdNaming();    	    	
    	hn.UpdateNames(householdids);
    	
    	//test a single member household, lastname, firstname, householdname:
    	Contact con = [select Household__r.Name, Household__r.Informal_Greeting__c, Household__r.Formal_Greeting__c from Contact where FirstName = 'FirstName0'];
        system.assertEquals('LastName0 ' +  system.label.DefaultHouseholdName, con.Household__r.Name);	
        system.assertEquals('FirstName0',con.Household__r.Informal_Greeting__c);
        system.assertEquals('Mr. FirstName0 LastName0', con.Household__r.Formal_Greeting__c);
        
        //update some contacts and note the changes
        
        //set first one to the last household, next two to the second, next five to the third, 
        //and next 10 to the forth to last
        integer counter = 0;
                
        for (Contact c : clist){
            
            if(counter == 0)
                c.npo02__Household__c = clist[clist.size() - 1].npo02__Household__c;
            else if (counter > 0 && counter < 3)
                c.npo02__Household__c = clist[clist.size() - 2].npo02__Household__c;
            else if (counter > 2 && counter < 8)
                c.npo02__Household__c = clist[clist.size() - 3].npo02__Household__c;
            else if (counter < 20)
                c.npo02__Household__c =clist[clist.size() - 4].npo02__Household__c;
        	counter++;
        }
        update clist;
        
        list<id> newhhids = new list<id>();
        newhhids.add(clist[clist.size() - 1].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 2].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 3].npo02__Household__r.id);
        newhhids.add(clist[clist.size() - 4].npo02__Household__r.id);
               
        HouseholdNaming.FutureUpdateNames(newhhids);
    	/*
    	map<id, Household__c> hhmap = new map<id, Household__c>([select id, Formal_Greeting__c, Name, Informal_Greeting__c from Household__c]);
    	
    	//refresh clist
    	clist.clear();
    	clist = [select Household__r.id, Household__r.Name, Household__r.Informal_Greeting__c, Household__r.Formal_Greeting__c from Contact where id IN :insertlist];
    	
    	//1 other family member
    	id testingid = clist[clist.size() - 1].npo02__Household__r.id;
        system.assertEquals(clist[clist.size() - 1].npo02__Household__r.Name, hhmap.get(testingid).Name);
        system.assertEquals(clist[clist.size() - 1].npo02__Household__r.Informal_Greeting__c, hhmap.get(testingid).Informal_Greeting__c);
        system.assertEquals(clist[clist.size() - 1].npo02__Household__r.Formal_Greeting__c, hhmap.get(testingid).Formal_Greeting__c);
        
        testingid = clist[clist.size() - 2].npo02__Household__r.id;
        system.assertEquals(clist[clist.size() - 2].npo02__Household__r.Name, hhmap.get(testingid).Name);
        system.assertEquals(clist[clist.size() - 2].npo02__Household__r.Informal_Greeting__c, hhmap.get(testingid).Informal_Greeting__c);
        system.assertEquals(clist[clist.size() - 2].npo02__Household__r.Formal_Greeting__c, hhmap.get(testingid).Formal_Greeting__c);
        
        testingid = clist[clist.size() - 3].npo02__Household__r.id;
        system.assertEquals(clist[clist.size() - 3].npo02__Household__r.Name, hhmap.get(testingid).Name);
        system.assertEquals(clist[clist.size() - 3].npo02__Household__r.Informal_Greeting__c, hhmap.get(testingid).Informal_Greeting__c);
        system.assertEquals(clist[clist.size() - 3].npo02__Household__r.Formal_Greeting__c, hhmap.get(testingid).Formal_Greeting__c);
        
        testingid = clist[clist.size() - 4].npo02__Household__r.id;
        system.assertEquals(clist[clist.size() - 4].npo02__Household__r.Name, hhmap.get(testingid).Name);
        system.assertEquals(clist[clist.size() - 4].npo02__Household__r.Informal_Greeting__c, hhmap.get(testingid).Informal_Greeting__c);
        system.assertEquals(clist[clist.size() - 4].npo02__Household__r.Formal_Greeting__c, hhmap.get(testingid).Formal_Greeting__c);
    	
    	//then update the households to cause different last name combinations and test
    	  */  	
    	
    	
    }
 

}
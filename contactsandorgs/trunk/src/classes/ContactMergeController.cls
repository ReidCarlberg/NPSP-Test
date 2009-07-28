public class ContactMergeController {
	
	public ContactMergeController(){
		searchText='';
		searchResults = new List<contactWrapper>();
		thisMerge = new mergeSet();
		displaySelected = false;
	}
	public Boolean displaySelected { get { return displaySelected; } set { displaySelected = value; } }
	
	public String searchText { get { return searchText; } set { searchText = value; } }
	
	public List<contactWrapper> searchResults { get { return searchResults; } set { searchResults = value; } }
	
	private Integer mergeLimit = 3;

	public mergeSet thisMerge { get { return thisMerge; } set { thisMerge = value; } }
	
	public class contactWrapper
    {
        public Contact con {get; set;}
        public Boolean selected {get; set;}
        public contactWrapper(Contact c)
        {
            con = c;
            selected = false;
        }
    }
    
    public class mergeSet
    {
        public List<Contact> selectedContacts {get; set;}
        
        public Boolean firstIsWinner {get; set;}
        public Boolean secondIsWinner {get; set;}
        public Boolean thirdIsWinner {get; set;}
        

        
        public Contact firstContact = new Contact();
        public Contact getfirstContact(){
    		if(selectedContacts.size()>0){
    			return selectedContacts[0];
    		} else {
    			return null;
    		}
        }
        public Contact secondContact = new Contact();
        public Contact getSecondContact(){
    		if(selectedContacts.size()>1){
    			return selectedContacts[1];
    		} else {
    			return null;
    		}
        }
        public Contact thirdContact = new Contact();
        public Contact getThirdContact(){
    		if(selectedContacts.size()>2){
    			return selectedContacts[2];
    		} else {
    			return null;
    		}
        }
        
        public Contact winner {get; set;}
        public List<Contact> losers {get; set;}
        
        public void selectFirstContact() {
		firstIsWinner = true;
    	secondIsWinner = false;
    	thirdIsWinner = false;
    	winner = firstContact;
    	Losers.clear();
    	if(secondContact!=null){
    		Losers.add(secondContact);
    	}
    	if(thirdContact!=null){
    		Losers.add(thirdContact);
    	}
	
	}
	
	public void selectSecondContact() {
		firstIsWinner = false;
    	secondIsWinner = true;
    	thirdIsWinner = false;
    	winner = secondContact;
    	Losers.clear();
    	if(firstContact!=null){
    		Losers.add(firstContact);
    	}
    	if(thirdContact!=null){
    		Losers.add(thirdContact);
    	}
	
	}
	
	public void selectThirdContact() {
		firstIsWinner = false;
    	secondIsWinner = false;
    	thirdIsWinner = true;
    	winner = thirdContact;
    	Losers.clear();
    	if(firstContact!=null){
    		Losers.add(firstContact);
    	}
    	if(secondContact!=null){
    		Losers.add(secondContact);
    	}
    	
	
	}
        
        public mergeSet() {
			selectedContacts = new List<Contact>();
			losers = new List<Contact>();
			winner = new Contact();
			
			firstIsWinner = false;
        	secondIsWinner = false;
        	thirdIsWinner = false;

        }
    }
	
	public void search() {
		thisMerge.selectedContacts.clear();
		searchResults.clear();
		displaySelected = false;
		
		String searchquery = 'FIND \'' + searchText + '\' IN ALL FIELDS RETURNING Contact(id,name,email,phone) LIMIT 20'; 
		List<List<SObject>> searchList = search.query(searchquery);
		for (SObject returnedObject : searchList[0]){
			//if the returned object is a contact, add it to the Contact list
			if(returnedObject.getSObjectType() == Contact.sObjectType){
				contactWrapper thisResult = new contactWrapper((Contact) returnedObject);
				
				searchResults.add(thisResult);	
			}
		}
	}
	
	public PageReference getSelected()
    {
        thisMerge.selectedContacts.clear();
        for(contactWrapper conWrapper : searchResults) {
        	if(conWrapper.selected == true) {
        		thisMerge.selectedContacts.add(conWrapper.con);
        	}
        }
        if(thisMerge.selectedContacts.size()>mergeLimit){
        	//report an error that you can only select 3 or fewer
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'You can only merge up to 3 contacts at a time.');
        	ApexPages.addMessage(myMsg);
        	displaySelected = false;
        } else {
        	
        	if (thisMerge.selectedContacts.size()>0){
        		displaySelected = true;
        	} else {
        		displaySelected = false;
        	}
        }
        return null;
    }

	

	
	public void mergeContacts() {

	}


}
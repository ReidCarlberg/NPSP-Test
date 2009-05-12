trigger SyncAdd4mAcc2Contact on Account (after update) {
    List<Contact> contacts = new List<Contact>();
    List<Account> modAccts = new List<Account>();
    
    
    for(Account acc:Trigger.new){
        
        
        if (            acc.Type == 'One-to-One Individual' && 
                        (acc.BillingStreet != Trigger.oldMap.get(acc.Id).BillingStreet ||
                        acc.BillingCity != Trigger.oldMap.get(acc.Id).BillingCity ||
                        acc.BillingState != Trigger.oldMap.get(acc.Id).BillingState ||
                        acc.BillingPostalCode != Trigger.oldMap.get(acc.Id).BillingPostalCode ||
                        acc.BillingCountry != Trigger.oldMap.get(acc.Id).BillingCountry ||
                        acc.ShippingStreet != Trigger.oldMap.get(acc.Id).ShippingStreet ||
                        acc.ShippingCity != Trigger.oldMap.get(acc.Id).ShippingCity ||
                        acc.ShippingState != Trigger.oldMap.get(acc.Id).ShippingState ||
                        acc.ShippingPostalCode != Trigger.oldMap.get(acc.Id).ShippingPostalCode ||
                        acc.ShippingCountry != Trigger.oldMap.get(acc.Id).ShippingCountry
                        )) {
            modAccts.add(acc);
          }
    }
    
    // As Trigger.new can at most contain 200 records, our query may retrieve at
    // most 200 contacts
    // assuming 1-1 relationship between Contact and Account
    List<Contact> cons = [Select c.OtherStreet, c.OtherState, c.OtherPostalCode, c.OtherCountry, 
        c.OtherCity, c.MailingStreet, c.MailingState, c.MailingPostalCode, c.MailingCountry, c.MailingCity, c.AccountId
        From Contact c where c.AccountId IN :modAccts];
    
        
        // For accounts in which the address fields changed, retrieve the
        // corresponding contacts
        // Check if address related fields modified, add to modAccts
        for(Contact c: cons){   
                        if (
                        c.MailingStreet != Trigger.newMap.get(c.AccountId).BillingStreet ||
                        c.MailingCity != Trigger.newMap.get(c.AccountId).BillingCity ||
                        c.MailingState != Trigger.newMap.get(c.AccountId).BillingState ||
                        c.MailingPostalCode != Trigger.newMap.get(c.AccountId).BillingPostalCode ||
                        c.MailingCountry != Trigger.newMap.get(c.AccountId).BillingCountry ||
                        c.OtherStreet != Trigger.newMap.get(c.AccountId).ShippingStreet ||
                        c.OtherCity != Trigger.newMap.get(c.AccountId).ShippingCity ||
                        c.OtherState != Trigger.newMap.get(c.AccountId).ShippingState ||
                        c.OtherPostalCode != Trigger.newMap.get(c.AccountId).ShippingPostalCode ||
                        c.OtherCountry != Trigger.newMap.get(c.AccountId).ShippingCountry
                        ) {
                            // Update contact fields
                            c.MailingStreet = Trigger.newMap.get(c.AccountId).BillingStreet;
                            c.MailingCity = Trigger.newMap.get(c.AccountId).BillingCity;
                            c.MailingState = Trigger.newMap.get(c.AccountId).BillingState;
                            c.MailingPostalCode = Trigger.newMap.get(c.AccountId).BillingPostalCode;
                            c.MailingCountry = Trigger.newMap.get(c.AccountId).BillingCountry;
                            c.OtherStreet = Trigger.newMap.get(c.AccountId).ShippingStreet;
                            c.OtherCity = Trigger.newMap.get(c.AccountId).ShippingCity;
                            c.OtherState = Trigger.newMap.get(c.AccountId).ShippingState;
                            c.OtherPostalCode = Trigger.newMap.get(c.AccountId).ShippingPostalCode;
                            c.OtherCountry = Trigger.newMap.get(c.AccountId).ShippingCountry;
                            
                            contacts.add(c);
                    }
        }   
    
    //update the contact records
    if(contacts.size() > 0) update contacts;

}
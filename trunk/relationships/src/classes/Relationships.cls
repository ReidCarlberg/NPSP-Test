public class Relationships {

/// <name> Relationships </name>
	/// <summary> Default Constructor </summary>
	public Relationships()
	{
	}
	
	/// <name> triggerAction </name>
	/// <summary> contains possible actions for a trigger </summary>
	public enum triggerAction {beforeInsert, beforeUpdate, beforeDelete, afterInsert, afterUpdate, afterDelete, afterUndelete}


	/// <name> Relationships </name>
	/// <summary> Overloads the Relationships object constructor to handle Relationship processing </summary>
	/// <param name="Relationships"> Relationship objects that are being triggered </param>
	/// <param name="oldRelationships"> Relationships object values before trigger event </param>
	/// <param name="ta"> Trigger action that is occuring </param>
	public Relationships(Relationship__c[] Relationships, Relationship__c[] oldRelationships, triggerAction ta) 
	{	
		// Relationship list for termination updates
		List<Relationship__c> origrelationships = new List<Relationship__c>();
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		List<Relationship__c> reciprocalsToUpdate = new List<Relationship__c>();
		
		Integer i = 0;			// processing counter		
		
		for(Relationship__c r : Relationships) 
		{
			// AFTER INSERT
			if (ta==triggerAction.afterInsert) 
			{
				if (r.ReciprocalRelationship__c == null)
				{
					relationshipsToCreate.add(r);
				}
				if (r.ReciprocalRelationship__c != null)
				{
					reciprocalsToUpdate.add(r);
				}
			}
			
			// AFTER UPDATE
			if (ta==triggerAction.afterUpdate) 
			{
				if (r.ReciprocalRelationship__c == oldRelationships[i].ReciprocalRelationship__c && r.RelatedContact__c != null)
				{
					relationshipsToUpdate.add(r);
					origRelationships.add(oldRelationships[i]);
				}
				if (r.RelatedContact__c == null)
				{
					relationshipsToDelete.add(r);
				}
			}

			// AFTER DELETE
			if (ta==triggerAction.afterDelete) 
			{
				if (r.ReciprocalRelationship__c != null)
				{
					relationshipsToDelete.add(r);
				}
			}

			i += 1;
		}

		if (relationshipsToCreate.size() > 0 ) {
			createRelationship(relationshipsToCreate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (reciprocalsToUpdate.size() > 0 ) {
			reciprocate(reciprocalsToUpdate);
		}
		if (relationshipsToUpdate.size() > 0 ) {
			updateRelationship(relationshipsToUpdate, origRelationships);
		}
		if (relationshipsToDelete.size() > 0 ) {
			deleteRelationship(relationshipsToDelete);
		}
	}

	/// <name> deleteRelationships </name>
	/// <summary> Deletes Reciprocal Relationships when a Relationship is deleted </summary>
	/// <param name="relationships">  </param>
	public static void deleteRelationship(Relationship__c[] relationships)
	{
		List<Id> relationshipsToDelete = new List<Id>();
		for(Relationship__c r : Relationships) 
		{
			if (r.ReciprocalRelationship__c != null)
			{
				relationshipsToDelete.add(r.ReciprocalRelationship__c);
			} else
			if (r.RelatedContact__c == null)
			{
				relationshipsToDelete.add(r.Id);
			}
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
		
	}


	/// <name> deleteEmptyRelationships </name>
	/// <summary> Deletes Relationships when a Contact is deleted </summary>
	/// <param name="contacts"> List of Contacts that were deleted </param>
	public static void deleteEmptyRelationships()
	{
		List<Relationship__c> relationshipsToDelete = new List<Relationship__c>();
		for (Relationship__c r : [Select Id from Relationship__c where RelatedContact__c = null])
		{
			relationshipsToDelete.add(r);
		}
		if ( relationshipsToDelete.size() > 0 )
		{
			Database.DeleteResult[] lsr = Database.delete(relationshipsToDelete, false);
		}
	}
	

	/// <name> reciprocate </name>
	/// <summary>  </summary>
	/// <param name="Relationships">  </param>
	public static void reciprocate(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		for(Relationship__c r : Relationships) 
		{
			Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c, ReciprocalRelationship__c=r.Id);
			relationshipsToUpdate.add(copy);
		}
		update relationshipsToUpdate;
	}

	
	/// <name> createRelationship </name>
	/// <summary> Inserts a new reciprocal Relationship After a relationship is Inserted</summary>
	/// <param name="Relationships">  </param>
	public static void createRelationship(Relationship__c[] Relationships)
	{
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		for(Relationship__c r : Relationships) 
		{
			Relationship__c copy = new Relationship__c();
			copy.Contact__c = r.RelatedContact__c;
			copy.RelatedContact__c = r.Contact__c;
			copy.Status__c = r.Status__c;
			copy.Type__c = r.Type__c;
			copy.ReciprocalRelationship__c = r.Id;
			copy.Description__c = r.Description__c;
			relationshipsToCreate.add(copy);
		}

		insert relationshipsToCreate;

	}


	/// <name> updateRelationship </name>
	/// <summary> Updates the Status and/or Type of a relationship After its reciprocal has been updated </summary>
	/// <param name="Relationships">  </param>
	/// <param name="oldRelationships">  </param>
	public static void updateRelationship(Relationship__c[] Relationships, Relationship__c[] oldRelationships)
	{
		List<Relationship__c> relationshipsToCreate = new List<Relationship__c>();
		List<Relationship__c> relationshipsToUpdate = new List<Relationship__c>();
		Integer counter = 0;											// processing counter		

		for(Relationship__c r : Relationships) 
		{
			if ((r.Status__c != oldRelationships[counter].Status__c || r.Type__c != oldRelationships[counter].Type__c || r.Status__c != oldRelationships[counter].Status__c || r.Description__c != oldRelationships[counter].Description__c)&& r.ReciprocalRelationship__c != null)
			{
				Relationship__c copy = new Relationship__c(Id=r.ReciprocalRelationship__c);
				
				//SWA 2009-05-13 - only attempt to modify the Contact field if the Related Contact  has changed
				if(oldRelationships[counter].RelatedContact__c!=r.RelatedContact__c){
					copy.Contact__c = r.RelatedContact__c;
				}
				copy.Status__c = r.Status__c;
				copy.Type__c = r.Type__c;
				copy.Description__c = r.Description__c;
				relationshipsToUpdate.add(copy);
			}
			counter += 1;
		}
		update relationshipsToUpdate;
	}


	/// <name> Relationships_Test </name>
	/// <summary> test default constructor </summary>
	static testMethod void Relationships_Test() {
  		Relationships testRelationships = new Relationships();
	}


	/// <name> createRelationship_Test </name>
	/// <summary> test method for createRelationship function </summary>
	static testMethod void createRelationship_Test() {
		Contact con = new Contact(FirstName='test', LastName='contact');
		insert con;

		Contact con2 = new Contact(FirstName='test', LastName='Contact2');
		insert con2;
		
		Relationship__c r = new Relationship__c();
		r.Contact__c = con.Id;
		r.RelatedContact__c = con2.Id;
		r.Status__c = 'Test';
		r.Type__c = 'Test';
		r.Description__c = 'Test Description';
		insert r;

		//Relationship__c r2 = new Relationship__c(Id=r.Id,Status__c='Test2');
		//update r2;
		
		Relationship__c[] rList = [select Id,Contact__c from Relationship__c where Id = :r.Id];
		System.assert(rList.size()>0);
		Relationship__c r2 = rList[0];
		r2.Status__c='Test2';
		
		update r2;
	}

	/// <name> deleteRelationship_Test </name>
	/// <summary> test method for deleteRelationship function </summary>
	static testMethod void deleteRelationship_Test() {
		Contact con = new Contact(FirstName='test', LastName='contact');
		insert con;

		Contact con2 = new Contact(FirstName='test', LastName='Contact2');
		insert con2;
		
		Relationship__c r = new Relationship__c();
		r.Contact__c = con.Id;
		r.RelatedContact__c = con2.Id;
		r.Status__c = 'Test';
		r.Type__c = 'Test';
		r.Description__c = 'Test Description';
		insert r;

		delete r;
	}

	/// <name> deleteEmptyRelationships_Test </name>
	/// <summary> test method for deleteEmptyRelationships function </summary>
	static testMethod void deleteEmptyRelationships_Test() {
		Contact con = new Contact(FirstName='test', LastName='contact');
		insert con;

		Contact con2 = new Contact(FirstName='test', LastName='Contact2');
		insert con2;
		
		Relationship__c r = new Relationship__c();
		r.Contact__c = con.Id;
		r.RelatedContact__c = con2.Id;
		r.Status__c = 'Test';
		r.Type__c = 'Test';
		r.Description__c = 'Test Description';
		insert r;

		delete con2;
	}

}
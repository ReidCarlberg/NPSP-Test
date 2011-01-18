trigger defaultTest on Contact (before Insert) { 
boolean aDefaultIsSelected = false; 
Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.Salutation; 
List<Schema.PicklistEntry> P = F.getPicklistValues(); 
for(Schema.PicklistEntry pe : P){ 
system.debug(pe.getValue() + ' : ' + pe.isDefaultValue()); 
if (pe.isDefaultValue()){ 
aDefaultIsSelected = true; 
} 
} 
system.assert(aDefaultIsSelected); 
}
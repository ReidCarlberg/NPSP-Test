trigger OpportunityRollup on Opportunity (after delete, after insert, after update) {
    
    // CALL THE NEW ROLLUP CODE
    OpportunityRollups rg = new OpportunityRollups(); 
    rg.rollupForOppTrigger(trigger.newMap, trigger.oldMap); 

}
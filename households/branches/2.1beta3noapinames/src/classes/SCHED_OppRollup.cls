global class SCHED_OppRollup implements Schedulable {

    global void execute(SchedulableContext SC) { 
        OpportunityRollups rg = new OpportunityRollups();
        rg.rollupAll();    
    }
    
    static testmethod void test(){ 
        Test.startTest(); 
        
        //Schedule the test job 
        String jobId = System.schedule('test Opp Sched', 
        '0 0 0 3 9 ? 2022',new SCHED_OppRollup()); 

        CronTrigger ct =[SELECT id,CronExpression,TimesTriggered,NextFireTime 
        FROM CronTrigger WHERE id=:jobId]; 
        //Verify the expressions are the same 
        System.assertEquals('0 0 0 3 9 ? 2022',ct.CronExpression); 
        //Verify the job has not run 
        System.assertEquals(0,ct.TimesTriggered); 
        //Verify the next time the job will run 
        System.assertEquals('2022-09-03 00:00:00',String.valueOf(ct.NextFireTime)); 
        
        Test.stopTest();        
    }   
}
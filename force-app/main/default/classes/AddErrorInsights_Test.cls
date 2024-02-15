@IsTest
private class AddErrorInsights_Test {
    
    @IsTest
    private static void apiCalledAndResultsStored() {

        // Setup
        insert new Settings__c(txt_OpenAiApiKey__c = 'any');
        
        OrgError__c e = (OrgError__c) new OrgError().persist();

        Test.startTest();
        new HttpMock()
                .post('/v1/chat/completions', 
                        new OpenAiCompletions.Response().withChoice('Check the Power cord'), 200)
                .mock();


        // Exercise
        AddErrorInsights.execute(new List<Id>{ e.Id });
        Test.stopTest();

        
        // Verify
        e = [SELECT txl_Hints__c FROM OrgError__c LIMIT 1];
        Assert.areEqual('Check the Power cord', e.txl_Hints__c);
    }
}
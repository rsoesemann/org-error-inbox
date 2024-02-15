@IsTest
private class SetupReparse_Test {

    private static List<String> mails;

    @IsTest
    private static void run() {

        // Setup
        setup();

        Triggers.skips.add(ParseOrgErrors.class);
        insert new OrgError__c(txl_FullMailBody__c = mails[6]);
        Triggers.skips.remove(ParseOrgErrors.class);

        SetupReparse step = new SetupReparse();
        System.assertEquals(ApexPages.Severity.WARNING, step.getStatus().getSeverity());


        // Exercise
        Test.startTest();
        step.run();
        Test.stopTest();


        // Verify
        System.assertEquals(ApexPages.Severity.CONFIRM, step.getStatus().getSeverity());
    }


    // HELPER

    private static void setup() {
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'error_mails_txt'];
        mails = resource.Body.toString().split('&');
    }
}
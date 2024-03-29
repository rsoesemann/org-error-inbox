@SuppressWarnings('PMD.AvoidHardcodingId')
@IsTest
private class ParseOrgErrors_Test {

    private static List<String> mails;

    @IsTest
    private static void reparseOnChange(){

        // Setup
        setup();

        OrgError__c e = new OrgError__c(txl_FullMailBody__c = mails[0]);
        insert e;


        // Exercise
        e.txl_FullMailBody__c = e.txl_FullMailBody__c.replaceAll('ACME.OpportunityService', 'ACME.LeadService');
        update e;

        
        // Verify
        System.assertEquals('ACME.LeadService' , [SELECT txt_ApexClass__c FROM OrgError__c LIMIT 1].txt_ApexClass__c);
    }


    @IsTest
    private static void realWorldErrors() {

        // Setup
        setup();

        List<OrgError__c> errors = new List<OrgError__c>();
        for(String mail : mails) {
            errors.add(new OrgError__c(txl_FullMailBody__c = mail));
        }


        // Exercise
        Test.startTest();
            new ParseOrgErrors(errors).execute();
        Test.stopTest();


        // Verify
        Integer index = 1;
        for(OrgError__c e : query()) {
            String message = 'Failed on error ' + index++ + ' ' + e.txl_FullMailBody__c;
            System.assertNotEquals(null, e.txt_OrgId__c, message);
            System.assertNotEquals(null, e.txt_UserId__c, message);
            System.assertNotEquals(null, e.txt_ApexClass__c, message);
            System.assertNotEquals(null, e.txt_Method__c, message);
            System.assertNotEquals(null, e.txt_ExceptionType__c, message);
            System.assertNotEquals(null, e.txt_ExceptionMessage__c, message);
        }
    }


    // HELPER

    private static void setup() {
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'error_mails_txt'];
        mails = resource.Body.toString().split('&');
        System.assert(!mails.isEmpty());
    }


    private static List<OrgError__c> query() {
        return [SELECT txt_UserId__c, txt_OrgId__c, txt_ExceptionType__c, txt_ExceptionMessage__c,
                txt_ApexClass__c, txt_Method__c, txt_VisualforcePage__c, txl_Stacktrace__c, txl_FullMailBody__c FROM OrgError__c];
    }


    private static OrgError__c error(DateTime dt) {
        return new OrgError__c(dtm_RecordedDate__c = dt);
    }
}
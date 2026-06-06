@IsTest
private class SetupEmailService_Test {

    @IsTest
    private static void execute() {
        MdApiMock mock = new MdApiMock();
        Test.setMock(WebServiceMock.class, mock);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();

        SetupEmailService step = iteration(new SetupEmailService());
        
        if (step.isActive) {
            testActivateFromInactive(step.service);
            testActivateFromNull();
        } else if (step.service != null) {
            testDeactivateFromActive(step.service);
            testActivateFromNull();
        } else {
            testActivateFromInactive(makeMockService());
            testDeactivateFromActive(makeMockService());
        }

        mock.sendStatus = 400;
        try {
            iteration(new SetupEmailService());
            System.assert(false, 'Exception expected');
        } catch (ApplicationException ex) {
            System.assert(true, 'Exception expected');
        }

        Test.stopTest();
    }

    private static SetupEmailService iteration(SetupEmailService step) {
        step.doRun();

        // Verify
        System.assertNotEquals(null, step.getSeverity());
        System.assertNotEquals(null, step.getMessage());
        System.assertNotEquals(null, step.buttonLabel);
        System.assertEquals(true, step.getShowButtonOnSuccess());

        return step;
    }

    private static void testDeactivateFromActive(EmailServicesAddress service) {
        service.Function.IsActive = true;
        SetupEmailService step = new SetupEmailService(service);
        System.assertNotEquals(null, step.service);
        System.assertEquals(true, step.isActive);
        iteration(step);
    }

    private static void testActivateFromInactive(EmailServicesAddress service) {
        service.Function.IsActive = false;
        SetupEmailService step = new SetupEmailService(service);
        System.assertNotEquals(null, step.service);
        System.assertEquals(false, step.isActive);
        iteration(step);
    }

    private static void testActivateFromNull() {
        SetupEmailService step = new SetupEmailService(null);
        System.assertEquals(null, step.service);
        System.assertEquals(false, step.isActive);
        iteration(step);
    }

    private static EmailServicesAddress makeMockService() {
        return new EmailServicesAddress(
            LocalPart = 'inbox',
            Function = new EmailServicesFunction(),
            FunctionId = '091cq0000002zc5AAA'
        );
    }


    // HELPER

    public class MdApiMock implements WebServiceMock, HttpCalloutMock {
        public Integer sendStatus = 200;

        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint,
                            String soapAction, String requestName, String responseNS, String responseName, String responseType) {
            response.put('response_x', '<createResponse><result><success>true</success></result></createResponse>');
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/soap+xml');
            res.setBody('<createResponse><result><success>true</success></result></createResponse>');
            res.setStatusCode(this.sendStatus);
            return res;
        }
    }
}
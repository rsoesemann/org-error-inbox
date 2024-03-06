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

    // HELPER

    public class HttpMock implements HttpCalloutMock {
    
        private Map<String, Map<String, Object>> responses = new Map<String, Map<String, Object>>();
        
        // PUBLIC
    
        public HttpMock post(String url, Object body, Integer statusCode) {
            return mock('POST', url, body, statusCode);
        }
    
        public HttpMock post(String url, Object body) {
            return post(url, body, 200);
        }
    
        public void mock() {
            Test.setMock(HttpCalloutMock.class, this);
        }
    
        public Object object(SObjectType type, Map<String, Object> properties) {
            Map<String, Object> result = new Map<String, Object>{
                'attributes' => new Map<String, Object>{
                    'type' => '' + type,
                    'url' => '/services/data/v25.0/sobjects/' + type + '/' + new Random().id(type)
                }
            };
            result.putAll(properties);
            return JSON.deserialize( JSON.serialize(result), System.Type.forName('' + type));
    
        }
    
        // implements HttpCalloutMock
    
        public HttpResponse respond(HttpRequest request) {
            HttpResponse result = badRequest();
    
            Object response = mockedResponse(request);
            if(response != null) {
                if(response instanceof Exception) {
                    throw (Exception) response;
                }
    
                result = (HttpResponse) response;
            }
    
            return result;
        }
    
    
        // PRIVATE
    
        private HttpMock mock(String method, String url, Object body, Integer statusCode) {
            if(!responses.containsKey(method)) {
                responses.put(method, new Map<String, Object>());
            }
            responses.get(method).put(url, asResponse(body, statusCode));
    
            return this;
        }
    
    
        private Object asResponse(Object body, Integer statusCode) {
            HttpResponse result = new HttpResponse();
            result.setStatusCode(statusCode);
    
            if(body instanceof Exception) {
                return body;
            }
            else if(body instanceof Blob) {
                result.setHeader('Content-Type', 'application/octet-stream');
                result.setBodyAsBlob((Blob) body);
            }
            else if(body instanceof String) {
                result.setHeader('Content-Type', 'application/json');
                result.setBody((String) body);
            }
            else {
                result.setHeader('Content-Type', 'application/json');
                result.setBody( JSON.serialize(body) );
            }
            
            return result;
        }
    
    
        private Object mockedResponse(HttpRequest request) {
            Object result = null;
    
            String method = request.getMethod();
            if(responses.containsKey(method)) {
                for(String mock : responses.get(method).keySet()) {
    
                    if(matches(request, mock)) {
                        result = responses.get(method).remove(mock);
                        break;
                    }
                }
            }
            else if(responses.containsKey('ANY')) {
                for(String mock : responses.get('ANY').keySet()) {
                    result = responses.get('ANY').remove(mock);
                    break;
                }
            }
            
            return result;
        }
    
        
        private Boolean matches(HttpRequest request, String candidate) {
            String delimiter = '#';

            String url = new Url(request.getEndpoint()).getPath();
            String bodyCondition = candidate.substringAfter(delimiter);
            candidate = candidate.removeEnd(delimiter + bodyCondition);
    
            Boolean urlMatch = (candidate.indexOfDifference(url) == -1);
            Boolean bodyMatch = (bodyCondition == null || request.getBody().contains(bodyCondition));
    
            return (urlMatch && bodyMatch);
        }
    
    
        private HttpResponse badRequest() {
            HttpResponse result = new HttpResponse();
            result.setStatusCode(500);
            result.setStatus('Invalid Request');
            result.setBody('{}');
            return result;
        }
    
    
        private HttpResponse asJsonResponse(Object body, Integer statusCode) {
            HttpResponse result = new HttpResponse();
            result.setHeader('Content-Type', 'application/json');
            result.setStatusCode(statusCode);
            result.setBody( JSON.serialize(body) );
            return result;
        }
    }
}
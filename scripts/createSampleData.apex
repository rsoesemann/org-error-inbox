delete [SELECT Id FROM OrgError__c];

List<Object> exceptions = new List<Object>{ 'System.DmlException', 'System.NullPointerException', 'System.QueryException', 'System.LimitsException', 'System.AsyncException', 'MyCustomException'};
List<Object> classes = new List<Object>{ 'SetupController', 'AccountService', 'AsyncHandler', 'TriggerFramework', 'Bills' };
List<Object> pages = new List<Object>{ 'setup', 'home', 'licenseManager', 'setupV1'};

Triggers.skips.add(ParseOrgErrors.class);

for(Integer i=0; i<new Random().integer(400,800); i++) {
    new OrgError()
        .exception((String) new Random().value(exceptions))
        .clazz((String) new Random().value(classes))
        .page((String) new Random().value(pages));
}
p1.persist();
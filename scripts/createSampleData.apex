delete [SELECT Id FROM OrgError__c];

StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = 'error_mails_txt'];
List<String> mails = resource.Body.toString().split('&');

List<OrgError__c> errors = new List<OrgError__c>();
for(String mail : mails) {
    errors.add(new OrgError__c(txl_FullMailBody__c = mail));
}

insert errors;
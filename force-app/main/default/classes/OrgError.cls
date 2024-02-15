public class OrgError extends DomainBuilder {

    public OrgError() {
        super(OrgError__c.SObjectType);

        set(OrgError__c.txt_UserId__c, new Random().id(User.SObjectType));
        set(OrgError__c.txt_OrgId__c, (new Random().string()).capitalize());
        set(OrgError__c.txt_ExceptionType__c, (new Random().string()+'Exception').capitalize());
        set(OrgError__c.txt_ApexClass__c, (new Random().string()+'.cls').capitalize());
        set(OrgError__c.txt_Method__c, (new Random().string()+'()').capitalize());
        set(OrgError__c.txt_VisualforcePage__c, (new Random().string()+'.page').capitalize());
        set(OrgError__c.txl_FullMailBody__c, 'empty ');
    }

    public OrgError exception(String value) {
        return (OrgError) set(OrgError__c.txt_ExceptionType__c, value);
    }

    public OrgError clazz(String value) {
        return (OrgError) set(OrgError__c.txt_ApexClass__c, value);
    }

    public OrgError page(String value) {
        return (OrgError) set(OrgError__c.txt_VisualforcePage__c, value);
    }
}
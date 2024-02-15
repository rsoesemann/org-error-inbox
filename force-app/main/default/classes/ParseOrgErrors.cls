// Note: Otherwise the Admin running this needs to own all Account and Licences
public without sharing class ParseOrgErrors implements Triggers.Handler,
                                                        Triggers.BeforeInsert,
                                                        Triggers.BeforeUpdate {

    public static Boolean parseAlways = false;
    
    private static final List<Tokenizer> TOKENIZERS = Tokenizer.initialize();

    private List<OrgError__c> errors;


    // CONSTRUCTOR

    public ParseOrgErrors() {
        // Note: Default ctor needed for Trigger framework
    }


    public ParseOrgErrors(List<OrgError__c> inserted) {
        errors = inserted;
    }

    
    public ParseOrgErrors(OrgError__c error) {
        this(new List<OrgError__c>{ error });
    }


    public ParseOrgErrors(List<OrgError__c> errors, Map<Id, OrgError__c> old) {
        this( changedBody(errors, old) );
    }


    // PUBLIC

    public Boolean criteria(Triggers.Context ctx) {
        return Triggers.WHEN_ALWAYS;
    }


    public void beforeInsert(Triggers.Context ctx) {
        new ParseOrgErrors(ctx.props.newList).execute();
    }


    public void beforeUpdate(Triggers.Context ctx) {
        new ParseOrgErrors( changedBody((List<OrgError__c>) ctx.props.newList, (Map<Id, OrgError__c>) ctx.props.oldMap) ).execute();
    }
      

    public void execute() {
        for(OrgError__c error : errors) {
            if(String.isNotBlank(error.txl_FullMailBody__c)) {
                for(Tokenizer tokenizer : TOKENIZERS) {
                    tokenizer.execute(error);
                }
            }
        }

        linkUsers(errors);
    }


    // PRIVATE

    private static List<OrgError__c> changedBody(List<OrgError__c> errors, Map<Id, OrgError__c> old) {
        List<OrgError__c> result = new List<OrgError__c>();

        for(OrgError__c error : errors) {
            Boolean bodyHasChanged = (error.txl_FullMailBody__c != old.get(error.Id).txl_FullMailBody__c);

            if(parseAlways || bodyHasChanged) {
                clearFields(error);
                result.add(error);
            }
        }

        return result;
    }

    private static void clearFields(OrgError__c error) {
        error.txt_UserId__c = null;
        error.lkp_User__c = null;
		error.txt_OrgId__c = null;
		error.txt_VisualforcePage__c = null;
		error.txt_ExceptionType__c = null;
		error.txt_ExceptionMessage__c = null;
        error.txt_ApexClass__c = null;
        error.txt_Method__c = null;
        error.txt_JobId__c = null;
        error.txt_Object__c = null;
        error.txt_Trigger__c = null;
        error.txt_RecordId__c = null;
    }

    private Boolean notRecordedLive(OrgError__c error) {
        // Note: Only equals when error received as email 
        return (error.CreatedDate > error.dtm_RecordedDate__c);
    }


    private void linkUsers(List<OrgError__c> errors) {
        for(OrgError__c error : errors) {
            error.lkp_User__c = error.txt_UserId__c;
        }
    }
}
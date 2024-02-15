public with sharing class SetupReparse extends BatchSetupStep {

    public Integer batchSize {
        get {
            if(batchSize == null) {
                batchSize =  1;
            }
            return batchSize;
        }
        set; 
    }

    public String filter {
        get {
            if(filter == null) {
                filter = 'txt_ExceptionType__c = NULL';
            }
            return filter;
        }
        set; 
    }
    
    public Integer recordCount {
        get {
            try {
                recordCount = Database.countQuery('SELECT Count() FROM OrgError__c WHERE ' + filter, AccessLevel.SYSTEM_MODE);
            }
            catch(Exception ex) {
                ApexPages.addMessages(ex);
            }

            return recordCount;
        }
        private set; 
    }

	
	// PUBLIC

	public override ApexPages.Message getStatus() {
		ApexPages.Message result = super.getStatus();

        if(result == null) {
			ApexPages.Severity severity = (recordCount > 0) ? ApexPages.Severity.WARNING : ApexPages.Severity.CONFIRM;
			result = new ApexPages.Message(severity, 'Reparse ' + recordCount + ' OrgErrors now?');
		}

		return result;
	}


	public override Integer batchSize() {
		return batchSize;
	}


    public PageReference refresh() {
        System.purgeOldAsyncJobs(System.today().addDays(1));
        return null;
    }


	public List<SObject> start(Database.BatchableContext ctx) {
		return Database.query('SELECT Id FROM OrgError__c WHERE ' + filter, AccessLevel.SYSTEM_MODE);
	}


	public void execute(Database.BatchableContext ctx, List<OrgError__c> errors) {
		ParseOrgErrors.parseAlways = true;
        update as system errors;
	}


	public void finish(Database.BatchableContext ctx) { }
}
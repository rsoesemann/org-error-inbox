public abstract class SetupStep {

    // ABSTRACT

    public abstract ApexPages.Message getStatus();
    public abstract PageReference run();

    // PUBLIC

    public Boolean success {
        get {
            try {
                return (getStatus().getSeverity() == ApexPages.Severity.CONFIRM);
            }
            catch(Exception ex) {
                return false;
            }
        }
        private set;
    }


    public String getMessage() {
        return getStatus().getSummary();
    }


    public String getSeverity() {
        return getStatus().getSeverity().name();
    }
    

    public PageReference doRun() {
        PageReference result = null;

        try {
            result = run();
        }
        catch(Exception ex) {
            ApexPages.addMessages(ex);
            if (Test.isRunningTest()) throw ex;
            System.debug(LoggingLevel.ERROR, '' +  ex);
        }

        return result;
    }


    public String buttonLabel {
        get {
            return buttonLabel();
        }
    }


    public virtual String buttonLabel() {
        return 'Execute';
    }


    public virtual Boolean getShowButtonOnSuccess() {
        return false;
    }


    protected String setupLink(String id, String type, String label) {
        return (id == null) ? '<b>' + label + '</b>'  : '<b><a href="/lightning/setup/' + type + '/page?address=%2F' + id +'" target="_blank">' + label + '</a></b>';
    }


    protected PageReference currentPage() {
        PageReference result = Page.setup;
        result.setRedirect(true);
        return result;
    }


    public class MetadataServiceException extends Exception {}


    public class ToolingApiResponse {
        public List<SObject_x> records;
    }


    public class SObject_x {
        public String Id;
        public String DeveloperName;
    }
}
public with sharing class SetupPageCtrl extends SetupCtrl {
   
    public SetupEmailService setupEmailService { get; set; }
    public SetupReparse setupReparse { get; set; }
    public SetupSlack setupSlack { get; set; }
    public SetupOpenAi setupOpenAi { get; set; }


    // CONSTRUCTOR

    public SetupPageCtrl() {
        setupEmailService = new SetupEmailService();
        setupReparse = new SetupReparse();
        setupSlack = new SetupSlack();
        setupOpenAi = new SetupOpenAi();
    }


    // PUBLIC

    public override List<SetupStep> steps() {
        return new List<SetupStep>{ setupEmailService, setupSlack, setupOpenAi };
    }
}
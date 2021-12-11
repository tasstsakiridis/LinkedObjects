/* Controller associated with pages rendering the survey.
 * Used by SurveyPage, ResultsPage, TakeSurvey
 */
global virtual with sharing class ViewSurveyController {
  //public Boolean qRequired                        {get; set;}
  public String  qQuestion                        { get; set; }
	public String  qChoices                         { get; set; }
  public String surveyName                        { get; set; }
  public String surveyHeader                    	{ get; set; }
  public String renderSurveyPreview             	{ get; set; }
  public String surveyId                          {
      get;
      set{
          this.surveyId = value;
          init();
      }
  }
    
  //public String questionName                      {get; set;}
  //public String questionType                      {get; set;}
  //public Boolean questionRequired                 {get; set;}
  //public List<SelectOption> singleOptions         {get; set;}
  //public List<String> responses                   {get; set;}
  //public List<SelectOption> anonymousOrUser       {get; set;}

  public List<question> allQuestions            	  { get; set; }
  public Integer allQuestionsSize                   { get; set; }
  public String  templateURL                    	  { get; set; }
  public String  surveyThankYouText             	  { get; set; }
  public String surveyContainerCss         		      { get; set; }
  public String  surveyThankYouURL              	  { get; set; }
  public String  caseId                         	  { get; set; }
  public String contactId             		        	{ get; set; }
  public string accountId             			        { get; set; }
  public String anonymousAnswer           		      { get; set; }
  public Boolean isInternal             			      { get; set; }
  public String baseURL               			        { get; set; }
  public String urlPrefix                           { get; set; }
  public String userType                            { get; set; }
  public Boolean communityUser                      { get; set; }

  public String userId              				        { get; set; }
  public String userName              			        { get; set; }
  public String surveyTakerId          		 	        { get; set; }
  public Boolean thankYouRendered          		      { get; set; }
  public List<String> newOrder           			      { get; set; }
  public string asNewSurvey                 		    { get; set; } // From GET paraemters on TakeSurvey.vfp -- If true, we won't get previouos records and will store as new response
  public String serializedMenuJSON                  { get; set; }

    /* Retrieves the list of questions, the survey name, after retrieving the
       necessary parameters from the url.
    */
 	//------------------------------------------------------------------------------//
    public ViewSurveyController(ApexPages.StandardController stdController) {
        // Get url parameters
        surveyId = Apexpages.currentPage().getParameters().get('id');
        caseId   = Apexpages.currentPage().getParameters().get('caId');
        contactId = Apexpages.currentPage().getParameters().get('cId');
        accountId = Apexpages.currentPage().getParameters().get('account');
        asNewSurvey = Apexpages.currentPage().getParameters().get('asNewSurvey');

        if(caseId ==null || caseId.length()<5){
            caseId = 'none';
        }
        if(contactId ==null || contactId.length()<5){
            contactId = 'none';
        }
        if(accountId ==null || accountId.length()<5){
            accountId= 'none';
        }
        if(asNewSurvey == null) {
            asNewSurvey = 'false';
        }
        // By default the preview is not showing up
        renderSurveyPreview = 'false';

        userId = UserInfo.getUserId();
    	system.debug('userId:'+userId);
        
        init();
    }

    public ViewSurveyController(viewShareSurveyComponentController controller){
        surveyId = Apexpages.currentPage().getParameters().get('id');
        caseId   = Apexpages.currentPage().getParameters().get('caId');
        contactId = Apexpages.currentPage().getParameters().get('cId');
        accountId = Apexpages.currentPage().getParameters().get('account');

        if(caseId ==null || caseId.length()<5){
            caseId = 'none';
        }
        if(contactId ==null || contactId.length()<5){
            contactId = 'none';
        }
        if(accountId ==null || accountId.length()<5){
            accountId= 'none';
        }

        // By default the preview is not showing up
        renderSurveyPreview = 'false';

        userId = UserInfo.getUserId();
        system.debug('userId:'+userId);
        
        init();
    }


    public void init(){
        userType = UserInfo.getUserType();
        if(userType != 'Standard'){
            urlPrefix = '/sales';
            communityUser = true;
        }else{
            urlPrefix = '';
            communityUser = false;
        }

        System.debug('surveyId: ' + surveyId);
        if (surveyId != null){
            // Retrieve all necessary information to be displayed on the page
            allQuestions = new List<question>();
            userId = UserInfo.getUserId();
            system.debug('userId:'+userId);
            accountId = Apexpages.currentPage().getParameters().get('account');
            
            String marketName = 'All';
            String channel = 'All';
            String storeType = 'All';
            if(accountId ==null || accountId.length()<5){
                accountId= 'none';
                List<User> thisUser = [SELECT Id, Market__c FROM User WHERE Id =:userId];
                if (thisUser.size() > 0) {
                    marketName = thisUser.get(0).Market__c;
                }
            } else {
                List<Account> thisAccount = [SELECT Id, Name, Market__r.Name, Channel__c FROM Account WHERE Id =:accountId];
                if (thisAccount.size() > 0) {
                    marketName = thisAccount.get(0).Market__r.Name;
                    channel = thisAccount.get(0).Channel__c;
                }
            }
            
            Set<SFAOverflowMenuItem> overflowButtons = SFAMetaSettingHelper.findOverflowButtons('AdHocSurvey', marketName, channel, storeType);
            System.debug(overflowButtons);
            serializedMenuJSON = overflowButtons == null ? '[]' : JSON.serialize(overflowButtons);            
            
            setupQuestionList();
            setSurveyNameAndThankYou(surveyId);
            
            // We don't need this ability right now, so default to user
            //anonymousOrUser = new List<SelectOption>();
            //anonymousOrUser.add(new SelectOption('Anonymous',System.Label.LABS_SF_Anonymous));
            //anonymousOrUser.add(new SelectOption('User','User ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName()));
            //anonymousAnswer = 'Anonymous';
            anonymousAnswer = 'User';

            isInternal =true;
            newOrder = new List<String>();
            String urlBase = URL.getSalesforceBaseUrl().toExternalForm();
            baseURL = urlBase;

            userName = UserInfo.getName();

            String profileId = UserInfo.getProfileId();
            try
            {
                Profile p = [select Id, UserType from Profile where Id=:profileId];
                if (p.UserType == 'Guest')
                {
                    isInternal = false;
                } else {
                    isInternal = true;
                }
            }
            catch (Exception e){
                isInternal = false;
            }


            thankYouRendered=false;
        }
    }


    /* Called during the setup of the page.
       Retrieve questions and responses from DB and inserts them in 2 lists. */
    public Integer setupQuestionList(){

        getAQuestion();
        return allQuestions.size();
    }


   /** Sets the survey's name variable
    *  param: sID   The survey ID as specified in the DB
    */
    public void setSurveyNameAndThankYou(String sId){
        Survey__c s = [SELECT Name, Id, URL__c, Thank_You_Text__c, thankYouText__c, thankYouLink__c, Survey_Header__c, Survey_Container_CSS__c FROM Survey__c WHERE Id =:sId];
        surveyName = s.Name;
        surveyHeader = s.Survey_Header__c;
        templateURL = s.URL__c+'id='+sId;//+'&cId={!Contact.Id}'+'&caId='+'{!Case.id}';
        surveyThankYouText = s.Thank_You_Text__c;
        if (surveyThankYouText == null)
        {
            surveyThankYouText = System.Label.LABS_SF_Survey_Submitted_Thank_you;
        }
        surveyThankYouURL = s.thankYouLink__c;
        surveyContainerCss = s.Survey_Container_CSS__c;
    }

//------------------------------------------------------------------------------//
  public Pagereference updateSurveyName(){
      Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
      s.Name = surveyName;
      try{
        update s;
      }catch (Exception e){
        Apexpages.addMessages(e);
      }
      return null;
  }


//------------------------------------------------------------------------------//
    public Pagereference updateSurveyThankYouAndLink(){
        Survey__c s = [SELECT Name, Id, URL__c, thankYouText__c, thankYouLink__c FROM Survey__c WHERE Id =:surveyId];
        s.thankYouText__c = surveyThankYouText;
        s.thankYouLink__c = surveyThankYouURL;
        try{
            update s;
        }catch(Exception e){
            Apexpages.addMessages(e);
        }
        return null;
    }


  //------------------------------------------------------------------------------//
  /** When requested from the page - when the user clicks on 'Update Order' -
      this function will reorganize the list so that it is displayed in the new order
   */
   public Pagereference refreshQuestionList(){
    setupQuestionList();
    return null;
   }



//------------------------------------------------------------------------------//



//------------------------------------------------------------------------------//
  public static boolean checkRequired(String response, Survey_Question__c question){
    if(question.Required__c == true){
        if(response == null || response =='NO RESPONSE')
          return false;
    }
    return true;
  }

   /** Redirects the page that displays the detailed results of the survey,
       from all users who took the survey.
    */
    public PageReference resultPage() {
        return new PageReference('/apex/ResultsPage?id='+surveyId);
    }


//------------------------------------------------------------------------------//

//------------------------------------------------------------------------------//

   /**
    */
    public List<String> getResponses() {
        List<SurveyQuestionResponse__c> qr = [Select Survey_Question__c, SurveyTaker__c, Response__c, Name From SurveyQuestionResponse__c limit 100];
        List<String> resp = new List<String>();
        for (SurveyQuestionResponse__c r : qr) {
            resp.add(r.Response__c);
        }

        return resp;
    }

   /** Class: question
    *  Retrieves the question information and puts it in the question object
    */
    public class question{
      public String name                      { get; set; }
      public String id                        { get; set; }
      public String question                  { get; set; }
      public String orderNumber               { get; set; }
      public String choices                   { get; set; }
      public String selectedOption            { get; set; }
      public Boolean required                 { get; set; }
      public String questionType              { get; set; }
      public String surveyName                { get; set; }
      public String renderFreeText            { get; set; }
      public String renderNumber              { get; set; }
      public String renderSelectRadio         { get; set; }
      public String renderSelectCheckboxes    { get; set; }
      public String renderSelectRow           { get; set; }
      public String singleOptionsForChart     { get; set; }
      public String qResultsForChart          { get; set; }
      public boolean noData                   { get; set; }
      public decimal numberAnswer             { get; set; }
      public boolean imageAttached            { get; set; }
      public string imageId                   { get; set; }
      public string accountId                 { get; set; }
      public string response                  { get; set; }
      public boolean updateExistingAnswers    { get; set; }

      public List<String> selectedOptions     { get; set; }
      public List<SelectOption> singleOptions { get; set; }
      public List<SelectOption> multiOptions  { get; set; }
      public List<String> responses           { get; set; }
      public List<String> strList             { get; set; } // The question's option as a list of string
      public List<Integer> resultsCounts      { get; set; } // The count of each response to a question's choices
      public List<SelectOption> rowOptions    { get; set; }
      public list<string> multiResponses      { get; set; }
      public map<string, string> choiceMap    { get; set; }
      public List<String> pointValues         { get; set; }
      public Map<String, Decimal> optionPointValues   { get; set; }

      public list<SurveyQuestionResponse__c> existingResponses = new list<SurveyQuestionResponse__c>();
      public ViewSurveyController vsc;

      /** Fills up the question object
       *  param:    Survey_Question__c
       */
      public question(Survey_Question__c sq, ViewSurveyController parentClass) {
        name = sq.Name;
        id = sq.Id;
        optionPointValues = new Map<String, Decimal>();
        question = sq.Question__c;
        orderNumber = String.valueOf(sq.OrderNumber__c+1);
        choices = sq.Choices__c;
        required = sq.Required__c;
        questionType = sq.Type__c;
        singleOptionsForChart = ' ';
        selectedOption = '';
        selectedOptions = new List<String>();
        imageAttached = sq.Image_Attached__c;
        if (imageAttached) {
          imageId = sq.Attachments[0].Id;
        }
        this.vsc = parentClass;
        system.debug('vsc: '+vsc);
        accountId = vsc.accountId;
        multiResponses = new list<string>();
        system.debug('sq: '+sq);
        system.debug('sq.Survey_Question_Answers__r: '+sq.Survey_Question_Answers__r);
        system.debug('accountId: '+accountId);
        updateExistingAnswers = false;
        for(SurveyQuestionResponse__c sqr: sq.Survey_Question_Answers__r){
          if(accountId == sqr.SurveyTaker__r.Account__c){
            updateExistingAnswers= true;
            if(questionType == 'Multi-Select--Vertical'){
              multiResponses.add(sqr.Response__c);
            }else{
              response = sqr.Response__c;
            }
            existingResponses.add(sqr);
          }

        }
        system.debug('name: '+name);
        system.debug('response: '+response);
        system.debug('multiResponses: '+multiResponses);
        if (sq.Type__c=='Single Select--Vertical'){
            renderSelectRadio='true';
            singleOptions = stringToSelectOptions(choices);
            for(Integer tt = 0; tt < singleOptions.size(); tt++) {
              System.debug('singleOptions. option: ' + tt + ' : ' +singleOptions.get(tt));
            }
            //optionPointValues = new Map<String, Integer>();
            if (sq.Point_Values__c != null && sq.Point_Values__c != '') {
              System.debug('sq.Point_Values__c: ' + sq.Point_Values__c);
              pointValues = sq.Point_Values__c.split(',');
              System.debug('pointValues: ' + pointValues);
              for(Integer i = 0; i < pointValues.size(); i++) {
                System.debug('option ['+(i+1)+'] = ' + singleOptions[i].getLabel());
                optionPointValues.put(singleOptions[i+1].getLabel(),Decimal.valueOf(pointValues[i]));
              }
            }

            renderSelectCheckboxes='false';
            renderFreeText='false';
            renderNumber='false';
            renderSelectRow = 'false';
            selectedOption = choiceMap.get(response);
            selectedOptions = new List<String>();
        } else if (sq.Type__c=='Multi-Select--Vertical') {
            renderSelectCheckboxes='true';
            multiOptions = stringToSelectOptions(choices);
            renderSelectRadio='false';
            renderFreeText='false';
            renderNumber='false';
            renderSelectRow = 'false';
            selectedOption = '';
            selectedOptions = new List<String>();
            for (string selected:multiResponses) {
              selectedOptions.add(choiceMap.get(selected));
            }
        }else if (sq.Type__c=='Single Select--Horizontal') {
            renderSelectCheckboxes='false';
            rowOptions = stringToSelectOptions(choices);
            if (sq.Point_Values__c != null && sq.Point_Values__c != '') {
              System.debug('sq.Point_Values__c: ' + sq.Point_Values__c);
              pointValues = sq.Point_Values__c.split(',');
              System.debug('pointValues: ' + pointValues);
              for(Integer i = 0; i < pointValues.size(); i++) {
                System.debug('option ['+(i+1)+'] = ' + rowOptions[i].getLabel());
                optionPointValues.put(rowOptions[i].getLabel(),Decimal.valueOf(pointValues[i]));
              }
            }

            renderSelectRadio='false';
            renderFreeText='false';
            renderSelectRow = 'true';
            renderNumber='false';
            selectedOption = choiceMap.get(response);
            selectedOptions = new List<String>();
        } else if (sq.Type__c=='Free Text') {
            renderFreeText='true';
            renderSelectRadio='false';
            renderSelectCheckboxes='false';
            renderNumber='false';
            renderSelectRow = 'false';
            choices= response;
        } else if (sq.Type__c=='Number') {
            renderNumber='true';
            renderFreeText='false';
            renderSelectRadio='false';
            renderSelectCheckboxes='false';
            renderSelectRow = 'false';
            if(response != null){
              system.debug('response is not null '+response);
              numberAnswer = Decimal.valueOf(response);
            }else{
              system.debug('response is null '+response);
              numberAnswer = null;
            }
            choices = response;
            system.debug('numberAnswer: '+numberAnswer);
        }
      }

       /** Splits up the string as given by the user and adds each option
        *  to a list to be displayed as option on the Visualforce page
        *  param: str   String as submitted by the user
        *  returns the List of SelectOption for the visualforce page
        */
      private List<SelectOption> stringToSelectOptions(String str){
        if (str == '') {
            return new List<SelectOption>();
        }
        strList = str.split(',');

        List<SelectOption> returnVal = new List<SelectOption>();
        Integer i = 0;
        choiceMap = new map<string,string>();
        if (questionType == 'Single Select--Vertical'){
          returnVal.add(new SelectOption('','--SELECT--'));
          choiceMap.put('--SELECT--',String.valueOf(i));
          i++;
        }
        for (String s: strList) {
            if (s!='') {
                if (s != 'null' && s!= null) {
                    String sBis = s.replace(' ', '%20');
                    singleOptionsForChart += s.trim()+'|';

                    /*RSC2012-02-20
                    String st = s.replace (' ', ' ');
                    returnVal.add(new SelectOption(String.valueOf(i),st));
                    */
                    returnVal.add(new SelectOption(String.valueOf(i),s.trim()));
                    System.debug('*****VALUES: ' + s.trim());
                    choiceMap.put(s.trim(),String.valueOf(i));
                    i++;
                }
            }
        }
        singleOptionsForChart = singleOptionsForChart.substring(0, singleOptionsForChart.length()-1);
        return returnVal;
      }
    }

    public question getSingleQuestion(Integer positionNum) {
      return allQuestions[positionNum];
    }


  /** Fills up the List of questions to be displayed on the Visualforce page
   */
    public List<question> getAQuestion() {
            qQuestion = '';
            qChoices ='';

        system.debug('userId: '+userId);
        List<Survey_Question__c> allQuestionsObject;
        if(asNewSurvey == 'true') {
            allQuestionsObject = [Select s.Type__c, s.Id, s.Survey__c, s.Required__c, s.Question__c, s.OrderNumber__c, s.Name, s.Choices__c, s.Point_Values__c, Image_Attached__c,
             (SELECT Id FROM Attachments WHERE ContentType LIKE 'image%' LIMIT 1)
             From Survey_Question__c s
             WHERE s.Survey__c =: surveyId ORDER BY s.OrderNumber__c];
        } else {
            allQuestionsObject = [Select s.Type__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
             s.OrderNumber__c, s.Name, s.Choices__c, s.Point_Values__c, Image_Attached__c,
             (SELECT Id FROM Attachments WHERE ContentType LIKE 'image%' LIMIT 1),
             (SELECT   Id, Response__c, Survey_Question__c, SurveyTaker__c, SurveyTaker__r.Account__c
              FROM   Survey_Question_Answers__r
              WHERE   SurveyTaker__r.User__c =:userId AND
              SurveyTaker__r.Account__c = :accountId)
             From Survey_Question__c s
             WHERE s.Survey__c =: surveyId ORDER BY s.OrderNumber__c];
        }
        allQuestions = new List<question>();
        Double old_OrderNumber = 0;
        Double new_OrderNumber;
        Double difference = 0;
        /* Make sure that the order number follow each other (after deleting a question, orders might not do so) */
        for (Survey_Question__c q : allQuestionsObject){
            new_OrderNumber = q.OrderNumber__c;
            difference = new_OrderNumber - old_OrderNumber - 1;
            if (difference > 0) {
                Double dd = double.valueOf(difference);
                Integer newOrderInt = dd.intValue();
                q.OrderNumber__c -= Integer.valueOf(newOrderInt);
            }
            old_OrderNumber = q.OrderNumber__c;
            system.debug('q: '+q);
            system.debug('q Answers: '+q.Survey_Question_Answers__r);
            system.debug('attachments: '+q.Attachments);
            system.debug('this: '+this);
            question theQ = new question(q, this);
            System.debug('question ['+theQ.Id+'] : ' + theQ);
            allQuestions.add(theQ);
        }
        allQuestionsSize = allQuestions.size();
        return allQuestions;
    }

    public void submitResults()
    {
      system.debug('allQuestions: '+allQuestions);
        List <SurveyQuestionResponse__c> sqrList = new List<SurveyQuestionResponse__c>();
        List <SurveyQuestionResponse__c> sqrDeleteList = new List<SurveyQuestionResponse__c>();
        for (question q : allQuestions)
        {
            /*SYSTEM.DEBUG('Question Loop Data:');
            System.debug('q.renderSelectRadio: ' + q.renderSelectRadio);
            System.debug('q.existingResponses: ' + q.existingResponses);
            System.debug('q.required: ' + q.required);
            System.debug('q.selectedOption: ' + q.selectedOption);
            System.debug('q.renderFreeText: ' + q.renderFreeText);
            System.debug('q.choices: ' + q.choices);
            System.debug('q.renderNumber: ' + q.renderNumber);
            System.debug('q.renderSelectCheckboxes: ' + q.renderSelectCheckboxes);
            System.debug('q.selectedOptions: ' + q.selectedOptions);
            System.debug('q.renderSelectRow: ' + q.renderSelectRow);
            System.debug('AddSurveyTaker(): ' + AddSurveyTaker());*/
          /*map<id, SurveyQuestionResponse__c> existingResponseMap = new map<Id,SurveyQuestionResponse__c>();
        for(SurveyQuestionResponse__c sqr:existingResponses){
          existingResponseMap.put(sqr.Survey_Question__c, sqr);
        }*/
          system.debug('q.existingResponses: '+q.existingResponses);
            SurveyQuestionResponse__c sqr = new SurveyQuestionResponse__c();
            //system.debug('q.numberAnswer'+q.numberAnswer.toPlainString());
            if (q.renderSelectRadio == 'true')
            {
              if(!q.existingResponses.isEmpty()){
                  sqr = q.existingResponses[0];
                }

                if (q.required &&  (q.selectedOption == null || q.selectedOption == ''))
                {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Fill_Out_Required_Fields));
                    return;
                }

                if (q.selectedOption == null || q.selectedOption == '')
                {
                    sqr.Response__c = '';
                }
                else
                {
                    sqr.Response__c = q.singleOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
                    sqr.Point_Value__c = q.optionPointValues.get(sqr.Response__c);
                }
                sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }
            else if (q.renderFreeText == 'true')
            {
              if(!q.existingResponses.isEmpty()){
                  sqr = q.existingResponses[0];
                }

                if (q.required && q.choices == '')
                {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Fill_Out_Required_Fields));
                    return;
                }
                System.debug('*****Select Radio ' + q.choices);

                sqr.Response__c = q.choices;
                sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }
            else if (q.renderNumber == 'true')
            {
              if(!q.existingResponses.isEmpty()){
                  sqr = q.existingResponses[0];
                }
                //system.debug('q.existingResponses[0]: '+q.existingResponses[0].Response__c);
                system.debug('q.response: '+q.response);
                system.debug('q.choices: '+q.choices);
                system.debug('q.numberAnswer: '+q.numberAnswer.toPlainString());

              string myStringNumberAnswer;
              if(q.numberAnswer == -1000000){
                sqr.Response__c = '';
            }else{
              myStringNumberAnswer = q.numberAnswer.toPlainString();
            }

                if (q.required && myStringNumberAnswer == '')
                {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Fill_Out_Required_Fields));
                    return;
                }

                sqr.Response__c = myStringNumberAnswer;
                sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }
            else if (q.renderSelectCheckboxes == 'true')
            {
                if (q.required && (q.selectedOptions == null || q.selectedOptions.size() == 0))
                {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Fill_Out_Required_Fields));
                    return;
                }
                //loop through what they've checked
                // if there is an existing response, map to that
                // if there is not an existing response, create new one
                //if there is an existing response that is not in what they've checked, delete it
                for (String opt : q.selectedOptions){
                    sqr = new SurveyQuestionResponse__c();
                    for(integer i=0;i<q.existingResponses.size();i++){
                      if(q.existingResponses[i].Response__c == q.multiOptions.get(Integer.valueOf(opt)).getLabel()){
                        sqr = q.existingResponses[i];
                        q.existingResponses.remove(i);
                      }
                    }
                    if (opt == '' || opt == null)
                    {
                        sqr.Response__c = '';
                    }
                    else
                    {
                        sqr.Response__c = q.multiOptions.get(Integer.valueOf(opt)).getLabel();
                      sqr.Point_Value__c = q.optionPointValues.get(sqr.Response__c);
                    }
                    sqr.Survey_Question__c = q.Id;
                    sqrList.add(sqr);
                }
                if(!q.existingResponses.isEmpty()){
                  system.debug('existingResponses to Delete:'+q.existingResponses);
                  //delete q.existingResponses;
                  sqrDeleteList.addAll(q.existingResponses);
                }
            }
            else if (q.renderSelectRow == 'true'){
              if(!q.existingResponses.isEmpty()){
                  sqr = q.existingResponses[0];
                }

                if (q.required && (q.selectedOption == null || q.selectedOption == ''))
                {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill out all required fields'));
                    return;
                }

                if (q.selectedOption == null || q.selectedOption == '')
                {
                    sqr.Response__c = '';
                }
                else
                {
                    sqr.Response__c = q.rowOptions.get(Integer.valueOf(q.selectedOption)).getLabel();
                    sqr.Point_Value__c = q.optionPointValues.get(sqr.Response__c);
                }
                sqr.Survey_Question__c = q.Id;
                sqrList.add(sqr);
            }


        }
        if(AddSurveyTaker())
        {
          System.debug('adding survey taker');
            for (SurveyQuestionResponse__c sqr : sqrList)
            {
                sqr.SurveyTaker__c = surveyTakerId;
            }
            upsert sqrList;
            delete sqrDeleteList;
            markSurveyComplete();
            thankYouRendered=true;
        }


    }

    public void markSurveyComplete(){
      Account_Ad_Hoc_Survey__c aahs;      
      try{
        aahs = [SELECT Id, Completed__c, Completed_Date__c FROM Account_Ad_Hoc_Survey__c WHERE Account__c = :accountId AND Survey__c = :surveyId LIMIT 1];
        aahs.Completed__c = true;
        aahs.Completed_Date__c = DateTime.now();
        update aahs;
      }catch(Exception e){
        //ApexPages.addMessages(e);
        System.debug('[markSurveyComplete] exception: ' + e.getMessage());
          aahs = new Account_Ad_Hoc_Survey__c();
          aahs.Account__c = accountId;
          aahs.Survey__c = surveyId;
          aahs.Completed__c = true;
          aahs.Completed_Date__c = DateTime.now();
          insert aahs;
      }
    }

    public Boolean AddSurveyTaker()
    {
        String userId;
        System.debug('[addsurveytaker] surveyid: ' + surveyId);
        if (surveyId == null)
        {
            return false;
        }
        if(caseId != null && (caseId.toUpperCase() =='NONE'|| caseId.length()<5))
          caseId = null;
        if(contactId != null && (contactId.toUpperCase() =='NONE'|| contactId.length()<5))
          contactId = null;
        if(accountId != null && (accountId.toUpperCase() =='NONE'|| accountId.length()<5))
          accountId = null;
        if (anonymousAnswer != 'Anonymous')
        {
            userId = UserInfo.getUserId();
        }
        else
        {
            userId = null;
        }

        //this section prevents a user from submitting the survey multiple times
        /*
        if(anonymousAnswer != 'Anonymous' && (contactId != null || caseId != null || accountId !=null))
        {
            List<SurveyTaker__c> check = [Select Contact__c, Survey__c, Case__c, User__c, Account__c
                            From SurveyTaker__c
                            Where Contact__c=:contactId and
                              Survey__c=:surveyId and
                              Case__c = :caseId and
                              User__c=:UserId and
                              Account__c=:accountId];
            if(check != null && check.size()>0){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.LABS_SF_You_have_already_taken_this_survey));

                return false;
            }
        }*/

        try{
          SurveyTaker__c existingSurveyTaken = null;
            // If we're doing a new survey, make an exception happen
            if(asNewSurvey == 'true') {
                existingSurveyTaken = null;
            } else {
                existingSurveyTaken = [SELECT Id FROM SurveyTaker__c WHERE User__c=:UserId AND Account__c=:accountId AND survey__c = :surveyId];
            }
          surveyTakerId = existingSurveyTaken.Id;
        }catch(Exception e){
          SurveyTaker__c st = new SurveyTaker__c();
          st.Contact__c = contactId;
          st.Survey__c = surveyId;
          st.Taken__c = 'false';
          st.Case__c = caseId;
          st.User__c = userId;
          st.Account__c = accountId;
          insert st;
          surveyTakerId = st.Id;
        }
        return true;
    }


}
public class MSD_Core_Create_FCPA_DCR {
    
    @future
    public static void createDCR(ID SurveyTargetId){
        Survey_Target_vod__c SVT = [Select Id,Account_vod__c,MSD_CORE_Country_Code__c,Segment_vod__c,Status_vod__c, 
                                   Sent_Email_vod__c,Survey_vod__c from Survey_Target_vod__c Where Id =:SurveyTargetId][0];
        
        Account thisAccount = [Select Id,MSD_CORE_Country_Code__c,MSD_CORE_FCPA_Value__c,
                               MSD_CORE_Due_Diligence_Date__c from Account Where Id =:SVT.Account_vod__c][0];
        
        //Get Survey Question count.
        List<Survey_Question_vod__c> surveyquestion = new List<Survey_Question_vod__c>();
        surveyquestion = [Select id from Survey_Question_vod__c where Survey_vod__c =:SVT.Survey_vod__c];
        
        //Get Question Response list for suevey target submitted
        List<Question_Response_vod__c> questionresponse = new List<Question_Response_vod__c>();
        questionresponse = [Select Id from Question_Response_vod__c where Survey_Target_vod__c =:SVT.Id];
        
        //first check if DCR is already created then no need to create any duplicate DCR
        List<Data_Change_Request_vod__c> checkExistingDCR = new List<Data_Change_Request_vod__c>();
        checkExistingDCR = [Select id from Data_Change_Request_vod__c where DCR_External_ID_vod__c =: thisAccount.id+'_'+SVT.Id];
        
        //if no existing dcr then only go and create the dcr. So no duplicate dcr create
        if(checkExistingDCR.size() == 0 && questionresponse.size() == surveyquestion.size()){
            
            List<Data_Change_Request_vod__c> DCRtoIns =  new List<Data_Change_Request_vod__c>();
            List<Data_Change_Request_Line_vod__c> DCRLineToIns = New List<Data_Change_Request_Line_vod__c>();
            RecordType DCRAccRecType =  [SELECT Id FROM RecordType WHERE SobjectType = 'Data_Change_Request_vod__c' 
                                         AND Name = 'Account_vod'];
            
            String Surveylink = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/MSD_CORE_Submitted_FCPA_Survey?Id='+SVT.Id;
            String FCPAfinalValue = SVT.Segment_vod__c;
            
            Data_Change_Request_vod__c ThisDCR = new Data_Change_Request_vod__c();
            Sent_Email_vod__c sEmail = new Sent_Email_vod__c();
            
            Data_Change_Request_Line_vod__c ThisDCRLINEforFCPA = new Data_Change_Request_Line_vod__c(
                                                                 MSD_CORE_Country_Code__c = thisAccount.MSD_CORE_Country_Code__c,
                                                                 New_Value_vod__c = FCPAfinalValue, 
                                                                 New_Localized_Value_vod__c = FCPAfinalValue, 
                                                                 Field_API_Name_vod__c = 'MSD_CORE_FCPA_Value__c',
                                                                 Field_Name_vod__c = 'FCPA Value');
            Data_Change_Request_Line_vod__c ThisDCRLINEforDDdate = new Data_Change_Request_Line_vod__c(
                                                                   MSD_CORE_Country_Code__c = thisAccount.MSD_CORE_Country_Code__c, 
                                                                   New_Value_vod__c = String.ValueOf(date.today()), 
                                                                   New_Localized_Value_vod__c = String.ValueOf(date.today()),
                                                                   Field_API_Name_vod__c = 'MSD_CORE_Due_Diligence_Date__c',
                                                                   Field_Name_vod__c = 'Due Diligence Date');
            Data_Change_Request_vod__c DCRRefrence = new Data_Change_Request_vod__c(DCR_External_ID_vod__c = thisAccount.Id+'_'+SVT.Id);
            System.debug('DCR refrence id is-->'+DCRRefrence);
            ThisDCRLINEforFCPA.Data_Change_Request_vod__r = DCRRefrence;
            ThisDCRLINEforDDdate.Data_Change_Request_vod__r = DCRRefrence;
            
            if(SVT.Sent_Email_vod__c != null) { 
                 
               sEmail = [Select Ownerid from Sent_Email_vod__c where id =:SVT.Sent_Email_vod__c][0];
               ThisDCR = new Data_Change_Request_vod__c(Ownerid = sEmail.Ownerid, 
                                                        DCR_External_ID_vod__c = thisAccount.Id+'_'+SVT.Id,
                                                        RecordTypeId = DCRAccRecType.Id, 
                                                        Account_vod__c = thisAccount.Id, 
                                                        MSD_CORE_Country_Code__c = thisAccount.MSD_Core_Country_Code__c,
                                                        MSD_Core_DCR_Source__c = 'FCPA Survey',
                                                        Status_vod__c = 'Submitted_vod', 
                                                        Sent_Datetime_vod__c = System.now(), 
                                                        Type_vod__c = 'Edit_vod', 
                                                        Notes_vod__c = 'FCPA Value set from Survey. Created by Batch job.\n To check the Survey Details clink on link:'+Surveylink);
               //System.debug('Setting exclusive owner of dcr'+sEmail.Ownerid);
             }
            
            else{
               ThisDCR = new Data_Change_Request_vod__c(DCR_External_ID_vod__c = thisAccount.Id+'_'+SVT.Id, 
                                                        RecordTypeId = DCRAccRecType.Id, 
                                                        Account_vod__c = thisAccount.Id, 
                                                        MSD_CORE_Country_Code__c = thisAccount.MSD_Core_Country_code__c,
                                                        MSD_Core_DCR_Source__c = 'FCPA Survey',
                                                        Status_vod__c = 'Submitted_vod', 
                                                        Sent_Datetime_vod__c = System.Now(),
                                                        Type_vod__c = 'Edit_vod', 
                                                        Notes_vod__c = 'FCPA Value set from Survey. Created by Batch job.\n To check the Survey Details clink on link:'+Surveylink); 
            }
                 //System.debug('with dcr line'+ThisDCRLINEforFCPA); 
                 Database.SaveResult[] results = Database.insert(new SObject[] {ThisDCR, ThisDCRLINEforFCPA,ThisDCRLINEforDDdate});
             
                
            
        }
        
        
    }

}
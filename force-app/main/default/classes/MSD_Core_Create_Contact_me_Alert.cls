public with sharing class MSD_Core_Create_Contact_me_Alert {
    
    private static boolean runonce=true;
    
    public static boolean runcheck(){
    
    if(runonce){
    runonce=false;
    return true;
        }else {
        return runonce;
        }
    
    }
    
    
    @future
    public static void createAlert(list<Id> svtIds){

        system.debug('id list sent from trigger '+ svtIds);

        list<alert_vod__c> createNewalertL = new list <alert_vod__c>();
        list<task> createNewtaskL = new list<Task>();
        Map<Id,Id> svttargetAccMap = new Map<Id,Id>();
        Map<Id,Id> svttargetSurvMap = new Map<Id,Id>();
        Map<Id,Integer> checkAlert = new Map<Id,Integer>(); 

        //Get the survey target id and corresponding account id from the list id


        //Get the surveytaget, survey details from the surveytarget key
        List<Survey_Target_vod__c> svttarList  = new list<Survey_Target_vod__c>([Select Id,Account_vod__r.id,Account_vod__r.Name,Account_vod__r.MSD_CORE_Country_Code__c, 
                                        Account_vod__r.PersonContactId,MSD_CORE_Country_Code__c,Status_vod__c,Sent_Email_vod__c,Sent_Email_vod__r.OwnerId,Survey_vod__c,
                                        Survey_vod__r.Name,Survey_vod__r.MSD_CORE_Country_Code__c,
                                        CreatedDate,End_Date_vod__c from Survey_Target_vod__c where Id in: svtIds ]);

        system.debug('List with details of the survey size'+svttarList.size());
        System.debug('LIst survey target original size is ' +svttarList);
        //system.debug(''+);
         //Get the survey target and corresponding  : there is a chnace that run  time error may occur - check later                            
        for(Survey_Target_vod__c sur_Target :svttarList){
            svttargetAccMap.put(sur_Target.id, sur_Target.Account_vod__r.id);
            svttargetSurvMap.put(sur_Target.id,sur_Target.Survey_vod__c);
        }

        //get the survey question count from survey target submitted map 
        List<Survey_Question_vod__c> surveyQuestionsList = New List<Survey_Question_vod__c>();
        surveyQuestionsList = [Select id,Survey_vod__c from Survey_Question_vod__c where Survey_vod__c in:svttargetSurvMap.values()];
    

        system.debug('surveyQuestionsList'+surveyQuestionsList);
        system.debug('surveyQuestionsList size'+surveyQuestionsList.size());

        list<Question_Response_vod__c> questionResponselist=new list<Question_Response_vod__c>  
        ([Select Id,Survey_Question_vod__c,Survey_Target_vod__c,createddate,Question_Text_vod__c,Response_vod__c
          from Question_Response_vod__c where Survey_Target_vod__c in :svttargetAccMap.keySet()]);

                system.debug('questionResponselist'+questionResponselist);
                system.debug('questionResponselist size'+questionResponselist.size());
                system.debug('Survey targets id and account map keyset'+svttargetAccMap.keySet());
                system.debug('Survey targets accounts map values'+svttargetAccMap.values());
        
         // List of alert id and survey target id                                                            
        List<alert_vod__c> existingalertList = new List<alert_vod__c>([Select id,MSD_Core_External_Id__c,Link_Reference_vod__c from alert_vod__c where 
                                                          MSD_Core_External_Id__c=:svttargetAccMap.keySet()]);   


        System.debug('ListSize'+ existingalertList.size());
        system.debug('list is' + existingalertList );
        alert_vod__c newalertR;
        Task newTaskR;
        Set<Id> svtSet = new Set<Id>();
        List<Survey_Target_vod__c> cloneresultSet = new List<Survey_Target_vod__c>();
        cloneresultSet = svttarList.clone();


        if(existingalertList.size()!=0){

            for(alert_vod__c aL : existingalertList){

                for(Survey_Target_vod__c sT : svttarList){

                        if(aL.MSD_Core_External_Id__c == sT.Id && aL.Link_Reference_vod__c == (sT.Account_vod__r.id +',Account') ){
                            
                            svtSet.add(aL.MSD_Core_External_Id__c);

                        }


                }

            }


        system.debug('Refined Survey set will be which needs to omitted '+svtSet);
        //Survey_Target_vod__c stV:svttarList

        for(Id stV:svtSet){
            Survey_Target_vod__c stvc= new Survey_Target_vod__c();
            stvc.id = stV;
            system.debug('stvc' + stvc);
              for (Survey_Target_vod__c sss :cloneresultSet) {  
                if (sss.id == stvc.id){
                    integer ii=svttarList.indexOf(sss);
                    if(ii != -1){
                    system.debug('Integer II ' +ii);
                    svttarList.remove(ii);
                    }
                }
            }

        }

        system.debug('Refined Survey target list size is which cannot have alerts '+svttarList.size());

    }
        
        // if no existing alert on the Account 

        For(integer i=0;i<svttarList.size();i++)
            {          
            if(questionResponselist.size() !=0){

                        for(Integer j=0; j<questionResponselist.size();j++){

                            for(Integer k=0; k<surveyQuestionsList.size();k++){

                                if(questionResponselist[j].Survey_Question_vod__c== surveyQuestionsList[k].Id){
                                    if((questionResponselist[j].Survey_Target_vod__c==svttarList[i].id) && questionResponselist[j].Response_vod__c !=null){
                                                    system.debug('value of j' + j);
                                                    system.debug('value of k' + k);

                                                        //alert creation for offline

                                                                /**
                                                    newalertR = new alert_vod__c(
                                                      Activation_Date_vod__c = questionResponselist[j].CreatedDate,
                                                          Dismissible_vod__c = TRUE,
                                                           Alert_Text_vod__c = System.Label.MSD_CORE_VVCCB_1351_Contact_me_1 +'\n\n' 
                                                                               + questionResponselist[j].Question_Text_vod__c+':--> '
                                                                               + questionResponselist[j].Response_vod__c+'\n',
                                                      Expiration_Date_vod__c = (Datetime)svttarList[i].End_Date_vod__c,
                                                       Link_Reference_vod__c = svttarList[i].Account_vod__c+ ',Account',
                                                    MSD_Core_Country_Code__c = svttarList[i].MSD_CORE_Country_Code__c,
                                                     MSD_Core_External_Id__c = svttarList[i].Id,
                                                          MSD_Core_Source__c = System.Label.MSD_CORE_VVCCB_1351_Contact_me_2,
                                                                        Name =  svttarList[i].Account_vod__r.Name + ' Has completed '  
                                                                               + svttarList[i].Survey_vod__r.Name,
                                                                                 //System.Label.MSD_CORE_VVCCB_1351_Contact_me_3,
                                                             Priority_vod__c = 'Important',
                                                               Public_vod__c = False,
                                                                     OwnerId = svttarList[i].Sent_Email_vod__r.OwnerId);


                                                                     **/

                                                
                                                // close alert creation for offline
                                                  

                                                // Task creation for online and offline

                                                newTaskR = new Task( WhoId = svttarList[i].Account_vod__r.PersonContactId, 
                                                                    WhatId = svttarList[i].Sent_Email_vod__c, 
                                                                   OwnerId = svttarList[i].Sent_Email_vod__r.OwnerId,
                                                                   Subject = svttarList[i].Survey_vod__r.Name,
                                                              ActivityDate = Date.newinstance(svttarList[i].CreatedDate.year(),
                                                                                              svttarList[i].CreatedDate.month(),
                                                                                              svttarList[i].CreatedDate.day()+3),  
                                                                                                
                                                                  Priority = 'High',
                                                                    Status = 'Not Started',
                                                               Description = System.Label.MSD_CORE_VVCCB_1351_Contact_me_1 
                                                                                +'\n\n' 
                                                                                + questionResponselist[j].Question_Text_vod__c
                                                                                +':--> '
                                                                                + questionResponselist[j].Response_vod__c
                                                                                +'\n' );

                                                // close Task creation for online and offline       

                                                /**
                                                if(newalertR != null){
                                                    createNewalertL.add(newalertR);
                                                    System.debug('new alert record'+ newalertR); 
                                                }

                                                **/

                                                if(newTaskR != null){
                                                    createNewtaskL.add(newTaskR);
                                                    System.debug('new task record'+ newTaskR); 
                                                }




                                                
                                                }
                                                   
                                            }
                                        

                                }
                            }
                        }
                    }
                    

                                                       

    List<alert_user_Action_vod__c> existingalertUAList = new list<alert_user_Action_vod__c>();
        if(/**createNewalertL.size()!=0 && **/createNewtaskL.size()!=0) {
        //insert createNewalertL;
        insert createNewtaskL;
        //existingalertUAList = createAlertUA(createNewalertL);
        } 
        System.debug('out of total code:created alert user action' + existingalertUAList);
        
        
        
    }

        /** as business decided to retire alerts
    
         public static list<alert_user_Action_vod__c> createAlertUA(list<alert_vod__c> alert_Ids){
            list<String> formIdList = new list<String>();
            System.debug('inside the LUA function' + alert_Ids);
            //Id formid = new id();
            List<alert_vod__c> alertList = new List<alert_vod__c>([Select id,OwnerId from Alert_vod__c where id in:alert_Ids] );
               
            for (alert_vod__c alert:alertList){
                 string formid = alert.id +'__' +alert.OwnerId;
                    formIdList.add(formid);
                }
               System.debug('LUA ext id list formation' + formIdList); 
            list<alert_user_Action_vod__c> createNewalertUAL = new list<alert_user_Action_vod__c>();
            List<alert_user_Action_vod__c> existingalertUAL = new list<alert_user_Action_vod__c>([select id from alert_user_Action_vod__c where 
                                                                                                    External_id_vod__c in: formIdList]);
            system.debug('size of list existingalertUAL' + existingalertUAL.size());
            
            if(existingalertUAL.size() ==0)
                    {
                for (alert_vod__c alert:alertList){    
                alert_user_Action_vod__c newAlertUAR =  new alert_user_Action_vod__c(alert_vod__c = alert.id,
                                                                                     User_vod__c =  alert.OwnerId
                                                                                      );                                                                                     
                        createNewalertUAL.add(newAlertUAR); 
                    }
                        insert createNewalertUAL;    
                    }
                    Return(createNewalertUAL);
                }

                **/
   }
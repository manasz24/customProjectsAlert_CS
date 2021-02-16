trigger MSD_Core_Survey_Target_FCPA on Survey_Target_vod__c (before insert,before update,after insert,after update) {

    if(system.isFuture())return;
    list<id> svtIds =new list<id>();
    User usr = [Select MSD_Core_Country_Code__c from User where Id=:UserInfo.getUserId()];      
    MSD_Core_FCPA_Survey_Setting__c[] xpowersurveysetting = [Select MSD_Core_Approve_By__c from MSD_Core_FCPA_Survey_Setting__c 
                                                          Where MSD_Core_Country_Code__c =:usr.MSD_CORE_Country_Code__c
                                                          and RecordType.DeveloperName = 'MSD_Core_XPower_Survey' Limit 1];

    for(Survey_Target_vod__c svt:trigger.new){
        
        System.debug('Total size is-->'+trigger.new.size());
        if(svt.Status_vod__c == 'Submitted_vod' && svt.MSD_Core_is_FCPA__c == true && svt.Segment_vod__c != null && Trigger.isAfter)
            {
                MSD_Core_Create_FCPA_DCR.createDCR(svt.Id);

            }
            
            // Edited By Manas for VVCCB-1351 'Contact me' start
                
            if(svt.Status_vod__c == 'Submitted_vod' && svt.MSD_Core_IsContactMeSurvey__c == true && Trigger.isAfter && MSD_Core_Create_Contact_me_Alert.runcheck())
            {
                svtIds.add(svt.Id);
                
            }
            // VVCCB-1351 code end
            
            
            // XPOWER Survey Check Start
            System.debug('status'+svt.Status_vod__c);
            System.debug('xpower'+svt.COI_Survey__c);
            System.debug('req status'+svt.MSD_CORE_Survey_Review_Status__c);
            
            if(xpowersurveysetting.size()>0){
            System.debug('approve by'+xpowersurveysetting[0].MSD_Core_Approve_By__c);
                if(svt.Status_vod__c == 'Submitted_vod' && svt.COI_Survey__c == true && 
                   svt.MSD_CORE_Survey_Review_Status__c== null && xpowersurveysetting[0].MSD_Core_Approve_By__c == 'Auto Approval' && Trigger.isBefore){
                      svt.MSD_CORE_Survey_Review_Status__c= ' Accepted';
                   }
            }

            // XPOWER Survey Check end
    }


    if(!svtIds.isEmpty()){
    MSD_Core_Create_Contact_me_Alert.createAlert(svtIds); // VVCCB-1351 called the funcn
        }

}
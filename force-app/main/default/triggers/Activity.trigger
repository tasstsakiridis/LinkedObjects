/* 
 * Description  : Activity used for roll up summary activity to parent market campaign on each activity created,edited, deleted.
 * Test Class   : PreEvaluationForm_Controller_Test
 * */
trigger Activity on Promotion_Activity__c (before insert, before update, after insert, after update, before delete, after delete) {
    /*
    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {        
        Id rtProposalId = Schema.SObjectType.Promotion_Activity__c.getRecordTypeInfosByName().get('Sales Proposal Locked').getRecordTypeId();
        List<String> proposals = new List<String>();
        for (Promotion_Activity__c activity : Trigger.new) {
            System.debug('activity market: ' + activity.Market__c + ', name: ' + activity.Market__r.Name + ', status: ' + activity.Status__c);
            if (activity.RecordTypeId == rtProposalId && activity.Status__c == 'Approved') {
                proposals.add(activity.Id);
            }
        }
        if (proposals.size() > 0) {
            PromotionActivity_Actuals_Helper.createProposalActuals(proposals);
        }

    }
	*/

    //----------

    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
        for (Promotion_Activity__c pa : Trigger.new) {
            if (pa.Promo_Brands__c != null) {
                pa.Promo_Brands_Description__c = pa.Promo_Brands__c.left(255);
            }
        }
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        System.debug('New Activity ' + Trigger.newMap.size());
        MRM_MarketCampaign_Helper.addMarketCampaignSummary(Trigger.newMap);
    } else if (Trigger.isDelete && Trigger.isBefore) {
         // Prevent the deletion of activities if they have related actuals.
        /*for (promotion_activity__c promo : [SELECT Id FROM promotion_activity__c
                                     WHERE Id IN (SELECT Activity__c FROM Actual__c) AND
                                     Id IN :Trigger.old]) {
                                         Trigger.oldMap.get(promo.Id).addError(
                                             'Cannot delete activities with related actuals.');
                                     }*/
        System.debug('Delete old Activity ' + Trigger.oldMap.size());
        MRM_MarketCampaign_Helper.subtractMarketCampaignSummary(Trigger.oldMap);
    } else if (Trigger.isUpdate) {
        if (Trigger.isBefore) {
            for(Promotion_Activity__c pa : Trigger.new) {
                System.debug('market filteer: ' + pa.Market_Filter__c);
                System.debug('recordtype: ' + pa.RecordType.Name + ', recordtypename: ' + pa.RecordTypeName__c);
                System.debug('status: ' + pa.Status__c);
                if (pa.Market_Filter__c == 'Australia' && pa.RecordTypeName__c == 'CRM - Australia' && pa.Status__c == 'Rejected') {
                    pa.Status__c = 'Draft';
                    pa.Incremental_Gross_Profit_Previous__c = pa.Incremental_Gross_Profit__c;
                    pa.Incremental_Gross_Profit__c = null;
                    if (pa.Project_Manager__c != pa.Commercial_Lead_Review_Entered_By__c) {
    	                pa.Incremental_Gross_Profit_Sales_Previous__c = pa.Incremental_Gross_Profit_Sales__c;
	                    pa.Incremental_Gross_Profit_Sales__c = null;                        
                    }
                    
                    System.debug('status: ' + pa.Status__c);
                    System.debug('Incremental Gross Profit: ' + pa.Incremental_Gross_Profit__c + ', previous: ' + pa.Incremental_Gross_Profit_Previous__c);
                    System.debug('Incremental Gross Profit Sales: ' + pa.Incremental_Gross_Profit_Sales__c + ', previous: ' + pa.Incremental_Gross_Profit_Sales_Previous__c);
                }
            }
        }
        Map<Id, Promotion_Activity__c> oldActivityMap = Trigger.oldMap;
        Map<Id, Promotion_Activity__c> newActivityMap = Trigger.newMap;
        if (Trigger.isBefore) {

            Promotion_Activity__c oldActvty;
            Map<Id, Promotion_Activity__c> reParentedActivities = new Map<Id, Promotion_Activity__c>();
            for (Promotion_Activity__c newActvty : newActivityMap.values()) {
                if (oldActivityMap.containsKey(newActvty.Id)) {
                    oldActvty = oldActivityMap.get(newActvty.Id);
                    if (oldActvty.Market_Campaign__c != newActvty.Market_Campaign__c) {
                        reParentedActivities.put(oldActvty.Id, oldActvty);
                    }
                }
            }
            MRM_MarketCampaign_Helper.subtractMarketCampaignSummary(reParentedActivities);
        } else {
            MRM_MarketCampaign_Helper.addMarketCampaignSummary(newActivityMap);
        }
    }
}
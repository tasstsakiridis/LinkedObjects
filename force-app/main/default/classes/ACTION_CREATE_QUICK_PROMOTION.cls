/**
* Test Class:  Create_Quick_Promotion_Action_Test
 */
public class ACTION_CREATE_QUICK_PROMOTION implements Callable {
    public Map<String, Object> createQuickPromotions(Map<String, Object> inputs) {
        Map<String, Object> result = new Map<String, Object>();
        String msg;

        try {
            if (inputs == null || inputs.size() == 0) {
                throw new BF_Exception('No Activity and Accounts provided to create quick promotions');
            }

            if (!inputs.containsKey('sourceObjectRecordId')) {
                throw new BF_Exception('No Activity ID provided');
            }

            if (!inputs.containsKey('linkedRecordIds')) {
                throw new BF_Exception('No Accounts provided');
            }
            
            String activityId = (String)inputs.get('sourceObjectRecordId');
            List<Object> linkedRecordIds = (List<Object>)inputs.get('linkedRecordIds');

            if (String.isEmpty(activityId)) {
                throw new BF_Exception('No Activity ID provided');                
            }

            if (linkedRecordIds == null || linkedRecordIds.size() == 0) {
                throw new BF_Exception('No Accounts provided');
            }

            List<String> accountIds = new List<String>();        
            for(Object o : linkedRecordIds) {
                accountIds.add(String.valueOf(o));
            }
            
            Promotion_Activity__c theActivity = [SELECT Id, Name, Channel__c, Begin_Date__c, End_Date__c, Market__c, Market__r.Name, Promotion_Type__c,
                                                        (SELECT Id, Name, Account__c FROM Promotions__r),
                                                        (SELECT Id, Name, Product_NoFilter__c, Price__c, Quantity__c FROM Activity_Products__r)
                                                    FROM Promotion_Activity__c 
                                                    WHERE Id =:activityId];
            if (accountIds.size() <= 10) {

                Map<String, Schema.RecordTypeInfo> promotionRecordTypes = Promotion__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();


                Map<String, Promotion__c> existingPromotions = new Map<String, Promotion__c>();
                if (theActivity.Promotions__r != null && theActivity.Promotions__r.size() > 0) {
                    for(Promotion__c p : theActivity.Promotions__r) {
                        existingPromotions.put(p.Account__c, p);
                    }
                }

                List<String> accountIdsToCreatePromotions = new List<String>();
                for(String accountId : accountIds) {
                    if (!existingPromotions.containsKey(accountId)) {
                        accountIdsToCreatePromotions.add(accountId);
                    }
                }
                List<Account> accounts = [SELECT Id, OwnerId, Name 
                                            FROM Account 
                                            WHERE Id =:accountIdsToCreatePromotions];

                String promotionRecordTypeName = theActivity.Promotion_Type__c;
                if (promotionRecordTypeName == 'Sales Promo') {
                    promotionRecordTypeName = 'Sales Promotion';
                }
                promotionRecordTypeName = promotionRecordTypeName.replaceAll(' ', '_');
                promotionRecordTypeName = promotionRecordTypeName.replaceAll('-', '_');
                System.debug('pomotionRecordTypeName: ' + promotionRecordTypeName);
                for(String key : promotionRecordTypes.keySet()) {
                    System.debug('promotion record type: ' + key);
                }
                if (!promotionRecordTypes.containsKey(promotionRecordTypeName)) {
                    throw new BF_Exception('Promotion record type could not be found for Activity of type ' + promotionRecordTypeName);
                }

                String promotionRecordTypeId = promotionRecordTypes.get(promotionRecordTypeName).getRecordTypeId();

                List<Promotion__c> promotionsToCreate = new List<Promotion__c>();
                for(Account a : accounts) {
                    Promotion__c p = new Promotion__c();
                    p.Name = (theActivity.Name + ' - ' + a.Name).left(80);
                    p.RecordTypeId = promotionRecordTypeId;
                    p.Created_By_System__c = true;
                    p.Status__c = 'Planned';
                    p.Promotion_Status__c = 'Planned';
                    p.Account__c = a.Id;
                    p.Market_Lookup__c = theActivity.Market__c;
                    p.Promotion_Start_Date__c = theActivity.Begin_Date__c;
                    p.Promotion_End_Date__c = theActivity.End_Date__c;
                    if (theActivity.Market__r.Name == 'Australia') {
                        p.Promotion_Activity_AUD__c = activityId;
                        p.AUD_Channel__c = theActivity.Channel__c;
                    } else {
                        p.Promotion_Activity__c = activityId;
                        p.Channel__c = theActivity.Channel__c;
                    } 
                    
                    promotionsToCreate.add(p);
                }

                if (promotionsToCreate.size() > 0) {
                    insert promotionsToCreate;
                    
                    if (theActivity.Activity_Products__r != null && theActivity.Activity_Products__r.size() > 0) {
                        List<Promotion_Material_Item__c> pmiToCreate = new List<Promotion_Material_Item__c>();
                        for(Promotion__c p : promotionsToCreate) {
                            for(Activity_Product__c ap : theActivity.Activity_Products__r) {
                                Promotion_Material_Item__c pmi = new Promotion_Material_Item__c();
                                pmi.Promotion__c = p.Id;
                                pmi.Activity__c = theActivity.Id;
                                pmi.Product_Custom__c = ap.Product_NoFilter__c;
                                if (ap.Quantity__c != null) {
                                    pmi.Quantity__c = ap.Quantity__c;    
                                }
                                if (ap.Price__c != null) {
                                    pmi.Sale_Price_Per_Bottle__c = ap.Price__c;
                                }

                                pmiToCreate.add(pmi);
                            }
                        }

                        if (pmiToCreate.size() > 0) {
                            insert pmiToCreate;
                        }
                    }

                    msg = System.Label.PromotionsCreatedForActivity;
                    msg = msg.replace('%0', String.valueOf(promotionsToCreate.size()));
                    msg = msg.replace('%1', theActivity.Name);
                    //result.put('message', 'Created ' + promotionsToCreate.size() + ' new promotion(s) for activity ' + theActivity.Name);
                } else {
                    msg = System.Label.NoPromotionsCreated;
                }

            } else {
                String userName = UserInfo.getName();
                String userEmail = UserInfo.getUserEmail();
                CreateQuickPromotions_BatchController bc = new CreateQuickPromotions_BatchController(activityId, theActivity.Name, accountIds, userName, userEmail);
                Database.executeBatch(bc);

                msg = 'Batch process started to create promotions for ' + accountIds.size() + ' accounts';
            }

            result.put('status', 'SUCCESS');
            result.put('message', msg);

        }catch(Exception ex) {
            System.debug('[ACTION_CREATE_QUICK_PROMOTION] exception: ' + ex.getMessage());
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }

        return result;
    }

    public Object call(String action, Map<String, Object> inputs) {
        System.debug('action: ' + action);
        switch on action {
            when 'createQuickPromotions' {
                return this.createQuickPromotions(inputs);
            }
            when else {
                throw new BF_Exception('Method ' + action + ' not implemented');            
            }
        }
    }
}
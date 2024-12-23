/**
* Test Class:  Create_Quick_Promotion_Action_Test
 */
public class ACTION_CREATE_QUICK_PROMOTION_CSV implements Callable {
    public Map<String, Object> createQuickPromotionsFromCSV(Map<String, Object> inputs) {
        Map<String, Object> result = new Map<String, Object>();
        String msg;

        try {
            if (inputs == null || inputs.size() == 0) {
                throw new BF_Exception('No Activity and Accounts provided to create quick promotions');
            }

            if (!inputs.containsKey('sourceObjectRecordId')) {
                throw new BF_Exception('No Activity ID provided');
            }

            String activityId = (String)inputs.get('sourceObjectRecordId');
            List<Object> linkedRecordIds = (List<Object>)inputs.get('linkedRecordIds');

            if (String.isEmpty(activityId)) {
                throw new BF_Exception('No Activity ID provided');                
            }

            Promotion_Activity__c theActivity = [SELECT Id, Name, Channel__c, Begin_Date__c, End_Date__c, Market__c, Market__r.Name, Promotion_Type__c,
                                                        (SELECT ContentDocument.FileExtension, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData
                                                            FROM ContentDocumentLinks )
                                                    FROM Promotion_Activity__c 
                                                    WHERE Id =:activityId];

            Blob csvData;
            if (theActivity.ContentDocumentLinks != null && theActivity.ContentDocumentLinks.size() > 0) {
                for(ContentDocumentLink cdl : theActivity.ContentDocumentLinks) {
                    if (cdl.ContentDocument.Title.toLowerCase().endsWith('_accounts') && cdl.ContentDocument.FileExtension.toLowerCase() == 'csv') {
                        csvData = cdl.ContentDocument.LatestPublishedVersion.VersionData;
                        break;
                    }
                }
            }

            if (csvData == null) {
                throw new BF_Exception('No CSV file found on ' + theActivity.Name + '. Make sure that the csv file attached ends with "_accounts".');
            }

            List<String> accountIds = new List<String>();        
            String csvFileBody = csvData.toString();
            List<String> csvRows = csvFileBody.split('\n');
            for(Integer i = 1; i < csvRows.size(); i++) {
                List<String> csvColumns = csvRows[i].split(',');
                String accountId = csvColumns[0];
                accountIds.add(accountId);
            }
            
            ACTION_CREATE_QUICK_PROMOTION action = new ACTION_CREATE_QUICK_PROMOTION();
            inputs.put('linkedRecordIds', accountIds);
            System.debug('[ACTION_CREATE_QUICK_PROMOTION_CSV] linkedRecordIds: ' + accountIds);
            result = action.createQuickPromotions(inputs);

        }catch(Exception ex) {
            System.debug('[ACTION_CREATE_QUICK_PROMOTION_CSV] exception: ' + ex.getMessage());
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }

        return result;
    }

    public Object call(String action, Map<String, Object> inputs) {
        System.debug('action: ' + action);
        switch on action {
            when 'createQuickPromotionsFromCSV' {
                return this.createQuickPromotionsFromCSV(inputs);
            }
            when else {
                throw new BF_Exception('Method ' + action + ' not implemented');            
            }
        }
    }
}
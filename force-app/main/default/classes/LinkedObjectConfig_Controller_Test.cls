@isTest(SeeAllData=true)
private class LinkedObjectConfig_Controller_Test {
    static testMethod void unitTest1() {
        Map<String, RecordTypeInfo> paRecordTypes = Schema.SObjectType.Promotion_Activity__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> pRecordTypes = Schema.SObjectType.Promotion__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> aRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> cRecordTypes = Schema.SObjectType.BF_Configuration__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> ciRecordTypes = Schema.SObjectType.BF_Configuration_Item__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> productRecordTypes = Schema.SObjectType.Product__c.getRecordTypeInfosByName();
        String rtActivity = paRecordTypes.get('CRM - Australia').getRecordTypeId();
        String rtPromotion = pRecordTypes.get('UK - PSA').getRecordTypeId();
        String rtSalesPromotion = pRecordTypes.get('Sales Promotion').getRecordTypeId();
        String rtAccount = aRecordTypes.get('AUD - Outlet').getRecordTypeId();
        String rtWetGoods = productRecordTypes.get('Wet Goods').getRecordTypeId();
        String rtLinkedObject = cRecordTypes.get('Linked Objects').getRecordTypeId();
        String rtFilter = ciRecordTypes.get('Filter').getRecordTypeId();
        String rtAction = ciRecordTypes.get('Action').getRecordTypeId();
        String rtCounter = ciRecordTypes.get('Counter').getRecordTypeId();
        String rtFieldList = ciRecordTypes.get('Preview Field List').getRecordTypeId();

        INFW_TestHelper helper = new INFW_TestHelper();
        User manager = helper.createUser('System Administrator', 'Test', 'Manager', 'Australia');
        insert manager;

        System.runAs(manager) {
            Market__c mAU = [SELECT Id, Name FROM Market__c WHERE Name = 'Australia' LIMIT 1];
            /*
            mAU.Name = 'Australia';
            mAU.Vistex_Clearing_Account__c = '0123456789';
            mAU.Country_ISO_Code_2__c = 'AU';
            mAU.Country_ISO_Code_3__c = 'AUS';
            insert mAU;
			*/
            
            Brand__c brand = new Brand__c();
            brand.Name = 'Brand';
            brand.eClips_Relevent__c = true;
            brand.Is_Active__c = true;
            insert brand;

            Account a = new Account();
            a.Name = 'Test Account';
            a.Market__c = mAU.Id;
            a.RecordTypeId = rtAccount;
            a.Channel__c = 'On';
            a.Actionable_Segment__c = 'Casual Dining';
            insert a;

            Promotion_Activity__c pa = new Promotion_Activity__c();
            pa.Name = 'testpsa';
            pa.RecordTypeId = rtActivity;
            pa.Market__c = mAU.Id;
            pa.Channel__c = 'On';
            pa.Begin_Date__c = Date.today();
            pa.End_Date__c = pa.Begin_Date__c.addYears(1);
            pa.Is_Length_in_Years__c = true;
            pa.Length_of_Agreement__c = 1;
            pa.Active__c = true;
            pa.Number_of_Payments__c = 2;
            pa.Status__c = 'Approved';
            pa.Approval_Status__c = 'Approved';
            pa.Brand__c = brand.Id;
            pa.Promotion_Type__c = 'Sales Promo';
            pa.Wombat_Active__c = true;
            insert pa;
            System.debug('pa1.Market: ' + pa.Market__c);
            System.debug('pa1.BeginDate: ' + pa.Begin_Date__c);
            System.debug('pa1.EndDate: ' + pa.End_Date__c);
            System.debug('pa1.Name: ' + pa.Name);
            
            Promotion__c p = new Promotion__c();
            p.Name = 'testpsa';
            p.RecordTypeId = rtSalesPromotion;
            p.Account__c = a.Id;
            p.AUD_Channel__c = 'On';
            p.Channel__c = 'On';
            p.Promotion_Activity__c = pa.Id;
            p.Promotion_Activity_AUD__c = pa.Id;
            p.Promotion_Start_Date__c = Date.today();
            p.Promotion_End_Date__c = p.Promotion_Start_Date__c.addMonths(4);
            p.Approval_Status__c = 'Approved';
            p.Status__c = 'Approved';
            insert p;
            

            Product__c prod1 = new Product__c();
            prod1.RecordTypeId = rtWetGoods;
            prod1.Brand__c = brand.Id;
            prod1.Name = 'Product 1';
            prod1.Channel__c = 'On';
            prod1.Market__c = mAU.Id;
            prod1.IsActive__c = true;
            insert prod1;

            BF_Configuration__c marketConfig = new BF_Configuration__c();
            marketConfig.Market__c = mAU.Id;
            marketConfig.Source_Object__c = 'Promotion_Activity__c';
            marketConfig.Linked_Object__c = 'Account';
            marketConfig.RecordTypeId = rtLinkedObject;
            insert marketConfig;
            
            BF_Configuration_Item__c marketConfigFilter1 = new BF_Configuration_Item__c();
            marketConfigFilter1.BF_Configuration__c = marketConfig.Id;
            marketConfigFilter1.RecordTypeId = rtFilter;
            marketConfigFilter1.Auto_Add__c = true;
            marketConfigFilter1.Object__c = 'Account';
            marketConfigFilter1.FieldName__c = 'Actionable_Segment__c';
            marketConfigFilter1.FieldValue__c = 'Casual Dining';
            marketConfigFilter1.FieldType__c = 'Text';
            marketConfigFilter1.Filter_Type__c = 'Value';
            marketConfigFilter1.Operator__c = 'equals';            

            BF_Configuration_Item__c marketConfigFilter2 = new BF_Configuration_Item__c();
            marketConfigFilter2.BF_Configuration__c = marketConfig.Id;
            marketConfigFilter2.RecordTypeId = rtFilter;
            marketConfigFilter2.Auto_Add__c = true;
            marketConfigFilter2.Object__c = 'Account';
            marketConfigFilter2.FieldName__c = 'Channel__c';
            marketConfigFilter2.FieldValue__c = '';
            marketConfigFilter2.FieldType__c = 'Text';
            marketConfigFilter2.Filter_Type__c = 'Field';
            marketConfigFilter2.Operator__c = 'equals';            
            marketConfigFilter2.Referenced_Object__c = 'Promotion_Activity__c';
            marketConfigFilter2.Referenced_Field__c = 'Channel__c';

            BF_Configuration_Item__c[] marketConfigItems = new BF_Configuration_Item__c[]{marketConfigFilter1, marketConfigFilter2};
            insert marketConfigItems;
            
            Map<String, String> sresult = LinkedObjectConfig_Controller.getObjectMetadata(pa.Id);
            
            Map<String, Object> result = LinkedObjectConfig_Controller.callAction('', '', '', '', null);
            result = LinkedObjectConfig_Controller.getUserDetail();
            System.assertNotEquals('ERROR', String.valueOf(result.get('status')));

            result = LinkedObjectConfig_Controller.getRecordData(pa.Id);
            System.debug('getRecordData result: ' + result);

            result = LinkedObjectConfig_Controller.createConfigForRecord(pa.Id, 'Promotion_Activity__c', 'Account', pa.Name, mAU.Name);
            System.debug('createConfigForRecord result: ' + result);

            result = LinkedObjectConfig_Controller.getConfigForRecord(pa.Id, 'Linked Objects');
            System.debug('getConfigForRecord result: ' + result);

            BF_Configuration__c config = (BF_Configuration__c)result.get('config');
            BF_Configuration_Item__c ciFilter = new BF_Configuration_Item__c();
            ciFilter.RecordTypeId = rtFilter;
            ciFilter.BF_Configuration__c = config.Id;
            ciFilter.Object__c = 'Promotion_Activity__c';
            ciFilter.FieldName__c = 'Id';
            ciFilter.FieldValue__c = pa.Id;
            ciFilter.FieldLabel__c = 'Activity';
            ciFilter.Operator__c = 'equals';
            insert ciFilter;

            Map<String, Object> filter1 = new Map<String, Object> {
                'Id' => ciFilter.Id,
                'Index__c' => 1,
                'Object__c' => 'Promotion_Activity__c',
                'FieldName__c' => 'Status__c',
                'FieldValue__c' => 'Approved',
                'FieldLabel__c' => 'Activity',
                'FieldType__c' => 'Text',
                'Operator__c' => 'equals'
            };
            Map<String, Object> filter2 = new Map<String, Object> {
                'Index__c' => 1,
                'Object__c' => 'Account',
                'FieldName__c' => 'Channel__c',
                'FieldValue__c' => '',
                'FieldLabel__c' => 'Channel',
                'Operator__c' => 'equals',
                'FieldType__c' => 'Text',
                'FilterType__c' => 'Field',
                'Referenced_Object__c' => 'Promotion_Activity__c',
                'Referenced_Field__c' => 'Channel__c'
            };
                
                Map<String, Object> filter3 = new Map<String, Object> {
                    'Index__c' => 2,
                        'Object__c' => 'Account',
                        'FieldName__c' => 'Channel__c',
                        'FieldValue__c' => 'Off',
                        'Operator__c' => 'notequals',
                        'FieldType__c' => 'Text',
                        'FilterType__c' => 'Value'
                        };
            List<String> filters = new List<String>();
            filters.add(JSON.serialize(filter1));
            filters.add(JSON.serialize(filter2));
            filters.add(JSON.serialize(filter3));
            result = LinkedObjectConfig_Controller.saveConfig(config.Id, 'Promotion_Activity__c', 'Account', '',pa.Id, rtActivity, filters, null);
            System.debug('saveConfig result: ' + result);

            List<String> fieldList = new List<String>();
            fieldList.add('Channel__c');
            result = LinkedObjectConfig_Controller.updateConfigFieldList(config.Id, 'Promotion__c', fieldList, 'Channel__c', '');
            System.debug('updateConfigFieldList result: ' + result);

            Map<String, Object> newFilter = new Map<String, Object> {
                'itemType' => 'Filter',
                'objectName' => 'Account',
                'index' => 2,
                'fieldName' => 'Name',
                'fieldValue' => 'Test',
                'fieldType' => 'Text',
                'operator' => 'starts with'
            };
            result = LinkedObjectConfig_Controller.saveItemConfiguration(config.Id, newFilter);
            System.debug('saveItemConfiguration result: ' + result);

            result = LinkedObjectConfig_Controller.getCount(config.Id, pa.Id, 'Promotion__c', 'Promotion_Activity__c');
            System.debug('getCount result: ' + result);

            result = LinkedObjectConfig_Controller.getDataForPreview(config.Id, false, manager.Id);
            System.debug('getDataForPreview result: ' + result);

            result = LinkedObjectConfig_Controller.saveConfig(config.Id, 'Promotion_Activity__c', 'Account', '','', rtActivity, null, null);
            System.debug('saveConfig2 result: ' + result);
            
            result = LinkedObjectConfig_Controller.getDataForPreview(config.Id, false, manager.Id);
            System.debug('getDataForPreview result: ' + result);

            result = LinkedObjectConfig_Controller.deleteItem(ciFilter.Id, 'Filter', 1);
            System.debug('deleteItem result: ' + result);
            
            LinkedObject lo = new LinkedObject('Promotion_Activity__c', 'Account');
            lo.controllingObjectItemConfigs.put('RecordType', 'CRM - Australia');
            lo.controllingObjectItemConfigs.put('Channel__c', 'On,Off');
            Boolean matchesCriteria = lo.recordMatchesCriteria(pa.Id, true);
            
        }
    }
}
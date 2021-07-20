@isTest
private class BF_CONFIGURATIONS_HELPER_TEST {
    static testMethod void unitTest1() {
        Map<String, RecordTypeInfo> cRecordTypes = Schema.SObjectType.BF_Configuration__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> ciRecordTypes = Schema.SObjectType.BF_Configuration_Item__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> paRecordTypes = Schema.SObjectType.Promotion_Activity__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> pRecordTypes = Schema.SObjectType.Promotion__c.getRecordTypeInfosByName();
        Map<String, RecordTypeInfo> aRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

        String rtLinkedObject = cRecordTypes.get('Linked Objects').getRecordTypeId();
        String rtFilter = ciRecordTypes.get('Filter').getRecordTypeId();
        String rtAction = ciRecordTypes.get('Action').getRecordTypeId();
        String rtActivity = paRecordTypes.get('UK - PSA').getRecordTypeId();
        String rtPromotion = pRecordTypes.get('UK - PSA').getRecordTypeId();
        String rtAccount = aRecordTypes.get('AUD - Outlet').getRecordTypeId();

        Market__c m = new Market__c();
        m.Name = 'Australia';
        m.Vistex_Clearing_Account__c = '0123456789';
        m.Country_ISO_Code_2__c = 'AU';
        m.Country_ISO_Code_3__c = 'AUS';
        insert m;

        Account a = new Account();
        a.RecordTypeId = rtAccount;
        a.Name = 'Test Account';
        a.Market__c = m.Id;
        a.Channel__c = 'On';
        insert a;

        Promotion_Activity__c pa = new Promotion_Activity__c();
        pa.RecordTypeId = rtActivity;
        pa.Market__c = m.Id;
        pa.Name = 'Test Activity';
        pa.Channel__c = 'On';
        insert pa;

        Promotion__c p = new Promotion__c();
        p.RecordTypeId = rtPromotion;
        p.Promotion_Activity__c = pa.Id;
        p.Channel__c = 'On';
        p.Account__c = a.Id;
        insert p;

        BF_Configuration__c config = new BF_Configuration__c();
        config.RecordTypeId = rtLinkedObject;
        config.Market__c = m.Id;
        config.Source_Object__c = 'Promotion__c';
        config.Linked_Object__c = 'Account';
        config.Source_Object_Market_Field_Name__c = 'Market__c';
        config.Source_Object_Market_Field_Type__c = 'Text';
        config.Source_Object_Record_Id__c = p.Id;
        config.Source_Object_Record_Type__c = rtPromotion;
        insert config;

        BF_Configuration_Item__c ciFilter = new BF_Configuration_Item__c();
        ciFilter.RecordTypeId = rtFilter;
        ciFilter.BF_Configuration__c = config.Id;
        ciFilter.Object__c = 'Promotion__c';
        ciFilter.FieldName__c = 'Channel__c';
        ciFilter.FieldValue__c = 'On';
        ciFilter.FieldLabel__c = 'Channel';
        ciFilter.Operator__c = 'equals';

        BF_Configuration_Item__c ciFilter2 = new BF_Configuration_Item__c();
        ciFilter2.RecordTypeId = rtFilter;
        ciFilter2.BF_Configuration__c = config.Id;
        ciFilter2.Object__c = 'Account';
        ciFilter2.FieldName__c = 'Channel__c';
        ciFilter2.FieldValue__c = 'On';
        ciFilter2.FieldLabel__c = 'Channel';
        ciFilter2.Operator__c = 'equals';
        
        BF_Configuration_Item__c ciAction = new BF_Configuration_Item__c();
        ciAction.RecordTypeId = rtAction;
        ciAction.BF_Configuration__c = config.Id;
        ciAction.Action_Class_Name__c = 'ACTION_CREATE_QUICK_PROMOTION';
        ciAction.Action_Method_Name__c = 'createQuickPromotions';
        ciAction.Action_Type__c = 'Apex';
        ciAction.Action_Label__c = 'Create quick promotions';

        BF_Configuration_Item__c[] items = new BF_Configuration_Item__c[]{ciFilter, ciFilter2, ciAction};
        insert items;

        Map<String, Object> result = BF_CONFIGURATIONS_HELPER.findConfigurations(p.Id, a.Id, m.Id, rtPromotion, false);
        System.debug(result);

        Map<String, Object> params = new Map<String, Object>();
        params.put('sourceObjectRecordId', p.Id);
        params.put('marketId', m.Id);
        params.put('marketName', m.Name);
        params.put('recordTypeId', rtPromotion);
        Map<String, Object> inputs = new Map<String, Object> {
            p.Id => params
        };
        result = BF_CONFIGURATIONS_HELPER.findConfigurations('Promotion__c', 'Account', inputs);
        System.debug(result);
        
        Set<String> promotionIds = new Set<String>();
        promotionIds.add(p.Id);
        params.clear();
        params.put('sourceObjectRecordIds', promotionIds);
        inputs.put(p.id, params);
        result = BF_CONFIGURATIONS_HELPER.findConfigurations('Promotion__c', 'Account', inputs);
        
    }
}
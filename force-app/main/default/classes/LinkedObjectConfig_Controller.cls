public with sharing class LinkedObjectConfig_Controller {
    @AuraEnabled(cacheable=true) 
    public static BF_Configuration__c getConfigForRecord(String recordId) {
        BF_Configuration__c config;
        if (String.isEmpty(recordId)) {
            return config;
        }

        Id theId = Id.valueOf(recordId);
        Schema.SObjectType typeOfObj = theId.getSobjectType();
        Schema.DescribeSObjectResult dsr = typeOfObj.getDescribe();

        String query = 'SELECT Id, Name, Source_Object__c, Linked_Object__c, Item_Config_Logic__c, Market__c, Source_Object_Record_Type__c, ';
        query += '(SELECT Id, Name, RecordTypeId, RecordType.Name, BF_Configuration__c, Object__c, FieldName__c, FieldValue__c, Operator__c, ';
        query += ' Index__c, Is_Filter__c, Object_to_Count__c, Field_Name_to_Query__c, Counter_Label__c, Is_Counter__c, Preview_Field_1__c, Preview_Field_2__c ';
        query += ' FROM BF_Configuration_Items__r ORDER BY RecordTypeId, Index__c)';
        query += ' FROM BF_Configuration__c';
        if (dsr.getName() == 'BF_Configuration__c') {
            query += ' WHERE Id =:recordId';
        } else {
            query += ' WHERE Source_Object_Record_Id__c =:recordId';
        }

        List<BF_Configuration__c> configs = Database.query(query);
        if (configs != null && configs.size() > 0) {
            config = configs.get(0);
        }
        return config;
    }

    @AuraEnabled 
    public static Map<String, Object> saveConfig(String configId, String sourceObject, String linkedObject, String market, String sourceObjectRecordId, String sourceObjectRecordType, List<String> filters, List<String> filtersToRemove) {
        System.debug('configId : ' + configId);
        System.debug('sourceObject : ' + sourceObject);
        System.debug('linkedObject : ' + linkedObject);
        System.debug('market : ' + market);
        System.debug('sourceObjectRecordId : ' + sourceObjectRecordId);
        System.debug('sourceObjectRecordType : ' + sourceObjectRecordType);
        System.debug('filters : ' + filters);
        System.debug('filtersToRemove: ' + filtersToRemove);

        Map<String, Object> result = new Map<String, Object>();
        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtId = rtList.get('Gantt Chart').getRecordTypeId();

        String marketId = market;
        if (market == null || market == '') {
            if (String.isNotEmpty(sourceObjectRecordId)) {
                List<SObject> l = Database.query('SELECT Market__c FROM ' + sourceObject + ' WHERE Id=:sourceObjectRecordId');
                if (l.size() > 0) {
                    marketId = String.valueOf(l[0].get('Market__c'));
                }
            } else {
                User u = [SELECT Id, Market__c FROM User WHERE Id =:UserInfo.getUserId()];
                String marketName = 'Australia';
                if (String.isNotEmpty(u.Market__c)) {
                    marketName = u.Market__c;
                }
                List<Market__c> marketList = [SELECT Id FROM Market__c WHERE Name =:marketName];
                marketId = marketList[0].Id;
            }
        }

        if (filtersToRemove != null && filtersToRemove.size() > 0) {
            List<BF_Configuration_Item__c> itemsToRemove = new List<BF_Configuration_Item__c>();
            for(String s : filtersToRemove) {
                BF_Configuration_Item__c bfci = new BF_Configuration_Item__c(Id = s);
                itemsToRemove.add(bfci);
            }
            delete itemsToRemove;
        }

        try {
            BF_Configuration__c bfConfig = new BF_Configuration__c();
            if (String.isNotEmpty(configId)) {
                bfConfig.Id = configId;
            }
            bfConfig.RecordTypeId = rtId;
            bfConfig.Source_Object__c = sourceObject;
            bfConfig.Linked_Object__c = linkedObject;
            bfConfig.Market__c = marketId;
            bfConfig.Source_Object_Record_Id__c = sourceObjectRecordId;
            bfConfig.Source_Object_Record_Type__c = sourceObjectRecordType;
            upsert bfConfig;
            
            List<BF_Configuration_Item__c> configItems = new List<BF_Configuration_Item__c>();
            if (filters != null && filters.size() > 0) {
                for(String filter : filters) {                    
                    BF_Configuration_Item__c bfConfigItem = new BF_Configuration_Item__c();
                    Map<String, Object> item = (Map<String, Object>)JSON.deserializeUntyped(filter);
                    if (item.containsKey('Id')) {
                        String itemId = String.valueOf(item.get('Id'));
                        if (String.isNotEmpty(itemId)) {
                            bfConfigItem.Id = String.valueOf(item.get('Id'));
                        }
                    }
                    if (String.isEmpty(bfConfigItem.Id)) {
                        bfConfigItem.BF_Configuration__c = bfConfig.Id;
                    }
                    System.debug('config item id: ' + bfConfigItem.Id);
                    System.debug('config id: ' + bfConfig.Id);

                    bfConfigItem.Object__c = String.valueOf(item.get('Object__c'));
                    bfConfigItem.FieldName__c = String.valueOf(item.get('FieldName__c'));
                    bfConfigItem.FieldValue__c = String.valueOf(item.get('FieldValue__c'));
                    bfConfigItem.Operator__c = String.valueOf(item.get('Operator__c'));
                    bfConfigItem.Index__c = Integer.valueOf(item.get('Index__c'));

                    configItems.add(bfConfigItem);
                }    
            }
            if (configItems.size() > 0) {
                upsert configItems;            
            }

            result.put('Id', bfConfig.Id);
            result.put('items', configItems);
        }catch(Exception ex) {
            result.put('error', ex.getMessage());            
        }
        return result;
    }

    @AuraEnabled 
    public static Map<String, Object> getDataForPreview(String configId) {
        System.debug('configId: ' + configId);
        BF_Configuration__c bfConfig = [SELECT Id, Name, Source_Object__c, Linked_Object__c, Market__c, Source_Object_Record_Type__c, Source_Object_Record_Id__c, 
                                            (SELECT Id, Name, RecordTypeId, Object__c, FieldName__c, FieldValue__c, Operator__c, Field_List__c, Preview_Field_1__c, Preview_Field_2__c,
                                                    Object_to_Count__c, Field_Name_to_Query__c
                                               FROM BF_Configuration_Items__r)
                                        FROM BF_Configuration__c
                                        WHERE Id=:configId];

        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtPreviewFieldList = rtList.get('Preview Field List').getRecordTypeId();
        String rtFilter = rtList.get('Linked Object Filter').getRecordTypeId();
        String rtCounter = rtList.get('Linked Object Counter').getRecordTypeId();
                                
        Map<String, Object> data = new Map<String, Object>();
        if (bfConfig == null) {
            data.put('error', 'No configuration found for Id [' + configId + ']');
            return data;
        }

        String[] sObjectTypes = new String[]{bfConfig.Linked_Object__c};
        Schema.DescribeSObjectResult[] describeResults = Schema.describeSObjects(sObjectTypes);
        Map<String, Schema.SObjectField> fields = describeResults[0].fields.getMap();

        String query = 'SELECT ';
        String fieldList = '';
        String whereClause = '';
        String fieldValue;
        Map<String, String> queryDetails;
        List<String> errors = new List<String>();

        if (String.isNotEmpty(bfConfig.Source_Object_Record_Id__c)) {
            data.put('sourceObjectRowCount', 1);
        } else {
            queryDetails = buildWhereClause(bfConfig.Source_Object__c, bfConfig.BF_Configuration_Items__r, rtPreviewFieldList, rtFilter);            
            try {
                query = 'SELECT ' + fieldList + ' FROM ' + bfConfig.Source_Object__c;
                if (queryDetails.containsKey('whereClause')) {
                    query += ' WHERE ' + queryDetails.get('whereClause');
                }
                query += ' LIMIT 1000';

                List<SObject> sourceObjectRows = Database.query(query);
                data.put('sourceObjectRows', sourceObjectRows);
                data.put('sourceObjectRowCount', sourceObjectRows == null ? 0 : sourceObjectRows.size());
            }catch(DmlException ex) {
                errors.add(ex.getMessage());
            }
        }

        queryDetails = buildWhereClause(bfConfig.Linked_Object__c, bfConfig.BF_Configuration_Items__r, rtPreviewFieldList, rtFilter);
        if (queryDetails.containsKey('fieldList')) {
            fieldList = queryDetails.get('fieldList');
            if (fieldList.indexOf('Name') < 0) {
                fieldList = 'Name,'+fieldList;
            }
            data.put('previewField1', queryDetails.get('previewField1'));
            data.put('previewField2', queryDetails.get('previewField2'));
        }
        if (String.isNotEmpty(fieldList)) {
            fieldList = 'Id,'+fieldList;
        } else {
            fieldList = 'Id, Name';
        }

        whereClause = '';
        if (queryDetails.containsKey('whereClause')) {
            whereClause = queryDetails.get('whereClause');
        }

        query += fieldList;
        query += ' FROM ' + bfConfig.Linked_Object__c;

        String marketId = '';
        if (String.isNotEmpty(bfConfig.Market__c)) {
            marketId = bfConfig.Market__c;        
        } else {
            User u = [SELECT Market__c FROM User WHERE Id =:UserInfo.getUserId()];
            String marketName = 'Australia';
            if (String.isNotEmpty(u.Market__c)) {
                marketName = u.Market__c;
            }
            Market__c m = [SELECT Id FROM Market__c WHERE Name =:marketName LIMIT 1];
            marketId = m.Id;
        }
        query += ' WHERE Market__c =:marketId ';    

        System.debug('whereClause: ' + whereClause);
        if (String.isNotEmpty(whereClause)) {
            whereClause = whereClause.removeEnd('AND ');
            query += ' AND ' + whereClause;
        }
        query += ' ORDER BY Name';
        query += ' LIMIT 1000';
        
        System.debug('query: ' + query);
        try {
            List<SObject> rows = Database.query(query);   
            data.put('linkedObjectRows', rows);
            data.put('linkedObjectRowCount', rows.size());

            List<Map<String, Object>> columns = new List<Map<String, Object>>();
            String[] fieldNames = fieldList.split(',');
            for(String fldName : fieldNames) {
                if (fldName != 'Id') {
                    Schema.DescribeFieldResult dsr = fields.get(fldName).getDescribe();

                    columns.add(new Map<String, Object> {
                        'label' => fldName,
                        'fieldName' => dsr.getName(),
                        'type' => dsr.getType(),
                        'sortable' => true,
                        'hideDefaultActions' => true
                    });                    
                }
            }
            data.put('columns', columns);

            if (String.isNotEmpty(bfConfig.Source_Object_Record_Id__c)) {
                Schema.SObjectType t = Schema.getGlobalDescribe().get(bfConfig.Source_Object__c);
                SObject sObjRec = t.newSObject(bfConfig.Source_Object_Record_Id__c);
                sObjRec.put('Linked_Object_Count__c', rows.size());
                update sObjRec;
            }

        } catch(DmlException dmlex) {
            data.put('error', dmlex.getMessage());
        }
        
        return data;
    }

    @AuraEnabled 
    public static Map<String, Object> getCount(String sourceRecordId, String objectToCount, String fieldNameToQuery) {
        System.debug('sourceRecordId: ' + sourceRecordId);
        System.debug('objectToCount: ' + objectToCount);
        System.debug('fieldNameToQuery: ' + fieldNameToQuery);
        Map<String, Object> data = new Map<String, Object>();
        if (String.isEmpty(sourceRecordId) || String.isEmpty(objectToCount) || String.isEmpty(fieldNameToQuery)) {
            data.put('error', 'No count config provided');
            return data;
        }
        
        try {
            String idToQuery = sourceRecordId;
            String query = 'SELECT COUNT() FROM ' + objectToCount + ' WHERE ' + fieldNameToQuery + ' =:idToQuery';
            Integer recordCount = Database.countQuery(query);
    
            data.put('count', recordCount);    
        }catch(Exception ex) {
            data.put('error', ex.getMessage());
        }

        return data;
    }

    @AuraEnabled 
    public static Map<String, Object> updateConfigFieldList(String configId, String objectName, List<String> fieldList, String previewField1, String previewField2) {
        Map<String, Object> result = new Map<String, Object>();
        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtPreviewFieldList = rtList.get('Preview Field List').getRecordTypeId();

        System.debug('configId: ' + configId);
        System.debug('recordTypeId: ' + rtPreviewFieldList);
        List<BF_Configuration_Item__c> items = [SELECT Id, Object__c, Field_List__c, Preview_Field_1__c, Preview_Field_2__c 
                                                  FROM BF_Configuration_Item__c 
                                                 WHERE BF_Configuration__c =:configId 
                                                   AND RecordTypeId =:rtPreviewFieldList];

        BF_Configuration_Item__c item;
        if (items != null && items.size() > 0) {
            item = items[0];
        }
        
        if (item == null) {
            item = new BF_Configuration_Item__c();            
            item.BF_Configuration__c = configId;
            item.RecordTypeId = rtPreviewFieldList;
            item.Object__c = objectName;
        }

        try {
            item.Preview_Field_1__c = previewField1;
            item.Preview_Field_2__c = previewField2;

            String fldNames = '';
            for(String s :fieldList) {
                if (s != 'Name') {
                    fldNames += s + ',';
                }
            }
            fldNames = fldNames.removeEnd(',');
            item.Field_List__c = fldNames;
            upsert item;
            
            result.put('status', 'SUCCESS');
            result.put('record', item);
        }catch(Exception ex) {
            result.put('error', ex.getMessage());
        }
        
        return result;
    }

    static Map<String, String> buildWhereClause(String objectName, List<BF_Configuration_Item__c> configItems, String rtPreviewFieldList, String rtFilter) {
        String whereClause = '';
        Boolean valuesIsList = false;
        Map<String, String> result = new Map<String, String>();
        if (configItems != null && configItems.size() > 0) {
            for(BF_Configuration_Item__c bfci : configItems) {
                System.debug('bfci: ' + bfci);
                if (bfci.Object__c == objectName) {
                    valuesIsList = bfci.FieldValue__c == null ? false : bfci.FieldValue__c.indexOf(',') > -1;
                    if (bfci.RecordTypeId == rtPreviewFieldList) {
                        result.put('fieldList', bfci.Field_List__c);
                        result.put('previewField1', bfci.Preview_Field_1__c);
                        result.put('previewField2', bfci.Preview_Field_2__c);
                    } else if (bfci.RecordTypeId == rtFilter) {
                        whereClause += bfci.FieldName__c;
                        if (bfci.Operator__c == 'startswith') {
                            whereClause += ' LIKE \'%' + bfci.FieldValue__c + '\'';
                        } else if (bfci.Operator__c == 'endswith') {
                            whereClause += ' LIKE \'' + bfci.FieldValue__c + '%\'';
                        } else if (bfci.Operator__c == 'includes') {                        
                            whereClause += ' INCLUDES (\'' + bfci.FieldValue__c.replaceAll(',','\',\'') + '\')';
                        } else if (bfci.Operator__c == 'notincludes') {
                            whereClause += ' EXCLUDES (\'' + bfci.FieldValue__c.replaceAll(',','\'.\'') + '\')';
                        } else if (bfci.Operator__c == 'equals') {
                            whereClause += ' = \'' + bfci.FieldValue__c + '\'';
                        } else if (bfci.Operator__c == 'notequals') {
                            whereClause += ' != \'' + bfci.FieldValue__c + '\'';
                        } else {
                            whereClause += ' ' + bfci.Operator__c + ' \'' + bfci.FieldValue__c + '\'';
                        }
    
                        whereClause += ' AND ';
                    }    
                }
            }

            whereClause = whereClause.removeEnd('AND ');
            result.put('whereClause', whereClause);
        }

        return result;

    }
}
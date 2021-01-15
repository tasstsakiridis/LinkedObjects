public with sharing class LinkedObjectConfig_Controller {
    @AuraEnabled
    public static Map<String, Object> getRecordData(String recordId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Id theId = Id.valueOf(recordId);
            Schema.SObjectType typeOfObj = theId.getSobjectType();
            Schema.DescribeSObjectResult dsr = typeOfObj.getDescribe();

            String query = 'SELECT Id, Name';
            if (dsr.fields.getMap().containsKey('Market__c')) {
                query += ', Market__c';
            }
            query += ' FROM ' + dsr.getName();
            query += ' WHERE Id =:theId';

            System.debug('query: ' + query);
            System.debug('object name: ' + dsr.getName());
            List<SObject> data = Database.query(query);
            if (data != null && data.size() > 0) {
                result.put('theRecord', data.get(0));
            }
            //System.debug('data: ' + data);
            //result.put('theRecord', data);
            result.put('theRecord_SObjectType', String.valueOf(typeOfObj));
        }catch(Exception ex) {
            System.debug('[getRecordData] exception: ' + ex);
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }

        return result;
    }

    @AuraEnabled(cacheable=true) 
    public static Map<String, Object> getConfigForRecord(String recordId, String configType) {
        Map<String, Object> result = new Map<String, Object>();
        String query = '';
        System.debug('recordId: ' + recordId);

        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtConfigId = rtList.get('Linked Objects').getRecordTypeId();

        try {
            BF_Configuration__c config;
            if (String.isEmpty(recordId)) {
                throw new BF_Exception('No record Id');
            }

            String configTypeId = rtConfigId;
            if (String.isNotEmpty(configType) && rtList.containsKey(configType)) {
                configTypeId = rtList.get(configType).getRecordTypeId();
            }

            Id theId = Id.valueOf(recordId);
            Schema.SObjectType typeOfObj = theId.getSobjectType();
            Schema.DescribeSObjectResult dsr = typeOfObj.getDescribe();
            
            result.put('theRecord_SObjectType', dsr.getName());

            Boolean hasFilters = false;
            query = 'SELECT Id, Name, Source_Object__c, Linked_Object__c, Item_Config_Logic__c, Market__c, Source_Object_Record_Type__c, ';
            query += '(SELECT Id, Name, RecordTypeId, RecordType.Name, BF_Configuration__c, Object__c, FieldName__c, FieldValue__c, Operator__c, ';
            query += ' Index__c, Is_Filter__c, Object_to_Count__c, Field_Name_to_Query__c, Counter_Label__c, Is_Counter__c, Preview_Field_1__c, Preview_Field_2__c, ';
            query += ' Is_Action__c, Is_Field_List__c, Action_Type__c, Action_Label__c, Action_Class_Name__c, Action_Method_Name__c, Action_Flow_Name__c, FieldType__c';
            query += ' FROM BF_Configuration_Items__r ORDER BY RecordTypeId, Index__c)';
            query += ' FROM BF_Configuration__c';
            query += ' WHERE ';
            if (dsr.getName() == 'BF_Configuration__c') {
                query += ' Id =:recordId';
            } else {
                query += ' Source_Object_Record_Id__c =:recordId AND RecordTypeId =:configTypeId';
            }

            System.debug('query: ' + query);
            List<BF_Configuration__c> configs = Database.query(query);
    
            if (configs != null && configs.size() > 0) {
                config = configs.get(0);
                result.put('config', config);
                List<Map<String,Object>> filters = new List<Map<String,Object>>();
                List<Map<String,Object>> actions = new List<Map<String,Object>>();
                List<Map<String,Object>> fieldList = new List<Map<String,Object>>();
                List<Map<String,Object>> counters = new List<Map<String,Object>>();

                for(BF_Configuration_Item__c configItem : config.BF_Configuration_Items__r) {
                    Map<String, Object> item = new Map<String, Object>{
                        'id' => configItem.Id,
                        'index' => configItem.Index__c,
                        'itemType' => configItem.RecordType.Name,
                        'objectName' => configItem.Object__c,
                        'fieldName' => configItem.FieldName__c,
                        'fieldValue' => configItem.FieldValue__c,
                        'fieldType' => configItem.FieldType__c,
                        'operator' => configItem.Operator__c,
                        'counterLabel' => configItem.Counter_Label__c,
                        'previewField1' => configItem.Preview_Field_1__c,
                        'previewField2' => configItem.Preview_Field_2__c,
                        'actionType' => configItem.Action_Type__c,
                        'actionLabel' => configItem.Action_Label__c,
                        'actionClassName' => configItem.Action_Class_Name__c,
                        'actionMethodName' => configItem.Action_Method_Name__c,
                        'actionFlowName' => configItem.Action_Flow_Name__c,
                        'objectToCount' => configItem.Object_to_Count__c,
                        'counterLabel' => String.isEmpty(configItem.Counter_Label__c) ? configItem.Object_to_Count__c + '.' + configItem.FieldName__c : configItem.Counter_Label__c
                    };

                    switch on (configItem.RecordType.Name) {
                        when 'Action' {
                            actions.add(item);
                        }
                        when 'Filter' {
                            filters.add(item);
                        }
                        when 'Counter' {
                            counters.add(item);
                        }
                        when 'Preview Field List' {
                            fieldList.add(item);
                        }

                    }
                }

                result.put('filters', filters);
                result.put('counters', counters);
                result.put('actions', actions);
                result.put('fieldList', fieldList);
                
            }

        }catch(Exception ex) {
            System.debug('exception : '+ ex);
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }
        return result;
    }

    @AuraEnabled 
    public static Map<String, Object> createConfigForRecord(String recordId, String sourceObject, String linkedObject, String recordName, String marketName) {
        Map<String, Object> result = new Map<String, Object>();

        try {

            System.debug('recordId: ' + recordId);
            System.debug('sourceObject: ' + sourceObject);
            System.debug('linkedObject: ' + linkedObject);
            System.debug('recordName: ' + recordName);
            System.debug('marketName: ' + marketName);
            Id marketId;
            try {
                marketId = Id.valueOf(marketName);
                List<Market__c> l_markets = [SELECT Id, Name FROM Market__c WHERE Id =:marketId LIMIT 1];
                if (l_markets != null && l_markets.size() > 0) {
                    marketName = String.valueOf(l_markets[0].get('Name'));
                }
            }catch(Exception typeException) {
                List<Market__c> l_markets = [SELECT Id FROM Market__c WHERE Name =:marketName LIMIT 1];
                if (l_markets != null && l_markets.size() > 0) {
                    marketId = String.valueOf(l_markets[0].get('Id'));
                }
            }
            Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration__c.SObjectType.getDescribe().getRecordTypeInfosByName();
            String rtConfigId = rtList.get('Linked Objects').getRecordTypeId();

            BF_Configuration__c config = new BF_Configuration__c();
            config.RecordTypeId = rtConfigId;
            config.Source_Object__c = sourceObject;
            config.Linked_Object__c = linkedObject;
            config.Source_Object_Record_Id__c = recordId;
            config.Market__c = marketId;
            insert config;   
            System.debug('config.Id: ' + config.Id);

            List<BF_Configuration_Item__c> filters = new List<BF_Configuration_Item__c>();

            Map<String, Schema.RecordTypeInfo> rtItemList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
            String rtFilterId = rtItemList.get('Filter').getRecordTypeId();
            System.debug('rtFilterId: ' + rtFilterId);
            BF_Configuration_Item__c filter1 = new BF_Configuration_Item__c();
            filter1.RecordTypeId = rtFilterId;
            filter1.BF_Configuration__c = config.Id;
            filter1.FieldName__c = 'Name';
            filter1.FieldValue__c = recordName;
            filter1.FieldType__c = 'Text';
            filter1.Operator__c = 'equals';
            filter1.Object__c = sourceObject;
            filter1.Index__c = 0;
            filters.add(filter1);
                        
            insert filters;

            List<Map<String, Object>> items = new List<Map<String, Object>>();
            for(BF_Configuration_Item__c bfci : filters) {
                Map<String, Object> item = new Map<String, Object>{
                    'id' => bfci.Id,
                    'index' => bfci.Index__c,
                    'itemType' => 'Filter',
                    'objectName' => bfci.Object__c,
                    'fieldName' => bfci.FieldName__c,
                    'fieldValue' => bfci.FieldValue__c,
                    'fieldType' => bfci.FieldType__c,
                    'operator' => bfci.Operator__c
                };

                items.add(item);
            }

            result.put('config', config);
            result.put('filters', items);
            result.put('status', 'SUCCESS');
        }catch(Exception ex) {
            System.debug('exception : '+ ex);
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());            
        }

        return result;
    }

    @AuraEnabled 
    public static Map<String, String> getObjectMetadata(String recordId) {
        Map<String, String> result = new Map<String, String>();

        Id theId = Id.valueOf(recordId);
        Schema.SObjectType typeOfObj = theId.getSobjectType();
        Schema.DescribeSObjectResult dsr = typeOfObj.getDescribe();

        result.put('type', dsr.getName());
        result.put('label', dsr.getLabel());
        result.put('labelPlural', dsr.getLabelPlural());

        return result;
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
                    bfConfigItem.FieldType__c = String.valueOf(item.get('FieldType__c'));
                    bfConfigItem.Operator__c = String.valueOf(item.get('Operator__c'));
                    bfConfigItem.Index__c = Integer.valueOf(item.get('Index__c'));

                    configItems.add(bfConfigItem);
                }    
            }
            if (configItems.size() > 0) {
                upsert configItems;            
            }

            BF_Configuration__c config = (BF_Configuration__c)getConfigForRecord(bfConfig.Id, '').get('config');
            result.put('Id', bfConfig.Id);
            result.put('items', config.BF_Configuration_Items__r);
        }catch(Exception ex) {
            result.put('error', ex.getMessage());            
        }
        return result;
    }

    @AuraEnabled 
    public static Map<String, Object> getDataForPreview(String configId) {
        Map<String, Object> data = new Map<String, Object>();
        System.debug('configId: ' + configId);
        if (configId == null) {
            data.put('error', 'No configuration found for Id [' + configId + ']');
            return data;
        }

        BF_Configuration__c bfConfig = [SELECT Id, Name, Source_Object__c, Linked_Object__c, Market__c, Source_Object_Record_Type__c, Source_Object_Record_Id__c, 
                                            (SELECT Id, Name, RecordTypeId, Object__c, FieldName__c, FieldValue__c, Operator__c, Field_List__c, Preview_Field_1__c, Preview_Field_2__c,
                                                    Object_to_Count__c, Field_Name_to_Query__c
                                               FROM BF_Configuration_Items__r)
                                        FROM BF_Configuration__c
                                        WHERE Id=:configId];

        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtPreviewFieldList = rtList.get('Preview Field List').getRecordTypeId();
        String rtFilter = rtList.get('Filter').getRecordTypeId();
        String rtCounter = rtList.get('Counter').getRecordTypeId();
                                
        if (bfConfig == null) {
            data.put('error', 'No configuration found for Id [' + configId + ']');
            return data;
        }

        String[] sObjectTypes = new String[]{bfConfig.Linked_Object__c,bfConfig.Source_Object__c};
        Schema.DescribeSObjectResult[] describeResults = Schema.describeSObjects(sObjectTypes);
        Map<String, Schema.SObjectField> linkedObjectFields = describeResults[0].fields.getMap();
        Map<String, Schema.SObjectField> sourceObjectFields = describeResults[1].fields.getMap();

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
                fieldList = queryDetails.get('fieldList');
                if (String.isEmpty(fieldList)) {
                    fieldList = 'Id,Name';
                }
                query = 'SELECT ' + fieldList + ' FROM ' + bfConfig.Source_Object__c;
                if (queryDetails.containsKey('whereClause')) {
                    query += ' WHERE ' + queryDetails.get('whereClause');
                }
                query += ' LIMIT 1000';

                System.debug('query: ' + query);
                List<SObject> sourceObjectRows = Database.query(query);
                data.put('sourceObjectRows', sourceObjectRows);
                data.put('sourceObjectRowCount', sourceObjectRows == null ? 0 : sourceObjectRows.size());
                
                String fieldApiName = '';
                String fieldType = '';
                List<Map<String, Object>> columns = new List<Map<String, Object>>();
                String[] fieldNames = fieldList.split(',');
                for(String fldName : fieldNames) {
                    System.debug('fldName: ' + fldName);
                    if (fldName != 'Id') {
                        if (sourceObjectFields.containsKey(fldName)) {
                            Schema.DescribeFieldResult dsr = sourceObjectFields.get(fldName).getDescribe();
                            fieldApiName = dsr.getName();
                            fieldType = dsr.getType().name();
                        } else {
                            fieldApiName = fldName;
                            fieldType = 'String';
                        }
    
                        columns.add(new Map<String, Object> {
                            'label' => fldName,
                            'fieldName' => fieldApiName,
                            'type' => fieldType,
                            'sortable' => true,
                            'hideDefaultActions' => true
                        });                    
                    }
                }
                data.put('sourceObjectColumns', columns);
    
            }catch(DmlException ex) {
                errors.add(ex.getMessage());
            }
        }

        fieldList = '';
        queryDetails = buildWhereClause(bfConfig.Linked_Object__c, bfConfig.BF_Configuration_Items__r, rtPreviewFieldList, rtFilter);
        if (queryDetails.containsKey('fieldList')) {
            fieldList = queryDetails.get('fieldList');
            data.put('previewField1', queryDetails.get('previewField1'));
            data.put('previewField2', queryDetails.get('previewField2'));
        }
        if (String.isNotEmpty(fieldList)) {
            if (fieldList.indexOf('Id') < 0) {
                fieldList = 'Id,'+fieldList;
            }
            if (fieldList.indexOf('Name') < 0) {
                fieldList = 'Name,'+fieldList;
            }    
        } else {
            fieldList = 'Id,Name';
        }

        whereClause = '';
        if (queryDetails.containsKey('whereClause')) {
            whereClause = queryDetails.get('whereClause');
        }

        query = 'SELECT ' + fieldList;
        query += ' FROM ' + bfConfig.Linked_Object__c;

        if (linkedObjectFields.containsKey('Market__c')) {
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
            if (String.isNotEmpty(whereClause)) {
                whereClause += 'AND ';
            }
            whereClause += 'Market__c=:marketId';
        }

        System.debug('whereClause: ' + whereClause);
        if (String.isNotEmpty(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        query += ' ORDER BY Name';
        query += ' LIMIT 1000';
        
        System.debug('query: ' + query);
        try {
            List<SObject> rows = Database.query(query);   
            data.put('linkedObjectRows', rows);
            data.put('linkedObjectRowCount', rows.size());

            String fieldApiName = '';
            String fieldType = '';
            List<Map<String, Object>> columns = new List<Map<String, Object>>();
            String[] fieldNames = fieldList.split(',');
            for(String fldName : fieldNames) {
                System.debug('fldName: ' + fldName);
                if (fldName != 'Id') {
                    if (linkedObjectFields.containsKey(fldName)) {
                        Schema.DescribeFieldResult dsr = linkedObjectFields.get(fldName).getDescribe();
                        fieldApiName = dsr.getName();
                        fieldType = dsr.getType().name();
                    } else {
                        fieldApiName = fldName;
                        fieldType = 'String';
                    }

                    columns.add(new Map<String, Object> {
                        'label' => fldName,
                        'fieldName' => fieldApiName,
                        'type' => fieldType,
                        'sortable' => true,
                        'hideDefaultActions' => true
                    });                    
                }
            }
            data.put('linkedObjectColumns', columns);

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
    public static Map<String, Object> getCount(String configId, String sourceRecordId, String objectToCount, String fieldNameToQuery) {
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
            String query = 'SELECT COUNT() FROM ' + objectToCount;
            if (String.isEmpty(sourceRecordId)) {
            } else {
                query += ' WHERE ' + fieldNameToQuery + ' =:idToQuery';
            }
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
    
    @AuraEnabled 
    public static Map<String, Object> saveItemConfiguration(String configId, Map<String, Object> item) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
            //String rtAction = rtList.get('Action').getRecordTypeId();
            //String rtFilter = rtList.get('Linked Object Filter').getRecordTypeId();
            //String rtCounter = rtList.get('Linked Object Counter').getRecordTypeId();

            System.debug('configId: ' + configId);
            System.debug('item: ' + item);
            for(String k : item.keySet()) {
                System.debug('item.'+k+' = ' + item.get(k));
            }
            String itemType = String.valueOf(item.get('itemType'));
            String objectName = String.valueOf(item.get('objectName'));
            Decimal index = Double.valueOf(item.get('index'));
            Boolean isNewItem = true;

            System.debug('itemType:' + itemType);
            System.debug('objectName:' + objectName);
            System.debug('index: ' + index);
            
            BF_Configuration_Item__c configItem = new BF_Configuration_Item__c();
            if (item.containsKey('id') && String.isNotEmpty(String.valueOf(item.get('id')))) {
                configItem.Id = String.valueOf(item.get('id'));
                isNewItem = false;
            }
            System.debug('configItem.Id: ' + configItem.Id);
            System.debug('isNewItem: '+ isNewItem);
            if (isNewItem) {
                configItem.RecordTypeId = rtList.get(itemType).getRecordTypeId();
                configItem.BF_Configuration__c = configId;
            }

            configItem.Index__c = index;
            configItem.Object__c = objectName;
            configItem.Action_Label__c = String.valueOf(item.get('actionLabel'));
            configItem.Action_Type__c = String.valueOf(item.get('actionType'));
            configItem.Action_Class_Name__c = String.valueOf(item.get('actionClassName'));
            configItem.Action_Method_Name__c = String.valueOf(item.get('actionMethodName'));
            configItem.Action_Flow_Name__c = String.valueOf(item.get('actionFlowName'));
            configItem.FieldName__c = String.valueOf(item.get('fieldName'));
            configItem.FieldValue__c = String.valueOf(item.get('fieldValue'));
            configItem.FieldType__c = String.valueOf(item.get('fieldType'));
            configItem.Operator__c = String.valueOf(item.get('operator'));
            configItem.Object_to_Count__c = String.valueOf(item.get('objectToCount'));
            configItem.Counter_Label__c = String.valueOf(item.get('counterLabel'));

            System.debug('configItem: '+ configItem);
            /*
            switch on itemType {
                when 'Action' {
                    if (isNewItem) {
                        configItem.RecordTypeId = rtAction;
                    }

                    configItem.Object__c = objectName;
                    configItem.Action_Type__c = String.valueOf(item.get('actionType'));
                    configItem.Action_Class_Name__c = String.valueOf(item.get('actionClassName'));
                    configItem.Action_Method_Name__c = String.valueOf(item.get('actionMethodName'));
                    configItem.Action_Flow_Name__c = String.valueOf(item.get('actionFlowName'));
                    configItem.Index__c = index;
                }

                when 'Filter' {
                    if (isNewItem) {
                        configItem.RecordTypeId = rtFilter;
                    }

                    configItem.Object__c = objectName;
                    configItem.FieldName__c = String.valueOf(item.get('fieldName'));
                    configItem.FieldValue__c = String.valueOf(item.get('fieldValue'));
                    configItem.Operator__c = String.valueOf(item.get('operator'));
                    configItem.Index__c = index;
                }

                when 'Counter' {
                    if (isNewItem) {
                        configItem.RecordTypeId = rtCounter;
                    }

                    configItem.Object_to_Count__c = objectName;
                    configItem.FieldName__c = String.valueOf(item.get('fieldName'));
                    configItem.Index__c = index;
                }

            }
            */
            upsert configItem;

            item.put('id', configItem.Id);
            System.debug('item: '+ item);
            result.put('status', 'SUCCESS');
            result.put('item', item);
        }catch(Exception ex) {
            result.put('message', ex.getMessage());
            result.put('status', 'ERROR');
        }

        return result;
    }

    @AuraEnabled 
    public static Map<String, Object> callAction(String className, String actionName, String actionType, String bfConfigId, List<Map<String, Object>> selectedItems) {
        /*
        switch on actionType {
            when 'Flow' {

            }
            when 'Apex' {

            }
            when else {

            }
        }
        
        Callable classToCall = (Callable)Type.forName(className).newInstance();
        Map<String, Object> result = classToCall.call(actionName, bfConfigId, selectedItems);

public void callFlow(String flowName, Map <String, Object> inputs) {
  Flow.Interview myFlow = Flow.Interview.createInterview(flowName, inputs);
  myFlow.start();
}        
        */
        Map<String, Object> result = new Map<String, Object>();        
        return result;
    }
}
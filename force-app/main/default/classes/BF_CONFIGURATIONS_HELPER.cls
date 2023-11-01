/**
 * Test Class:  BF_CONFIGUATIONS_HELPER_TEST
 */
public with sharing class BF_CONFIGURATIONS_HELPER {
    public static Set<String> actionsQueue = new Set<String>();

    public static Map<String, Object> findConfigurations(Id sourceObjectRecordId, Id linkedObjectRecordId, String marketId, String recordTypeId, Boolean runActions) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('hasConfigurations', false);

        try {

            Schema.SObjectType sourceObjectType = sourceObjectRecordId.getSobjectType();
            Schema.SObjectType linkedObjectType = linkedObjectRecordId.getSobjectType();

            Schema.DescribeSObjectResult dsrSourceObject = sourceObjectType.getDescribe();
            Schema.DescribeSObjectResult dsrLinkedObject = linkedObjectType.getDescribe();

            String sourceObjectName = dsrSourceObject.getName();
            String linkedObjectName = dsrLinkedObject.getName();
			System.debug('sourceObjectRecordId: ' + sourceObjectRecordId + ', sourceObjectName: ' + sourceObjectName);
            System.debug('linkedObjectRecordId: ' + linkedObjectRecordId + ', linkedObjectName: ' + linkedObjectName);
            String soql = 'SELECT Id, Action_Class_Name__c, Action_Flow_Name__c, Action_Method_Name__c, Action_Type__c, ';
            soql += ' FieldName__c, Object__c, FieldValue__c, Operator__c, Is_Filter__c, Is_Action__c ';
            soql += ' FROM BF_Configuration_Item__c ';
            soql += ' WHERE BF_Configuration__r.Source_Object__c=:sourceObjectName AND BF_Configuration__r.Linked_Object__c=:linkedObjectName';
            if (!String.isEmpty(marketId)) {
                soql += ' AND BF_Configuration__r.Market__c =:marketId';
            }
            if (String.isNotEmpty(recordTypeId)) {
                soql += ' AND (BF_Configuration__r.Source_Object_Record_Type__c =:recordTypeId OR BF_Configuration__r.Source_Object_Record_Type__c = NULL)';
            }
            System.debug('marketId: ' + marketId);
            System.debug('recordTypeId: ' + recordTypeId);
			System.debug('soql : ' + soql);
            List<BF_Configuration_Item__c> configurations = Database.query(soql);
            System.debug('# of configurations found: ' + configurations.size());
            String sourceObjectFieldList = '';
            String sourceObjectWhereClause = '';
            String linkedObjectFieldList = '';
            String linkedObjectWhereClause = '';
            String whereClause = '';
            for(BF_Configuration_Item__c bfci : configurations) {
                System.debug('bfci: ' + bfci);
                if (bfci.Is_Filter__c) {
                    whereClause = bfci.FieldName__c;
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
        
                    if (bfci.Object__c == sourceObjectName) {
                        sourceObjectFieldList += bfci.FieldName__c + ',';
                        sourceObjectWhereClause += whereClause;
                    }
                    if (bfci.Object__c == linkedObjectName) {
                        linkedObjectFieldList += bfci.FieldName__c + ',';
                        linkedObjectWhereClause += whereClause;
                    }
                }
            }
            sourceObjectFieldList = sourceObjectFieldList.removeEnd(',');
            sourceObjectWhereClause = sourceObjectWhereClause.removeEnd('AND ');
            linkedObjectFieldList = linkedObjectFieldList.removeEnd(',');
            linkedObjectWhereClause = linkedObjectWhereClause.removeEnd('AND ');

            if (String.isEmpty(sourceObjectFieldList)) {
                sourceObjectFieldList = 'Id';
            } else if (sourceObjectFieldList.indexOfIgnoreCase('id') < 0) {
                sourceObjectFieldList = 'Id,' + sourceObjectFieldList;
            }
            if (String.isEmpty(linkedObjectFieldList)) {
                linkedObjectFieldList = 'Id';
            } else if (linkedObjectFieldList.indexOfIgnoreCase('id') < 0) {
                linkedObjectFieldList = 'Id,' + linkedObjectFieldList;
            }

            String sourceObjectSOQL = 'SELECT ' + sourceObjectFieldList + ' FROM ' + sourceObjectName + ' WHERE Id =:sourceObjectRecordId AND ' + sourceObjectWhereClause;
            String linkedObjectSOQL = 'SELECT ' + linkedObjectFieldList + ' FROM ' + linkedObjectName + ' WHERE Id =:linkedObjectRecordId AND ' + linkedObjectWhereClause;

            List<SObject> sourceObjectData = Database.query(sourceObjectSOQL);
            List<SObject> linkedObjectData = Database.query(linkedObjectSOQL);

            Boolean matchesCriteria = sourceObjectData != null && sourceObjectData.size() > 0 && linkedObjectData != null && linkedObjectData.size() > 0;
            if (matchesCriteria) {
                result.put('configurations', configurations);
                result.put('hasConfigurations', true);    

                if (runActions) {
                    for(BF_Configuration_Item__c bfci : configurations) {
                        if (bfci.Is_Action__c && !actionsQueue.contains(bfci.Action_Label__c)) {
                            String actionName = bfci.Action_Type__c == 'Flow' ? bfci.Action_Flow_Name__c : bfci.Action_Method_Name__c;
                            actionsQueue.add(bfci.Action_Label__c); 
                            List<String> linkedRecordIds = new List<String>();
                            linkedRecordIds.add(linkedObjectRecordId);
                            Map<String, Object> inputsMap = new Map<String, Object> {
                                'sourceObjectId' => sourceObjectRecordId,
                                'linkedRecordIds' => linkedRecordIds
                            };
                            result.put(bfci.Action_Label__c, BF_CALL_CUSTOM_ACTION.callAction(bfci.Action_Class_Name__c, actionName, bfci.Action_Type__c, bfci.BF_Configuration__c, JSON.serialize(inputsMap)));
                        }
                    }
                }
            }
            
            result.put('status', 'SUCCESS');
        }catch(Exception ex) {
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }

        return result;
    }

    public static Map<String, Object> findConfigurations(String sourceObject, String linkedObject, Map<String, Object> inputs) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            Set<String> marketIds = new Set<String>();
            Set<String> marketNames = new Set<String>();
            Set<String> recordTypeIds = new Set<String>();
            Set<String> sourceObjectRecordIds = new Set<String>();
            String marketId = '';
            String marketName = '';
            String recordTypeId = '';
            String sourceObjectRecordId = '';
            String soql = '';
            if (inputs.containsKey('sourceObjectRecordIds')) {
                sourceObjectRecordIds = (Set<String>)inputs.get('sourceObjectRecordIds');
            } else {
                for(Object o : inputs.values()) {
                    Map<String, Object> inputObject = (Map<String, Object>)o;
                    sourceObjectRecordId = String.valueOf(inputObject.get('sourceObjectRecordId'));
                    if (String.isNotEmpty(sourceObjectRecordId)) {
                        sourceObjectRecordIds.add(sourceObjectRecordId);
                    }
    
                    marketId = String.valueOf(inputObject.get('marketId'));
                    if (String.isNotEmpty(marketId)) {
                        marketIds.add(marketId);
                    }
    
                    marketName = String.valueOf(inputObject.get('marketName'));
                    if (String.isNotEmpty(marketName)) {
                        marketNames.add(marketName);
                    }
    
                    recordTypeId = String.valueOf(inputObject.get('recordTypeId'));
                    if (String.isNotEmpty(recordTypeId)) {
                        recordTypeIds.add(recordTypeId);
                    }
                }       

                if (marketNames.size() > 0) {
                    List<Market__c> markets = [SELECT Id FROM Market__c WHERE Name =:marketNames];
                    for(Market__c m : markets) {
                        marketIds.add(m.Id);
                    }
                }
            }


            if (marketIds.size() == 0 && marketNames.size() == 0 && recordTypeIds.size() == 0) {
                String marketFieldName = '';
                String marketFieldType = 'Lookup';
                String sourceObjectRecordType = '';
                List<BF_Configuration__c> configs = [SELECT Market__c, Source_Object_Market_Field_Name__c, Source_Object_Market_Field_Type__c, Source_Object_Record_Type__c 
                                                        FROM BF_Configuration__c 
                                                        WHERE Source_Object__c=:sourceObject 
                                                          AND Linked_Object__c=:linkedObject
                                                        LIMIT 1];
                if (configs != null && configs.size() > 0) {
                    marketFieldName = configs[0].Source_Object_Market_Field_Name__c;
                    marketFieldType = configs[0].Source_Object_Market_Field_Type__c;    
                    sourceObjectRecordType = configs[0].Source_Object_Record_Type__c;            
                }
    
                soql = '';
                if (String.isNotEmpty(marketFieldName)) {
                    soql = marketFieldName;
                }
                if (String.isNotEmpty(sourceObjectRecordType)) {
                    if (String.isNotEmpty(soql)) {
                        soql += ',';
                    }
                    soql += 'RecordTypeId';
                }
                if (String.isNotEmpty(soql)) {
                    soql = 'SELECT ' + soql + ' FROM ' + sourceObject + ' WHERE Id=:sourceObjectRecordIds';
                    List<SObject> sourceObjectRows = Database.query(soql);
                    for(SObject obj : sourceObjectRows) {
                        if (String.isNotEmpty(marketFieldName)) {
                            if (marketFieldType == 'Lookup') {
                                marketIds.add(String.valueOf(obj.get(marketFieldName)));
                            } else {
                                marketNames.add(String.valueOf(obj.get(marketFieldName)));
                            }
                        }
                        if (String.isNotEmpty(sourceObjectRecordType)) {
                            recordTypeIds.add(String.valueOf(obj.get('RecordTypeId')));
                        }
                    }
                }    
            }
            String endSoql = '';
            String whereClause = '';
            soql = 'SELECT Id, Action_Class_Name__c, Action_Filter__c, Action_Flow_Name__c, Action_Label__c, Action_Method_Name__c, ';
            soql += 'Action_Triggered_By__c, Action_Type__c,';
            soql += 'BF_Configuration__c, FieldName__c, Operator__c, FieldValue__c, RecordTypeId, RecordType.Name, Is_Action__c, Is_Filter__c, ';
            soql += ' BF_Configuration__r.Market__c, BF_Configuration__r.Source_Object_Record_Id__c, BF_Configuration__r.Source_Object_Record_Type__c,';
            soql += ' BF_Configuration__r.Source_Object_Market_Field_Name__c, BF_Configuration__r.Source_Object_Market_Field_Type__c ';
            soql += ' FROM BF_Configuration_Item__c';
            whereClause += ' WHERE BF_Configuration__r.Source_Object__c=:sourceObject';
            whereClause += '   AND BF_Configuration__r.Linked_Object__c=:linkedObject';
            
            if (String.isNotEmpty(sourceObjectRecordId)) {
                whereClause += ' AND BF_Configuration__r.Source_Object_Record_Id__c=:sourceObjectRecordId';
            }
            if (marketIds.size() > 0) {
                whereClause += ' AND (BF_Configuration__r.Market__c=:marketIds';
                endSoql = ')';
            }
            if (marketNames.size() > 0) {
                if (marketIds.size() > 0) {
                    whereClause += ' OR ';
                } else {
                    whereClause += ' AND ';
                }
                whereClause += ' BF_Configuration__r.Market_Name__c=:marketNames';
                endSoql = ')';
            }
            if (recordTypeIds.size() > 0) {
                if (marketIds.size() > 0) {
                    whereClause += ' OR ';
                } else {
                    whereClause += ' AND ';
                }
                whereClause += ' BF_Configuration__r.Source_Object_Record_Type__c =:recordTypeIds';
                endSoql = ')';
            }
            System.debug('soql: ' + soql);

            soql += whereClause + endSoql;
            System.debug('whereClause: ' + whereClause);
            List<BF_Configuration_Item__c> configItems = Database.query(soql);
            
            Set<BF_Configuration_Item__c> items_Market;
            Set<BF_Configuration_Item__c> items_RecordType;
            Set<BF_Configuration_Item__c> items_RecordId;
            Map<String, Set<BF_Configuration_Item__c>> configsByMarket = new Map<String, Set<BF_Configuration_Item__c>>();
            Map<String, Set<BF_Configuration_Item__c>> configsByRecordType = new Map<String, Set<BF_Configuration_Item__c>>();
            Map<String, Set<BF_Configuration_Item__c>> configsByRecordId = new Map<String, Set<BF_Configuration_Item__c>>();
            for(BF_Configuration_Item__c configItem : configItems) {
                if (String.isNotEmpty(configItem.BF_Configuration__r.Market__c)) {
                    if (configsByMarket.containsKey(configItem.BF_Configuration__r.Market__c)) {
                        items_Market = configsByMarket.get(configItem.BF_Configuration__r.Market__c);
                    } else {
                        items_Market = new Set<BF_Configuration_Item__c>();
                    }
                    items_Market.add(configItem);
                    configsByMarket.put(configItem.BF_Configuration__r.Market__c, items_Market);    
                }
                if (String.isNotEmpty(configItem.BF_Configuration__r.Source_Object_Record_Type__c)) {
                    if (configsByRecordType.containsKey(configItem.BF_Configuration__r.Source_Object_Record_Type__c)) {
                        items_RecordType = configsByRecordType.get(configItem.BF_Configuration__r.Source_Object_Record_Type__c);
                    } else {
                        items_RecordType = new Set<BF_Configuration_Item__c>();
                    }
                    items_RecordType.add(configItem);
                    configsByRecordType.put(configItem.BF_Configuration__r.Source_Object_Record_Type__c, items_RecordType);
                }

                if (String.isNotEmpty(configItem.BF_Configuration__r.Source_Object_Record_Id__c)) {
                    sourceObjectRecordId = configItem.BF_Configuration__r.Source_Object_Record_Id__c;
                    if (sourceObjectRecordIds.contains(sourceObjectRecordId)) {
                        if (configsByRecordId.containsKey(sourceObjectRecordId)) {
                            items_RecordId = configsByRecordId.get(sourceObjectRecordId);
                        } else {
                            items_RecordId = new Set<BF_Configuration_Item__c>();
                        }
                        items_RecordId.add(configItem);
                        configsByRecordId.put(sourceObjectRecordId, items_RecordId);
                    }
                }
            }
            
            Map<String, Set<BF_Configuration_Item__c>> itemsById = new Map<String, Set<BF_Configuration_Item__c>>();
            Set<BF_Configuration_Item__c> items;
            for(String key : inputs.keySet()) {
                Map<String, Object> o = (Map<String, Object>)inputs.get(key);
                marketId = String.valueOf(o.get('marketId'));
                marketName = String.valueOf(o.get('marketName'));
                recordTypeId = String.valueOf(o.get('recordTypeId'));
                sourceObjectRecordId = String.valueOf(o.get('sourceObjectRecordId'));
                
                if (itemsById.containsKey(key)) {
                    items = itemsById.get(key);
                } else {
                    items = new Set<BF_Configuration_Item__c>();
                }
                if (configsByMarket.containsKey(marketId)) {
                    items.addAll(configsByMarket.get(marketId));
                }
                if (configsByRecordType.containsKey(recordTypeId)) {
                    items.addAll(configsByRecordType.get(recordTypeId));
                }
                if (configsByRecordId.containsKey(sourceObjectRecordId)) {
                    items.addAll(configsByRecordId.get(sourceObjectRecordId));
                }
                itemsById.put(key, items);
            }

            result.put('status', 'SUCCESS');
            result.put('configurations', itemsById);
            result.put('configurationsByMarket', configsByMarket);
            result.put('configurationsByRecordType', configsByRecordType);
            result.put('configurationsByRecordId', configsByRecordId);        
        }catch(Exception ex) {
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }

        return result;
    }

    public static String buildQueryFromConfigurations(List<BF_Configuration_Item__c> configs, String sourceObjectRecordId) {
        String soql = '';
        String fieldValue = '';
        String operator = '';
        Boolean valuesIsList = false;
        List<String> listValues;

        Map<String, Schema.RecordTypeInfo> rtList = BF_Configuration_Item__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        String rtFilter = rtList.get('Filter').getRecordTypeId();

        for (BF_Configuration_Item__c bfci : configs) {      
            if (bfci.RecordTypeId == rtFilter) {
                if (bfci.Filter_Type__c == 'Value') {
                    fieldValue = bfci.FieldValue__c == null ? '' : bfci.FieldValue__c;
                } else if (bfci.Filter_Type__c == 'Field' && String.isNotEmpty(sourceObjectRecordId)) {
                    fieldValue = getReferencedFieldValue(bfci.Referenced_Object__c, bfci.Referenced_Field__c, sourceObjectRecordId);
                    if (String.isNotEmpty(fieldValue)) {
                        fieldValue = fieldValue.replaceAll(';',',');
                    }
                }
                valuesIsList = fieldValue == null ? false : fieldValue.indexOf(',') > -1;
                if (valuesIsList) {
                    listValues = fieldValue.split(',');
                }

                switch on bfci.Operator__c {
                    when 'starts with' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql += bfci.FieldName__c + ' LIKE \'%' + s + '\' OR ';
                            }
                            soql = soql.removeEnd('OR ');
                            soql += ')';
                        } else {
                            soql += bfci.FieldName__c + ' LIKE \'' + fieldValue + '%\'';
                        }
                    }

                    when 'ends with' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql +=  bfci.FieldName__c + ' LIKE \'%' + s + '\' OR ';
                            }
                            soql = soql.removeEnd('OR ');
                            soql += ')';
                        } else {
                            soql +=  bfci.FieldName__c + ' LIKE \'%' + fieldValue + '\'';
                        }

                    }
                    when 'contains' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql +=  bfci.FieldName__c + ' LIKE \'%' + s + '%\' OR ';
                            }
                            soql = soql.removeEnd('OR ');
                            soql += ')';
                        } else {
                            soql +=  bfci.FieldName__c + ' LIKE \'%' + fieldValue + '%\'';
                        }
                    }
                    when 'notcontains' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql += ' (NOT' +  bfci.FieldName__c + ' LIKE \'%' + s + '%\') AND ';
                            }
                            soql = soql.removeEnd('AND ');
                            soql += ')';
                        } else {
                            soql += ' LIKE \'%' + fieldValue + '\'';
                        }
                    }

                    when 'includes' {
                        soql +=  bfci.FieldName__c + ' INCLUDES (\'' + fieldValue.replaceAll(',','\',\'') + '\')';
                    }
                    when 'notincludes' {
                        soql +=  bfci.FieldName__c + ' EXCLUDES (\'' + fieldValue.replaceAll(',','\'.\'') + '\')';
                    }
                    when 'equals' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql +=  bfci.FieldName__c + ' = \'' + s + '\' OR ';
                            }
                            soql = soql.removeEnd('OR ');
                            soql += ')';
                        } else {
                            if (bfci.FieldType__c == 'Text' || bfci.FieldType__c == 'Date') {
                                soql +=  bfci.FieldName__c + ' = \'' + fieldValue + '\'';
                            } else {
                                soql +=  bfci.FieldName__c + ' = ' + fieldValue;                            
                            }
                        }

                    }

                    when 'notequals' {
                        if (valuesIsList) {
                            soql += '(';
                            for(String s : listValues) {
                                soql +=  bfci.FieldName__c + ' != \'' + s + '\' AND ';
                            }
                            soql = soql.removeEnd('AND ');
                            soql += ')';
                        } else {
                            soql +=  bfci.FieldName__c + ' != \'' + fieldValue + '\'';
                        }
                    }

                    when else {
                        soql +=  bfci.FieldName__c + ' ' + bfci.Operator__c + ' \'' + fieldValue + '\'';
                    }
                }

                soql += ' AND ';

            }      
        }

        soql = soql.removeEnd('AND ');


        return soql;
    }    

    private static String getReferencedFieldValue(String objectName, String fieldName, String recordId) {
        String returnValue = '';
        String soql = 'SELECT ' + fieldName + ' FROM ' + objectName + ' WHERE Id =\'' + recordId + '\'';
        List<SObject> records = Database.query(soql);
        System.debug('record: ' + records);
        if (records != null && records.size() > 0) {
            returnValue = (String)records[0].get(fieldName);
            System.debug('returnValue: ' + returnValue);
        }
        return returnValue;
    }

}
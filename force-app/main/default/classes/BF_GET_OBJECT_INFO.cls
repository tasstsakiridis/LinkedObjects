public with sharing class BF_GET_OBJECT_INFO {
    @AuraEnabled 
    public Map<String, Object> getObjectInfo(String[] objects) {
        Schema.DescribeSObjectResult[] objectInfos = Schema.DescribeSObjectResult(objects);
        Map<String, Object> result = new Map<String, Object>();

        

        return result;
    }
}

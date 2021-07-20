/**
 * Test Class:  LinkedObjectConfig_Controller_Test
 */
public class LinkedObject {
    public string controllingObject                         { get; set; }
    public string linkedObject                              { get; set; }
    public Map<String, String> linkedObjectItemConfigs      { get; set; }
    public Map<String, String> controllingObjectItemConfigs { get; set; }

    public LinkedObject() {
        init();
    }

    public LinkedObject(String controllingObject, String linkedObject) {
        init();

        this.controllingObject = controllingObject;
        this.linkedObject = linkedObject;
         
    }
    void init() {
        this.controllingObject = '';
        this.linkedObject = '';
        this.linkedObjectItemConfigs = new Map<String, String>();
        this.controllingObjectItemConfigs = new Map<String, String>();
    }

    public Boolean recordMatchesCriteria(String theRecordId, Boolean isControllingObject) {
        Boolean doesMatch = true;
        String soql = '';
        if (isControllingObject) {
            for(String s : controllingObjectItemConfigs.keySet()) {
                if (s == 'RecordType') {
                    soql += 'RecordTypeId,';
                } else {
                    soql += s + ',';
                }
            }
        } else {
            for(String s : linkedObjectItemConfigs.keySet()) {
                if (s == 'RecordType') {
                    soql += 'RecordTypeId,';
                } else {
                    soql += s + ',';
                }
            }
        }

        soql = soql.removeEnd(',');
        soql = 'SELECT ' +  soql + ' FROM ' + (isControllingObject ? controllingObject : linkedObject);
        soql += ' WHERE Id = \'' + theRecordId + '\'';
        System.debug('[LinkedObject] soql: ' + soql);
        SObject obj = Database.query(soql);
        if (isControllingObject) {
            String val = '';
            String objVal = '';
            Set<String> listOfCriteria = new Set<String>();
            System.debug('[LinkedObject] controllingObjectItemConfigs: ' + controllingObjectItemConfigs);
            for(String s : controllingObjectItemConfigs.keySet()) {
                System.debug('[LinkedObject] s = ' + s);
                System.debug('[LinkedObject] configs[s] = ' + controllingObjectItemConfigs.get(s));
                if (s == 'RecordType') {
                    System.debug('[LinkedObject] obj[RecordTypeId] = ' + obj.get('RecordTypeId'));
                    Map<String, RecordTypeInfo> mRT = Schema.getGlobalDescribe().get(controllingObject).getDescribe().getRecordTypeInfosByName();
                    System.debug('[LinkedObject] mRT = ' + mRT);
                    if (mRT.containsKey(controllingObjectItemConfigs.get(s))) {
	                    System.debug('[LinkedObject] mRT.id = ' + mRT.get(controllingObjectItemConfigs.get(s)).getRecordTypeId());
                        if (obj.get('RecordTypeId') != mRT.get(controllingObjectItemConfigs.get(s)).getRecordTypeId()) {
                            doesMatch = false; break;
                        }
                    }
                } else {
                    val = controllingObjectItemConfigs.get(s);
                    objVal = obj.get(s).toString();
                    System.debug('[LinkedObject] objVal = ' + objVal);
                    System.debug('[LinkedObject] val = ' + val);
                    if (val.contains(',')) {
                        listOfCriteria.clear();
                        listOfCriteria.addAll(val.split(','));
                        System.debug('[LinkedObject] listOofCriteria = ' + listOfCriteria);
                        System.debug('[LinkedObject] contains val: ' + listOfCriteria.contains(val));

                        if (!listOfCriteria.contains(objVal)) {
                            doesMatch = false; break;
                        }
                    } else {
                        if (objVal != val) {
                            doesMatch = false; break;
                        }
                    }
                }
                /*
                } else if (obj.get(s) != controllingObjectItemConfigs.get(s)) {
                    System.debug('[LinkedObject] obj[s] = ' + obj.get(s));
                    doesMatch = false; break;
                }
                */
            }
        }
 
        return doesMatch;
    }
}
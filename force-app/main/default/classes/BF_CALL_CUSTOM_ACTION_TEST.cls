@isTest
public class BF_CALL_CUSTOM_ACTION_TEST {
    static testMethod void unitTest1() {
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('sourceObjectRecordId', '1234');
        inputs.put('linkedObjectRecordIds', new List<String>());

        // Call Test Apex Class
        Map<String, Object> result = BF_CALL_CUSTOM_ACTION.callAction('BF_CALL_ACTION_TESTCLASS', 'testCallAction', 'apex', '', JSON.serialize(inputs))
        System.assertEquals('SUCCESS', String.valueOf(result.get('status')));

        // Call Test Flow
        result = BF_CALL_CUSTOM_ACTION.callAction('', 'BF_CALL_ACTION_TESTFLOW', 'flow', '', JSON.serialize(inputs));
        System.assertEquals('OK', String.valueOf(result.get('status')));

    }
}
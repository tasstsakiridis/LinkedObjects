/**
 * Test Class:  BF_CALL_CUSTOM_ACTION_TEST
 */
public class BF_CALL_CUSTOM_ACTION {
    @AuraEnabled 
    public static Map<String, Object> callAction(String className, String actionName, String actionType, String bfConfigId, String inputs) {
        Map<String, Object> result = new Map<String, Object>();        
        
        Map<String, Object> inputsMap = (Map<String, Object>)JSON.deserializeUntyped(inputs);

        System.debug('className: ' + className);
        System.debug('actionName: ' + actionName);
        System.debug('actionType: ' + actionType);
        System.debug('configId: ' + bfConfigId);
        System.debug('inputs: ' + inputs);
        switch on actionType {
            when 'Flow' {
                Flow.Interview theFlow = Flow.Interview.createInterview(actionName, inputsMap);
                theFlow.start();
                result.put('status',theFlow.getVariableValue('status'));
                result.put('message', theFlow.getVariableValue('message'));                
            }
            when 'Apex' {
                Callable classToCall = (Callable)Type.forName(className).newInstance();
                Map<String, Object> classResult = (Map<String, Object>)classToCall.call(actionName, inputsMap); 
                if (classResult != null) {
                    result.put('status', classResult.get('status'));
                    result.put('message', classResult.get('message'));
                }       
            }
            when else {

            }
        }
                
        return result;
    }

}

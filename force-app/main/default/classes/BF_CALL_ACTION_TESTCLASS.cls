public class BF_CALL_ACTION_TESTCLASS implements Callable {
    public Object call(String action, Map<String, Object> inputs) {
        System.debug('action: ' + action);
        return new Map<String, Object> {
            'status' => 'SUCCESS'
                };
    }
}
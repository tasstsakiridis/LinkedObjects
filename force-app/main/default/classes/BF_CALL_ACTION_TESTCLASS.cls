public class BF_CALL_ACTION_TESTCLASS implements Callable {
    public static Map<String, Object> testCallAction(Map<String, Object> inputs) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('status', 'SUCCESS');
        result.put('message', 'Processing Done');
        return result;
    }
}

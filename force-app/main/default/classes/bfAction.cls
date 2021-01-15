global interface bfAction {
    /**
     * Input parameters map
     *    actionName : String : required : The name of the method to execute
     * 
     * Output parameters map
     *    status : String :
     *       Values:  OK, ERROR, SUCCESS
     * 
     *    message : String : The exception message
     *    
     */
    Map<String, Object> action(Map<String, Object> params);
}
public class CalculateActionableSegment {
    static String getKey(String key, Map<String, List<Actionable_Segment_Config__c>> configs) {
        String[] parts = key.split('_');
        Integer numberOfParts = parts.size() - 1;

        System.debug('[getKey] key: ' + key);
        System.debug('[getKey] numberOfParts: ' + numberOfParts);
        System.debug('[getKey] parts: ' + parts);

        String returnKey = key;
        Boolean keyFound = false;
        while (!keyFound) {
            System.debug('[getKey] key: ' + key);
            if (configs.containsKey(key)) {
                keyFound = true;
            } else {
                numberOfParts--;
                if (numberOfParts <= 1) { break; }

                for(Integer i = 0; i < numberOfParts; i++) {
                    returnKey += parts[i] + '_';
                }

                returnKey.removeEnd('_');
            }

        }

        return returnKey;
    }

    static Map<String, List<Actionable_Segment_Config__c>> getActionableSegmentConfigs() {
        Map<String, List<Actionable_Segment_Config__c>> m_ActionableSegmentConfig = new Map<String, List<Actionable_Segment_Config__c>>();
        List<Actionable_Segment_Config__c> l_ActionableSegmentConfig = [SELECT Market__c, Dimension__c, Channel__c, Group__c, Point_Value__c, Segment_Value__c, Position__c 
                                                                            FROM Actionable_Segment_Config__c
                                                                        ORDER BY Market__c, Position__c, Point_Value__c DESC];
        List<Actionable_Segment_Config__c> l_SegmentConfigs;
        String key = '';
        for(Actionable_Segment_Config__c segmentConfig : l_ActionableSegmentConfig) {                
            key = segmentConfig.Market__c;
            if (segmentConfig.Channel__c != null && segmentConfig.Channel__c != '')  { key += '_' + segmentConfig.Channel__c; }
            if (segmentConfig.Group__c != null && segmentConfig.Group__c != '') { key += '_' + segmentConfig.Group__c; }
            if (m_ActionableSegmentConfig.containsKey(key)) {
                l_SegmentConfigs = m_ActionableSegmentConfig.get(key);
            } else {
                l_SegmentConfigs = new List<Actionable_Segment_Config__c>();
            }

            l_SegmentConfigs.add(segmentConfig);
            m_ActionableSegmentConfig.put(key, l_SegmentConfigs);
        }

        for(String k : m_ActionableSegmentConfig.keySet()) {
            l_SegmentConfigs = m_ActionableSegmentConfig.get(k);
            System.debug('key: ' + k + ' has ' + l_SegmentConfigs.size() + ' configs');
            for(Actionable_Segment_Config__c a : l_SegmentConfigs) {
                System.debug('['+k+'] Channel: ' + a.Channel__c + ', Dimension: ' + a.Dimension__c + ', Position: ' + a.Position__c + ', Point: ' + a.Point_Value__c + ', SegmentValue: ' + a.Segment_Value__c);
            }
        }

        return m_ActionableSegmentConfig;
    }

    @InvocableMethod
    public static void CalculateActionableSegment(List<Id> surveyTakerIds) {
        List<SurveyTaker__c> l_SurveyTaker = [SELECT Id, Account__c, Survey__c, Account__r.Market__c, Account__r.Channel__c, Account__r.Group__c,
                                                (SELECT Dimension__c, Point_Value__c FROM Survey_Question_Answers__r) 
                                                FROM SurveyTaker__c
                                               WHERE Id =:surveyTakerIds];

        if (l_SurveyTaker.size() > 0) {
            Map<String, List<Actionable_Segment_Config__c>> m_ActionableSegmentConfig = getActionableSegmentConfigs();
            List<Actionable_Segment_Config__c> l_SegmentConfigs;

            Map<String, String> m_Accounts = new Map<String, String>();                    
            Map<String, Integer> m_Segments = new Map<String, Integer>();
            Boolean useSegmentConfig = true;
            String segmentGroup = '';
            String accountGroup = '';
            String key = '';
            for(SurveyTaker__c st : l_SurveyTaker) {
                System.debug('survey Taker Id: ' + st.Id + ', account: ' + st.Account__c + ', market: ' + st.Account__r.Market__c);                
                key = st.Account__r.Market__c;
                if (st.Account__r.Channel__c != null && st.Account__r.Channel__c != '') { key += '_' + st.Account__r.Channel__c; }
                if (st.Account__r.Group__c != null && st.Account__r.Group__c != '') { key += '_' + st.Account__r.Group__c; }
                key = getKey(key, m_ActionableSegmentConfig);
                System.debug('[calcactionablesegment] key: ' + key);
                if (m_ActionableSegmentConfig.containsKey(key)) {
                    l_SegmentConfigs = m_ActionableSegmentConfig.get(key); 
                                                   
                    for(Actionable_Segment_Config__c segmentConfig : l_SegmentConfigs) {
                        useSegmentConfig = true;
                        if (segmentConfig.Channel__c != null && segmentConfig.Channel__c != '' && segmentConfig.Channel__c == st.Account__r.Channel__c) {
                            segmentGroup = segmentConfig.Group__c == null ? '' : segmentConfig.Group__c;
                            accountGroup = st.Account__r.Group__c == null ? '' : st.Account__r.Group__c;
                            if (segmentGroup != accountGroup) { useSegmentConfig = false; }
                        }
                        System.debug('segment config dimension: ' + segmentConfig.Dimension__c);
                        if (useSegmentConfig) {
                            m_Segments.put(segmentConfig.Dimension__c, 0);
                        }
                    }

                    for(SurveyQuestionResponse__c sqr : st.Survey_Question_Answers__r) {
                        if (sqr.Dimension__c != null && m_Segments.containsKey(sqr.Dimension__c)) {
                            Integer p = (Integer)m_Segments.get(sqr.Dimension__c);
                            p += (Integer)sqr.Point_Value__c;
                            m_Segments.put(sqr.Dimension__c, p);
                        }
                    }

                    for(String s : m_Segments.keySet()) {
                        System.debug(s + ' = ' + String.valueOf(m_Segments.get(s)));
                    }
                    Map<String, String> m_ActionableSegment = new Map<String, String>();
                    for(Actionable_Segment_Config__c segmentConfig : l_SegmentConfigs) {
                        if (m_Segments.containsKey(segmentConfig.Dimension__c)) {
                            if (m_Segments.get(segmentConfig.Dimension__c) <= segmentConfig.Point_Value__c) {
                                m_ActionableSegment.put(segmentConfig.Dimension__c, segmentConfig.Segment_Value__c);
                            }
                        }
                    }
                    
                    String actionableSegment = '';
                    for(String s : m_ActionableSegment.values()) {
                        actionableSegment += s + ' ';
                    }
                    System.debug('actionable segment: ' + actionableSegment);
                    if (actionableSegment.length() > 0) { actionableSegment.removeEnd(' '); }
                    m_Accounts.put(st.Account__c, actionableSegment);
                }
            }

            if (m_Accounts.size() > 0) {
                List<Account> l_AccountsToupdate = [SELECT Id, Actionable_Segment__c
                                                    FROM Account 
                                                    WHERE Id =:m_Accounts.keySet()];
                for(Account a : l_AccountsToupdate) {
                    a.Actionable_Segment__c = m_Accounts.get(a.Id);
                }
                update l_AccountsToupdate;
            }
        }
    }
}
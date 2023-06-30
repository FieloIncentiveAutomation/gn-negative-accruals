global class F_BonusBasedStatusBatchScheduler implements Database.Batchable<sobject>, Schedulable {

	 global void execute(SchedulableContext SC){
        Database.executeBatch(new F_BonusBasedStatusBatchScheduler(),100);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM FieloPLT__Member__c WHERE FieloPLT__Status__c = \'Active\' ';

        return Database.getQueryLocator(query);
    }

	global void execute(Database.BatchableContext BC, List<FieloPLT__Member__c> scope) {
        Map<Id, Decimal> membersValueMap = new Map<Id, Decimal>();
        Map<Id, Set<Integer>> memberActiveMonths = new Map<Id, Set<Integer>>();

        Set<Id> memberIdSet = new Map<Id,FieloPLT__Member__c>(scope).keySet();

        String query =
            String.format(
                'SELECT ' +
                    'Id, ' +
                    'FieloPLT__Member__c, ' +
                    'Flexpoint__c, ' +
                    'FieloPLT__Date__c ' +
                'FROM FieloPLT__Transaction__c ' +
                'WHERE ' +
                    'FieloPLT__Date__c = {0} AND ' +
                    'FieloPLT__Type__c != :expirationType AND ' +
                    'FieloPLT__Member__r.F_OptOut__c = false AND ' +
                    'F_Online_Transaction_Type__c = null AND ' +
                    'FieloPLT__Event__r.FieloPLT__Type__c != :bonusEventType AND ' +
                    'FieloPLT__Member__c IN :memberIdSet AND ' +
                    'Flexpoint__c != null',
                new List<String> {
                    (Test.isRunningTest() ? 'THIS_YEAR' : 'LAST_YEAR')
                }
            );

        List<FieloPLT__Transaction__c> listTr =
            (List<FieloPLT__Transaction__c>) Database.queryWithBinds(
                query,
                new Map<String, Object> {
                    'expirationType' => 'Expiration',
                    'bonusEventType' => 'Bonus Based on Status',
                    'memberIdSet' => memberIdSet
                },
                AccessLevel.SYSTEM_MODE
            );

        //Create Map Of Id Members and its Values
        for(FieloPLT__Transaction__c tr : listTr){
            if(membersValueMap.containsKey(tr.FieloPLT__Member__c)){
                membersValueMap.put(tr.FieloPLT__Member__c, membersValueMap.get(tr.FieloPLT__Member__c) + tr.Flexpoint__c);
            }else{
                membersValueMap.put(tr.FieloPLT__Member__c, tr.Flexpoint__c);
            }
            if(tr.FieloPLT__Date__c != null){
                if(memberActiveMonths.containsKey(tr.FieloPLT__Member__c)){
                    Set<Integer> activeMonths = memberActiveMonths.get(tr.FieloPLT__Member__c);
                    activeMonths.add(tr.FieloPLT__Date__c.month());
                    memberActiveMonths.put(tr.FieloPLT__Member__c, activeMonths);
                }else{
                    memberActiveMonths.put(tr.FieloPLT__Member__c, new Set<Integer>{tr.FieloPLT__Date__c.month()});
                }
            }
        }
        //Create Events
        List<FieloPLT__Event__c> events = new List<FieloPLT__Event__c>();
        for(Id memberId : membersValueMap.keySet()){
            if (membersValueMap.get(memberId).setScale(2) < 0.00) membersValueMap.put(memberId, 0.00);

            events.add(new FieloPLT__Event__c(FieloPLT__Member__c = memberId,  FieloPLT__Type__c= 'Bonus Based on Status', FieloPLT__Value__c = membersValueMap.get(memberId)));
            /* Deactivated per business request
            if(memberActiveMonths.containsKey(memberId)){
                events.add(new FieloPLT__Event__c(FieloPLT__Member__c = memberId,  FieloPLT__Type__c= 'Active Months Bonus', FieloPLT__Value__c = membersValueMap.get(memberId), F_ActiveMonths__c = (memberActiveMonths.get(memberId)).size()));
            }*/
        }
		insert events;
    }

    global void finish(Database.BatchableContext bc){}



}
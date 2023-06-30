public with sharing class Fielo_Points {

    public static Fielo_SObjectSelector selectorInstance {get{
        if (selectorInstance == null) {
            selectorInstance = new Fielo_SObjectSelector();
        }
        return selectorInstance;
    } set; }

    public static DescribeSObjectResult memberObjectDescribe {get {
        if (memberObjectDescribe == null) {
            memberObjectDescribe = SObjectType.FieloPLT__Member__c;
        }
        return memberObjectDescribe;
    } set; }

    public static Map<String, SObjectField> memberFieldsMap {get {
        if (memberFieldsMap == null) {
            memberFieldsMap = memberObjectDescribe.fields.getMap();
        }
        return memberFieldsMap;
    } set; }

    public static Set<Id> approvedIds = new Set<Id>();

    public static void onBeforeInsert(List<FieloPLT__Point__c> records) {
        List<FieloPLT__Point__c> positiveAccruals = new List<FieloPLT__Point__c>();
        for (FieloPLT__Point__c record : records) {
            if ( record.FieloPLT__Status__c == 'Approved') {
                if ( !isLessThanZero(record) && isMemberBalanceNegative(record) ) {
                    Decimal oldBalance = record.FieloPLT__MemberBalance__c - record.FieloPLT__TotalPoints__c; // 100
                    Decimal usedPoints =
                        Math.abs(oldBalance) > record.FieloPLT__TotalPoints__c ?
                            record.FieloPLT__TotalPoints__c :
                            Math.abs(oldBalance);
                    record.FieloPLT__UsedPoints__c = usedPoints;

                    System.debug(
                        'newBalance: ' + record.FieloPLT__MemberBalance__c +
                        ' oldBalance: ' + oldBalance +
                        ' totalPoints: ' + record.FieloPLT__TotalPoints__c +
                        ' usedPoints: ' + usedPoints
                    );
                }
            }
        }
    }

    public static void onAfterInsert(List<FieloPLT__Point__c> records) {
        List<FieloPLT__Point__c> negativeAccruals = new List<FieloPLT__Point__c>();
        Set<Id> memberIds = new Set<Id>();

        for (FieloPLT__Point__c record : records) {
            if ( record.FieloPLT__Status__c == 'Approved') {
                if ( isAccrual(record) && isLessThanZero(record) ) {
                    negativeAccruals.add(record);
                }
                memberIds.add(record.FieloPLT__Member__c);
            }
        }

        if (!memberIds.isEmpty()) {
            Map<Id, FieloPLT__PointType__c> currenciesMap = Fielo_CurrencyService.currenciesMap;

            Map<Id, FieloPLT__Member__c> membersMap =
                new Map<Id, FieloPLT__Member__c>(
                    (List<FieloPLT__Member__c>) selectorInstance.getRecords(
                        'FieloPLT__Member__c',
                        getMemberFields(currenciesMap),
                        new Map<String, String>{'Id' => ':recordIds'},
                        new Map<String, Object>{'recordIds' => memberIds},
                        AccessLevel.SYSTEM_MODE
                    )
                );

            if (!negativeAccruals.isEmpty()) {
                Fielo_PointService.usePoints(negativeAccruals, membersMap);
            }
        }
    }

    public static void onBeforeUpdate(List<FieloPLT__Point__c> records, Map<Id, FieloPLT__Point__c> existingRecords) {
        List<FieloPLT__Point__c> positiveAccruals = new List<FieloPLT__Point__c>();
        Set<Id> memberIds = new Set<Id>();

        for (FieloPLT__Point__c record : records) {
            FieloPLT__Point__c oldRecord = existingRecords.get(record.Id);
            System.debug(
                JSON.serializePretty(
                    new Map<String, Object> {
                        'Id' => record.Id,
                        'Status' => record.FieloPLT__Status__c,
                        'OldStatus' => oldRecord.FieloPLT__Status__c,
                        'MemberBalance' => record.FieloPLT__MemberBalance__c,
                        'TotalPoints' => record.FieloPLT__TotalPoints__c
                    }
                )
            );
            if ( record.FieloPLT__Status__c == 'Approved') {
                if ( !isLessThanZero(record) &&
                isMemberBalanceNegative(record) &&
                approvedIds.contains(record.Id) &&
                record.FieloPLT__MemberBalance__c != oldRecord.FieloPLT__MemberBalance__c
                ) {
                    approvedIds.remove(record.Id);
                    Decimal oldBalance = record.FieloPLT__MemberBalance__c - record.FieloPLT__TotalPoints__c;
                    Decimal usedPoints =
                        Math.abs(oldBalance) > record.FieloPLT__TotalPoints__c ?
                            record.FieloPLT__TotalPoints__c :
                            Math.abs(oldBalance);
                    record.FieloPLT__UsedPoints__c = usedPoints;
                }
                if (oldRecord.FieloPLT__Status__c != 'Approved') {
                    approvedIds.add(record.Id);
                }
            }
        }
    }

    /* public static void onAfterUpdate(List<FieloPLT__Point__c> records, Map<Id, FieloPLT__Point__c> existingRecords) {
        List<FieloPLT__Point__c> negativeAccruals = new List<FieloPLT__Point__c>();
        Set<Id> memberIds = new Set<Id>();

        for (FieloPLT__Point__c record : records) {
            FieloPLT__Point__c oldRecord = existingRecords.get(record.Id);
            if ( record.FieloPLT__Status__c == 'Approved' && oldRecord.FieloPLT__Status__c != 'Approved') {
                if ( isAccrual(record) && isLessThanZero(record) ) {
                    negativeAccruals.add(record);
                }
                memberIds.add(record.FieloPLT__Member__c);
            }
        }

        if (!memberIds.isEmpty()) {
            Map<Id, FieloPLT__PointType__c> currenciesMap = Fielo_CurrencyService.currenciesMap;

            Map<Id, FieloPLT__Member__c> membersMap =
                new Map<Id, FieloPLT__Member__c>(
                    (List<FieloPLT__Member__c>) selectorInstance.getRecords(
                        'FieloPLT__Member__c',
                        getMemberFields(currenciesMap),
                        new Map<String, String>{'Id' => ':recordIds'},
                        new Map<String, Object>{'recordIds' => memberIds},
                        AccessLevel.SYSTEM_MODE
                    )
                );

            if (!negativeAccruals.isEmpty()) {
                Fielo_PointService.usePoints(negativeAccruals, membersMap);
            }
        }
    } */

    public static boolean isAccrual(FieloPLT__Point__c record) {
        return record.FieloPLT__Rule__c != null ||
            record.FieloPLT__ChallengeReward__c != null;
    }

    public static boolean isLessThanZero(FieloPLT__Point__c record) {
        return record?.FieloPLT__TotalPoints__c != null ?
            record?.FieloPLT__TotalPoints__c?.setScale(3) < (0.00).setScale(3) :
            false;
    }

    public static Boolean isMemberBalanceNegative(FieloPLT__Point__c record) {
        return (record.FieloPLT__MemberBalance__c - record.FieloPLT__TotalPoints__c).setScale(3) < (0.00).setScale(3);
    }

    public static Set<String> getMemberFields(Map<Id, FieloPLT__PointType__c> currenciesMap) {
        Set<String> memberFields = new Set<String>{
            'FieloPLT__Program__c'
        };

        for (FieloPLT__PointType__c curr : currenciesMap.values()) {
            memberFields.add(curr.FieloPLT__MemberBalanceField__c);
        }

        return memberFields;
    }
}
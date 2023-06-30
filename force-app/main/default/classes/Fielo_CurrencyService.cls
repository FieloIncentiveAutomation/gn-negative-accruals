public with sharing class Fielo_CurrencyService {

    public static Fielo_SObjectSelector selectorInstance {get{
        if (selectorInstance == null) {
            selectorInstance = new Fielo_SObjectSelector();
        }
        return selectorInstance;
    } set; }

    public static Map<Id, FieloPLT__PointType__c> currenciesMap { get{
        if (currenciesMap == null) {
            currenciesMap = getCurrencies();
        }
        return currenciesMap;
    } set;}

    public static Map<Id, FieloPLT__PointType__c> getCurrencies() {
        String path = 'FieloPLT.Settings.CURRENCIES';

        Map<Id, FieloPLT__PointType__c> currenciesMap =
            (Map<Id, FieloPLT__PointType__c>) Cache.Org.get(path + 'currenciesMap');

        if(currenciesMap == null) {
            return new Map<Id, FieloPLT__PointType__c>(
                (List<FieloPLT__PointType__c>) selectorInstance.getRecords(
                    'FieloPLT__PointType__c',
                    new Map<String, String>{'FieloPLT__Status__c' => ':status'},
                    new Map<String, Object>{'status' => 'Active'},
                    AccessLevel.SYSTEM_MODE
                )
            );
        }
        return currenciesMap;
    }

}
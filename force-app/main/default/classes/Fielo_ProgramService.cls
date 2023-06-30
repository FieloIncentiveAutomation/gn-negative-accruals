public with sharing class Fielo_ProgramService {

    public static Fielo_SObjectSelector selectorInstance {get{
        if (selectorInstance == null) {
            selectorInstance = new Fielo_SObjectSelector();
        }
        return selectorInstance;
    } set; }

    public static Map<String, Object> programInfo {get{
        if (programInfo == null) {
            programInfo = getProgramCurrencies();
        }
        return programInfo;
    } set;}

    public static Map<Id, Map<Id, FieloPLT__ProgramPointType__c>> programCurrenciesMap {get{
        if (programCurrenciesMap == null) {
            programCurrenciesMap = (Map<Id, Map<Id, FieloPLT__ProgramPointType__c>>) programInfo.get('programCurrenciesMap');
        }
        return programCurrenciesMap;
    } set;}

    public static Map<Id, Map<Id, Id>> programCurrenciesByCurrency {get{
        if (programCurrenciesByCurrency == null) {
            programCurrenciesByCurrency = (Map<Id, Map<Id, Id>>) programInfo.get('programCurrenciesByCurrency');
        }
        return programCurrenciesByCurrency;
    } set;}

    public static Map<String, Object> getProgramCurrencies() {
        String path = 'FieloPLT.Settings.PROGRAMS';

        Map<Id, Map<Id, FieloPLT__ProgramPointType__c>> programCurrenciesMap =
            (Map<Id, Map<Id, FieloPLT__ProgramPointType__c>>) Cache.Org.get(path + 'programCurrenciesMap');
        Map<Id, Map<Id, Id>> programCurrenciesByCurrency =
            (Map<Id, Map<Id, Id>>) Cache.Org.get(path + 'programCurrenciesByCurrency');

        if(programCurrenciesMap == null || programCurrenciesByCurrency == null) {
            programCurrenciesMap = new Map<Id, Map<Id, FieloPLT__ProgramPointType__c>>();
            programCurrenciesByCurrency = new Map<Id, Map<Id, Id>>();

            for (FieloPLT__ProgramPointType__c ppt : (List<FieloPLT__ProgramPointType__c>) selectorInstance.getRecords(
                    'FieloPLT__ProgramPointType__c',
                    new Map<String, String>{'FieloPLT__PointType__r.FieloPLT__Status__c' => ':status'},
                    new Map<String, Object>{'status' => 'Active'},
                    AccessLevel.SYSTEM_MODE
                )
            ) {
                if (programCurrenciesMap.containsKey(ppt.FieloPLT__Program__c)) {
                    programCurrenciesMap.get(ppt.FieloPLT__Program__c).put(ppt.Id, ppt);
                } else {
                    programCurrenciesMap.put(ppt.FieloPLT__Program__c, new Map<Id, FieloPLT__ProgramPointType__c>{ppt.Id => ppt});
                }
                if (programCurrenciesByCurrency.containsKey(ppt.FieloPLT__Program__c)) {
                    programCurrenciesByCurrency.get(ppt.FieloPLT__Program__c).put(ppt.FieloPLT__PointType__c, ppt.Id);
                } else {
                    programCurrenciesByCurrency.put(ppt.FieloPLT__Program__c, new Map<Id, Id>{ppt.FieloPLT__PointType__c => ppt.Id});
                }
            }
        }
        return new Map<String, Object> {
            'programCurrenciesMap' => programCurrenciesMap,
            'programCurrenciesByCurrency' => programCurrenciesByCurrency
        };
    }

}
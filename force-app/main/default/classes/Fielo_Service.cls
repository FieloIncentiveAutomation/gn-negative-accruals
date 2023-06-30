public with sharing class Fielo_Service {
    public static void setStaticVariables() {
        Fielo_CurrencyService.selectorInstance = null;
        Fielo_CurrencyService.currenciesMap = null;
        Fielo_ProgramService.selectorInstance = null;
        Fielo_ProgramService.programInfo = null;
        Fielo_ProgramService.programCurrenciesMap = null;
        Fielo_ProgramService.programCurrenciesByCurrency = null;
        Fielo_Points.approvedIds = new Set<Id>();
    }
}
public with sharing class Fielo_PointService {

    public static void usePoints(List<FieloPLT__Point__c> points, Map<Id, FieloPLT__Member__c> membersMap) {

        Map<Id, FieloPLT__PointType__c> currenciesMap = Fielo_CurrencyService.currenciesMap;
        Map<Id, Map<Id, FieloPLT__ProgramPointType__c>> programCurrenciesMap = Fielo_ProgramService.programCurrenciesMap;
        Map<Id, Map<Id, Id>> programCurrenciesByCurrency = Fielo_ProgramService.programCurrenciesByCurrency;

        Map<Id,Map<Id,List<FieloPLT__Point__c>>> membersPoints = new Map<Id,Map<Id,List<FieloPLT__Point__c>>>();
        Map<Id, Map<Id, Decimal>> pointsToUseByCurrency = new Map<Id, Map<Id, Decimal>>();
        Map<Id, Map<Id, List<FieloPLT__Point__c>>> pointRecordsToUseByCurrency = new Map<Id, Map<Id, List<FieloPLT__Point__c>>>();
        List<FieloPLT__PointsUsage__c> poinstAudit = new List<FieloPLT__PointsUsage__c>();
        Map<Id, FieloPLT__Point__c> pointsToUpdate = new Map<Id, FieloPLT__Point__c>();

        for (FieloPLT__Point__c p : points) {
            if (pointsToUseByCurrency.get(p.FieloPLT__Member__c)?.get(p.FieloPLT__PointType__c) != null ) {
                pointsToUseByCurrency.get(p.FieloPLT__Member__c)?.put(p.FieloPLT__PointType__c, pointsToUseByCurrency.get(p.FieloPLT__Member__c).get(p.FieloPLT__PointType__c) + p.FieloPLT__TotalPoints__c);
            } else if (pointsToUseByCurrency.get(p.FieloPLT__Member__c) != null) {
                pointsToUseByCurrency.get(p.FieloPLT__Member__c)?.put(p.FieloPLT__PointType__c, p.FieloPLT__TotalPoints__c);
            } else {
                pointsToUseByCurrency.put(p.FieloPLT__Member__c, new Map<Id, Decimal>{p.FieloPLT__PointType__c =>  p.FieloPLT__TotalPoints__c});
            }

            if (pointRecordsToUseByCurrency.get(p.FieloPLT__Member__c)?.get(p.FieloPLT__PointType__c) != null ) {
                pointRecordsToUseByCurrency.get(p.FieloPLT__Member__c).get(p.FieloPLT__PointType__c).add(p);
            } else if (pointRecordsToUseByCurrency.get(p.FieloPLT__Member__c) != null) {
                pointRecordsToUseByCurrency.get(p.FieloPLT__Member__c)?.put(p.FieloPLT__PointType__c, new List<FieloPLT__Point__c>{p});
            } else {
                pointRecordsToUseByCurrency.put(p.FieloPLT__Member__c, new Map<Id, List<FieloPLT__Point__c>>{p.FieloPLT__PointType__c => new List<FieloPLT__Point__c>{p}});
            }
        }

        System.debug(
            'pointsToUseByCurrency: ' + JSON.serializePretty(pointsToUseByCurrency)
        );

        Set<Id> memberIds = membersMap.keySet();

        String query =
            'SELECT ' +
                'FieloPLT__TotalPoints__c, ' +
                'FieloPLT__UsedPoints__c, ' +
                'FieloPLT__ExpiredPoints__c, ' +
                'FieloPLT__ExpirationDate__c, ' +
                'FieloPLT__Member__c, ' +
                'FieloPLT__PointType__c ' +
            'FROM FieloPLT__Point__c ' +
            'WHERE (' +
                    'FieloPLT__Transaction__c != null OR ' +
                    'FieloPLT__Redemption__c != null '+
                ') AND ' +
                'FieloPLT__Balance__c > 0 ' +
                'AND FieloPLT__Status__c = \'Approved\' ' +
                'AND FieloPLT__Member__c IN: memberIds ' +
            'ORDER BY ' +
                'FieloPLT__ExpirationDate__c ASC NULLS LAST, ' +
                'CreatedDate, ' +
                'Id';

        //look for all the points records related to the members and group them by member
        for(FieloPLT__Point__c p : (List<FieloPLT__Point__c>) Database.query(query)){
            processPoints(membersPoints, p);
        }

        FieloPLT__PointType__c curr;
        FieloPLT__ProgramPointType__c programCurrency;
        Id programId, programCurrencyId;

        for (Id memberId : pointsToUseByCurrency.keySet()) {
            programId = membersMap.get(memberId).FieloPLT__Program__c;
            if (membersPoints.containsKey(memberId)) {
                for (Id currencyId : pointsToUseByCurrency.get(memberId).keySet()) {
                    curr = currenciesMap.get(currencyId);
                    programCurrencyId = programCurrenciesByCurrency.get(programId).get(currencyId);
                    programCurrency = programCurrenciesMap.get(programId).get(programCurrencyId);

                    if (membersPoints.get(memberId).containsKey(currencyId)) {

                        //bring the points of the member
                        List<FieloPLT__Point__c> pointList = membersPoints.get(memberId).get(currencyId);

                        for(FieloPLT__Point__c negativePoint : pointRecordsToUseByCurrency.get(memberId).get(currencyId)) {
                            Double pointsToSubstract = -(negativePoint.FieloPLT__TotalPoints__c);

                            //loop the list of points until all the required points are used
                            while(pointsToSubstract > 0 && pointList != null && !pointList.isEmpty()){
                                FieloPLT__Point__c point = pointList.get(0);
                                //If still have points available
                                if(point.FieloPLT__UsedPoints__c == null)
                                    point.FieloPLT__UsedPoints__c = 0;
                                if(point.FieloPLT__UsedPoints__c < point.FieloPLT__TotalPoints__c){
                                    Decimal pointsUsed = 0;
                                    //If one record of points is enough
                                    if( (point.FieloPLT__TotalPoints__c - point.FieloPLT__UsedPoints__c) > pointsToSubstract ){
                                        point.FieloPLT__UsedPoints__c += pointsToSubstract;
                                        pointsUsed = pointsToSubstract;
                                        pointsToSubstract = 0;
                                    } else {
                                        pointsToSubstract -= point.FieloPLT__TotalPoints__c - point.FieloPLT__UsedPoints__c;
                                        pointsUsed = point.FieloPLT__TotalPoints__c - point.FieloPLT__UsedPoints__c;
                                        point.FieloPLT__UsedPoints__c = point.FieloPLT__TotalPoints__c;
                                        pointList.remove(0);
                                    }
                                    if(programCurrency.FieloPLT__AuditPoints__c){
                                        poinstAudit.add(
                                            new FieloPLT__PointsUsage__c(
                                                FieloPLT__Quantity__c = pointsUsed,
                                                FieloPLT__PointsSource__c = point.Id,
                                                FieloPLT__UsedPoints__c = negativePoint.Id
                                            )
                                        );
                                    }
                                }
                                pointsToUpdate.put(point.Id,point);
                            }
                        }
                    }
                }
            }
        }

        if (!pointsToUpdate.isEmpty()) {
            update pointsToUpdate.values();
        }
    }

    private static void processPoints(Map<Id,Map<Id,List<FieloPLT__Point__c>>> membersPoints, FieloPLT__Point__c point){
        if(membersPoints.containsKey(point.FieloPLT__Member__c)){
            if(membersPoints.get(point.FieloPLT__Member__c).containsKey(point.FieloPLT__PointType__c)){
                membersPoints.get(point.FieloPLT__Member__c).get(point.FieloPLT__PointType__c).add(point);
            }else{
                membersPoints.get(point.FieloPLT__Member__c).put(point.FieloPLT__PointType__c, new List<FieloPLT__Point__c>{point});
            }
        } else {
            Map<Id,List<FieloPLT__Point__c>> pointsMap = new Map<Id,List<FieloPLT__Point__c>>{point.FieloPLT__PointType__c => new List<FieloPLT__Point__c>{point}};
            membersPoints.put(point.FieloPLT__Member__c, pointsMap);
        }
    }
}
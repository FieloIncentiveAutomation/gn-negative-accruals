@isTest
public with sharing class TestNegativeAccruals {
    public static FieloPLT__Program__c program;
    public static FieloPLT__RuleTrigger__c rt;
    public static FieloPLT__Action__c action;
    public static List<FieloPLT__Promotion__c> promotions;
    public static List<FieloPLT__Rule__c> rules;
    public static List<FieloPLT__Member__c> members;

    static {
        FieloPLT.CacheAPI.enableOnDemand(false);
        FieloPLT.CacheAPI.enableCacheAccess(false);

        FieloPLT.SObjectService.enableAdminPermission(true);
        insert F_SObjectForTest.createFlexpointCurrency();
        FieloPLT.SObjectService.enableAdminPermission(false);

        program = F_SObjectForTest.createPrograms('Program', 1)[0];
        insert program;

        rt = F_SObjectForTest.createRuleTrigger('Event', 'FieloPLT__Event__c', 'CreatedDate', 'FieloPLT__Event__c', 'FieloPLT__Event__c', 'FieloPLT__Event__c');
        insert rt;

        action = F_SObjectForTest.createAction('FieloPLT__Member__c', null, null, rt.Id);
        insert action;

        promotions = F_SObjectForTest.createPromotions('TestPromotion', 1, program.Id);
        insert promotions;

        rules = F_SObjectForTest.createRules('Rule ', 1, program.Id);
        rules.get(0).FieloPLT__Type__c = 'No Competition';
        rules.get(0).FlexpointConversionMode__c = 'Multiplier';
        rules.get(0).FlexpointConversionValue__c = 1;
        rules.get(0).FlexpointFieldName__c = 'FieloPLT__Value__c';
        rules.get(0).FieloPLT__Action__c = action.Id;
        rules.get(0).FieloPLT__Promotion__c = promotions.get(0).Id;
        rules.get(0).FieloPLT__RelatedList__c = 'FieloPLT__Event__c';
        insert rules;

        promotions.get(0).FieloPLT__Status__c = 'Active';
        update promotions;

        members =  F_SObjectForTest.createIndividualAccounts('testMember', 1, program.Id);
        insert members;
        FieloPLT.CacheAPI.enableOnDemand(true);
        FieloPLT.CacheAPI.enableCacheAccess(true);
    }

    /**
     * Case A: Not Earmarked correctly
     */
    @istest
    static void caseA() {
        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(250, members.get(0).Flexpoint__c, 'Member should have 250 points left');

        List<FieloPLT__Point__c> points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(250, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(250, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
    }

    /**
     * Case A: Not Earmarked correctly
     */
    @istest
    static void caseA_WithApproval() {
        FieloPLT__ProgramPointType__c ppt =
            Fielo_ProgramService.programCurrenciesMap.get(program.Id).values().get(0);
        ppt.FieloPLT__RequestPointApproval__c = true;
        update ppt;

        Fielo_Service.setStaticVariables();

        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(0, members.get(0).Flexpoint__c, 'Member should have 0 points');

        List<FieloPLT__Point__c> points = [
            SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
            FROM FieloPLT__Point__c
            WHERE FieloPLT__Member__c = :members.get(0).Id
            ORDER BY CreatedDate, Id
        ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c);
        Assert.areEqual(  0, points.get(0).FieloPLT__UsedPoints__c);
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c);
        Assert.areEqual(  0, points.get(0).FieloPLT__MemberBalance__c);

        Assert.areEqual(-250, points.get(1).FieloPLT__TotalPoints__c);
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c);
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c);
        Assert.areEqual(   0, points.get(1).FieloPLT__MemberBalance__c);

        update new List<FieloPLT__Point__c> {
            new FieloPLT__Point__c(
                Id = points.get(0).Id,
                FieloPLT__Status__c = 'Approved'
            ),
            new FieloPLT__Point__c(
                Id = points.get(1).Id,
                FieloPLT__Status__c = 'Approved'
            )
        };

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(250, members.get(0).Flexpoint__c, 'Member should have 250 points left');

        points = [
            SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c
            FROM FieloPLT__Point__c
            WHERE FieloPLT__Member__c = :members.get(0).Id
            ORDER BY CreatedDate, Id
        ];

        Assert.areEqual(250, members.get(0).Flexpoint__c, 'Member should have 250 points left');
        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(250, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(250, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
    }


    /**
     * Case B: Not earmarked correctly + spent
     */
    @istest
    static void caseB() {
        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 300
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(50, members.get(0).Flexpoint__c, 'Member should have 250 points left');

        List<FieloPLT__Point__c> points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-500, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(-250, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual(300, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual(250, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual( 50, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual( 50, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');
    }

    /**
     * Case B: Not earmarked correctly + spent
     */
    @istest
    static void caseB_WithApproval() {
        FieloPLT__ProgramPointType__c ppt =
            Fielo_ProgramService.programCurrenciesMap.get(program.Id).values().get(0);
        ppt.FieloPLT__RequestPointApproval__c = true;
        update ppt;

        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 300
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(0, members.get(0).Flexpoint__c, 'Member should have 0 points left');

        List<FieloPLT__Point__c> points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        List<FieloPLT__Point__c> updPoints = new List<FieloPLT__Point__c>();
        for (FieloPLT__Point__c p : points) {
            updPoints.add(
                new FieloPLT__Point__c(
                    Id = p.Id,
                    FieloPLT__Status__c = 'Approved'
                )
            );
        }

        update updPoints;

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(50, members.get(0).Flexpoint__c, 'Member should have 250 points left');

        points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-500, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(-250, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual(300, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual(250, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual( 50, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual( 50, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');
    }

    /**
     * Case B: Not earmarked correctly + spent
     */
    @istest
    static void caseB_2() {
        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new List<FieloPLT__Event__c> {
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 150
                ),
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 150
                )
            };

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -50
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(0, members.get(0).Flexpoint__c, 'Member should have 250 points left');

        List<FieloPLT__Point__c> points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-500, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(-250, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual( 150, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual( 150, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(   0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(   0, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual(-100, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');

        Assert.areEqual(150, points.get(4).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #5');
        Assert.areEqual(150, points.get(4).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #5');
        Assert.areEqual(  0, points.get(4).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #5');
        Assert.areEqual(  0, points.get(4).FieloPLT__Balance__c, 'Wrong Balance for Point #5');
        Assert.areEqual( 50, points.get(4).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #5');

        Assert.areEqual(-50, points.get(5).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__Balance__c, 'Wrong Balance for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #6');
    }

    /**
     * Case B: Not earmarked correctly + spent
     */
    @istest
    static void caseB_2_WithApproval() {
        FieloPLT__ProgramPointType__c ppt =
            Fielo_ProgramService.programCurrenciesMap.get(program.Id).values().get(0);
        ppt.FieloPLT__RequestPointApproval__c = true;
        update ppt;

        Test.startTest();
            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -500
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            FieloPLT.SObjectService.setStaticVariables();

            insert new List<FieloPLT__Event__c> {
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 150
                ),
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 150
                )
            };

            FieloPLT.SObjectService.setStaticVariables();

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -50
            );
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(0, members.get(0).Flexpoint__c, 'Member should have 0 points left');

        List<FieloPLT__Point__c> points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        List<FieloPLT__Point__c> updPoints = new List<FieloPLT__Point__c>();
        for (FieloPLT__Point__c p : points) {
            updPoints.add(
                new FieloPLT__Point__c(
                    Id = p.Id,
                    FieloPLT__Status__c = 'Approved'
                )
            );
        }
        FieloPLT__Point__c redeem = updPoints.remove(updPoints.size()-1);
        update updPoints;
        update redeem;

        points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(0, members.get(0).Flexpoint__c, 'Member should have 0 points left');

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-500, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(-250, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual( 150, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual( 150, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(   0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(   0, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual(-100, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');

        Assert.areEqual(150, points.get(4).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #5');
        Assert.areEqual(150, points.get(4).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #5');
        Assert.areEqual(  0, points.get(4).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #5');
        Assert.areEqual(  0, points.get(4).FieloPLT__Balance__c, 'Wrong Balance for Point #5');
        Assert.areEqual( 50, points.get(4).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #5');

        Assert.areEqual(-50, points.get(5).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__Balance__c, 'Wrong Balance for Point #6');
        Assert.areEqual(  0, points.get(5).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #6');
    }

    /**
     * Case C: Wrong Expiration
     */
    @isTest
    static void caseC() {
        Test.startTest();
            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -250
            );

            insert new List<FieloPLT__Event__c> {
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 300
                )
            };
            List<FieloPLT__Point__c> points =
                [
                    SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                    FROM FieloPLT__Point__c
                    WHERE FieloPLT__Member__c = :members.get(0).Id
                    ORDER BY CreatedDate, Id
                ];

            Date expDate = date.today().addDays(-1);
            update new FieloPLT__Point__c(
                Id = points.get(0).Id,
                FieloPLT__ExpirationDate__c = expDate,
                FieloPLT__ExpirationDateCheck__c = DateTime.newInstance(expDate.year(), expDate.month(), expDate.day()).format('yyyyMMdd')
            );

            Database.executeBatch(new FieloPLT.PointsPartialExpirationBatchSchedule());
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(300, members.get(0).Flexpoint__c, 'Member should have 0 points left');

        points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-250, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual( 250, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual(300, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(300, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual(300, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');
    }

    /**
     * Case C: Wrong Expiration
     */
    @isTest
    static void caseC_WithApproval() {
        FieloPLT__ProgramPointType__c ppt =
            Fielo_ProgramService.programCurrenciesMap.get(program.Id).values().get(0);
        ppt.FieloPLT__RequestPointApproval__c = true;
        update ppt;

        Test.startTest();
            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = 500
            );

            insert new FieloPLT__Event__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__Value__c = -250
            );

            insert new FieloPLT__Transaction__c(
                FieloPLT__Member__c = members.get(0).Id,
                FieloPLT__IsAdjust__c = true,
                Flexpoint__c = -250
            );

            insert new List<FieloPLT__Event__c> {
                new FieloPLT__Event__c(
                    FieloPLT__Member__c = members.get(0).Id,
                    FieloPLT__Value__c = 300
                )
            };
            List<FieloPLT__Point__c> points =
                [
                    SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                    FROM FieloPLT__Point__c
                    WHERE FieloPLT__Member__c = :members.get(0).Id
                    ORDER BY CreatedDate, Id
                ];

            List<FieloPLT__Point__c> updPoints = new List<FieloPLT__Point__c>();
            for (FieloPLT__Point__c p : points) {
                updPoints.add(
                    new FieloPLT__Point__c(
                        Id = p.Id,
                        FieloPLT__Status__c = 'Approved'
                    )
                );
            }
            update updPoints;

            Date expDate = date.today().addDays(-1);
            update new FieloPLT__Point__c(
                Id = points.get(0).Id,
                FieloPLT__ExpirationDate__c = expDate,
                FieloPLT__ExpirationDateCheck__c = DateTime.newInstance(expDate.year(), expDate.month(), expDate.day()).format('yyyyMMdd')
            );

            Database.executeBatch(new FieloPLT.PointsPartialExpirationBatchSchedule());
        Test.stopTest();

        members = [SELECT Id, Flexpoint__c FROM FieloPLT__Member__c WHERE Id =:members.get(0).Id];

        Assert.areEqual(300, members.get(0).Flexpoint__c, 'Member should have 0 points left');

        points =
            [
                SELECT Id, FieloPLT__TotalPoints__c, FieloPLT__UsedPoints__c, FieloPLT__ExpiredPoints__c, FieloPLT__Balance__c, FieloPLT__MemberBalance__c
                FROM FieloPLT__Point__c
                WHERE FieloPLT__Member__c = :members.get(0).Id
                ORDER BY CreatedDate, Id
            ];

        Assert.areEqual(500, points.get(0).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__ExpiredPoints__c, 'Wrong Expired Points for Point #1');
        Assert.areEqual(  0, points.get(0).FieloPLT__Balance__c, 'Wrong Balance for Point #1');
        Assert.areEqual(500, points.get(0).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #1');

        Assert.areEqual(-250, points.get(1).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #2');
        Assert.areEqual(   0, points.get(1).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #1');
        Assert.areEqual(   0, points.get(1).FieloPLT__Balance__c, 'Wrong Balance for Point #2');
        Assert.areEqual( 250, points.get(1).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #2');

        Assert.areEqual(-250, points.get(2).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__Balance__c, 'Wrong Balance for Point #3');
        Assert.areEqual(   0, points.get(2).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #3');

        Assert.areEqual(300, points.get(3).FieloPLT__TotalPoints__c, 'Wrong Total Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__UsedPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(  0, points.get(3).FieloPLT__ExpiredPoints__c, 'Wrong Used Points for Point #4');
        Assert.areEqual(300, points.get(3).FieloPLT__Balance__c, 'Wrong Balance for Point #4');
        Assert.areEqual(300, points.get(3).FieloPLT__MemberBalance__c, 'Wrong Member Balance for Point #4');
    }
}
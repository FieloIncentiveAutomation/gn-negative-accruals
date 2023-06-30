@isTest
public class F_TestBonusBasedStatusBatchScheduler {

    @isTest
    static void positiveAndNegativeTransactions() {
        //GIVEN
        //Create Program A
        FieloPLT__Program__c program = new FieloPLT__Program__c(Name = 'Program A');
        Insert program;

        //Insert Levels
        List<FieloPLT__Level__c> levels = F_SObjectForTest.createLevels('Test', 2, program.Id);
        levels[0].Name = 'Silver';
        levels[0].F_threshold__c = 1000;
        levels[0].FieloPLT__LogicalExpression__c = 'ALL';
        levels[0].FieloPLT__Order__c = 1;

        levels[1].Name = 'Gold';
        levels[1].F_threshold__c = 2000;
        levels[1].FieloPLT__LogicalExpression__c = 'ALL';
        levels[1].FieloPLT__Order__c = 2;
        insert levels;

        //Insert Criteria
        List<FieloPLT__Criterion__c> criterias = F_SObjectForTest.createLevelCriteria(levels[0].Id,2);
        criterias[0].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[0].FieloPLT__NumberValue__c = 0;
        criterias[0].FieloPLT__Operator__c = 'greater or equal';

        criterias[1].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[1].FieloPLT__NumberValue__c = 1000;
        criterias[1].FieloPLT__Operator__c = 'less than';

		criterias.addAll(F_SObjectForTest.createLevelCriteria(levels[1].Id,1));
        criterias[2].FieloPLT__Level__c = levels[1].Id;
        criterias[2].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[2].FieloPLT__NumberValue__c = 1000;
        criterias[2].FieloPLT__Operator__c = 'greater or equal';
        insert criterias;

        //Activate Levels
		levels[0].FieloPLT__IsActive__c = true;
        levels[1].FieloPLT__IsActive__c = true;
        update levels;

        //Insert Accounts
        Account acc = new Account(Name = 'Test Account1', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States');
        insert acc;

        //Insert Members
        FieloPLT__Member__c member = new FieloPLT__Member__c(Name = 'Test Member 1', FieloPLT__Email__c = 'memberTest1@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = acc.Id, F_LevelOverri_deEndDt__c = System.today().addDays(10), F_OptOut__c = false);
        Insert member;

        Date today = System.today();
		List<FieloPLT__Transaction__c> transactions = new List<FieloPLT__Transaction__c>();
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = member.Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 200, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
		transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = member.Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = -100, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
        insert transactions;

		//WHEN
        Test.startTest();
            F_BonusBasedStatusBatchScheduler obj = new F_BonusBasedStatusBatchScheduler();
            DataBase.executeBatch(obj,200);
        Test.stopTest();

		//THEN
        // Check Events for Bonus Based on Status type
        List<FieloPLT__Event__c> evts = [SELECT Id, FieloPLT__Type__c, FieloPLT__Value__c, FieloPLT__Member__c FROM FieloPLT__Event__c WHERE FieloPLT__Member__c =: member.Id AND  FieloPLT__Type__c= 'Bonus Based on Status'];
        System.assertEquals(1, evts.size(), 'The system did not generated 1 events.');
		System.assertEquals('Bonus Based on Status' , evts[0].FieloPLT__Type__c, 'The system generated other type of event.');
		System.assertEquals(100, evts[0].FieloPLT__Value__c, 'The system generated wrong event value.');

        // Check Events for Active Months Bonus type
        /* Deactivated per business request
        evts = [SELECT Id, FieloPLT__Type__c, F_ActiveMonths__c, FieloPLT__Member__c FROM FieloPLT__Event__c WHERE FieloPLT__Member__c  =: member.Id AND  FieloPLT__Type__c= 'Active Months Bonus'];
        System.assertEquals(1, evts.size(), 'The system did not generated 2 events.');
        System.assertEquals('Active Months Bonus' , evts[0].FieloPLT__Type__c, 'The system generated other type of event.');
		System.assertEquals(1, evts[0].F_ActiveMonths__c, 'The system generated wrong event value.');
		*/
    }

    @isTest
    static void positiveTransactions() {
        //GIVEN
        //Create Program A
        FieloPLT__Program__c program = new FieloPLT__Program__c(Name = 'Program A');
        Insert program;


        //Insert Levels
        List<FieloPLT__Level__c> levels = F_SObjectForTest.createLevels('Test', 2, program.Id);
        levels[0].Name = 'Silver';
        levels[0].F_threshold__c = 1000;
        levels[0].FieloPLT__LogicalExpression__c = 'ALL';
        levels[0].FieloPLT__Order__c = 1;

        levels[1].Name = 'Gold';
        levels[1].F_threshold__c = 2000;
        levels[1].FieloPLT__LogicalExpression__c = 'ALL';
        levels[1].FieloPLT__Order__c = 2;
        insert levels;

        //Insert Criteria
        List<FieloPLT__Criterion__c> criterias = F_SObjectForTest.createLevelCriteria(levels[0].Id,2);
        criterias[0].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[0].FieloPLT__NumberValue__c = 0;
        criterias[0].FieloPLT__Operator__c = 'greater or equal';

        criterias[1].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[1].FieloPLT__NumberValue__c = 1000;
        criterias[1].FieloPLT__Operator__c = 'less than';

		criterias.addAll(F_SObjectForTest.createLevelCriteria(levels[1].Id,1));
        criterias[2].FieloPLT__Level__c = levels[1].Id;
        criterias[2].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[2].FieloPLT__NumberValue__c = 1000;
        criterias[2].FieloPLT__Operator__c = 'greater or equal';
        insert criterias;

        //Activate Levels
		levels[0].FieloPLT__IsActive__c = true;
        levels[1].FieloPLT__IsActive__c = true;
        update levels;

        //Insert Accounts
        Account acc = new Account(Name = 'Test Account1', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States');
        insert acc;

        //Insert Members
        FieloPLT__Member__c member = new FieloPLT__Member__c(Name = 'Test Member 1', FieloPLT__Email__c = 'memberTest1@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = acc.Id, F_LevelOverri_deEndDt__c = System.today().addDays(10), F_OptOut__c = false);
        Insert member;

        Date today = System.today();
		List<FieloPLT__Transaction__c> transactions = new List<FieloPLT__Transaction__c>();
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = member.Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 100, FieloPLT__Date__c = today.addMonths(-12), FlexpointExpirationDate__c = today.addMonths(18)));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = member.Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 200, FieloPLT__Date__c = today.addMonths(-13), FlexpointExpirationDate__c = today.addMonths(18)));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = member.Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 300, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
        insert transactions;

		//WHEN
        Test.startTest();
            F_BonusBasedStatusBatchScheduler obj = new F_BonusBasedStatusBatchScheduler();
            DataBase.executeBatch(obj,200);
        Test.stopTest();

		//THEN
        // Check Events for Bonus Based on Status type
        List<FieloPLT__Event__c> evts = [SELECT Id, FieloPLT__Type__c, FieloPLT__Value__c, FieloPLT__Member__c FROM FieloPLT__Event__c WHERE FieloPLT__Member__c =: member.Id AND  FieloPLT__Type__c= 'Bonus Based on Status'];
        System.assertEquals(1, evts.size(), 'The system did not generated 1 events.');
		System.assertEquals('Bonus Based on Status' , evts[0].FieloPLT__Type__c, 'The system generated other type of event.');
		System.assertEquals(300, evts[0].FieloPLT__Value__c, 'The system generated wrong event value.');

        // Check Events for Active Months Bonus type
        /* Deactivated per business request
        evts = [SELECT Id, FieloPLT__Type__c, F_ActiveMonths__c, FieloPLT__Member__c FROM FieloPLT__Event__c WHERE FieloPLT__Member__c  =: member.Id AND  FieloPLT__Type__c= 'Active Months Bonus'];
        System.assertEquals(1, evts.size(), 'The system did not generated 2 events.');
        System.assertEquals('Active Months Bonus' , evts[0].FieloPLT__Type__c, 'The system generated other type of event.');
		System.assertEquals(3, evts[0].F_ActiveMonths__c, 'The system generated wrong event value.');
        */
    }

    @isTest
    static void noTransactions() {
        //GIVEN
        //Create Program A
        FieloPLT__Program__c program = new FieloPLT__Program__c(Name = 'Program A');
        Insert program;

        //Insert Accounts
        Account acc = new Account(Name = 'Test Account1', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States');
        insert acc;

        //Insert Members
        FieloPLT__Member__c member = new FieloPLT__Member__c(Name = 'Test Member 1', FieloPLT__Email__c = 'memberTest1@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = acc.Id, F_LevelOverri_deEndDt__c = System.today().addDays(10), F_OptOut__c = false);
        Insert member;

		//WHEN
        Test.startTest();
            F_BonusBasedStatusBatchScheduler obj = new F_BonusBasedStatusBatchScheduler();
            DataBase.executeBatch(obj,200);
        Test.stopTest();

		//THEN
        // Check Events for Bonus Based on Status type
        List<FieloPLT__Event__c> evts = [SELECT Id, FieloPLT__Type__c, FieloPLT__Value__c, FieloPLT__Member__c FROM FieloPLT__Event__c];
        System.assertEquals(0, evts.size(), 'The system did not generated 1 events.');
    }

    @isTest
	static void statusBonusScheduleTest() {
		//GIVEN
		//Create Program A
        FieloPLT__Program__c program = new FieloPLT__Program__c(Name = 'Program A');
        Insert program;

        //Insert Levels
        List<FieloPLT__Level__c> levels = F_SObjectForTest.createLevels('Test', 2, program.Id);
        levels[0].Name = 'Silver';
        levels[0].F_threshold__c = 1000;
        levels[0].FieloPLT__LogicalExpression__c = 'ALL';
        levels[0].FieloPLT__Order__c = 1;

        levels[1].Name = 'Gold';
        levels[1].F_threshold__c = 2000;
        levels[1].FieloPLT__LogicalExpression__c = 'ALL';
        levels[1].FieloPLT__Order__c = 2;
        insert levels;

        //Insert Criteria
        List<FieloPLT__Criterion__c> criterias = F_SObjectForTest.createLevelCriteria(levels[0].Id,2);
        criterias[0].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[0].FieloPLT__NumberValue__c = 0;
        criterias[0].FieloPLT__Operator__c = 'greater or equal';

        criterias[1].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[1].FieloPLT__NumberValue__c = 1000;
        criterias[1].FieloPLT__Operator__c = 'less than';

		criterias.addAll(F_SObjectForTest.createLevelCriteria(levels[1].Id,1));
        criterias[2].FieloPLT__Level__c = levels[1].Id;
        criterias[2].FieloPLT__FieldName__c = 'FieloPLT__Points__c';
        criterias[2].FieloPLT__NumberValue__c = 1000;
        criterias[2].FieloPLT__Operator__c = 'greater or equal';
        insert criterias;

        //Activate Levels
		levels[0].FieloPLT__IsActive__c = true;
        levels[1].FieloPLT__IsActive__c = true;
        update levels;

        //Insert Accounts
        List<Account> accs = new List<Account>();
        accs.add(new Account(Name = 'Test Account1', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States'));
        accs.add(new Account(Name = 'Test Account2', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States'));
        accs.add(new Account(Name = 'Test Account3', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States'));
        insert accs;

        //Insert Members
        List<FieloPLT__Member__c> members = new List<FieloPLT__Member__c>();
        members.add(new FieloPLT__Member__c(Name = 'Test Member 1', FieloPLT__Email__c = 'memberTest1@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = accs[0].Id, FieloPLT__Status__c = 'Active', F_LevelOverri_deEndDt__c = System.today().addDays(10), F_OptOut__c = false));
        members.add(new FieloPLT__Member__c(Name = 'Test Member 2', FieloPLT__Email__c = 'memberTest2@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = accs[1].Id, FieloPLT__Status__c = 'Active', F_LevelOverri_deEndDt__c = System.today(), F_OptOut__c = false));
        members.add(new FieloPLT__Member__c(Name = 'Test Member 3', FieloPLT__Email__c = 'memberTest3@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = accs[2].Id, FieloPLT__Status__c = 'Active', F_LevelOverri_deEndDt__c = System.today(), F_OptOut__c = false));
        Insert members;

        Date today = System.today();
		List<FieloPLT__Transaction__c> transactions = new List<FieloPLT__Transaction__c>();
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[0].Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 100, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
		transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[0].Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = -100, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[1].Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 100, FieloPLT__Date__c = today.addMonths(-1), FlexpointExpirationDate__c = today.addMonths(18)));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[1].Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 200, FieloPLT__Date__c = today.addMonths(-2), FlexpointExpirationDate__c = today.addMonths(18)));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[1].Id, FieloPLT__IsAdjust__c = true, Flexpoint__c = 300, FieloPLT__Date__c = today, FlexpointExpirationDate__c = today.addMonths(18)));
		insert transactions;


		//WHEN
        Test.startTest();
            F_BonusBasedStatusBatchScheduler sh1 = new F_BonusBasedStatusBatchScheduler();
            String sch = '0 0 0 1 * ? *';
			System.schedule('Bonus Based Status Scheduler Test', sch, sh1);
        Test.stopTest();

		//THEN
        System.assertNotEquals(null, sh1);
    }
}
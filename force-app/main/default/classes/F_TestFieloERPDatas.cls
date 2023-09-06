@isTest
public class F_TestFieloERPDatas {

    public class MockSchedulableContext implements SchedulableContext{
        private string fakeJobId { get{
            if (fakeJobId == null) {
                fakeJobId = SObjectType.CronTrigger.getKeyPrefix().rightPad(12,'0') +
                    String.valueOf(Integer.valueOf(Math.floor(Math.random() * 100))).leftPad(3,'0') +
                    'AAA';
            }
            return fakeJobId;
        } set;}

        public Id getTriggerId() {
            return this.fakeJobId;
        }
    }

    @TestSetup
    static void makeData() {
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
        Account acc1 = new Account(Name = 'Test Account1', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States');
        Account acc2 = new Account(Name = 'Test Account2', BillingStreet='7800 Marshal Rd.', BillingPostalCode='100016', BillingCity='New York', BillingCountry='United States');
        accs.add(acc1);
        accs.add(acc2);
        insert accs;

        //Insert Members
        List<FieloPLT__Member__c> members = new List<FieloPLT__Member__c>();
        members.add(new FieloPLT__Member__c(Name = 'Test Member 1', FieloPLT__Email__c = 'memberTest1@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = acc1.Id, F_LevelOverri_deEndDt__c = System.today().addDays(10)));
        members.add(new FieloPLT__Member__c(Name = 'Test Member 2', FieloPLT__Email__c = 'memberTest2@yopmail.com', FieloPLT__Program__c = program.Id, FieloPLT__Account__c = acc2.Id, F_LevelOverri_deEndDt__c = System.today().addDays(10)));
        Insert members;

		List<FieloPLT__Transaction__c> transactions = new List<FieloPLT__Transaction__c>();
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[0].Id, FieloPLT__IsAdjust__c = true, FieloPLT__Points__c = 1100));
        transactions.add(new FieloPLT__Transaction__c(FieloPLT__Member__c = members[1].Id, FieloPLT__IsAdjust__c = true, FieloPLT__Points__c = 1100));
        insert transactions;

        //Calculate Member Levels
        FieloPLT.MemberService.calculateMembersLevel(new Set<Id>{members[0].Id, members[1].Id});

        //Insert Fielo ERP Datas
        List<FieloERPData__c> fieloERPDatas = new List<FieloERPData__c>();
        for(Integer i = 0; i < 100; i++){
	        fieloERPDatas.add(new FieloERPData__c(Name = 'Fielo ERP Data Test ' + i + ' Indirect', BillToAccount__c = acc1.Id, SellToAccount__c = acc2.Id, IndirectBilled__c = true));
	        fieloERPDatas.add(new FieloERPData__c(Name = 'Fielo ERP Data Test ' + i, BillToAccount__c = acc1.Id, SellToAccount__c = acc2.Id, IndirectBilled__c = false));
        }
        insert fieloERPDatas;
    }

    @isTest
    static void scheduleOnceTest(){

        F_OfflineCustomSettings__c setting = F_OfflineCustomSettings__c.getOrgDefaults();
        setting.ERPBatchDataInterval__c = 1;
        setting.Batch_Size__c = 200;
        upsert setting;

        Test.startTest();
            F_FieloERPDataBatch2 obj = new F_FieloERPDataBatch2();
            MockSchedulableContext context = new MockSchedulableContext();
            obj.execute(context);
        Test.stopTest();

        List<FieloERPData__c> indirectBilledERPData = [SELECT Id, SellToAccount__c, Member__c FROM FieloERPData__c WHERE Name = 'Fielo ERP Data Test 0 Indirect'];
        List<FieloPLT__Member__c> memberWithSameSellAccount = [SELECT Id, FieloPLT__Account__c FROM FieloPLT__Member__c WHERE Name = 'Test Member 2'];

        List<FieloERPData__c> notIndirectBilledERPData = [SELECT Id, BillToAccount__c, Member__c FROM FieloERPData__c WHERE Name = 'Fielo ERP Data Test 0'];
        List<FieloPLT__Member__c> memberWithSameBillAccount = [SELECT Id, FieloPLT__Account__c FROM FieloPLT__Member__c WHERE Name = 'Test Member 1'];

        System.assertEquals(indirectBilledERPData[0].SellToAccount__c, memberWithSameSellAccount[0].FieloPLT__Account__c);
        System.assertEquals(indirectBilledERPData[0].Member__c, memberWithSameSellAccount[0].Id);

        System.assertEquals(notIndirectBilledERPData[0].BillToAccount__c, memberWithSameBillAccount[0].FieloPLT__Account__c);
        System.assertEquals(notIndirectBilledERPData[0].Member__c, memberWithSameBillAccount[0].Id);
    }

     @isTest
    static void abortJobTest(){
        Id jobId;
        Integer startTime = System.Now().millisecond();
        F_OfflineCustomSettings__c setting = F_OfflineCustomSettings__c.getOrgDefaults();
        setting.ERPBatchDataInterval__c = 30;
        setting.Batch_Size__c = 200;
        upsert setting;

        Test.startTest();
            F_FieloERPDataBatch2 obj = new F_FieloERPDataBatch2();
            String sch = '0 0 1 * * ?';

            jobId = System.schedule('F_FieloERPDataBatch2_' + startTime, sch, obj);

            F_FieloERPDataBatch2.abortJob(jobId);
        Test.stopTest();
    }
}
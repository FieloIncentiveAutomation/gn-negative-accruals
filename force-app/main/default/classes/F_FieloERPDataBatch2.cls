global class F_FieloERPDataBatch2 implements Database.Batchable<sobject>, Schedulable {
  private
  static final String JOB_NAME = 'F_FieloERPDataBatch2';
  private
  static final String DEFAULT_CRON_STRING = '0 55 * * * ?';
  private
  static final String STATUS_PENDING = 'Pending';
  private
  static final String STATUS_PROCESSED = 'Processed';
  private
  static final String STATUS_ERROR = 'Error';

  /**
   * This class is used to process GNs ERP data records so Fielo engine is triggered and 
   * rewards and points are calculated. 
   * @description This method will schedule the batch job each x min. This mehtod checks
   * if the same batch is already scheduled or is processing.
   */
    // Change the LOGIC HERE
    global static Boolean isScheduled(Boolean init){
        Id jobId;
        // Query for existing CronTrigger records with the same job name
        List<CronTrigger> ct = [SELECT
                                    Id, State
                                FROM
                                    CronTrigger
                                WHERE
                                    CronJobDetail.Name =: JOB_NAME];
        
        // Query for the number of enqueued jobs with the same Apex class and status
        if(ct.size() > 0){
            jobId = ct[0].Id;
            system.debug('ct[0].State: ' + ct[0].State);
        }

        Integer enqueuedJobs = [SELECT
                                    COUNT()
                                FROM
                                    AsyncApexJob
                                WHERE
                                    Status IN ('Processing','Preparing') AND  ApexClass.Name =: JOB_NAME
                               ];
        system.debug('enqueuedJobs: ' + enqueuedJobs);



        if(init && enqueuedJobs == 1){
            system.debug('return 1');
            return false;

        }else if(init && enqueuedJobs == 2){
            abortJob(jobId);
            system.debug('return 2');
            return true;
        }
        else if(enqueuedJobs == 2 && !init){
            abortJob(jobId);
            system.debug('return 3');
            return true;
        }else if(enqueuedJobs == 0 && !init){
              List<FieloERPData__c> listCheck = [SELECT Id FROM FieloERPData__c WHERE F_Status__c = null OR F_Status__c =:STATUS_PENDING limit 1];

            // Default
            if(listCheck == null || listCheck.size()==0){
                if(jobId != null){
                    System.abortJob(jobId);
                }
                System.schedule(JOB_NAME, DEFAULT_CRON_STRING ,new F_FieloERPDataBatch2());
                system.debug('return 5');
                return true;
            }else{
                abortJob(jobId);
                system.debug('return 5.2');
                return true;
            }


        }
        system.debug('return 6');
        return true;
    }
    // Method to abort a job and reschedule it
    global static void abortJob(Id jobId){
        F_OfflineCustomSettings__c settingsInstance = F_OfflineCustomSettings__c.getInstance();
        if(jobId != null){
            System.abortJob(jobId);
        }
        system.debug('jobId: ' + jobId);
        Integer interval = Integer.valueOf(settingsInstance.ERPBatchDataInterval__c) * 60;
        Datetime sysTime = System.now().addSeconds(interval);
        String CronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' * * * ?';
        System.schedule(JOB_NAME, CronExpression, new F_FieloERPDataBatch2());
    }
    // Method to execute the scheduled job
  global void execute(SchedulableContext SC) {
    Integer BatchSize = 5; // Set your desired batch size here
    F_OfflineCustomSettings__c customSetting = F_OfflineCustomSettings__c.getInstance();

    if (customSetting != null) {
        batchSize = Integer.valueOf(customSetting.Batch_Size__c);
        if(batchSize==null || batchSize<1){
            batchSize = 10;
        }
    }
    Database.executeBatch(new F_FieloERPDataBatch2(), BatchSize);
  }
    /**
     * @description Retrieves members associated with specified Account Ids.
     * @param accountId Set of Account Ids to retrieve members for.
     * @return List of FieloPLT__Member__c objects.
     */
  public
  List<FieloPLT__Member__c> getMembers(Set<Id> accountId) {
    // clang-format off
    return new List<FieloPLT__Member__c>([
      SELECT
        Id,
        FieloPLT__Account__c
      FROM
        FieloPLT__Member__c
        WHERE FieloPLT__Account__c IN:accountId AND F_OptOut__c !=  true]);
    // clang-format on
  }
	// Query for members based on Account Id
  global Database.QueryLocator start(Database.BatchableContext BC) {
      if(isScheduled(true)){
        return Database.getQueryLocator([
            SELECT
            Id
            FROM FieloERPData__c
            LIMIT 0]
        );
      }
      else{
          // clang-format off
          return Database.getQueryLocator([
              SELECT
              Id,
              Member__c,
              F_Status__c,
              IndirectBilled__c,
              SellToAccount__c,
              BillToAccount__c
              FROM
              FieloERPData__c
              WHERE
              F_Status__c = null
              OR F_Status__c = : STATUS_PENDING
              ORDER BY
              LastModifiedDate ASC]);
          // clang-format on
      }


  }
   // Method to process the batch job
  global void execute(Database.BatchableContext BC, List<FieloERPData__c> scope) {
      try{
          List<FieloPLT__ErrorLog__c> errorLogList = new List<FieloPLT__ErrorLog__c>();
          if(scope != null){
              system.debug('execute 1 '+scope.size());
              Map<String, String> accountsWithMembers = new Map<String, String>();
              Set<Id> accountId = new Set<Id>();

              for (FieloERPData__c erp : scope) {
                  if (erp.Member__c == null) {
                      if (erp.IndirectBilled__c) {
                          accountId.add(erp.SellToAccount__c);
                      } else {
                          accountId.add(erp.BillToAccount__c);
                      }
                  }
              }
              if (!accountId.isEmpty()) {
                  for (FieloPLT__Member__c member : getMembers(accountId)) {
                      accountsWithMembers.put(member.FieloPLT__Account__c, member.Id);
                  }
              }
              if (!accountsWithMembers.isEmpty()) {
                  for (FieloERPData__c erp : scope) {
                      try {
                          if (erp.IndirectBilled__c) {
                              if (accountsWithMembers.containsKey(erp.SellToAccount__c)) {
                                  erp.Member__c = accountsWithMembers.get(erp.SellToAccount__c);
                              }
                          } else if (accountsWithMembers.containsKey(erp.BillToAccount__c)) {
                              erp.Member__c = accountsWithMembers.get(erp.BillToAccount__c);
                          }
                          erp.F_Status__c = STATUS_PROCESSED;
                      } catch (Exception e) {
                          erp.F_Status__c = STATUS_ERROR;
                          FieloPLT__ErrorLog__c errorLog = new FieloPLT__ErrorLog__c(FieloPLT__Message__c = e.getMessage(), FieloPLT__StackTrace__c = e.getStackTraceString(), FieloPLT__Type__c = JOB_NAME, FieloPLT__UserId__c = UserInfo.getUserId(), FieloERPData__c = erp.Id);
                          errorLogList.add(errorLog);
                      }
                  }
                  update scope;

                  //Save Batch Errors 
                  if (errorLogList.size() > 0) {
                      insert errorLogList;
                  }
              }
          }
      }
      catch(Exception e){
          FieloPLT__ErrorLog__c errorLog = new FieloPLT__ErrorLog__c(FieloPLT__Message__c = e.getMessage(), FieloPLT__StackTrace__c = e.getStackTraceString(), FieloPLT__Type__c = JOB_NAME, FieloPLT__UserId__c = UserInfo.getUserId());
          insert errorLog;
      }
  }
      // Method to finish the batch job and update the scheduling status
  global void finish(Database.BatchableContext bc) {
      isScheduled(false);
  }
}
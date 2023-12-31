public class F_SObjectForTest {

	private static Integer recNum = 0;
	private static Integer uniqueExternalIdCode(){
        return ++recNum;
    }

  	public static List<FieloPLT__Level__c> createLevels(String basename, Integer count, Id programId){
		List<FieloPLT__Level__c> results = new List<FieloPLT__Level__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Level__c(
					Name = basename + x,
					FieloPLT__Program__c = programId,
					FieloPLT__ExternalId__c = basename + x + uniqueExternalIdCode()
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

	public static FieloPLT__PointType__c createFlexpointCurrency(){
		return new FieloPLT__PointType__c(
			Name = 'FlexPoint',
			FieloPLT__ExternalId__c = '00D200000006Wrs-a6k2o00000AARMm',
			FieloPLT__MemberBalanceField__c = 'Flexpoint__c',
			FieloPLT__TransactionBalanceField__c = 'Flexpoint__c',
			FieloPLT__RedemptionBalanceField__c = 'Flexpoint__c',
			FieloPLT__RedemptionItemBalanceField__c = 'Flexpoint__c',
			FieloPLT__RewardBalanceField__c = 'Flexpoint__c',
			FieloPLT__ConversionModeField__c = 'FlexpointConversionMode__c',
			FieloPLT__ConversionValueField__c = 'FlexpointConversionValue__c',
			FieloPLT__RecordFieldNameField__c = 'FlexpointFieldName__c',
			FieloPLT__MonthsUntilExpirationField__c = 'FlexpointMonthsUntilExpiration__c',
			FieloPLT__PointExpirationDateField__c = 'FlexpointExpirationDate__c',
			FieloPLT__PointExpirationModeField__c = 'FlexpointExpirationMode__c',
			FieloPLT__PointReflectionField__c = 'FlexpointReflection__c',
			FieloPLT__TransactionExpirationDateField__c = 'FlexpointExpirationDate__c',
			FieloPLT__DecimalsNumber__c = 2,
			FieloPLT__Status__c = 'Active'
		);
	}

    public static List<FieloPLT__Criterion__c> createLevelCriteria(Id levelId, Integer count){
		List<FieloPLT__Criterion__c> results = new List<FieloPLT__Criterion__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Criterion__c(
					FieloPLT__Level__c = levelId,
					FieloPLT__ExternalId__c = levelId + '-' + x + uniqueExternalIdCode()
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

	public static List<FieloPLT__Program__c> createPrograms(String basename, Integer count) {
		List<FieloPLT__Program__c> results = new List<FieloPLT__Program__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Program__c(
					Name = basename + x,
					FieloPLT__OnlineTransactionProcessing__c = true,
					FieloPLT__CapAdjustmentTransactions__c = true,
					FieloPLT__ExternalId__c = guid()
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

    public static FieloPLT__RuleTrigger__c createRuleTrigger(String name, String objectName, String dateField, String lookUpFromTransaction, String lookUpFromTracker, String lookupFromPoint){
		FieloPLT__RuleTrigger__c rt = new FieloPLT__RuleTrigger__c(
			Name = name,
			FieloPLT__Object__c = objectName,
			FieloPLT__Date__c = dateField,
			FieloPLT__LookupFromTransaction__c = lookUpFromTransaction,
			FieloPLT__LookupFromTracker__c = lookUpFromTracker,
			FieloPLT__LookupFrompoint__c = lookUpFrompoint,
			FieloPLT__Status__c = 'Active',
			FieloPLT__Prefix__c = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe().getKeyPrefix(),
			FieloPLT__ExternalId__c = objectName + '-' + name + uniqueExternalIdCode()
		);
		System.assertNotEquals(null, rt);
		return rt;
	}

    public static FieloPLT__Action__c createAction(String targetMember, String conditionField, String conditionValue, Id ruleTriggerId){
		FieloPLT__Action__c action = new FieloPLT__Action__c(
			FieloPLT__TargetMember__c = targetMember,
			FieloPLT__RuleTrigger__c = ruleTriggerId,
			FieloPLT__ConditionField__c = conditionField,
			FieloPLT__conditionValue__c = conditionValue,
			FieloPLT__ExternalId__c = ruleTriggerId + '-' + targetMember + uniqueExternalIdCode()
		);
		System.assertNotEquals(null, action);
		return action;
	}

    public static List<FieloPLT__Promotion__c> createPromotions(String basename, Integer count, Id programId){
		List<FieloPLT__Promotion__c> results = new List<FieloPLT__Promotion__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Promotion__c(
					Name = basename + x,
					FieloPLT__Program__c = programId,
					FieloPLT__ExternalId__c = guid()
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

    public static List<FieloPLT__Rule__c> createRules(String basename, Integer count, Id promotionId){
		List<FieloPLT__Rule__c> results = new List<FieloPLT__Rule__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Rule__c(
					Name = basename + x,
					FieloPLT__Promotion__c = promotionId,
					FieloPLT__ExternalId__c = guid()
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

    public static List<FieloPLT__Member__c> createIndividualAccounts(String basename, Integer count, Id programId){
		List<FieloPLT__Member__c> results = new List<FieloPLT__Member__c>();
		for(Integer x = 0; x < count; x++){
			results.add(
				new FieloPLT__Member__c(
					Name = basename + x,
					FieloPLT__Email__c = (basename + x).deleteWhitespace() + Datetime.now().getTime() + '@fielo.com',//se agrega el datetime para que si se crean más de 200 registros los mails sean distintos
					FieloPLT__Program__c = programId,
					FieloPLT__Type__c = 'Individual Account'
				)
			);
		}
		System.assertNotEquals(null, results);
		return results;
	}

	public static String guid(){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        return guid;
    }
}
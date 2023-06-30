public with sharing class Fielo_SObjectSelector {
    public string objectName;
    public string query;
    public Map<String, Object> bindMap;
    public AccessLevel queryAccessLevel;
    public DescribeSObjectResult objectDescribe;
    public Map<String, SObjectField> fieldTokensMap;

    public List<SObject> getRecords(String objectName, Map<String, String> dataFilter, Map<String,Object> bindMap, AccessLevel in_accessLevel) {
        try {
            this.objectName = objectName;
            this.objectDescribe = Schema.describeSObjects(new List<String>{objectName})?.get(0);
            this.fieldTokensMap = this.objectDescribe.fields.getMap();
        } catch (Exception e) {
            System.debug(e);
        }

        if (this.objectDescribe == null) return null;

        return getRecords(
            objectName,
            this.objectDescribe.fields.getMap().keySet(),
            dataFilter,
            bindMap,
            in_accessLevel
        );
    }

    public List<SObject> getRecords(String objectName, Set<String> fields, Map<String, String> dataFilter, Map<String,Object> bindMap, AccessLevel in_accessLevel) {
        this.query = String.format(
            'SELECT {1} FROM {0} {2}',
            new List<String>{
                objectName,
                String.join(new List<String>(fields) ,','),
                getWhereClause(dataFilter)
            }
        );
        this.bindMap = bindMap;
        this.queryAccessLevel = in_accessLevel;

        return Database.queryWithBinds(
            this.query,
            this.bindMap,
            this.queryAccessLevel
        );
    }

    public String getWhereClause(Map<String, String> dataFilter) {
        Set<String> conditions = new Set<String>();
        for (String fieldName : dataFilter.keySet()) {
            conditions.add(
                fieldName + ' = ' + getConditionValue(fieldName, dataFilter.get(fieldName))
            );
        }
        return conditions.isEmpty() ?
            '' :
            ('WHERE ' + String.join(new List<String>(conditions), ' AND '));
    }

    public String getConditionValue(String fieldName, String value) {
        if (value.trim().startsWith(':')) {
            return value;
        } else {
            Set<String> nonQuotedTypes = new Set<String>{'DOUBLE','DATETIME','DATE','CURRENCY','INTEGER','BOOLEAN','PERCENT','TIME'};
            if (nonQuotedTypes.contains(fieldTokensMap.get(fieldName).getDescribe().getType().name().toLowerCase())) {
                return value;
            } else {
                return '\'' + value + '\'';
            }
        }
    }
}
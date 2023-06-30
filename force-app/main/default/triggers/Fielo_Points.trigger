trigger Fielo_Points on FieloPLT__Point__c (before insert, after insert, before update ,after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Fielo_Points.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            Fielo_Points.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Fielo_Points.onAfterInsert(Trigger.new);
        }
    }
}
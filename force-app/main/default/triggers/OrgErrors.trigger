trigger OrgErrors on OrgError__c (before insert, before update) {
    Triggers.prepare()
                .beforeInsert()
                    .bind( new ParseOrgErrors() )
                .beforeUpdate()
                    .bind( new ParseOrgErrors() )
                .execute();
}
/**
 * BSD 3-Clause License
 *
 * Copyright (c) 2020, Jianfeng Jin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@IsTest
public class TriggersTest implements Triggers.Handler, Triggers.BeforeInsert {
    public static String getFakeId(Schema.SObjectType objectType, Integer index) {
        return objectType.getDescribe().getKeyPrefix()
            + '000zzzz' // start from a large Id to avoid confliction during unit test.
            + String.valueOf(index).leftPad(5, '0');
    }

    static List<Account> createAccounts() {
        return new List<Account> {
            new Account(Id = getFakeId(Account.SObjectType, 1), Name = 'Account 1', Description = 'Account 1', BillingCity = 'New York'),
            new Account(Id = getFakeId(Account.SObjectType, 2), Name = 'Account 2', Description = 'Account 2', BillingCity = 'New York'),
            new Account(Id = getFakeId(Account.SObjectType, 3), Name = 'Account 3', Description = 'Account 3', BillingCity = 'New York')
        };
    }

    @IsTest
    static void testSkips_getHandlerName_ByType() {
        Triggers.Skips skips = new Triggers.Skips();
        skips.add(String.class);
        Assert.areEqual(true, skips.contains(String.class));

        skips.remove(String.class);
        Assert.areEqual(0, skips.skippedHandlers.size());

        skips.add(TriggersTest.TriggersTest.class);
        Assert.areEqual(true, skips.contains(TriggersTest.class));

        skips.clear();
        Assert.areEqual(0, skips.skippedHandlers.size());

        skips.add(TriggersTest.class);
        Assert.areEqual(true, skips.contains(new TriggersTest()));
    }

    // ====================
    // #region Test Binding
    @IsTest
    static void testBinding_BaseLine() {
        Triggers.prepare()
            .beforeInsert()
                .bind(new MainHandler())
            .beforeUpdate()
                .bind(new MainHandler())
            .beforeDelete()
                .bind(new MainHandler())
            .execute();

        Triggers.prepare()
            .afterInsert()
                .bind(new MainHandler())
            .afterUpdate()
                .bind(new MainHandler())
            .afterDelete()
                .bind(new MainHandler())
            .afterUndelete()
                .bind(new MainHandler())
            .execute();
    }

    @IsTest
    static void testBinding_NullLoader() {
        Triggers.Loader loader = Triggers.LOADER;

        Triggers.LOADER = new Triggers.NullLoader();
        Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, null, null)
            .beforeInsert()
                .load()
                .load('tag1')
            .execute();
    }

    @IsTest
    static void testBinding_Stop_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new StopHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Stop_AfterInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.AFTER_INSERT, null, null);
        triggerManager.afterInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new MainHandler())
            .bind(new StopHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Inactive_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new InactiveHandler())
            .bind(new MainHandler())
            .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Skip_Remove() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager.beforeInsert()
            .bind(new FirstHandler())
            .bind(new MainHandler())
            .bind(new AddSkippedHandler())
            .bind(new TriggersTest())
            .bind(new RemoveSkippedHandler())
            .bind(new TriggersTest())
            .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Skip_Clear() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, null, null);
        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new AddSkippedHandler())
                .bind(new TriggersTest())
                .bind(new ClearSkippedHandler())
                .bind(new TriggersTest())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }
    // #endregion
    // ====================

    // ==================
    // #region Test State
    @IsTest
    static void testBinding_State_BeforeInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            System.TriggerOperation.BEFORE_INSERT, new List<SObject>{}, new List<SObject>());
        triggerManager
            .beforeInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterInsert() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.AFTER_INSERT, null, null);
        triggerManager
            .afterInsert()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeUpdate() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            System.TriggerOperation.BEFORE_UPDATE, new List<SObject>(), new List<SObject>());
        triggerManager
            .beforeUpdate()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUpdate() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(
            System.TriggerOperation.AFTER_UPDATE, new List<SObject> (), new List<SObject> ());
        triggerManager
            .afterUpdate()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_BeforeDelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.BEFORE_DELETE, null, null);
        triggerManager
            .beforeDelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterDelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.AFTER_DELETE, null, null);
        triggerManager
            .afterDelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_State_AfterUndelete() {
        Triggers.ManagerImpl triggerManager = (Triggers.ManagerImpl) Triggers.prepare(System.TriggerOperation.AFTER_UNDELETE, null, null);
        triggerManager
            .afterUndelete()
                .bind(new FirstHandler())
                .bind(new MainHandler())
                .bind(new MainHandler())
                .bind(new LastHandler())
        .execute();

        Assert.areEqual(4, triggerManager.context.state.get('counter'));
    }

    @IsTest
    static void testBinding_Mock() {
        List<SObject> oldList = new List<SObject> {
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'Old Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'Old Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'Old Name 3')};

        List<SObject> newList = new List<SObject> {
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 1), Name = 'New Name 1'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 2), Name = 'New Name 2'),
            new Account(Id = TriggersTest.getFakeId(Account.SObjectType, 3), Name = 'New Name 3')};

        Triggers.prepare(System.TriggerOperation.BEFORE_INSERT, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.AFTER_INSERT, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.BEFORE_UPDATE, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.AFTER_UPDATE, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.BEFORE_DELETE, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.AFTER_DELETE, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();

        Triggers.prepare(System.TriggerOperation.AFTER_UNDELETE, oldList, newList)
            .afterUpdate()
                .bind(new AccountNameChangedHandler())
        .execute();
    }
    // #endregion
    // ==================

    // ===================
    // #region Test Helper
    @IsTest
    static void testProps_IsChanged_Negative() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = true;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        Boolean isChanged = props.isChanged(accounts[0].Id, Account.Name);

        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_GetValues_Undelete() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = false;
        props.isUndelete = true;
        props.newList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        Assert.areEqual(3, names.size());
        Assert.areEqual('Account 1', (String)names[0]);
        Assert.areEqual('Account 2', (String)names[1]);
        Assert.areEqual('Account 3', (String)names[2]);
    }

    @IsTest
    static void testProps_GetValues_Delete() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = false;
        props.isDelete = true;
        props.isUndelete = false;
        props.oldList = new List<Account> {
            new Account(Name = 'Account 1'),
            new Account(Name = 'Account 2'),
            new Account(Name = 'Account 3')
        };

        List<Object> names = props.getValues(Account.Name);
        Assert.areEqual(3, names.size());
        Assert.areEqual('Account 1', (String)names[0]);
        Assert.areEqual('Account 2', (String)names[1]);
        Assert.areEqual('Account 3', (String)names[2]);
    }

    @IsTest
    static void testProps_FilterChanged_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChanged() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChanged(Account.Name);
        Boolean isChanged = props.isChanged(Account.Name);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }


    @IsTest
    static void testProps_FilterChangedAny_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description);

        Assert.areEqual(2, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAny_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].BillingCity = 'Account 4';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAny(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAny(Account.Name, Account.Description, Account.BillingCity);

        Assert.areEqual(3, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2_NoChange() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;

        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        props.newList = accounts;
        props.newMap = new Map<Id, Account>(accounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        Assert.areEqual(0, changedIds.size());
        Assert.areEqual(false, isChanged);
    }

    @IsTest
    static void testProps_FilterChangedAll_X2() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }

    @IsTest
    static void testProps_sObjectType() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        Assert.areEqual(null, props.sObjectType);
        props.setSObjectType();
        Assert.areEqual(Account.SObjectType, props.sObjectType);
    }

    @IsTest
    static void testProps_FilterChangedAll_X3() {
        Triggers.Props props = new Triggers.Props();
        props.isInsert = false;
        props.isUpdate = true;
        props.isDelete = false;
        props.isUndelete = false;
        List<Account> accounts = createAccounts();
        props.oldList = accounts;
        props.oldMap = new Map<Id, Account>(accounts);
        List<Account> newAccounts = accounts.deepClone();
        newAccounts[0].Id = accounts[0].Id;
        newAccounts[0].Name = 'Account 6';
        newAccounts[0].Description = 'Account 6';
        newAccounts[0].BillingCity = 'Dalian';
        newAccounts[1].Id = accounts[1].Id;
        newAccounts[1].Name = 'Account 4';
        newAccounts[1].Description = 'Account 4';
        newAccounts[2].Id = accounts[2].Id;
        newAccounts[2].Description = 'Account 5';
        newAccounts[2].BillingCity = 'Dalian';
        props.newList = newAccounts;
        props.newMap = new Map<Id, Account>(newAccounts);

        List<Id> changedIds = props.filterChangedAll(Account.Name, Account.Description, Account.BillingCity);
        Boolean isChanged = props.isChangedAll(Account.Name, Account.Description, Account.BillingCity);

        Assert.areEqual(1, changedIds.size());
        Assert.areEqual(true, isChanged);
    }
    // #endregion
    // ===================

    // =====================
    // #region Handler Impls
    // TriggersTest is treated as a handler to be skipped, because inner class cannot be reflected
    // from an instance back to type properly.
    public Boolean criteria(Triggers.Context context) {
        return Triggers.WHEN_ALWAYS;
    }

    public void beforeInsert(Triggers.Context context) {
        context.state.put('counter', (Integer)context.state.get('counter') + 1);
        context.next();
        context.state.put('counter', (Integer)context.state.get('counter') + 1);
    }

    public class FirstHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // negative case, shouldn't do this
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            if (context.state.get('counter') == null) {
                context.state.put('counter', 0);
            }
            Assert.areEqual(0, context.state.get('counter'));
            context.next();
            Assert.areEqual(4, context.state.get('counter'));
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class MainHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class StopHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.stop();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class InactiveHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // negative test, shouldn't work in when method
            context.next();
            context.next();
            return !Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
            context.next();
            context.state.put('counter', (Integer)context.state.get('counter') + 1);
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class AddSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.skips.add(TriggersTest.class);
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class RemoveSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            if (context.skips.contains(TriggersTest.class)) {
                context.skips.remove(TriggersTest.class);
            }
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class ClearSkippedHandler implements Triggers.Handler, Triggers.BeforeInsert {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            context.skips.clear();
            context.next();
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }
    }

    public class LastHandler implements Triggers.Handler, Triggers.BeforeInsert, Triggers.AfterInsert,
        Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete, Triggers.AfterDelete,
        Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            context.next(); // shouldn't work in when method
            return Triggers.WHEN_ALWAYS;
        }

        private void then(Triggers.Context context) {
            Assert.areEqual(2, context.state.get('counter'));
            context.next();
            Assert.areEqual(2, context.state.get('counter'));
        }

        public void beforeInsert(Triggers.Context context) {
            then(context);
        }

        public void afterInsert(Triggers.Context context) {
            then(context);
        }

        public void beforeUpdate(Triggers.Context context) {
            then(context);
        }

        public void afterUpdate(Triggers.Context context) {
            then(context);
        }

        public void beforeDelete(Triggers.Context context) {
            then(context);
        }

        public void afterDelete(Triggers.Context context) {
            then(context);
        }

        public void afterUndelete(Triggers.Context context) {
            then(context);
        }
    }

    public class AccountNameChangedHandler implements Triggers.Handler, Triggers.BeforeInsert,
        Triggers.AfterInsert, Triggers.BeforeUpdate, Triggers.AfterUpdate, Triggers.BeforeDelete,
        Triggers.AfterDelete, Triggers.AfterUndelete {
        public Boolean criteria(Triggers.Context context) {
            return Triggers.WHEN_ALWAYS;
        }

        public void beforeInsert(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }

        public void afterInsert(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }

        public void beforeUpdate(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());

            Assert.areEqual(3, context.props.filterChanged(Account.Name).size());
            Assert.areEqual(true, context.props.isChanged(Account.Name));
        }

        public void afterUpdate(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());

            Assert.areEqual(3, context.props.filterChanged(Account.Name).size());
            Assert.areEqual(true, context.props.isChanged(Account.Name));
        }

        public void beforeDelete(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(null, context.props.newList);
            Assert.areEqual(null, context.props.newMap);

        }

        public void afterDelete(Triggers.Context context) {
            Assert.areEqual(3, context.props.oldList.size());
            Assert.areEqual(3, context.props.oldMap.size());
            Assert.areEqual(null, context.props.newList);
            Assert.areEqual(null, context.props.newMap);
        }

        public void afterUndelete(Triggers.Context context) {
            Assert.areEqual(null, context.props.oldList);
            Assert.areEqual(null, context.props.oldMap);
            Assert.areEqual(3, context.props.newList.size());
            Assert.areEqual(3, context.props.newMap.size());
        }
    }
    // #endregion
    // =====================
}
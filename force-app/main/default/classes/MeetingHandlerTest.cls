@IsTest
public with sharing class MeetingHandlerTest {
    private static final String USER_1_EMAIL = 'testuser1@example.com';
    private static final String USER_2_EMAIL = 'testuser2@example.com';
    private static final String USER_3_EMAIL = 'testuser3@example.com';
    private static final String USER_4_EMAIL = 'testuser4@example.com';
    private static final String MEETING_1_SUBJECT = 'SUBJECT_1';
    private static final String ACCOUNT_1_NAME = 'ACCOUNT_1_TEST_NAME';
    private static final String ACCOUNT_2_NAME = 'ACCOUNT_1_TEST_NAME';
    private static final String MANUAL_ROW_CAUSE = 'Manual';

    private static final List<String> USER_EMAILS = new List<String>{
            USER_1_EMAIL,
            USER_2_EMAIL,
            USER_3_EMAIL,
            USER_4_EMAIL
    };

        @TestSetup
    public static void testSetup() {
        Profile profile = [SELECT Id FROM Profile WHERE (NOT (Name LIKE '%admin%' OR Name LIKE '%read%')) AND UserLicense.Name = 'Salesforce' LIMIT 1];

        User user_1 = new User(
                LastName = 'User1',
                Email = USER_1_EMAIL,
                Username = USER_1_EMAIL + System.currentTimeMillis(),
                Alias = 'user1',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );
        User user_2 = new User(
                LastName = 'User2',
                Email = USER_2_EMAIL,
                Username = USER_2_EMAIL + System.currentTimeMillis(),
                Alias = 'user2',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );

        User user_3 = new User(
                LastName = 'User3',
                Email = USER_3_EMAIL,
                Username = USER_3_EMAIL + System.currentTimeMillis(),
                Alias = 'user3',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );

        User user_4 = new User(
                LastName = 'User4',
                Email = USER_4_EMAIL,
                Username = USER_4_EMAIL + System.currentTimeMillis(),
                Alias = 'user4',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );

        insert new List<User>{user_1, user_2, user_3, user_4};

        Account account_1 = new Account(Name = ACCOUNT_1_NAME, ManufacturerId__c = 'ID0', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');
        insert account_1;

        AccountShare user_1_AccountShare = createAccountShare(user_1.Id, account_1.Id);
        AccountShare user_2_AccountShare = createAccountShare(user_2.Id, account_1.Id);

        insert new List<AccountShare>{user_1_AccountShare, user_2_AccountShare};

        Meeting__c meeting_1 = new Meeting__c(
                StartDateTime__c = Datetime.now(),
                EndDateTime__c = Datetime.now().addDays(3),
                Type__c = 'Allgemein',
                Subject__c = MEETING_1_SUBJECT,
                Company__c = account_1.Id);

        System.runAs(user_4) {
            insert meeting_1;
        }

        Attendee__c participant_1 = new Attendee__c(User__c = user_1.Id, Meeting__c = meeting_1.Id);
        Attendee__c participant_3 = new Attendee__c(User__c = user_3.Id, Meeting__c = meeting_1.Id);

        insert new List<Attendee__c>{participant_1, participant_3};

        Meeting__Share meetingShareUser1 = new Meeting__Share(
                ParentId = meeting_1.Id,
                UserOrGroupId = user_1.Id,
                AccessLevel = 'Read',
                RowCause = MANUAL_ROW_CAUSE
        );
        Meeting__Share meetingShareUser2 = new Meeting__Share(
                ParentId = meeting_1.Id,
                UserOrGroupId = user_2.Id,
                AccessLevel = 'Read',
                RowCause = MANUAL_ROW_CAUSE
        );
        Meeting__Share meetingShareUser3 = new Meeting__Share(
                ParentId = meeting_1.Id,
                UserOrGroupId = user_3.Id,
                AccessLevel = 'Read',
                RowCause = MANUAL_ROW_CAUSE
        );

        insert new List<Meeting__Share>{meetingShareUser1, meetingShareUser2, meetingShareUser3};
    }

    @IsTest
    static void testUpdate_accountLookupAddedOrDeleted() {
        Account account_1 = [SELECT Id FROM Account WHERE Name = :ACCOUNT_1_NAME LIMIT 1];
        Meeting__c meeting = [SELECT Id FROM Meeting__c WHERE Subject__c = :MEETING_1_SUBJECT LIMIT 1];
        List<User> users = [SELECT Id, LastName FROM User WHERE Email IN :USER_EMAILS];
        Set<Id> allUserIds = new Set<Id>{users[0].Id, users[1].Id, users[2].Id, users[3].Id};
        Map<Id, Meeting__Share> shareByUserId = getShareRecordsByUserId(meeting.Id, allUserIds);

        System.assertEquals(4, shareByUserId.size(), 'Precondition failed: the number of exist shares is not correct');

        List<User> usersWithManualShare = new List<User>{users[0], users[1], users[2]};
        for (User user : usersWithManualShare) {
            System.assertEquals('Manual', shareByUserId.get(user.Id)?.RowCause, 'Precondition failed: share type not Manual or share not exist for ' + user.LastName);
        }

        System.assertEquals('Owner', shareByUserId.get(users[3].Id)?.RowCause, 'Precondition failed: share type not Owner or share not exist for ' + user.LastName);

        //After removing  Account lookup access must be removed for users who are not participant or owner
        meeting.Company__c = null;
        update meeting;

        Map<Id, Meeting__Share> updatedShareByUserId = getShareRecordsByUserId(meeting.Id, allUserIds);

        System.assertEquals(3, updatedShareByUserId.size(), 'The number of exist shares is not correct');

        usersWithManualShare = new List<User>{users[0], users[2]};
        for (User user : usersWithManualShare) {
            System.assertEquals('Manual', shareByUserId.get(user.Id)?.RowCause, 'Share type not Manual or share not exist for ' + user.LastName);
        }

        System.assertEquals('Owner', shareByUserId.get(users[3].Id)?.RowCause, 'Share type not Owner or share not exist for ' + user.LastName);

        //After linking account to the meeting access must be shared with users linked to account through the AccountShare
        meeting.Company__c = account_1.Id;
        update meeting;

        updatedShareByUserId = getShareRecordsByUserId(meeting.Id, allUserIds);

        System.assertEquals(4, shareByUserId.size(), 'The number of exist shares is not correct');

        usersWithManualShare = new List<User>{users[0], users[1], users[2]};
        for (User user : usersWithManualShare) {
            System.assertEquals('Manual', shareByUserId.get(user.Id)?.RowCause, 'Share type not Manual or share not exist for ' + user.LastName);
        }

        System.assertEquals('Owner', shareByUserId.get(users[3].Id)?.RowCause, 'Share type not Owner or share not exist for ' + user.LastName);
    }

    @IsTest
    static void testUpdate_accountLookupChanged() {
        // Account account_1 = [SELECT Id FROM Account WHERE Name = :ACCOUNT_1_NAME LIMIT 1];
        Account account_2 = new Account(Name = ACCOUNT_2_NAME, ManufacturerId__c = 'ID0', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');
        insert account_2;

        List<User> users = [SELECT Id, LastName FROM User WHERE Email IN :USER_EMAILS];
        Set<Id> allUserIds = new Set<Id>{users[0].Id, users[1].Id, users[2].Id, users[3].Id};

        Meeting__c meeting = [SELECT Id FROM Meeting__c WHERE Subject__c = :MEETING_1_SUBJECT LIMIT 1];
        
        Attendee__c participant_3 = [SELECT Id FROM Attendee__c WHERE User__c = :users[2].Id AND Meeting__c = :meeting.Id LIMIT 1];
        delete participant_3;

        AccountShare user_3_AccountShare = createAccountShare(users[2].Id, account_2.Id);
        insert user_3_AccountShare;

        Map<Id, Meeting__Share> shareByUserId = getShareRecordsByUserId(meeting.Id, allUserIds);

        System.assertEquals(3, shareByUserId.size(), 'Precondition failed: the number of exist shares is not correct');

        List<User> usersWithManualShare = new List<User>{users[0], users[1]};
        for (User user : usersWithManualShare) {
            System.assertEquals('Manual', shareByUserId.get(user.Id)?.RowCause, 'Precondition failed: share type not Manual or share not exist for ' + user.LastName);
        }

        System.assertEquals('Owner', shareByUserId.get(users[3].Id)?.RowCause, 'Precondition failed: share type not Owner or share not exist for ' + user.LastName);

        //After linking metting to another account access must be shared with users who linked to new account through the AccountShare
        meeting.Company__c = account_2.Id;
        update meeting;

        Map<Id, Meeting__Share> updatedShareByUserId = getShareRecordsByUserId(meeting.Id, allUserIds);

        System.assertEquals(3, shareByUserId.size(), 'The number of exist shares is not correct');

        usersWithManualShare = new List<User>{users[0], users[2]};
        for (User user : usersWithManualShare) {
            System.assertEquals('Manual', shareByUserId.get(user.Id)?.RowCause, 'Share type not Manual or share not exist for ' + user.LastName);
        }

        System.assertEquals('Owner', shareByUserId.get(users[3].Id)?.RowCause, 'Share type not Owner or share not exist for ' + user.LastName);
    }

    private static Map<Id, Meeting__Share> getShareRecordsByUserId(Id meetingId, Set<Id> userIds) {
        Map<Id, Meeting__Share> shareByUserId = new Map<Id, Meeting__Share>();

        List<Meeting__Share> shares =  [
                SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel
                FROM Meeting__Share
                WHERE ParentId = :meetingId AND (RowCause = 'Manual' OR RowCause = 'Owner') AND UserOrGroupId IN :userIds
        ];

        for (Meeting__Share share : shares) {
            shareByUserId.put(share.UserOrGroupId, share);
        }

        return shareByUserId;
    }

    private static AccountShare createAccountShare(Id userId, Id accountId) {
        AccountShare share = new AccountShare(
                AccountId = accountId,
                UserOrGroupId = userId,
                AccountAccessLevel = 'Edit',
                OpportunityAccessLevel = 'None',
                CaseAccessLevel = 'None',
                RowCause = MANUAL_ROW_CAUSE
        );

        return share;
    }
}
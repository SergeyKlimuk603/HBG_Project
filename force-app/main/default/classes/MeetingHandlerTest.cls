public with sharing class MeetingHandlerTest {
    private static final String USER_1_EMAIL = 'alice.participant1@example.com';
    private static final String USER_2_EMAIL = 'bob.participant2@example.com';
    private static final String USER_OWNER_EMAIL = 'owner.meeting@example.com';
    private static final String MEETING_1_SUBJECT = 'SUBJECT_1';
    private static final String MEETING_2_SUBJECT = 'SUBJECT_2';
    private static final String ACCOUNT_1_NAME = 'ACCOUNT_1_TEST_NAME';
    private static final String ACCOUNT_2_NAME = 'ACCOUNT_1_TEST_NAME';

        @TestSetup
    public static void testSetup() {
        Profile profile = [SELECT Id FROM Profile WHERE (NOT (Name LIKE '%admin%' OR Name LIKE '%read%')) AND UserLicense.Name = 'Salesforce' LIMIT 1];

        User user_1 = new User(
                FirstName = 'Alice',
                LastName = 'Participant1',
                Email = USER_1_EMAIL,
                Username = USER_1_EMAIL + System.currentTimeMillis(),
                Alias = 'alip1',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );
        User user_2 = new User(
                FirstName = 'Bob',
                LastName = 'Participant2',
                Email = USER_2_EMAIL,
                Username = USER_2_EMAIL + System.currentTimeMillis(),
                Alias = 'bobp2',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );

        User userOwner = new User(
                FirstName = 'Owner',
                LastName = 'MeetingOwner',
                Email = USER_OWNER_EMAIL,
                Username = USER_OWNER_EMAIL + System.currentTimeMillis(),
                Alias = 'ownmt',
                TimeZoneSidKey = 'Europe/Berlin',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile.Id
        );

        insert new List<User>{
                user_1, user_2, userOwner
        };
        Account account_1 = new Account(Name = ACCOUNT_1_NAME, ManufacturerId__c = 'ID0', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');
        Account account_2 = new Account(Name = ACCOUNT_2_NAME, ManufacturerId__c = 'ID1', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');

        Meeting__c meeting_1 = new Meeting__c(
                StartDateTime__c = Datetime.now(),
                EndDateTime__c = Datetime.now().addDays(3),
                Type__c = 'Allgemein',
                Subject__c = MEETING_1_SUBJECT);

        Meeting__c meeting_2 = new Meeting__c(StartDateTime__c = Datetime.now(),
                EndDateTime__c = Datetime.now().addDays(3),
                Type__c = 'Allgemein',
                Subject__c = MEETING_2_SUBJECT);

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Meeting_Permission'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userOwner.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        System.runAs(userOwner) {

            insert new List<Account>{
                    account_1, account_2
            };
            meeting_1.Company__c = account_1.Id;
            meeting_2.Company__c = account_2.Id;
            insert new List<Meeting__c>{
                    meeting_1, meeting_2
            };
        }
    }
}
/****************************************************************************************************
* Class AttendeeHandler
*
*   Create By   :  Andrei Pivavarchyk (mindsquare GmbH)
*   Create Date :  10.09.2025
*   Description  :  Trigger Handler for the Attendee__c SObject. This class implements the ITrigger
*           interface to help ensure the trigger code is bulkified and all in one place.
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                             Date           Description
*   * -----------------------------------------------------------------------------------------------
*   * Andrei Pivavarchyk (mindsquare GmbH)  10.09.2025     Init version.
****************************************************************************************************/
@IsTest
private class AttendeeHandlerTest {

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

    @IsTest
    static void testInsert_grantAccess_single() {
        Meeting__c meeting = [SELECT Id FROM Meeting__c WHERE Subject__c = :MEETING_1_SUBJECT];
        User user_1 = [SELECT Id FROM User WHERE Email = :USER_1_EMAIL];

        List<Meeting__Share> meetingShare = getShareRecordsByMeetingId(meeting.Id, new Set<Id>{
                user_1.Id
        });
        System.assertEquals(0, meetingShare.size(), 'Precondition failed: no shares should exist');
        Attendee__c attendee = createAttendee(user_1.Id, meeting.Id);
        List<Meeting__Share> newMeetingShare = getShareRecordsByMeetingId(meeting.Id, new Set<Id>{
                user_1.Id
        });
        System.assertEquals(1, newMeetingShare.size(), 'Expected a Meeting__Share for the inserted attendee');
    }


    @IsTest
    static void testInsertGrantAccessBulk() {

        User user_1 = [SELECT Id FROM User WHERE Email = :USER_1_EMAIL LIMIT 1];
        User user_2 = [SELECT Id FROM User WHERE Email = :USER_2_EMAIL LIMIT 1];
        User userOwner = [SELECT Id FROM User WHERE Email = :USER_OWNER_EMAIL LIMIT 1];

        Meeting__c meeting_1 = [SELECT Id FROM Meeting__c WHERE Subject__c = :MEETING_1_SUBJECT];
        Meeting__c meeting_2 = [SELECT Id FROM Meeting__c WHERE Subject__c = :MEETING_2_SUBJECT];

        List<Meeting__Share> meetingShare_1 = getShareRecordsByMeetingId(meeting_1.Id, new Set<Id>{
                user_1.Id, user_2.Id
        });
        List<Meeting__Share> meetingShare_2 = getShareRecordsByMeetingId(meeting_2.Id, new Set<Id>{
                user_1.Id, user_2.Id
        });

        System.assertEquals(0, meetingShare_1.size(), 'Precondition failed: no shares should exist');
        System.assertEquals(0, meetingShare_2.size(), 'Precondition failed: no shares should exist');


        System.runAs(userOwner) {
            List<Attendee__c> allAttendees = new List<Attendee__c>();
            List<Attendee__c> firstAttendeeList = new List<Attendee__c>();
            List<Attendee__c> duplicateAttendeeList = new List<Attendee__c>();

            //Create 2 participants with the same user for each meeting
            for (Integer i = 0; i <= 1; i++) {
                List<Attendee__c> iterationAttendeeList = new List<Attendee__c>();

                iterationAttendeeList.add(new Attendee__c(User__c = user_1.Id, Meeting__c = meeting_1.Id));
                iterationAttendeeList.add(new Attendee__c(User__c = user_1.Id, Meeting__c = meeting_2.Id));

                iterationAttendeeList.add(new Attendee__c(User__c = user_2.Id, Meeting__c = meeting_1.Id));
                iterationAttendeeList.add(new Attendee__c(User__c = user_2.Id, Meeting__c = meeting_2.Id));

                iterationAttendeeList.add(new Attendee__c(User__c = userOwner.Id, Meeting__c = meeting_1.Id));
                iterationAttendeeList.add(new Attendee__c(User__c = userOwner.Id, Meeting__c = meeting_2.Id));

                allAttendees.addAll(iterationAttendeeList);
                if (i == 0) {
                    firstAttendeeList.addAll(iterationAttendeeList);
                } else if (i == 1) {
                    duplicateAttendeeList.addAll(iterationAttendeeList);
                }
            }
            insert allAttendees;

            Set<Id> meetingIds = new Set<Id>{
                    meeting_1.Id, meeting_2.Id
            };
            List<Meeting__Share> shareRecordsUser_1 = getShareRecordsByUserId(user_1.Id, meetingIds);
            List<Meeting__Share> shareRecordsUser_2 = getShareRecordsByUserId(user_2.Id, meetingIds);
            List<Meeting__Share> shareRecordsUserOwner = getShareRecordsByUserId(userOwner.Id, meetingIds);

            System.assertEquals(meetingIds.size(), shareRecordsUser_1.size(), 'No shares exist for user_1');
            System.assertEquals(meetingIds.size(), shareRecordsUser_2.size(), 'No shares exist for user_2');
            System.assertEquals(meetingIds.size(), shareRecordsUserOwner.size(), 'No shares exist for userOwner');

            //After removing duplicate participants nothing should changed
            delete duplicateAttendeeList;

            List<Meeting__Share> shareRecordsUser_1_updated = getShareRecordsByUserId(user_1.Id, meetingIds);
            List<Meeting__Share> shareRecordsUser_2_updated = getShareRecordsByUserId(user_2.Id, meetingIds);
            List<Meeting__Share> shareRecordsUserOwner_updated = getShareRecordsByUserId(userOwner.Id, meetingIds);

            System.assertEquals(meetingIds.size(), shareRecordsUser_1_updated.size(), 'No shares exist for user_1');
            System.assertEquals(meetingIds.size(), shareRecordsUser_2_updated.size(), 'No shares exist for user_2');
            System.assertEquals(meetingIds.size(), shareRecordsUserOwner_updated.size(), 'No shares exist for userOwner');

            //After removing  participants access must be removed except owner User
            delete firstAttendeeList;

            List<Meeting__Share> shareRecordsUser_1_updated_2 = getShareRecordsByUserId(user_1.Id, meetingIds);
            List<Meeting__Share> shareRecordsUser_2_updated_2 = getShareRecordsByUserId(user_2.Id, meetingIds);
            List<Meeting__Share> shareRecordsUserOwner_updated_2 = getShareRecordsByUserId(userOwner.Id, meetingIds);

            System.assertEquals(0, shareRecordsUser_1_updated_2.size(), 'user_1 still has an access to the meeting');
            System.assertEquals(0, shareRecordsUser_2_updated_2.size(), 'user_2 still has an access to the meeting');
            System.assertEquals(meetingIds.size(), shareRecordsUserOwner_updated_2.size(), 'No shares exist for userOwner');
        }
    }


    private static List<Meeting__Share> getShareRecordsByMeetingId(Id meetingId, Set<Id> userIds) {
        return [
                SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel
                FROM Meeting__Share
                WHERE ParentId = :meetingId AND (RowCause = 'Manual' OR RowCause = 'Owner') AND UserOrGroupId IN :userIds
        ];
    }
    private static List<Meeting__Share> getShareRecordsByUserId(Id userId, Set<Id> meetingIds) {
        return [
                SELECT Id, ParentId, UserOrGroupId, RowCause, AccessLevel
                FROM Meeting__Share
                WHERE ParentId IN :meetingIds AND (RowCause = 'Manual' OR RowCause = 'Owner') AND UserOrGroupId = :userId
        ];
    }

    private static Attendee__c createAttendee(Id userId, Id meetingId) {
        Attendee__c attendee = new Attendee__c(
                User__c = userId,
                Meeting__c = meetingId
        );

        insert attendee;
        return attendee;
    }

}



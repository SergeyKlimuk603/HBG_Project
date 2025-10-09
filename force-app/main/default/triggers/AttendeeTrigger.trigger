/****************************************************************************************************
* Class AttendeeTrigger
*
*   Create By   :  Andrei Pivavarchyk (mindsquare GmbH)
*   Create Date :  10.09.2025
*   Description :  Trigger on Attendee__c object
*
*   Modification Log:
*   -------------------------------------------------------------------------------------------------
*   * Developer                             Date           Description
*   * -----------------------------------------------------------------------------------------------
*   * Andrei Pivavarchyk (mindsquare GmbH)  10.09.2025     Init version.
****************************************************************************************************/

trigger AttendeeTrigger on Attendee__c (after insert, after update, after delete) {
    new AttendeeHandler().execute();
}
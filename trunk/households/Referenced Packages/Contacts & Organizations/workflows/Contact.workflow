<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Contact%2EAlternateEmail%2EUpdate</fullName>
        <field>AlternateEmail__c</field>
        <formula>Email</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EHomePhone%2EUpdate</fullName>
        <field>HomePhone</field>
        <formula>Phone</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EMobilePhone%2EUpdate</fullName>
        <field>MobilePhone</field>
        <formula>Phone</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EOtherEmail%2EUpdate</fullName>
        <field>OtherPhone</field>
        <formula>Phone</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EPersonalEmail%2EUpdate</fullName>
        <field>HomeEmail__c</field>
        <formula>Email</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EPreferredEmail</fullName>
        <field>Email</field>
        <formula>CASE(
 Preferred_Email__c ,
&quot;Work&quot;,
 WorkEmail__c ,
&quot;Personal&quot;,
 HomeEmail__c,
&quot;Alternate&quot;,
 AlternateEmail__c,
If(LEN(WorkEmail__c)&gt;0 , WorkEmail__c ,
if(LEN(  HomeEmail__c)&gt;0,  HomeEmail__c,
 AlternateEmail__c
)))</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EPreferredPhone</fullName>
        <description>Populates the standard Phone field displayed on activities based on the Preferred Phone field value.</description>
        <field>Phone</field>
        <formula>CASE(
  PreferredPhone__c ,
&quot;Work&quot;,
  WorkPhone__c  ,
&quot;Home&quot;,
 HomePhone,
&quot;Mobile&quot;,
 MobilePhone,
&quot;Other&quot;,
 OtherPhone,
If(LEN( WorkPhone__c )&gt;0 , WorkPhone__c  ,
if(LEN(  HomePhone)&gt;0,  HomePhone,
if(LEN( MobilePhone)&gt;0, MobilePhone,
OtherPhone
))))</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EWorkEmail%2EUpdate</fullName>
        <field>WorkEmail__c</field>
        <formula>Email</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contact%2EWorkPhone%2EUpdate</fullName>
        <field>WorkPhone__c</field>
        <formula>Phone</formula>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Contact%2EEmailChanged_Alternate</fullName>
        <actions>
            <name>Contact%2EAlternateEmail%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Email ), ISPICKVAL( Preferred_Email__c ,&quot;Alternate&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EEmailChanged_Personal</fullName>
        <actions>
            <name>Contact%2EPersonalEmail%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Email ), ISPICKVAL( Preferred_Email__c ,&quot;Personal&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EEmailChanged_Work</fullName>
        <actions>
            <name>Contact%2EWorkEmail%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Email ), ISPICKVAL( Preferred_Email__c ,&quot;Work&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPhoneChanged_Home</fullName>
        <actions>
            <name>Contact%2EHomePhone%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Phone), ISPICKVAL( PreferredPhone__c ,&quot;Home&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPhoneChanged_Mobile</fullName>
        <actions>
            <name>Contact%2EMobilePhone%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Phone), ISPICKVAL( PreferredPhone__c ,&quot;Mobile&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPhoneChanged_Other</fullName>
        <actions>
            <name>Contact%2EOtherEmail%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Phone), ISPICKVAL( PreferredPhone__c ,&quot;Other&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPhoneChanged_Work</fullName>
        <actions>
            <name>Contact%2EWorkPhone%2EUpdate</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND( ISCHANGED( Phone), ISPICKVAL( PreferredPhone__c ,&quot;Work&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPreferred_Email%5F%5Fc</fullName>
        <actions>
            <name>Contact%2EPreferredEmail</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This workflow OVERWRITES the existing value in the standard Email field based on the Preferred Email field value.  This rule needs to be turned on manually after an Upgrade to this package.</description>
        <formula>OR( LEN(Email)=0, ISCHANGED(Preferred_Email__c) , ISCHANGED(WorkEmail__c) , ISCHANGED(HomeEmail__c) , ISCHANGED(AlternateEmail__c)  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Contact%2EPreferred_Phone%5F%5Fc</fullName>
        <actions>
            <name>Contact%2EPreferredPhone</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>This workflow OVERWRITES the existing value in the standard Phone field based on the Preferred Phone field value.  This rule needs to be turned on manually after an Upgrade to this package.</description>
        <formula>AND(  NOT(ISPICKVAL(PreferredPhone__c,&quot;&quot;)),   OR(  ISCHANGED(PreferredPhone__c) ,  ISCHANGED(WorkPhone__c) ,  ISCHANGED(HomePhone) ,  ISCHANGED(MobilePhone) , ISCHANGED(OtherPhone)  )  )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>

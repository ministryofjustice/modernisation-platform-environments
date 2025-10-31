
debugger; 
import fetch from 'node-fetch';
import https from 'https';

const httpsAgent = new https.Agent({
    rejectUnauthorized: false,
  });

let suffix = "" + Date.now()

let endpoint = 'ingest' 
// let endpoint = 'dev-ingest' 
// let endpoint = 'preingest' 


let doc = getDvlaDoc(
	{
		correlationId : 		"" + suffix,
		documentId : 			  "" + suffix,
		description  :      endpoint + " BITS TEST " + suffix,
		name : 					    endpoint + " BITS TEST " + suffix,
		dvlaDocIdName: 			endpoint + " BITS TEST " + suffix,
		dvlaDocIdUniqueId:  "CSDD" + suffix,

	}
)



let result = await sendRequest(doc, 'https://' + endpoint  + '.cjsonline.gov.uk/BITSWebService/BITSWebservice.asmx' )


console.log(result)




async function sendRequest (body, url) {

  const response = await fetch(url, {
    method: 'post',
    body: body ,
    headers: {'Content-Type': 'text/xml'},
    agent: httpsAgent,
  //      headers: {'Content-Type': 'application/soap+xml'}
  });
  const data = await response.text();

  return data

}  



function getDvlaDoc({correlationId, documentId, description, name, dvlaDocIdName, dvlaDocIdUniqueId})  {


	let text  = `<?xml version="1.0" encoding="iso-8859-1"?>
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
		  <soap:Body>
		    <BITSSubmit xmlns="urn:BITS-cjsonline-gov-uk:pilot:BITS">
		      <BITSRequestMessage xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:op="urn:integration-cjsonline-gov-uk:pilot:operations" xmlns:bi="urn:BITS-cjsonline-gov-uk:pilot:BITS" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:be="urn:integration-cjsonline-gov-uk:pilot:entities" xmlns:me="urn:integration-cjsonline-gov-uk:pilot:messaging" xmlns:ty="urn:integration-cjsonline-gov-uk:pilot:types">
		        <bi:RoutingHeader>
		          <me:SourceSystemIdentifier>SCC01</me:SourceSystemIdentifier>
		          <me:DestinationSystemIdentifier>XCJSE01</me:DestinationSystemIdentifier>
		        </bi:RoutingHeader>
		        <bi:CJODocumentRequest MessageCorrelationID="${correlationId}" SuccessResponseRequired="true" TransactionRequired="false">
		          <bi:DocumentConfig>BITS.DVLAD20Handler</bi:DocumentConfig>
		          <bi:DocumentRegistration>
		            <bi:Document VersionNumber="77">
		              <be:DocumentIdentifier VersionNumber="99">
		                <be:DocumentID>${documentId}</be:DocumentID>
		                <be:SystemID>SCC01</be:SystemID>
		              </be:DocumentIdentifier>
		              <be:DocumentType VersionNumber="88">
		                <be:Code>D20</be:Code>
		                <be:Category>2</be:Category>
		                <be:Description>${description}</be:Description>
		              </be:DocumentType>
		              <be:RegisteringLocation>453</be:RegisteringLocation>
		              <be:Name>${name}</be:Name>
		              <be:Description>2E Detention and Training Order - Basic Create</be:Description>
		              <be:RegistrationDate>2003-12-01T00:00:00.0000000-00:00</be:RegistrationDate>
		              <be:ModificationDate>2003-12-01T00:00:00.0000000-00:00</be:ModificationDate>
		              <be:DocumentSize>2000</be:DocumentSize>
		            </bi:Document>
		            <bi:DocumentAccess>
		              <bi:Roles>
		                <bi:RoleIdentifier VersionNumber="55">
		                  <be:RoleID>PRI</be:RoleID>
		                </bi:RoleIdentifier>
		              </bi:Roles>
		            </bi:DocumentAccess>
		            <bi:RegistrationEntities>
		              <CRNs RegisterAll="true" RegisterWithLocation="true" />
		            </bi:RegistrationEntities>
		            <bi:NotificationsAndAlerts>
		              <be:NarrativeText>A Comment String</be:NarrativeText>
		            </bi:NotificationsAndAlerts>
		          </bi:DocumentRegistration>
		          <bi:DocumentContent>


		<cs:DVLAD20 xmlns:cs="http://www.courtservice.gov.uk/schemas/courtservice" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:apd="http://www.govtalk.gov.uk/people/AddressAndPersonalDetails" xsi:schemaLocation="http://www.courtservice.gov.uk/schemas/courtservice DVLAD20-v6-1.xsd">
		  <cs:DocumentID>
		  	  <cs:DocumentName>${dvlaDocIdName}</cs:DocumentName>
			  <cs:UniqueID>${dvlaDocIdUniqueId}</cs:UniqueID>
			  <cs:DocumentType>D20</cs:DocumentType>
			  <cs:TimeStamp>2015-07-15T15:13:20.569</cs:TimeStamp>
			  <cs:Version>1.0</cs:Version>
			  <cs:SecurityClassification>NPM</cs:SecurityClassification>
			  <cs:SellByDate>2016-05-10</cs:SellByDate>
			  <cs:XSLstylesheetURL>http://www.courtservice.gov.uk/transforms/courtservice/DVLAD20-v1-6.xsl</cs:XSLstylesheetURL>
		  </cs:DocumentID>
		  <cs:CourtHouse><cs:CourtHouseType>Crown Court</cs:CourtHouseType>
		  <cs:CourtHouseCode CourtHouseShortName="SNARE">453</cs:CourtHouseCode>
		    <cs:CourtHouseName>SNARESBROOK</cs:CourtHouseName>
		    <cs:CourtHouseAddress><apd:Line>Whqxmwpxiis Oiuxv Diuwm</apd:Line>
		    <apd:Line>87 Dirrapuwd Dcrr</apd:Line><apd:Line>Snaresbrook</apd:Line>
		      <apd:Line>London</apd:Line>
		      <apd:PostCode>M44 4YK</apd:PostCode>
		    </cs:CourtHouseAddress>
		  </cs:CourtHouse>
		  <cs:CaseNumber>T20140005</cs:CaseNumber>
		  <cs:CRESTdefendantID>29438</cs:CRESTdefendantID>
		  <cs:D20NotificationMessage Flow="D20NotificationDetailsFromTheCourt" Interface="XhibitDVLAdrivers" SchemaVersion="1.2">
		    <cs:DriversWithEndorsements><cs:Driver><cs:SourceCMU>CRWN</cs:SourceCMU>
		    <cs:SourceMCC>0</cs:SourceMCC>
		      <cs:SourceCourthouse>CRWN</cs:SourceCourthouse>
		      <cs:SourceCourtroom>0</cs:SourceCourtroom>
		      <cs:SourceIdentity>XHIBIT</cs:SourceIdentity>
		      <cs:DocumentType>D20</cs:DocumentType>
		      <cs:LibraCaseAccountNumber>T20140005</cs:LibraCaseAccountNumber>
		      <cs:EventDate>2015-07-15</cs:EventDate>
		      <cs:BasicDriverDetails><cs:DriverNumber>HINGS713154BJ9WS</cs:DriverNumber>
		      <cs:PersonName><cs:PersonFamilyName>FURNIER</cs:PersonFamilyName>
		      <cs:PersonGivenName1>VINCENT</cs:PersonGivenName1>
		        <cs:PersonGivenName2>VINCENT</cs:PersonGivenName2>
		        <cs:PersonGivenName3>Baron</cs:PersonGivenName3></cs:PersonName>
		        <cs:Birthdate>1976-04-20</cs:Birthdate>
		        <cs:Gender>Male</cs:Gender></cs:BasicDriverDetails>
		      <cs:LicenceRecordType>2</cs:LicenceRecordType>
		      <cs:DriverLicenceIssue>29</cs:DriverLicenceIssue>
		      <cs:CounterpartIssue>A</cs:CounterpartIssue><cs:PreviouslyNotifiedEndorsements>0</cs:PreviouslyNotifiedEndorsements><cs:LicenceToFollowMarker>0</cs:LicenceToFollowMarker>
		      <cs:UnstructuredAddress><cs:AddressLine1>12 GREEN ACRES</cs:AddressLine1><cs:AddressLine2>EALING BROADWAY</cs:AddressLine2><cs:AddressLine3>LONDON</cs:AddressLine3>
		      <cs:PostCode>EC1 3TT</cs:PostCode></cs:UnstructuredAddress><cs:HardshipMarker>no</cs:HardshipMarker><cs:EndorsementsNotified>yes</cs:EndorsementsNotified>
		      <cs:PaperLicenceEnclosed>no</cs:PaperLicenceEnclosed><cs:PhotocardEnclosed>yes</cs:PhotocardEnclosed><cs:PaperLicenceEndorsed>no</cs:PaperLicenceEndorsed>
		      <cs:CounterpartLicenceEndorsed>no</cs:CounterpartLicenceEndorsed><cs:ForeignLicenceEnclosed>no</cs:ForeignLicenceEnclosed><cs:OtherName>Alfred Furnier</cs:OtherName>
		      <cs:OtherAddress><cs:AddressLine1>10 DENT STREET </cs:AddressLine1><cs:AddressLine2>LONDON</cs:AddressLine2><cs:AddressLine3>London</cs:AddressLine3>
		      <cs:AddressLine4>THATCHAM</cs:AddressLine4><cs:AddressLine5>WEST BERKSHIRE</cs:AddressLine5><cs:PostCode>EC1 2RT</cs:PostCode></cs:OtherAddress></cs:Driver>
		      <cs:Endorsement><cs:ConvictionDate>2015-07-13</cs:ConvictionDate><cs:BasicEndorsementDetails><cs:DVLAoffenceCode>OH12</cs:DVLAoffenceCode>
		      <cs:OffenceDate>2015-07-13</cs:OffenceDate><cs:ConvictingCourt>2681</cs:ConvictingCourt><cs:SentencingCourt>1778</cs:SentencingCourt>
		        <cs:DateOfSentence>2015-07-13</cs:DateOfSentence><cs:Fine>100.00</cs:Fine><cs:PenaltyPoints>5</cs:PenaltyPoints><cs:DisqualificationPeriod>020604</cs:DisqualificationPeriod>
		        <cs:DisqualificationUntilTestPassed>1</cs:DisqualificationUntilTestPassed><cs:DisqualificationPendingSentence>2</cs:DisqualificationPendingSentence>
		        <cs:AlcoholLevelMethod>A</cs:AlcoholLevelMethod><cs:AlcoholLevelAmount>37</cs:AlcoholLevelAmount><cs:SecondarySentencePeriod>30</cs:SecondarySentencePeriod>
		        <cs:SecondarySentenceQualifier>C30D</cs:SecondarySentenceQualifier><cs:DateDisqualificationRemoved>2015-07-17</cs:DateDisqualificationRemoved>
		        <cs:DateDisqualificationSuspended>2015-07-16</cs:DateDisqualificationSuspended><cs:DateDisqualificationReimposed>2015-07-15</cs:DateDisqualificationReimposed>
		        <cs:AppealCourt>453</cs:AppealCourt></cs:BasicEndorsementDetails></cs:Endorsement><cs:Endorsement><cs:ConvictionDate>2015-07-13</cs:ConvictionDate>
		        <cs:BasicEndorsementDetails><cs:DVLAoffenceCode>OA87</cs:DVLAoffenceCode><cs:OffenceDate>2015-07-13</cs:OffenceDate><cs:ConvictingCourt>2681</cs:ConvictingCourt>
		        <cs:SentencingCourt>1952</cs:SentencingCourt><cs:DateOfSentence>2015-07-13</cs:DateOfSentence><cs:Fine>20.00</cs:Fine><cs:PenaltyPoints>2</cs:PenaltyPoints>
		          <cs:DisqualificationPeriod>010203</cs:DisqualificationPeriod><cs:DisqualificationUntilTestPassed>1</cs:DisqualificationUntilTestPassed>
		          <cs:DisqualificationPendingSentence>1</cs:DisqualificationPendingSentence><cs:AlcoholLevelMethod>A</cs:AlcoholLevelMethod><cs:AlcoholLevelAmount>23</cs:AlcoholLevelAmount><cs:SecondarySentencePeriod>12</cs:SecondarySentencePeriod>
		          <cs:SecondarySentenceQualifier>A12M</cs:SecondarySentenceQualifier><cs:DateDisqualificationRemoved>2015-07-20</cs:DateDisqualificationRemoved><cs:DateDisqualificationSuspended>2015-07-21</cs:DateDisqualificationSuspended>
		          <cs:DateDisqualificationReimposed>2015-07-22</cs:DateDisqualificationReimposed><cs:AppealCourt>453</cs:AppealCourt></cs:BasicEndorsementDetails></cs:Endorsement><cs:Endorsement><cs:ConvictionDate>2015-07-13</cs:ConvictionDate>
		          <cs:BasicEndorsementDetails><cs:DVLAoffenceCode>0B34</cs:DVLAoffenceCode><cs:OffenceDate>2015-07-13</cs:OffenceDate><cs:ConvictingCourt>2681</cs:ConvictingCourt><cs:SentencingCourt>3222</cs:SentencingCourt>
		          <cs:DateOfSentence>2015-07-13</cs:DateOfSentence><cs:Fine>300.00</cs:Fine><cs:PenaltyPoints>3</cs:PenaltyPoints><cs:DisqualificationPeriod>030201</cs:DisqualificationPeriod>
		            <cs:DisqualificationUntilTestPassed>1</cs:DisqualificationUntilTestPassed><cs:DisqualificationPendingSentence>2</cs:DisqualificationPendingSentence><cs:AlcoholLevelMethod>U</cs:AlcoholLevelMethod>
		            <cs:AlcoholLevelAmount>13</cs:AlcoholLevelAmount><cs:SecondarySentencePeriod>6</cs:SecondarySentencePeriod><cs:SecondarySentenceQualifier>F6W</cs:SecondarySentenceQualifier>
		            <cs:DateDisqualificationRemoved>2015-07-27</cs:DateDisqualificationRemoved><cs:DateDisqualificationSuspended>2015-07-28</cs:DateDisqualificationSuspended><cs:DateDisqualificationReimposed>2015-07-29</cs:DateDisqualificationReimposed>
		            <cs:AppealCourt>453</cs:AppealCourt></cs:BasicEndorsementDetails></cs:Endorsement><cs:Endorsement><cs:ConvictionDate>2015-07-13</cs:ConvictionDate><cs:BasicEndorsementDetails><cs:DVLAoffenceCode>3R45</cs:DVLAoffenceCode>
		            <cs:OffenceDate>2015-07-13</cs:OffenceDate><cs:ConvictingCourt>2681</cs:ConvictingCourt><cs:SentencingCourt>2814</cs:SentencingCourt><cs:DateOfSentence>2015-07-13</cs:DateOfSentence><cs:Fine>40.00</cs:Fine><cs:PenaltyPoints>4</cs:PenaltyPoints>
		              <cs:DisqualificationPeriod>040506</cs:DisqualificationPeriod><cs:DisqualificationPendingSentence>1</cs:DisqualificationPendingSentence><cs:AlcoholLevelMethod>B</cs:AlcoholLevelMethod><cs:AlcoholLevelAmount>49</cs:AlcoholLevelAmount>
		              <cs:SecondarySentencePeriod>2</cs:SecondarySentencePeriod><cs:SecondarySentenceQualifier>H2Y</cs:SecondarySentenceQualifier><cs:DateDisqualificationRemoved>2015-07-06</cs:DateDisqualificationRemoved>
		              <cs:DateDisqualificationSuspended>2015-07-07</cs:DateDisqualificationSuspended><cs:DateDisqualificationReimposed>2015-07-08</cs:DateDisqualificationReimposed>
		              <cs:NoDisqualificationMitigatingCircumstances>no</cs:NoDisqualificationMitigatingCircumstances>
		              <cs:NoDisqualificationSpecialReasons>yes</cs:NoDisqualificationSpecialReasons>
		              <cs:NotificationOfDisability>no</cs:NotificationOfDisability>
		              <cs:AppealCourt>453</cs:AppealCourt>
		              <cs:Appeals>
		                <cs:AppealAgainstConviction>yes</cs:AppealAgainstConviction>
		                <cs:AppealAgainstSentenceOnly>no</cs:AppealAgainstSentenceOnly>
		                <cs:AppealAllowed>yes</cs:AppealAllowed>
		                <cs:AppealDismissed>1999-05-31</cs:AppealDismissed>
		                <cs:AppealAbandoned>1999-05-31</cs:AppealAbandoned>
		                <cs:SentenceVaried>no</cs:SentenceVaried>
		                <cs:AppealRemitted>1999-05-31</cs:AppealRemitted>
		              </cs:Appeals>
		            </cs:BasicEndorsementDetails></cs:Endorsement></cs:DriversWithEndorsements></cs:D20NotificationMessage><cs:Form><cs:FormNumber>1</cs:FormNumber><cs:TotalForms>1</cs:TotalForms>
		              </cs:Form>
		   </cs:DVLAD20>

		          </bi:DocumentContent>
		        </bi:CJODocumentRequest>
		      </BITSRequestMessage>
		    </BITSSubmit>
		  </soap:Body>
		</soap:Envelope>`


		return text 

}


function getDailyListDoc({correlationId, documentId, description, name, dvlaDocIdName, dvlaDocIdUniqueId})  {


let text  = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"> <soap:Body>
  <BITSSubmit xmlns="urn:BITS-cjsonline-gov-uk:pilot:BITS">
    <BITSRequestMessage xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:op="urn:integration-cjsonline-gov-uk:pilot:operations" xmlns:bi="urn:BITS-cjsonline-gov-uk:pilot:BITS" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:be="urn:integration-cjsonline-gov-uk:pilot:entities" xmlns:me="urn:integration-cjsonline-gov-uk:pilot:messaging" xmlns:ty="urn:integration-cjsonline-gov-uk:pilot:types">
      <bi:RoutingHeader>
        <me:SourceSystemIdentifier>SCC010457</me:SourceSystemIdentifier>
        <me:DestinationSystemIdentifier>XCJSE01</me:DestinationSystemIdentifier>
      </bi:RoutingHeader>
      <bi:CJODocumentRequest MessageCorrelationID="${correlationId}" SuccessResponseRequired="true" TransactionRequired="false">
        <bi:DocumentConfig>BITS.DailyListHandler</bi:DocumentConfig>
        <bi:DocumentRegistration>
          <bi:Document VersionNumber="1">
            <be:DocumentIdentifier VersionNumber="1">
              <be:DocumentID>${documentId}</be:DocumentID>
              <be:SystemID>SCC010457</be:SystemID>
            </be:DocumentIdentifier>
            <be:DocumentType VersionNumber="1">
              <be:Code>DAILYLIST</be:Code>
              <be:Description>Daily List, Swansea on 24/12/21 FINAL v1</be:Description>
            </be:DocumentType>
            <be:RegisteringLocation>457</be:RegisteringLocation>
            <be:Name>DL 24/12/21 FINAL v1</be:Name>
            <be:Description>Daily List, Swansea on 24/12/21 FINAL v1</be:Description>
            <be:RegistrationDate>2022-03-16T10:13:58</be:RegistrationDate>
            <be:ModificationDate>2022-03-16T10:13:58</be:ModificationDate>
            <be:DocumentSize>18416</be:DocumentSize>
          </bi:Document>
          <bi:DocumentAccess>
            <bi:Roles>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>POL</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>MC</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>CPS</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>PRO</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>DEF</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>YOT</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>WS</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>VS</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>PA</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>DA</be:RoleID>
              </bi:RoleIdentifier>
              <bi:RoleIdentifier VersionNumber="1">
                <be:RoleID>JUD</be:RoleID>
              </bi:RoleIdentifier>
            </bi:Roles>
          </bi:DocumentAccess>
          <bi:RegistrationEntities>
            <bi:CRNs RegisterAll="true" RegisterWithLocation="true"></bi:CRNs>
          </bi:RegistrationEntities>
        </bi:DocumentRegistration>
        <bi:DocumentContent>
          <cs:DailyList xmlns:cs="http://www.courtservice.gov.uk/schemas/courtservice" xmlns:apd="http://www.govtalk.gov.uk/people/AddressAndPersonalDetails" xmlns="http://www.govtalk.gov.uk/people/AddressAndPersonalDetails" xmlns:p2="http://www.govtalk.gov.uk/people/bs7666" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.courtservice.gov.uk/schemas/courtservice DailyList-v6-2.xsd">
            <cs:DocumentID>
              <cs:DocumentName>Daily List FINAL v1 24-DEC-21</cs:DocumentName>
              <cs:UniqueID>${documentId + "001"}</cs:UniqueID>
              <cs:DocumentType>DL</cs:DocumentType>
              <cs:TimeStamp>2022-03-16T10:13:58.000</cs:TimeStamp>
              <cs:Version>1.0</cs:Version>
              <cs:SecurityClassification>NPM</cs:SecurityClassification>
              <cs:SellByDate>2022-05-20</cs:SellByDate>
              <cs:XSLstylesheetURL>http://www.courtservice.gov.uk/transforms/courtservice/dailyListHtml-v2-2.xsl</cs:XSLstylesheetURL>
            </cs:DocumentID>
            <cs:ListHeader>
              <cs:ListCategory>Criminal</cs:ListCategory>
              <cs:StartDate>2021-12-24</cs:StartDate>
              <cs:EndDate>2021-12-24</cs:EndDate>
              <cs:Version>FINAL 1</cs:Version>
              <cs:PublishedTime>2022-03-16T10:13:57.000</cs:PublishedTime>
              <cs:CRESTlistID>707</cs:CRESTlistID>
            </cs:ListHeader>
            <cs:CrownCourt>
              <cs:CourtHouseType>Crown Court</cs:CourtHouseType>
              <cs:CourtHouseCode CourtHouseShortName="SWANS">457</cs:CourtHouseCode>
              <cs:CourtHouseName>SWANSEA</cs:CourtHouseName>
              <cs:CourtHouseAddress>
                <apd:Line>The Law Courts QE III</apd:Line>
                <apd:Line>Qe II</apd:Line>
                <apd:Line> ST HELENS</apd:Line>
                <apd:Line>-</apd:Line>
                <apd:Line>Swansea</apd:Line>
                <apd:PostCode>SE10 9FG</apd:PostCode>
              </cs:CourtHouseAddress>
              <cs:CourtHouseDX>DX: 321 SWANSEA</cs:CourtHouseDX>
              <cs:CourtHouseTelephone>01792 484701</cs:CourtHouseTelephone>
              <cs:CourtHouseFax>01792 484714</cs:CourtHouseFax>
              <cs:Description>CROWN COURT</cs:Description>
            </cs:CrownCourt>
            <cs:CourtLists>
              <cs:CourtList>
                <cs:CourtHouse>
                  <cs:CourtHouseType>Crown Court</cs:CourtHouseType>
                  <cs:CourtHouseCode>457</cs:CourtHouseCode>
                  <cs:CourtHouseName>SWANSEA</cs:CourtHouseName>
                  <cs:Description>CROWN COURT</cs:Description>
                </cs:CourtHouse>
                <cs:Sittings>
                  <cs:Sitting>
                    <cs:CourtRoomNumber>1</cs:CourtRoomNumber>
                    <cs:SittingSequenceNo>1</cs:SittingSequenceNo>
                    <cs:SittingAt>10:00:00</cs:SittingAt>
                    <cs:SittingPriority>T</cs:SittingPriority>
                    <cs:Judiciary>
                      <cs:Judge>
                        <apd:CitizenNameTitle>MS</apd:CitizenNameTitle>
                        <apd:CitizenNameForename>ALLISON</apd:CitizenNameForename>
                        <apd:CitizenNameSurname>KELLEY</apd:CitizenNameSurname>
                        <apd:CitizenNameRequestedName>Before Judge : KELLEY</apd:CitizenNameRequestedName>
                        <cs:CRESTjudgeID>309</cs:CRESTjudgeID>
                      </cs:Judge>
                    </cs:Judiciary>
                    <cs:Hearings>
                      <cs:Hearing>
                        <cs:HearingSequenceNumber>1</cs:HearingSequenceNumber>
                        <cs:HearingDetails HearingType="TRL">
                          <cs:HearingDescription>For Trial</cs:HearingDescription>
                          <cs:HearingDate>2021-12-24</cs:HearingDate>
                        </cs:HearingDetails>
                        <cs:CRESThearingID>5569</cs:CRESThearingID>
                        <cs:TimeMarkingNote> </cs:TimeMarkingNote>
                        <cs:CaseNumber>T20200190</cs:CaseNumber>
                        <cs:Prosecution ProsecutingAuthority="Other Prosecutor">
                          <cs:ProsecutingReference>DUNN</cs:ProsecutingReference>
                          <cs:ProsecutingOrganisation>
                            <cs:OrganisationName>CHRISTINE CAROLYN DUNN</cs:OrganisationName>
                          </cs:ProsecutingOrganisation>
                        </cs:Prosecution>
                        <cs:CommittingCourt>
                          <cs:CourtHouseType>Magistrates Court</cs:CourtHouseType>
                          <cs:CourtHouseCode CourtHouseShortName="ACTY">6723</cs:CourtHouseCode>
                          <cs:CourtHouseName>ACTON YOUTH COURT</cs:CourtHouseName>
                          <cs:CourtHouseAddress>
                            <apd:Line>THE COURT HOUSE</apd:Line>
                            <apd:Line>WINCHESTER STREET</apd:Line>
                            <apd:Line>ACTON</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>LONDON</apd:Line>
                            <apd:PostCode>W3 8PB</apd:PostCode>
                          </cs:CourtHouseAddress>
                          <cs:CourtHouseTelephone>020 7992 9014</cs:CourtHouseTelephone>
                        </cs:CommittingCourt>
                        <cs:NumberOfDefendants>1</cs:NumberOfDefendants>
                        <cs:Defendants>
                          <cs:Defendant>
                            <cs:PersonalDetails>
                              <cs:Name>
                                <apd:CitizenNameForename>Van</apd:CitizenNameForename>
                                <apd:CitizenNameForename>Slayerf</apd:CitizenNameForename>
                                <apd:CitizenNameSurname>HELSINGN</apd:CitizenNameSurname>
                              </cs:Name>
                              <cs:IsMasked>no</cs:IsMasked>
                              <cs:DateOfBirth>
                                <apd:BirthDate>1989-03-06</apd:BirthDate>
                                <apd:VerifiedBy>not verified</apd:VerifiedBy>
                              </cs:DateOfBirth>
                              <cs:Sex>male</cs:Sex>
                              <cs:Address>
                                <apd:Line>ADDRESS 1</apd:Line>
                                <apd:Line>ADDRESS 2</apd:Line>
                                <apd:Line>ADDRESS 3</apd:Line>
                                <apd:Line>ADDRESS 4</apd:Line>
                                <apd:Line>TOWN,COUNTY</apd:Line>
                              </cs:Address>
                            </cs:PersonalDetails>
                            <cs:ContactDetails></cs:ContactDetails>
                            <cs:ASNs>
                              <cs:ASN>2007BB1234567890123Y</cs:ASN>
                            </cs:ASNs>
                            <cs:CRESTdefendantID>30687</cs:CRESTdefendantID>
                            <cs:URN>01A21234521</cs:URN>
                            <cs:CustodyStatus>On bail</cs:CustodyStatus>
                            <cs:Counsel></cs:Counsel>
                            <cs:Charges NumberOfCharges="6">
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="TH68009">
                                <cs:CRN>2007BB1234567890123Y001</cs:CRN>
                                <cs:CRESTchargeID>457S00670903</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Theft from other vehicle</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-02-05T10:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceEndDateTime>2021-02-05T11:00:00.000</cs:OffenceEndDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670903</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="2" CJSoffenceCode="TH68010">
                                <cs:CRN>2007BB1234567890123Y001</cs:CRN>
                                <cs:CRESTchargeID>457S00670904</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Theft from a shop / stall</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-02-04T12:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceEndDateTime>2021-02-04T13:00:00.000</cs:OffenceEndDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670904</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="3" CJSoffenceCode="TH68015">
                                <cs:CRN>2007BB1234567890123Y001</cs:CRN>
                                <cs:CRESTchargeID>457S00670905</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Theft of conveyance other than motor vehicle / pedal cycle</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-02-04T13:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceEndDateTime>2021-02-04T13:30:00.000</cs:OffenceEndDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670905</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="4" CJSoffenceCode="TH68001">
                                <cs:CRN>2007BB1234567890123Y001</cs:CRN>
                                <cs:CRESTchargeID>457S00670906</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Theft from the person of another</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-02-04T14:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceEndDateTime>2021-02-04T15:00:00.000</cs:OffenceEndDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670906</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="RT88026">
                                <cs:CRN>2007BB1234567890123Y002</cs:CRN>
                                <cs:CRESTchargeID>457S00671114</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Dangerous driving</cs:OffenceStatement>
                                <cs:ArrestingPoliceForceCode>01</cs:ArrestingPoliceForceCode>
                                <cs:OffenceStartDateTime>2021-08-17T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>671114</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="RT88191">
                                <cs:CRN>2007BB1234567890123Y001</cs:CRN>
                                <cs:CRESTchargeID>457S00671115</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200190</cs:CaseNumber>
                                <cs:OffenceStatement>Use vehicle without insurance</cs:OffenceStatement>
                                <cs:ArrestingPoliceForceCode>01</cs:ArrestingPoliceForceCode>
                                <cs:OffenceStartDateTime>2020-11-01T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>671115</cs:CRESToffenceNumber>
                              </cs:Charge>
                            </cs:Charges>
                            <cs:DefendantNumber>1</cs:DefendantNumber>
                          </cs:Defendant>
                        </cs:Defendants>
                      </cs:Hearing>
                      <cs:Hearing>
                        <cs:HearingSequenceNumber>2</cs:HearingSequenceNumber>
                        <cs:HearingDetails HearingType="TRL">
                          <cs:HearingDescription>For Trial</cs:HearingDescription>
                          <cs:HearingDate>2021-12-24</cs:HearingDate>
                        </cs:HearingDetails>
                        <cs:CRESThearingID>5566</cs:CRESThearingID>
                        <cs:TimeMarkingNote> </cs:TimeMarkingNote>
                        <cs:CaseNumber>T20190024</cs:CaseNumber>
                        <cs:Prosecution ProsecutingAuthority="Crown Prosecution Service">
                          <cs:ProsecutingReference>Crown Prosecution Service</cs:ProsecutingReference>
                          <cs:ProsecutingOrganisation>
                            <cs:OrganisationCode>001</cs:OrganisationCode>
                            <cs:OrganisationName>Crown Prosecution Service</cs:OrganisationName>
                          </cs:ProsecutingOrganisation>
                        </cs:Prosecution>
                        <cs:CommittingCourt>
                          <cs:CourtHouseType>Magistrates Court</cs:CourtHouseType>
                          <cs:CourtHouseCode CourtHouseShortName="ALTPM">1778</cs:CourtHouseCode>
                          <cs:CourtHouseName>ALTON AND PETERSFIELD MAGISTRATES&apos; COURT</cs:CourtHouseName>
                          <cs:CourtHouseAddress>
                            <apd:Line>THE COURT HOUSE</apd:Line>
                            <apd:Line>CIVIC CENTRE</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>ALDERSHOT,HAMPSHIRE</apd:Line>
                            <apd:PostCode>GU11 1NY</apd:PostCode>
                          </cs:CourtHouseAddress>
                          <cs:CourtHouseDX>DX 50102 ALDERSHOT 1</cs:CourtHouseDX>
                          <cs:CourtHouseTelephone>01252 27878</cs:CourtHouseTelephone>
                        </cs:CommittingCourt>
                        <cs:NumberOfDefendants>1</cs:NumberOfDefendants>
                        <cs:Defendants>
                          <cs:Defendant>
                            <cs:PersonalDetails>
                              <cs:Name>
                                <apd:CitizenNameSurname>XEROX</apd:CitizenNameSurname>
                              </cs:Name>
                              <cs:IsMasked>no</cs:IsMasked>
                              <cs:Sex>unknown</cs:Sex>
                              <cs:Address>
                                <apd:Line>59 COPIER WAY</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>COPY,COPYLANDS</apd:Line>
                                <apd:PostCode>CR5 5WE</apd:PostCode>
                              </cs:Address>
                            </cs:PersonalDetails>
                            <cs:ContactDetails></cs:ContactDetails>
                            <cs:ASNs>
                              <cs:ASN>1535VA0744237750552G</cs:ASN>
                            </cs:ASNs>
                            <cs:CRESTdefendantID>70696</cs:CRESTdefendantID>
                            <cs:URN>40CH0005189</cs:URN>
                            <cs:CustodyStatus>Not applicable</cs:CustodyStatus>
                            <cs:Counsel></cs:Counsel>
                            <cs:Charges NumberOfCharges="1">
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="RT88058">
                                <cs:CRN>1535VA0744237750552G001</cs:CRN>
                                <cs:CRESTchargeID>457S00670902</cs:CRESTchargeID>
                                <cs:CaseNumber>T20190024</cs:CaseNumber>
                                <cs:OffenceStatement>Ride cycle whilst unfit to ride through drink or drug</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-02-03T10:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceEndDateTime>2021-02-03T10:30:00.000</cs:OffenceEndDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670902</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="RT88936">
                                <cs:CRN>1535VA0744237750552G002</cs:CRN>
                                <cs:CRESTchargeID>457S00671116</cs:CRESTchargeID>
                                <cs:CaseNumber>T20190024</cs:CaseNumber>
                                <cs:OffenceStatement>Permit danger of injury due to vehicle condition - load/passenger</cs:OffenceStatement>
                                <cs:ArrestingPoliceForceCode>01</cs:ArrestingPoliceForceCode>
                                <cs:OffenceStartDateTime>2019-06-12T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>671116</cs:CRESToffenceNumber>
                              </cs:Charge>
                            </cs:Charges>
                            <cs:DefendantNumber>1</cs:DefendantNumber>
                          </cs:Defendant>
                        </cs:Defendants>
                      </cs:Hearing>
                    </cs:Hearings>
                  </cs:Sitting>
                  <cs:Sitting>
                    <cs:CourtRoomNumber>1</cs:CourtRoomNumber>
                    <cs:SittingSequenceNo>2</cs:SittingSequenceNo>
                    <cs:SittingPriority>T</cs:SittingPriority>
                    <cs:Judiciary>
                      <cs:Judge>
                        <apd:CitizenNameSurname>N/A</apd:CitizenNameSurname>
                        <apd:CitizenNameRequestedName>N/A</apd:CitizenNameRequestedName>
                      </cs:Judge>
                    </cs:Judiciary>
                    <cs:Hearings></cs:Hearings>
                  </cs:Sitting>
                  <cs:Sitting>
                    <cs:CourtRoomNumber>2</cs:CourtRoomNumber>
                    <cs:SittingSequenceNo>1</cs:SittingSequenceNo>
                    <cs:SittingAt>10:00:00</cs:SittingAt>
                    <cs:SittingPriority>T</cs:SittingPriority>
                    <cs:Judiciary>
                      <cs:Judge>
                        <apd:CitizenNameTitle>MS</apd:CitizenNameTitle>
                        <apd:CitizenNameForename>WANDA</apd:CitizenNameForename>
                        <apd:CitizenNameSurname>MATTHEWS</apd:CitizenNameSurname>
                        <apd:CitizenNameSuffix>QC</apd:CitizenNameSuffix>
                        <apd:CitizenNameRequestedName>Before Judge : MATTHEWS</apd:CitizenNameRequestedName>
                        <cs:CRESTjudgeID>53</cs:CRESTjudgeID>
                      </cs:Judge>
                    </cs:Judiciary>
                    <cs:Hearings>
                      <cs:Hearing>
                        <cs:HearingSequenceNumber>1</cs:HearingSequenceNumber>
                        <cs:HearingDetails HearingType="TRL">
                          <cs:HearingDescription>For Trial</cs:HearingDescription>
                          <cs:HearingDate>2021-12-24</cs:HearingDate>
                        </cs:HearingDetails>
                        <cs:CRESThearingID>5567</cs:CRESThearingID>
                        <cs:TimeMarkingNote> </cs:TimeMarkingNote>
                        <cs:CaseNumber>T20190078</cs:CaseNumber>
                        <cs:Prosecution ProsecutingAuthority="Other Prosecutor">
                          <cs:ProsecutingReference>HANSON</cs:ProsecutingReference>
                          <cs:ProsecutingOrganisation>
                            <cs:OrganisationName>MATTHEW JIMMY HANSON</cs:OrganisationName>
                          </cs:ProsecutingOrganisation>
                        </cs:Prosecution>
                        <cs:CommittingCourt>
                          <cs:CourtHouseType>Magistrates Court</cs:CourtHouseType>
                          <cs:CourtHouseCode CourtHouseShortName="BAM">2725</cs:CourtHouseCode>
                          <cs:CourtHouseName>BARNET MAGISTRATES&apos; COURT</cs:CourtHouseName>
                          <cs:CourtHouseAddress>
                            <apd:Line>7C HIGH STREET</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>BARNET</apd:Line>
                            <apd:PostCode>EN5 5UE</apd:PostCode>
                          </cs:CourtHouseAddress>
                          <cs:CourtHouseDX>DX 8626 BARNET</cs:CourtHouseDX>
                          <cs:CourtHouseTelephone>020 8441 9042</cs:CourtHouseTelephone>
                        </cs:CommittingCourt>
                        <cs:NumberOfDefendants>1</cs:NumberOfDefendants>
                        <cs:Defendants>
                          <cs:Defendant>
                            <cs:PersonalDetails>
                              <cs:Name>
                                <apd:CitizenNameForename> Tamarisk </apd:CitizenNameForename>
                                <apd:CitizenNameSurname> GENERIC-FIFTEEN </apd:CitizenNameSurname>
                              </cs:Name>
                              <cs:IsMasked>no</cs:IsMasked>
                              <cs:DateOfBirth>
                                <apd:BirthDate>1988-06-12</apd:BirthDate>
                                <apd:VerifiedBy>not verified</apd:VerifiedBy>
                              </cs:DateOfBirth>
                              <cs:Sex>female</cs:Sex>
                              <cs:Address>
                                <apd:Line>1 THE ROAD</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>-</apd:Line>
                                <apd:Line>LONDON</apd:Line>
                              </cs:Address>
                            </cs:PersonalDetails>
                            <cs:ContactDetails></cs:ContactDetails>
                            <cs:ASNs>
                              <cs:ASN>1900NP0004531002001D</cs:ASN>
                            </cs:ASNs>
                            <cs:CRESTdefendantID>31332</cs:CRESTdefendantID>
                            <cs:URN>63AA0008819</cs:URN>
                            <cs:CustodyStatus>On bail</cs:CustodyStatus>
                            <cs:Counsel>
                              <cs:Solicitor>
                                <cs:Party>
                                  <cs:Organisation>
                                    <cs:OrganisationName>Bishopliz Camberley</cs:OrganisationName>
                                    <cs:OrganisationAddress>
                                      <apd:Line>56 COMMERCIAL ROAD</apd:Line>
                                      <apd:Line>SWINDON</apd:Line>
                                      <apd:Line>-</apd:Line>
                                      <apd:Line>-</apd:Line>
                                      <apd:Line>SWINDON,WILTSHIRE</apd:Line>
                                    </cs:OrganisationAddress>
                                    <cs:OrganisationDX>SWINDON 24</cs:OrganisationDX>
                                    <cs:ContactDetails>
                                      <Telephone>
                                        <TelNationalNumber>0175678253</TelNationalNumber>
                                      </Telephone>
                                    </cs:ContactDetails>
                                  </cs:Organisation>
                                </cs:Party>
                                <cs:StartDate>2019-02-19</cs:StartDate>
                              </cs:Solicitor>
                            </cs:Counsel>
                            <cs:Charges NumberOfCharges="2">
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="TN51012">
                                <cs:CRN>1900NP0004531002001D001</cs:CRN>
                                <cs:CRESTchargeID>457S00670925</cs:CRESTchargeID>
                                <cs:CaseNumber>T20190078</cs:CaseNumber>
                                <cs:OffenceStatement>Slay the Lord High Chancellor</cs:OffenceStatement>
                                <cs:ArrestingPoliceForceCode>01</cs:ArrestingPoliceForceCode>
                                <cs:OffenceStartDateTime>2021-06-01T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670925</cs:CRESToffenceNumber>
                              </cs:Charge>
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="RT88026">
                                <cs:CRN>1900NP0004531002001D001</cs:CRN>
                                <cs:CRESTchargeID>457S00671070</cs:CRESTchargeID>
                                <cs:CaseNumber>T20190078</cs:CaseNumber>
                                <cs:OffenceStatement>Dangerous driving</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2021-05-11T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>671070</cs:CRESToffenceNumber>
                              </cs:Charge>
                            </cs:Charges>
                            <cs:DefendantNumber>1</cs:DefendantNumber>
                          </cs:Defendant>
                        </cs:Defendants>
                      </cs:Hearing>
                      <cs:Hearing>
                        <cs:HearingSequenceNumber>2</cs:HearingSequenceNumber>
                        <cs:HearingDetails HearingType="TRL">
                          <cs:HearingDescription>For Trial</cs:HearingDescription>
                          <cs:HearingDate>2021-12-24</cs:HearingDate>
                        </cs:HearingDetails>
                        <cs:CRESThearingID>5568</cs:CRESThearingID>
                        <cs:TimeMarkingNote> </cs:TimeMarkingNote>
                        <cs:CaseNumber>T20200191</cs:CaseNumber>
                        <cs:Prosecution ProsecutingAuthority="Other Prosecutor">
                          <cs:ProsecutingReference>TRANSPORT FOR LONDON</cs:ProsecutingReference>
                          <cs:ProsecutingOrganisation>
                            <cs:OrganisationName> TRANSPORT FOR LONDON</cs:OrganisationName>
                          </cs:ProsecutingOrganisation>
                        </cs:Prosecution>
                        <cs:CommittingCourt>
                          <cs:CourtHouseType>Magistrates Court</cs:CourtHouseType>
                          <cs:CourtHouseCode CourtHouseShortName="ACTY">6723</cs:CourtHouseCode>
                          <cs:CourtHouseName>ACTON YOUTH COURT</cs:CourtHouseName>
                          <cs:CourtHouseAddress>
                            <apd:Line>THE COURT HOUSE</apd:Line>
                            <apd:Line>WINCHESTER STREET</apd:Line>
                            <apd:Line>ACTON</apd:Line>
                            <apd:Line>-</apd:Line>
                            <apd:Line>LONDON</apd:Line>
                            <apd:PostCode>W3 8PB</apd:PostCode>
                          </cs:CourtHouseAddress>
                          <cs:CourtHouseTelephone>020 7992 9014</cs:CourtHouseTelephone>
                        </cs:CommittingCourt>
                        <cs:NumberOfDefendants>1</cs:NumberOfDefendants>
                        <cs:Defendants>
                          <cs:Defendant>
                            <cs:PersonalDetails>
                              <cs:Name>
                                <apd:CitizenNameForename>Nicholas</apd:CitizenNameForename>
                                <apd:CitizenNameForename>Jackson</apd:CitizenNameForename>
                                <apd:CitizenNameSurname>T-ORG DEFENDANT ONE</apd:CitizenNameSurname>
                              </cs:Name>
                              <cs:IsMasked>no</cs:IsMasked>
                              <cs:DateOfBirth>
                                <apd:BirthDate>1976-01-12</apd:BirthDate>
                                <apd:VerifiedBy>not verified</apd:VerifiedBy>
                              </cs:DateOfBirth>
                              <cs:Sex>male</cs:Sex>
                              <cs:Address>
                                <apd:Line>45 CROWNSHOT AVENUE</apd:Line>
                                <apd:Line>FINEDOON</apd:Line>
                                <apd:Line>SPARROW TOWERS</apd:Line>
                                <apd:Line>HIGH STRRET</apd:Line>
                                <apd:Line>CARDIFF,BERKSHIRE</apd:Line>
                                <apd:PostCode>CA2 4TY</apd:PostCode>
                              </cs:Address>
                            </cs:PersonalDetails>
                            <cs:ContactDetails></cs:ContactDetails>
                            <cs:ASNs>
                              <cs:ASN>1547VA2334454720741C</cs:ASN>
                            </cs:ASNs>
                            <cs:CRESTdefendantID>30402</cs:CRESTdefendantID>
                            <cs:CustodyStatus>In custody</cs:CustodyStatus>
                            <cs:Counsel></cs:Counsel>
                            <cs:Charges NumberOfCharges="1">
                              <cs:Charge IndictmentCountNumber="1" CJSoffenceCode="TA02008">
                                <cs:CRN>1547VA2334454720741C001</cs:CRN>
                                <cs:CRESTchargeID>457S00670881</cs:CRESTchargeID>
                                <cs:CaseNumber>T20200191</cs:CaseNumber>
                                <cs:OffenceStatement>Sell/offer for sale newspaper/periodical/other publication containing tobacco advertisement</cs:OffenceStatement>
                                <cs:OffenceStartDateTime>2020-06-23T00:00:00.000</cs:OffenceStartDateTime>
                                <cs:OffenceParticulars>tba</cs:OffenceParticulars>
                                <cs:CRESToffenceNumber>670881</cs:CRESToffenceNumber>
                              </cs:Charge>
                            </cs:Charges>
                            <cs:DefendantNumber>1</cs:DefendantNumber>
                          </cs:Defendant>
                        </cs:Defendants>
                      </cs:Hearing>
                    </cs:Hearings>
                  </cs:Sitting>
                </cs:Sittings>
              </cs:CourtList>
            </cs:CourtLists>
          </cs:DailyList>
        </bi:DocumentContent>
      </bi:CJODocumentRequest>
    </BITSRequestMessage>
  </BITSSubmit>
  </soap:Body>
</soap:Envelope>
`


		return text 

}






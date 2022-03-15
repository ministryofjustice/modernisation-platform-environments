
debugger; 
import fetch from 'node-fetch';
import https from 'https';

const httpsAgent = new https.Agent({
    rejectUnauthorized: false,
  });

let suffix = "" + Date.now()


let dvladoc = getDvlaDoc(
	{
		correlationId : 		 "" + suffix,
		documentId : 			 "GC BITS TEST " + suffix,
		description  :           "GC BITS TEST " + suffix,
		name : 					 "GC BITS TEST " + suffix,
		dvlaDocIdName: 			 "GC BITS TEST " + suffix,
		dvlaDocIdUniqueId:       "CSDD" + suffix,

	}
)


let result = await sendRequest(dvladoc, 'https://ingest.cjsonline.gov.uk/BITSWebService/BITSWebservice.asmx' )


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










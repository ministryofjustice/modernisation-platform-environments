
debugger; 
import fetch from 'node-fetch';
import https from 'https';

const httpsAgent = new https.Agent({
    rejectUnauthorized: false,
  });

let suffix = "" + Date.now()

// let endpoint = 'ingest' 
let endpoint = 'dev-ingest' 
// let endpoint = 'preingest' 


let dvladoc = getObligatoryDisqualificationDoc(
	{
		correlationId : 		 "" + suffix,
		messageText : 			 endpoint + "CJIP TEST " + suffix,
		// description  :    "GC BITS TEST " + suffix,
		// name : 					 "GC BITS TEST " + suffix,

	}
)


let result = await sendRequest(dvladoc, 'https://'  + endpoint + '.cjsonline.gov.uk/CJIPWebService/CJIPWebservice.asmx' )


console.log(result)




async function sendRequest (body, url) {

  const response = await fetch(url, {
    method: 'post',
    body: body ,
    headers: {
    	'Content-Type': 'text/xml',
    	'SOAPAction'  : 'urn:uk:gov:cjse:cjip/Submit',
    },
    agent: httpsAgent,
  //      headers: {'Content-Type': 'application/soap+xml'}
  });
  const data = await response.text();

  return data

} 


function getObligatoryDisqualificationDoc({correlationId, messageText}){

	return `<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
		  <soap:Body>
		    <Submit xmlns="urn:uk:gov:cjse:cjip">
		      <me:CjseMessage xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:op="urn:integration-cjsonline-gov-uk:pilot:operations" xmlns:bi="urn:BITS-cjsonline-gov-uk:pilot:BITS" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:be="urn:integration-cjsonline-gov-uk:pilot:entities" xmlns:me="urn:integration-cjsonline-gov-uk:pilot:messaging" xmlns:ty="urn:integration-cjsonline-gov-uk:pilot:types">
		        <me:RoutingHeader>
		          <me:SourceSystemIdentifier>SCC010456</me:SourceSystemIdentifier>
		          <me:DestinationSystemIdentifier>XCJSE01</me:DestinationSystemIdentifier>
		        </me:RoutingHeader>
		        <me:OperationRequests MessageCorrelationID="${correlationId}">
		          <me:OperationRequest xsi:type="op:GenerateOtherCaseFileEventOperation" CorrelationID="${correlationId}">
		            <be:CaseFileIdentifier>
		              <be:CaseFileID>S20050650</be:CaseFileID>
		              <be:SystemID>SCC010404</be:SystemID>
		            </be:CaseFileIdentifier>
		            <be:EventParameters>
		              <!--     <be:EventTypeID>10600</be:EventTypeID> -->
		              <!-- Jury Sworn -->
		              <!--     <be:EventTypeID>10105</be:EventTypeID> -->
		              <!--    <be:EventTypeID>10105</be:EventTypeID> -->
		              <!-- Case Closed: log event -->
		              <!--   <be:EventTypeID>10600</be:EventTypeID> -->
		              <!-- Jury Sworn -->
		              <be:EventTypeID>12311</be:EventTypeID> <!-- Obligatory Disqualification -->
		              <be:EventTime>2006-02-12T15:00:00</be:EventTime>
		              <be:EventLocation>404</be:EventLocation>
		              <be:MessageText>${messageText}</be:MessageText>
		              <be:CaseFileIDs>
		                <be:CaseFileID>S20050650</be:CaseFileID>
		              </be:CaseFileIDs>
		              <be:PNCIDs>
		                <be:PNCID>20110000000A</be:PNCID>
		              </be:PNCIDs>
		              <be:PrisonerIDs>
		                <be:PrisonerID>BA0001</be:PrisonerID>
		                <!--  <be:PrisonerID>BA0002</be:PrisonerID>
				 					<be:PrisonerID>BA0003</be:PrisonerID> -->
		              </be:PrisonerIDs>
		            </be:EventParameters>
		          </me:OperationRequest>
		        </me:OperationRequests>
		      </me:CjseMessage>
		    </Submit>
		  </soap:Body>
		</soap:Envelope>`


}















const { Console } = require("console");
const c2 = new Console(process.stderr);

var differenceInHours = require('date-fns/differenceInHours')

var chalk = require("chalk")


const AWS = require('aws-sdk');
AWS.config.update({region:'eu-west-2'});

const ec2 = new AWS.EC2({apiVersion: '2016-11-15'});

fs = require('fs');
const appvar = JSON.parse(fs.readFileSync("../application_variables.json"))

let envString = process.argv[2]


serverTypeToName = {
  "infra1"    : "infra1"      ,
  "infra2"    : "infra2"      ,
  "exchange"  : "infra6"      ,
  "database"  : "suprig01"    ,
  "app"       : "suprig02"    ,
  "portal"    : "suprig03"    ,
  "cjim"      : "suprig04"    ,
  "cjip"      : "suprig05"    ,
  "sms"       : "XHBPRESMS01" 
}


let nameFilter = 'SharedToProd'
let previousHoursToQuery = 36


// get the current AMIs
const params = {
  Filters: [
    {
      Name: 'state',
      Values: [
        'available'
      ]
    }
  ],
  Owners: [
    '276038508461',
  ]  
 };


async function main() {

  try {

    let response = await ec2.describeImages(params).promise()

    let images = response.Images


  

    images = images.map(i=>{
      i.CreationDate = new Date(i.CreationDate)
      return i
    })
    .filter(i => {
        return (differenceInHours(new Date() , i.CreationDate ) < previousHoursToQuery ) 
    })
    .filter(i => {
       return i.Name.toLowerCase().includes(nameFilter.toLowerCase())
    })
    .map(i=>{
      i.serverType = i.Name.split("-")[0]
      i.serverName = serverTypeToName[i.serverType]
      return i
    })
    .sort(function compare(a, b) {
      var dateA = new Date(a.CreationDate);
      var dateB = new Date(b.CreationDate);
      return dateA - dateB;
    });

    console.error("Found amis:-")

    c2.table(images.map(i => {return  {
      CreationDate : i.CreationDate,
      serverName   : i.serverName ,  
      serverType   : i.serverType , 
      id           : i.ImageId   
    }}  ))

    images = images
    .filter(i => {
        return Object.keys(serverTypeToName).includes(i.serverType)
    })
    .forEach(i=>{

      let amiJsonKeyName = `${i.serverName}-ami`
      appvar.accounts[envString][amiJsonKeyName] = i.ImageId

    })


    console.log(JSON.stringify(appvar, null, 2))

  } catch (err) {

    console.log("Error grabbing latest images")

    console.log(err, err.stack);  
  }

}


main()







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
let previousHoursToQuery = 3.02


// get the current snapshots
const params = {
  OwnerIds: ["self"]
 };


async function main() {

  try {

    let response = await ec2.describeSnapshots(params).promise()

    let snapshots = response.Snapshots

 debugger;

    snapshots = snapshots
    .filter(i => {
       return i.Description.toLowerCase().includes(nameFilter.toLowerCase())
    })
    .filter(i => {
        return (differenceInHours(new Date() , i.StartTime ) < previousHoursToQuery ) 
    })
    .map(i=>{

      i.descriptionString = i.Description.match(/(\[.+?\] )*(.+)/)[2]

      i.serverType = i.descriptionString.split("-")[0]
      i.serverType = i.descriptionString.split("-")[0]
      i.serverName = serverTypeToName[i.serverType]
      i.diskNumber = i.descriptionString.match(/disk([0-9]+)/)[1]
      return i
    })
    .sort(function compare(a, b) {
      var dateA = new Date(a.StartTime);
      var dateB = new Date(b.StartTime);
      return dateA - dateB;
    });
    // .sort(( a, b ) => {
    //     if ( a.serverType < b.serverType ){
    //       return -1;
    //     }
    //     if ( a.serverType > b.serverType ){
    //       return 1;
    //     }
    //     return 0;
    //   }
    //)

    console.error("Found snapshots:-")

    c2.table(snapshots.map(i => {return  {
      StartTime   : i.StartTime, 
      Description : i.Description,
      serverName  : i.serverName ,  
      serverType  : i.serverType , 
      id : i.SnapshotId   
    }}  ))

    // console.error("Found snapshots:-\n\n" + snapshots.map(i => `${i.Description} - ${i.SnapshotId}`).join("\n")  + "\n" )

    snapshots = snapshots
    .filter(i => {
        return Object.keys(serverTypeToName).includes(i.serverType)
    })
    .forEach(i=>{

      let snapshotJsonKeyName = `${i.serverName}-disk-${i.diskNumber}-snapshot`
      appvar.accounts[envString][snapshotJsonKeyName] = i.SnapshotId

    })
    // .map(i => {
    //   return `"${i.serverName}-snapshot" : "${i.ImageId}"`
    // }).join("\n")

    


    console.log(JSON.stringify(appvar, null, 2))



  } catch (err) {

    console.log("Error grabbing latest snapshots")

    console.log(err, err.stack);  
  }

}


main()
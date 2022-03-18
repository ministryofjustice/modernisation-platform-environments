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
let previousHoursToQuery = 72


// get the current snapshots
const params = {
  OwnerIds: ["276038508461"]
  // Filters: [




    // {
    //   Name: 'name',
    //   Values: [
    //     nameFilter
    //   ]
    // },
    // {
    //   Name: 'state',
    //   Values: [
    //     'available'
    //   ]
    // }
  // ] 
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



    console.error("Found snapshots:-\n\n" + snapshots.map(i => `${i.Description} - ${i.SnapshotId}`).join("\n")  + "\n" )

    snapshots = snapshots
    .map(i=>{
      i.serverType = i.Description.split("-")[0]
      i.serverName = serverTypeToName[i.serverType]
      i.diskNumber = i.Description.match(/disk([0-9]+)/)[1]
      return i
    })
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
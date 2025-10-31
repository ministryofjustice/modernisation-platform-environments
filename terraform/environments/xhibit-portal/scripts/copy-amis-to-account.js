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


async function main() {

  try {

   let response = await ec2.describeInstances().promise()
   let instances = response.Reservations.map(r => r.Instances)

    console.log(JSON.stringify(instances, null, 2))

   } catch (err) {

    console.log("Error grabbing latest snapshots")

    console.log(err, err.stack);  
  }

}


main()   



//   var params = {
//     Name: 'STRING_VALUE', /* required */
//     SourceImageId: 'STRING_VALUE', /* required */
//     SourceRegion: 'STRING_VALUE', /* required */
//     ClientToken: 'STRING_VALUE',
//     Description: 'STRING_VALUE',
//     DestinationOutpostArn: 'STRING_VALUE',
//     DryRun: true || false,
//     Encrypted: true || false,
//     KmsKeyId: 'STRING_VALUE'
//   };





// async function copyImage(params) {

//   return ec2.copyImage(params, function(err, data) {
//     if (err) console.log(err, err.stack); // an error occurred
//     else     console.log(data);           // successful response
//   });

// }

// var params = {
//   InstanceId: 'STRING_VALUE', /* required */
//   Name: 'STRING_VALUE', /* required */
//   BlockDeviceMappings: [
//     {
//       DeviceName: 'STRING_VALUE',
//       Ebs: {
//         DeleteOnTermination: true || false,
//         Encrypted: true || false,
//         Iops: 'NUMBER_VALUE',
//         KmsKeyId: 'STRING_VALUE',
//         OutpostArn: 'STRING_VALUE',
//         SnapshotId: 'STRING_VALUE',
//         Throughput: 'NUMBER_VALUE',
//         VolumeSize: 'NUMBER_VALUE',
//         VolumeType: standard | io1 | io2 | gp2 | sc1 | st1 | gp3
//       },
//       NoDevice: 'STRING_VALUE',
//       VirtualName: 'STRING_VALUE'
//     },
//     /* more items */
//   ],
//   Description: 'STRING_VALUE',
//   DryRun: true || false,
//   NoReboot: true || false,
//   TagSpecifications: [
//     {
//       ResourceType: capacity-reservation | client-vpn-endpoint | customer-gateway | carrier-gateway | dedicated-host | dhcp-options | egress-only-internet-gateway | elastic-ip | elastic-gpu | export-image-task | export-instance-task | fleet | fpga-image | host-reservation | image | import-image-task | import-snapshot-task | instance | instance-event-window | internet-gateway | ipam | ipam-pool | ipam-scope | ipv4pool-ec2 | ipv6pool-ec2 | key-pair | launch-template | local-gateway | local-gateway-route-table | local-gateway-virtual-interface | local-gateway-virtual-interface-group | local-gateway-route-table-vpc-association | local-gateway-route-table-virtual-interface-group-association | natgateway | network-acl | network-interface | network-insights-analysis | network-insights-path | network-insights-access-scope | network-insights-access-scope-analysis | placement-group | prefix-list | replace-root-volume-task | reserved-instances | route-table | security-group | security-group-rule | snapshot | spot-fleet-request | spot-instances-request | subnet | subnet-cidr-reservation | traffic-mirror-filter | traffic-mirror-session | traffic-mirror-target | transit-gateway | transit-gateway-attachment | transit-gateway-connect-peer | transit-gateway-multicast-domain | transit-gateway-route-table | volume | vpc | vpc-endpoint | vpc-endpoint-service | vpc-peering-connection | vpn-connection | vpn-gateway | vpc-flow-log,
//       Tags: [
//         {
//           Key: 'STRING_VALUE',
//           Value: 'STRING_VALUE'
//         },
//         /* more items */
//       ]
//     },
//     /* more items */
//   ]
// };
// ec2.createImage(params, function(err, data) {
//   if (err) console.log(err, err.stack); // an error occurred
//   else     console.log(data);           // successful response
// });





// find running boxes
// shut them down
// copy each machine to 
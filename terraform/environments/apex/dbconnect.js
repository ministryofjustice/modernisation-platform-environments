// CWA automated backup script
// - Makes call to lambda which connects to EC2 instance and put
//   DB in backup mode
// - Call Oracle SQL scripts as Oracle user
//
//   version: 0.1
//   auth: phil h
/////////////////////////////////////////////////////////////////////

const SSH = require("simple-ssh");
const AWS = require("aws-sdk");

//SSM object with temp parms
const ssm = new AWS.SSM({ apiVersion: "2014-11-06" });

// Environment variables
const pem = "MGMT_EC2_KEY_DEFAULT";
const username = "ec2-user";

//Set date format
var today = new Date();
var dd = today.getDate();
var mm = today.getMonth() + 1;
var yyyy = today.getFullYear();

if (dd < 10) {
  dd = "0" + dd;
}

if (mm < 10) {
  mm = "0" + mm;
}
today = dd + "-" + mm + "-" + yyyy;

//EC2 object
let ec2 = new AWS.EC2({ apiVersion: "2014-10-31" });

//Get private IP address for EC2 instances tagged with Name:{ appname }
// May return more than 1 instance if there are multiple instances with the same name
async function getInstances(appname) {
  console.log("Getting all instances tagged with Name:", appname);
  return ec2
    .describeInstances({ Filters: [{ Name: "tag:Name", Values: [appname] }] })
    .promise();
}

async function getIPaddress(appname) {
  var instance_ip_list = [];
  var instance_data = await getInstances(appname);
  for (const res of instance_data["Reservations"]) {
    for (const instance of res["Instances"]) {
      instance_ip_list.push(instance["PrivateIpAddress"]);
    }
  }
  console.log("Found ", instance_ip_list.length, " instances");
  return instance_ip_list;
}


// Get SSH key from param store

async function getSSMparam() {
  return await ssm.getParameter({ Name: pem, WithDecryption: true }).promise();
}

// Trigger SSH connection to the EC2 instance
// Run SSH command

async function connSSH(action, appname) {
  //get ssm key
  const key = await getSSMparam();

  const myKey = key["Parameter"]["Value"];

  const addresses = await getIPaddress(appname);
  // all this config could be passed in via the event
  for(var address of addresses){
    const ssh = new SSH({
      host: address,
      port: 22,
      user: username,
      key: myKey,
    });

    let prom = new Promise(function (resolve, reject) {
      if (action == "begin") {
        console.log("[+] Trying connecting to EC2 ==>> " + address);
        console.log(`[+] Running "begin backup commands" as Oracle`);

        ssh
          .exec(
            'sudo su - oracle -c "sqlplus / as sysdba <<EOFUM' +
              "\n" +
              "alter system switch logfile;" +
              "\n" +
              "alter system switch logfile;" +
              "\n" +
              "alter database begin backup;" +
              "\n" +
              "exit;" +
              "\n" +
              'EOFUM"',
            {
              pty: true,
              out: console.log.bind(console),
              exit: function (code, stdout, stderr) {
                console.log("operation exited with code: " + code);
                console.log(stdout);
                console.log(stderr);
              },
            }
          )
          .start();
      } else if (action == "end"){
        console.log(`[+] Running "end backup commands" as Oracle`);

        ssh
          .exec(
            'sudo su - oracle -c "sqlplus / as sysdba <<EOFUM' +
              "\n" +
              "alter database end backup;" +
              "\n" +
              "alter system switch logfile;" +
              "\n" +
              "alter system switch logfile;" +
              "\n" +
              "exit;" +
              "\n" +
              'EOFUM"',
            {
              pty: true,
              out: console.log.bind(console),
              exit: function (code, stdout, stderr) {
                console.log("operation exited with code: " + code);
                console.log(stdout);
                console.log(stderr);
              },
            }
          )
          .start();
      }
    });
    try {
      await prom;

      const response = {
        statusCode: 200,
      };

      console.log(`[+] Completed DB alter state: ${action} ==>> ` + address);
      console.log("[+] Returned response: " + response);

      ssh.end();

      return response;
    } catch (e) {
      console.log(e);
      context.fail();
    }
  }
}

exports.handler = async (event, context) => {
  try {
    console.log("[+} Received event:", JSON.stringify(event, null, 2));
    await connSSH(event.action, event.appname);

    context.done();
  } catch (error) {
    console.error(error);
    context.fail();
  }
};

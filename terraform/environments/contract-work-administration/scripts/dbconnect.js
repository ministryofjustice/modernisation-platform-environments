/////////////////////////////////////////////////////////////////////
// CWA Automated backup script
// - Makes call to lambda which connects to EC2 instance and put
//   DB in backup mode
// - Call Oracle SQL scripts as Oracle user
//
//   version: 2.0 (for migration to MP)
//   - Using ssh2 instead of simple-ssh package to allow for
//     kex algorithm specified
//
/////////////////////////////////////////////////////////////////////

const { Client } = require('ssh2');
const AWS = require("aws-sdk");

//SSM object with temp parms
const ssm = new AWS.SSM({ apiVersion: "2014-11-06" });

// Environment variables
const pem = "EC2_SSH_KEY";
const username = "ec2-user";

//EC2 object
let ec2 = new AWS.EC2({ apiVersion: "2014-10-31" });

// Get private IP address for EC2 instances tagged with Name:{ appname } that are running
// May return more than 1 instance if there are multiple instances with the same name
async function getInstances(appname) {
  console.log("Getting all instances tagged with Name:", appname);
  return ec2
    .describeInstances({ Filters: [{ Name: "tag:Name", Values: [appname] }, {Name: "instance-state-name", Values: ["running"]}]})
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

///////////////////////////////////////


async function connSSH(action, appname) {
  const key = await getSSMparam();
  const myKey = key["Parameter"]["Value"];
  const addresses = await getIPaddress(appname);
  var exec_error = false;
  for(var address of addresses){
    let prom = new Promise(function (resolve, reject) {
      if (action == "begin") {
        console.log("[+] Trying connecting to EC2 ==>> " + address);
        const conn = new Client();
        console.log(`[+] Running "begin backup commands" as Oracle`);
        conn.on('ready', () => {
          console.log('Client :: ready');
          conn.exec('sudo su - oracle -c "sqlplus / as sysdba <<EOFUM' +
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
            pty: true
          },
          (err, stream) => {
            if (err) {
              reject(err);
            }  
            stream.on('close', (code, signal) => {
              conn.end();
              console.log('Stream :: close :: code: ' + code + ', signal: ' + signal);
              setTimeout(() => {  resolve(); }, 2000); // Ugly solution to wait until the ssh socket closes before resolving...
            }).on('data', (data) => {
              console.log('STDOUT: ' + data);
              if (data.toString().toUpperCase().includes("ERROR")) exec_error = true;
            }).stderr.on('data', (data) => {
              console.log('STDERR: ' + data);
              if (data.toString().toUpperCase().includes("ERROR")) exec_error = true;
            })
            ;
          });
        }).connect({
          host: address,
          port: 22,
          username: username,
          privateKey: myKey,
          // debug: console.log, // Uncomment to get more detailed logs
          algorithms: {
            kex: ["diffie-hellman-group1-sha1"]
          }
        });
      } else if (action == "end"){
        console.log("[+] Trying connecting to EC2 ==>> " + address);
        console.log(`[+] Running "begin backup commands" as Oracle`);

        const conn = new Client();
        conn.on('ready', () => {
          console.log('Client :: ready');
          conn.exec('sudo su - oracle -c "sqlplus / as sysdba <<EOFUM' +
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
            pty: true
          },
          (err, stream) => {
            if (err) {
              reject(err);
            }  
            stream.on('close', (code, signal) => {
              conn.end();
              console.log('Stream :: close :: code: ' + code + ', signal: ' + signal);
              setTimeout(() => {  resolve(); }, 2000); // Ugly solution to wait until the ssh socket closes before resolving...
            }).on('data', (data) => {
              console.log('STDOUT: ' + data);
              if (data.toString().toUpperCase().includes("ERROR")) exec_error = true;
            }).stderr.on('data', (data) => {
              console.log('STDERR: ' + data);
              if (data.toString().toUpperCase().includes("ERROR")) exec_error = true;
            })
            ;
          });
        }).connect({
          host: address,
          port: 22,
          username: username,
          privateKey: myKey,
          // debug: console.log, // Uncomment to get more detailed logs
          algorithms: {
            kex: ["diffie-hellman-group1-sha1"]
          }
        });
      }
    });
    try {
      await prom;
      console.log('EXEC_ERROR: ' + exec_error);
      if (exec_error) {
        throw new Error('Please see logs above for more detail.')
      }
      console.log(`[+] Completed DB alter state: ${action} ==>> ` + address);
    } catch (e) {
      throw new Error(`SSH Exec did not run successfully on the instance ${address}: ` + e );
    }
  }
}


exports.handler = async (event, context) => {
  try {
    console.log("[+} Received event:", JSON.stringify(event, null, 2));
    await connSSH(event.action, event.appname);

    context.done();
  } catch (error) {
    throw new Error(error);
  }
};

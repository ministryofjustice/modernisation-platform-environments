/////////////////////////////////////////////////////////////////////
//   Automated backup script
// - Calls dbconnect lambda to put DB in backup mode
// - Triggers volume snapshots for all volumes connected to instance
//
//   version: 1.0 (for migration to MP)
/////////////////////////////////////////////////////////////////////

const AWS = require("aws-sdk");

//Set date format
var date_ob = new Date();
var day = ("0" + date_ob.getDate()).slice(-2);
var month = ("0" + (date_ob.getMonth() + 1)).slice(-2);
var year = date_ob.getFullYear();
   
var date = day + "/" + month + "/" + year;

//lambda object
let lambda = new AWS.Lambda({ apiVersion: "2015-03-31" });

//EC2 object
let ec2 = new AWS.EC2({ apiVersion: "2014-10-31" });

async function invokeLambdaStart(appname) {
  // try {
    console.log("[+] Putting DB into backup mode");

    const lambdaInvokeStart = await lambda
      .invoke({
        FunctionName: "connectDBFunction",
        InvocationType: "RequestResponse", // This means invoking the function synchronously. Note that if Lambda was able to run the function, the status code is 200, even if the function returned an error.
        Payload: JSON.stringify({ action: "begin", appname: appname }),
      })
      .promise();
    
    //Check lambda returns success
    if (lambdaInvokeStart["FunctionError"] == null)
    {
      // Run the volume snapshots
      console.log("[+] Creating volume snapshot");
      await handleSnapshot(appname);
    } else {
      console.log("Return output: ", lambdaInvokeStart);
      throw new Error("The connectDBFunction (begin) Lambda function has an error. Please see that function's logs for more information.");
    }

  // } catch (e) {
  //   throw new Error("[-] " + e);
  // }
}

async function invokeLambdaStop(appname) {
  // try {
    console.log("[+] Putting DB into normal operations mode");

    // setTimeout(() => {
    //   console.log("[+] Waiting for DB.....");
    // }, 7000);

    const lambdaInvokeStop = await lambda
      .invoke({
        FunctionName: "connectDBFunction",
        InvocationType: "RequestResponse",
        Payload: JSON.stringify({ action: "end", appname: appname }),
      })
      .promise();

    //Check lambda returns success
    if (lambdaInvokeStop["FunctionError"] == null)
    {
      // Run the volume snapshots
      console.log("[+] Datatbase is back in normal operations mode");
    } else {
      console.log("Return output: ", lambdaInvokeStop);
      throw new Error("The connectDBFunction (end) Lambda function has an error. Please see that function's logs for more information.");
    }

  // } catch (e) {
  //   console.log("[-] " + e);
  //   throw new Error("The connectDBFunction Lambda (end) function has an error. Please see that function's logs for more information.");
  // }
}

async function invokeLambdaFinal(appname) {
  try {
    console.log("Waiting for DB to be ready");
    await new Promise(resolve => setTimeout(resolve, 30000));
    console.log("[+] Taking final snapshots out of backup mode");
    await handleSnapshot2(appname);
  } catch (e) {
    console.log("[-]" + e);
    throw new Error("There is an error taking final shapshots.");
  }
}


// Grab volume id all volumes attached to the instance and snapshot

async function handleSnapshot(appname) {
  try {
    // Get all instances of our app
    const instances = await getInstanceId(appname);

    // Get all volumes on all instances of our app
    var volumes_list = [];
    var snapshot_list = [];
    for (const instance of instances) {
      const volumes = await listVolumes(instance);
      volumes_list.push(volumes);
    }

    // Loop over instance, if more than 1 instance returned
    for (const instance_list of volumes_list) {
      for (const volume of instance_list["Volumes"]) {
        console.log("Taking snapshot of Volume: ", volume);
        var volume_id = volume["VolumeId"];
        var volume_device = volume["Attachments"][0]["Device"];
        var volume_name = '';
        for(var tag of volume['Tags']){
          if(tag['Key'].includes('Name')){
            volume_name = tag['Value'];
          }
        }
        // Trigger  EBS snapshots
        let snap = await ec2CreateSnapshot(volume_id, appname, volume_device, volume_name, date);
        snapshot_list.push(snap.SnapshotId);
      }
    }
  } catch (error) {
    console.log(error);
  }
}

//Get instanceId for EC2 instances tagged with Name:{ appname }
// May return more than 1 instance if there are multiple instances with the same name
async function getInstance(appname) {
  console.log("Getting all instances tagged with Name:", appname);
  return ec2
    .describeInstances({ Filters: [{ Name: "tag:Name", Values: [appname] }] })
    .promise();
}

// Capture all app instance IPs in a list
async function getInstanceId(appname) {
  var instance_id_list = [];
  var instance_data = await getInstance(appname);
  for (const res of instance_data["Reservations"]) {
    for (const instance of res["Instances"]) {
      instance_id_list.push(instance["InstanceId"]);
    }
  }
  console.log("Found ", instance_id_list.length, " instances");
  return instance_id_list;
}

// List all volumes for EC2 instance

async function listVolumes(instance_id) {
  console.log("getting volumes for ", instance_id);
  return ec2
    .describeVolumes({
      Filters: [{ Name: "attachment.instance-id", Values: [instance_id] }],
    })
    .promise();
}

// Create EC2 snapshot based on volume id

async function ec2CreateSnapshot(volume, appname, volume_device, volume_name, date) {
  console.log("Creating snapshot of volume:", volume, volume_device, volume_name, date);
  let params = {
    VolumeId: volume,
    Description:
      appname + " automatically created snapshot and resource volume id: " + volume,
    TagSpecifications: [
      {
        ResourceType: "snapshot",
        Tags: [
          {
            Key: "Name",
            Value: appname + "-" + volume_name + "-" + volume_device + "-" + date
          },
          {
            Key: "Application",
            Value: appname
          },
          { 
            Key: "Date",
            Value: date 
          },
          {
            Key: "dlm:snapshot-with:volume-hourly-35-day-retention",
            Value: "yes"
          },
          {
            Key: "Created_by",
            Value: "Automated snapshot created by DBSnapshotFunction Lambda"
          }
        ],
      },
    ],
  };
  return ec2.createSnapshot(params).promise();
}

async function handleSnapshot2(appname) {
  try {
    // Get all instances of our app
    const instances = await getInstanceId(appname);

    // Get all volumes on all instances of our app
    var volumes_list = [];
    for (const instance of instances) {
      const volumes = await listVolumes(instance);
      volumes_list.push(volumes);
    }

    // Loop over instance, if more than 1 instance returned
    for (const instance_list of volumes_list) {
      for (const volume of instance_list["Volumes"]) {
        var volume_id = volume["VolumeId"];
        var volume_device = volume["Attachments"][0]["Device"];
        var volume_name='';
        for(var tag of volume['Tags']){
          if(tag['Key'].includes('Name')){
            volume_name = tag['Value'];
          }
        }
        // if the drive is oraarch/oraredo trigger an EBS snapsot
        for(const tag of volume['Tags']){
          if (tag['Value'].includes('arch')){
            console.log(volume_id, "is oraarch volume");
            let snap = await ec2CreateSnapshot2(volume_id, appname, volume_device, volume_name, date);
            console.log("[+] Taking snapshot " + snap.SnapshotId);
            break;
          }}
        for(const tag of volume['Tags']){
          if (tag['Value'].includes('redo')){
            console.log(volume_id, "is oraredo volume");
            let snap = await ec2CreateSnapshot2(volume_id, appname, volume_device, volume_name, date);
            console.log("[+] Taking snapshot " + snap.SnapshotId);
            break;
          }
        }
      }
    }
  } catch (error) {
    console.log(error);
  }
}

async function ec2CreateSnapshot2(volume, appname, volume_device, volume_name, date) {
  console.log("Creating snapshot of volume:", volume, volume_device, volume_name, date);
  let params = {
    VolumeId: volume,
    Description:
      appname + " automatically created snapshot OUT OF BACKUPMODE and resource volume id: " + volume,
    TagSpecifications: [
      {
        ResourceType: "snapshot",
        Tags: [
          {
            Key: "Name",
            Value: appname + "-" + volume_name + "-" + volume_device + "-" + date
          },
          {
            Key: "Application",
            Value: appname
          },
          { 
            Key: "Date",
            Value: date 
          },
          {
            Key: "dlm:snapshot-with:volume-hourly-35-day-retention",
            Value: "yes"
          },
          {
            Key: "Created_by",
            Value: "Automated OUT OF BACKUPMODE snapshot created by DBSnapshotFunction Lambda"
          }
        ],
      },
    ],
  };
  return ec2.createSnapshot(params).promise();
}

exports.handler = async (event, context) => {
  const appname = event.appname;
  try {
    console.log("Putting DB into Hotbackup mode and taking snapshot");
    await invokeLambdaStart(appname);
  }
  catch (error) {
    throw new Error(error);
  }
  try{
    console.log("Taking DB out of Hotbackup mode");
    await invokeLambdaStop(appname);
  } catch (error) {
    throw new Error(error);
  }
  //////////////////////////////////
  // Unsure why this part is required to take a second set of oraarch and oraredo snapshots, thus disabling it for now
  //////////////////////////////////
  // try{
  //   console.log("Operating outside of Hotbackup mode");
  //   await invokeLambdaFinal(appname);
  //   console.log("Snapshots Complete");
  // } catch (error) {
  //   throw new Error(error);
  // }
};

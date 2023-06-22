"use strict";
var fs = require("fs");
var swagger = require("./swagger.json");

exports.handler = function (event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      "Content-Type": "text/html;",
    },
    body: fs.readFileSync("./index.html", "utf8"),
  };

  if (event.requestContext.path.endsWith("swagger.json")) {
    response = {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json;",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(swagger),
    };
  }

  console.log(response);
  console.log(event);
  console.log(context);
  callback(null, response);
};

// exports.handler({
//   requestContext: { path: "/a/b/c" }
// },null,()=>{});

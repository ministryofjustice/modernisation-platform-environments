module.exports.handler = (event, context, callback) => {
    console.log('=== FUNCTION START ===');
	const request = event.Records[0].cf.request;
	request.uri = request.uri.replace(/^\/api/, "");
	callback(null, request);
};
var net = require('net');
net.createServer(function(socket){
    socket.on('data', function(data){
        
        const out = data.toString()
        socket.write(out)
        console.log(out)


    });

    socket.on('error' , (e) =>{

        console.error('ERROR '+ e)

    })

}).listen(25);
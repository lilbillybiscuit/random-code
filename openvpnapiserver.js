// Hi! This is a one-tile file server for the vpn files generated by https://git.io/vpn
// Please notify me if you find any bugs/vulnerabilities in this code, thanks! :D
var slugify = require('slugify');
var fs = require('fs');

var express = require('express'),
  app = express(),
  port = process.env.PORT || 27000,
  bodyParser = require('body-parser');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get("/:file1", function(req, res) {
    var filesafe = slugify(req.params.file1, { remove: /"<>#%\{\}\|\\\^~\[\]`;\?:@=&/g });
    //console.log(filesafe);
    var beforedirectory='/root/';
    var database="/root/used/";
    try {
        if (!fs.existsSync(database+filesafe)) {
            console.log(fs.existsSync(beforedirectory+filesafe+".ovpn"));
            if (!fs.existsSync(beforedirectory+filesafe+".ovpn")) {
                res.json({result: "error4"});
            } else {
                console.log(database+filesafe);
                res.download(beforedirectory+filesafe+".ovpn", filesafe+".ovpn");
                if (!fs.existsSync(database)){
                    fs.mkdirSync(database);
                }
                fs.writeFileSync(database+filesafe, "1");
                return;
            }
            
        } else {
            res.json({result: "error3"});
        }
    } catch (err) {
        console.log(err);
        res.json({result: "error2"});
    }
});

app.listen(port);
console.log('OVPN Config server started on: http://localhost:' + port);

process.on('SIGINT', function() {
    console.log("Stopping server...");
    process.exit();
});


/*
  Packages the game as ".love" archive.
*/

var path = require('path');
var fs = require('fs-extra');
var luamin = require('luamin');
var recursive = require('recursive-readdir');
var Zip = new require('node-zip');

var srcFolder = path.join(__dirname,"src");
var binFolder = path.join(__dirname,"bin");

recursive(srcFolder, function (err, files) {
  files.forEach(function(f){
    var parsed = path.parse(f);

    // Minifies lua
    if(parsed.ext === '.lua'){
      var destination = f.replace(srcFolder,binFolder);
      exportLua(f,destination);
    }
  })
});

function exportLua(inputFile, outputFile) {
  var lua = fs.readSync(inputFile);
  var minifiedLua = luamin(lua);
  fs.outputFileSync(destination, minifiedLua);
}

function archive(callback){
  recursive(binFolder, function (err, files) {
    if(err) {
      callback(err)
      return;
    }

    var zip = new Zip();
    files.forEach(function(f){
      var innerPath = f.replace(binFolder,"");
      var innerContent = fs.readSync(f);
      zip.file(innerPath, innerContent);
    });
    var zipContent = zip.generate({base64:false,compression:'DEFLATE'});
    var zipDestination = path.join(__dirname,"game.love");
    fs.outputFileSync(zipDestination, zipContent);
    callback(err);
  })

}

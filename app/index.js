var generators = require('yeoman-generator');
var _ = require('lodash');
var request = require('request');
var async = require('async');

var luaModules = {
  "kikito/middleclass" : "https://api.github.com/repos/kikito/middleclass/contents/middleclass.lua",
  "kikito/bump" : "https://api.github.com/repos/kikito/bump.lua/contents/bump.lua",
  "kikito/gamera" : "https://api.github.com/repos/kikito/gamera/contents/gamera.lua",
  "kikito/inspect" : "https://api.github.com/repos/kikito/inspect.lua/contents/inspect.lua",
  "kikito/i18n" : "https://api.github.com/repos/kikito/i18n.lua/contents/i18n.lua"
};

function downloadGithubFile(options,callback) {
  request({uri : options.uri, headers: { 'Accept': 'application/vnd.github.v3.raw', 'User-Agent' : 'node/request' }}, function (error, response, body) {
    if (!error && response.statusCode == 200) {
      options.fs.write(options.destination, body)
      callback(null,options.destination);
    }
    else if(err){
      callback(err);
    }
    else{
      callback(new Error("Failed to download file from github (" + response.statusCode + ")"));
    }
  });
};

module.exports = generators.Base.extend({
  initializing: function () {
    this.props = {};
  },

  prompting: function () {
    var done = this.async();

    this.prompt({
      type    : 'checkbox',
      name    : 'gameModules',
      message : 'Which game module do you need (with a limit of 60/hour) ?',
      choices: Object.keys(luaModules),
      default : Object.keys(luaModules),
      store   : true
    }, function (answers) {
      this.props.gameModules = answers.gameModules;
      done();
    }.bind(this));
  },
  writing: function () {
    var done = this.async();

    // 1. Creating local files from templates

    var tmpl = [
      { in: 'src/main.lua'  },
      { in: 'archive.js'  },
    ];

    tmpl.forEach(function(t){
      this.fs.copyTpl(
        this.templatePath(t.in),
        this.destinationPath(t.out ? t.out : t.in),
        t.args
      );
    })

    // 2. Downloading all requested game modules from github (warning: rate limit)
    var options = [];
    for (var i = 0; i < this.props.gameModules.length; i++) {
      var uri = luaModules[this.props.gameModules[i]];
      var filename = uri.substring(uri.lastIndexOf("/"));
      options.push({
        fs: this.fs,
        uri: uri,
        destination: this.destinationPath("src/libs/"+filename)
      });
    }

    async.map(options, downloadGithubFile , function(err, results){ done(); });
  }
});

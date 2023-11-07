const webpack = require('webpack');

module.exports = (env, args) => {
  return {
    context: __dirname,
    entry: './app.js',
    output: {
      path: __dirname + '/bin',
      filename: 'app.js'
    },
  };
};

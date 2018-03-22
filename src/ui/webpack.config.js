const path = require('path');

module.exports = {
  entry: './js/src/cycle_designer/index.js',

  output: {
    path: path.resolve(__dirname, 'js/build'),
    filename: 'cycle_designer.js',
  },

  module: {
    rules: [{ test: /\.js$/, exclude: /node_modules/, loader: 'babel-loader' }],
  },
};

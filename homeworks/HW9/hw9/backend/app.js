// Extracts modules.
const express = require('express');
const path = require('path');
const bodyParser = require('body-parser');
const logger = require('morgan');

const googleMap = require('./routes/googleMap');
const yelpFusion = require('./routes/yelpFusion');


// Generates server instance and runs the server.
const port = process.env.PORT || 3000
const app = express();
app.listen(port, () => {
  console.log(`app Running at http://127.0.0.1:${port}`);
});

// Declears variables.
const users = {};

// Adds middleweres
// app.use(favicon(path.join(__dirname, 'public', 'favicon.ico')));
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

app.use('/googlemap', googleMap);
app.use('/yelpQuery', yelpFusion);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});
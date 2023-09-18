global.toastr = require("toastr")

require("@rails/ujs").start();
require("@rails/activestorage").start();
require("turbolinks").start();
require("trix");
require("@rails/actiontext");

window.bootstrap = require('bootstrap/dist/js/bootstrap.bundle.js')
import 'bootstrap';

import '@fortawesome/fontawesome-free/css/all'

import "../stylesheets/application"
import "controllers"

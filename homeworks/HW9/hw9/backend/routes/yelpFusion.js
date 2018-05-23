
//http://localhost:31045/yelpQuery?term=Four+Barrel+Coffee&location=san+francisco,+ca




'use strict';

const yelp = require('yelp-fusion');
var express = require('express');
var router = express.Router();

// Place holder for Yelp Fusion's API Key. Grab them
// from https://www.yelp.com/developers/v3/manage_app
const apiKey = 'yelp OpenAPI key';

router.get('/', function(req, res, next) {
    console.log("GET ", "/yelpQuery", req.query);
    const client = yelp.client(apiKey);

    var params = {};

    if (req.query.phone) {
        params.phone = req.query.phone;        
    } 
    
    if (req.query.location) {
        params.location = req.query.location;
    }

    if (req.query.term) {
        params.term = req.query.term;
    }

    client.search(params).then(response => {
        if (response.jsonBody.total && (0 < response.jsonBody.total)) {
            const firstResult = response.jsonBody.businesses[0];

            console.log(`id: ${response.jsonBody.businesses[0].id}`);
            client.reviews(response.jsonBody.businesses[0].id).then(response => {
                console.log("ret : ", response.jsonBody);
                res.send({ reviews: response.jsonBody.reviews });
            }).catch(e => {
                console.log(e);
            });
        } else {
            res.send({ reviews: [] });
        }
        // const prettyJson = JSON.stringify(firstResult, null, 4);
        // console.log(prettyJson);
    }).catch(e => {
        console.log(e);
    });
});

module.exports = router;
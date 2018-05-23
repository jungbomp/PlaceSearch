//http://localhost:31045/googlemap/nearby
//http://localhost:31045/googlemap/nearby?latitude=34.0266&longitude=-118.2831&from=location&addr=New+York&type=default&keyword=burger+King
//http://localhost:31045/googlemap/placedetail?placeid=placeid
//https://maps.googleapis.com/maps/api/geocode/json?&address=New+York&key=google_map_api_key_for_place
//https://maps.googleapis.com/maps/api/place/nearbysearch/json?&location=40.7127753,-74.0059728&radius=16090&type=default&keyword=burger+King&key=google_map_api_key_for_place
//https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=pagetoken&key=google_map_api_key_for_place
//https://maps.googleapis.com/maps/api/place/details/json?&placeid=placeid&key=google_map_api_key_for_place
//https://maps.googleapis.com/maps/api/streetview?size=998x500&location=34.0223519,-118.285117&fov=90&heading=235&pitch=10&key=google_map_api_key_for_place


var request = require('request');
var express = require('express');
var router = express.Router();

var createGoogleMapApiObj = function() {
    
    var singleObj = null;
    
    return (function() {
        var key = 'google_map_api_key_for_place';
        var googleMapsClient = null;

        function requiredParam (param) {
            const requiredParamError = new Error(
                `Required parameter, "${param}" is missing.`
            )
           
            // preserve original stack trace
            if (typeof Error.captureStackTrace === 'function') {
                Error.captureStackTrace(
                    requiredParamError,
                    requiredParam
                )
            }
    
            throw requiredParamError
        }
    
        function doOpenApiCall({
            url,
            retType,
            key,
            params
        }, callback) {
            var query = url+"/"+retType+"?";
            for (var k in params) {
                if (typeof params[k]=='string') params[k]=params[k].replace(/ /g, '+');
                query += ('&'+k+'='+params[k]);
            }
            
            query += ("&key="+key.replace(/ /g, '+'));
            console.log("doOpenApiCall : ", query);
            
            request.get(query, function(error, res, body) {
                // Print the error if one occurred
                console.log('error:', error);
                // Print the response status code if a response was received
                console.log('statusCode:',res && res.statusCode);
               
                if (0 > res.headers["content-type"].indexOf("image")) {
                    //Print the response data
                    console.log('response:',body);
                    callback(JSON.parse(body));
                } else {
                    console.log(`response(image): ${res.request.href}`);
                    callback({ url: res.request.href });
                }
    
            });
        }
    
        // Retrieve geocode from address by google map API.
        // Return an array which contains latitude and longitude.
        function getGeocodeByAddress(addr, callback) {
            // If googleMapsclient node.js library for google map is declared, use it.
            if (googleMapsClient) {
                googleMapsClient.geocode({ "address": addr }, function(err, response) {
                    if (!err) {
                        console.log("getGeocodeByAddress : ", response.json.results);
                        callback(response.json.results);
                    } else if (err === 'timeout') {
                        // Handle timeout.
                        console.log(err);
                    } else if (err.json) {
                        // Inspect err.status for more info.
                        console.log(err);
                    } else {
                        // Handle network error.
                        console.log("err : other", err);
                    }
                });
            } else {
                var url = "https://maps.googleapis.com/maps/api/geocode";
                var key = "google_map_api_key_for_place";
    
                doOpenApiCall({
                    url: url,
                    retType: "json",
                    key: key,
                    params: { "address": addr }
                }, function(ret) {
                    console.log("getGeocodeByAddress : ", ret.results);
                    callback(ret.results);
                });
            }
        }
    
        // Retrieve place information from address by google map API.
        function getPlaceFromNearbySearch({
            location,
            radius,
            type,
            keyword
        }, callback) {
            var url = "https://maps.googleapis.com/maps/api/place/nearbysearch";
    
            doOpenApiCall({
                url: url,
                retType: "json",
                key: key,
                params: {
                    "location": location,
                    "radius": radius,
                    "type": type,
                    "keyword": keyword
                }
            }, function(ret) {
                console.log("getPlaceFromNearbySearch : ", ret);
                callback({ results: ret.results, next_page_token: (ret.next_page_token||null) });
            });
        }
    
        // Retrieve places from google map OpenAPI.
        function getPlaces({
            latitude,
            longitude,
            from,
            addr,
            radius,
            type,
            keyword
        }, callback) {
            // If radius is not provided by client, set radius to 10.
            // And convert radius from mile to miter by multipling 1609.
            radius = (radius||10)*1609;

            // Google map API allows radius at most 50,000 meters.
            if (50000 < radius) {
                radius = 50000;
            }
    
            var geometry = { "latitude": latitude, "longitude": longitude };
            if ("location" == from) {
                getGeocodeByAddress(addr, function(ret) {
                    if (0 < ret.length) {
                        geometry.latitude = ret[0].geometry.location.lat;
                        geometry.longitude = ret[0].geometry.location.lng;
                    } else {
                        geometry.latitude = -99999;
                        geometry.longitude = -99999;
                    }
                    
                    fullfill(geometry);
                });
    
                return;
            }
    
            fullfill(geometry);
    
            function fullfill(geometry) {
                // If googleMapsclient node.js library for google map is declared, use it.
                if (googleMapsClient) {
                    googleMapsClient.placesNearby({
                        "location": geometry.latitude+","+geometry.longitude,
                        "radius": radius,
                        "type": type,
                        "keyword": keyword
                    }, function(err, response) {
                        if (!err) {
                            var placeJson = { 
                                "geometry": { 
                                    "lat": geometry.latitude,
                                    "lng": geometry.longitude
                                },
                                "results": response.json.results,
                                "next_page_token" : response.json.next_page_token
                            };
        
                            console.log("Result of nearbysearch : ", placeJson);
                            callback(placeJson);
                        } else if (err === 'timeout') {
                            // Handle timeout.
                            console.log(err);
                        } else if (err.json) {
                            // Inspect err.status for more info.
                            console.log(err);
                        } else {
                            // Handle network error.
                            console.log("err : other", err);
                        }
        
                    });
                } else {
                    getPlaceFromNearbySearch({
                        "location": geometry.latitude+","+geometry.longitude,
                        "radius": radius,
                        "type": type,
                        "keyword": keyword
                    }, function(ret) {
                        var placeJson = { 
                            "geometry": { 
                                "lat": geometry.latitude,
                                "lng": geometry.longitude
                            },
                            "results": ret.results,
                            "next_page_token" : ret.next_page_token
                        };
    
                        console.log("Result of nearbysearch : ", placeJson);
                        callback(placeJson);
                    });
                }
            }
        }
    
        // Retrieve next places from google map OpenAPI.
        function getNextPage(pagetoken, callback) {
            // If googleMapsclient node.js library for google map is declared, use it.
            if (googleMapsClient) {
                googleMapsClient.placesNearby({
                    "pagetoken": pagetoken
                }, function(err, response) {
                    if (!err) {
                        console.log("getNextPage : ", response.json.results);
                        callback({
                            results: response.json.results,
                            next_page_token: (response.json.next_page_token||null)
                        });
                    } else if (err === 'timeout') {
                        // Handle timeout.
                        console.log(err);
                    } else if (err.json) {
                        // Inspect err.status for more info.
                        console.log(err);
                    } else {
                        // Handle network error.
                        console.log("err : other", err);
                    }
                    
                });
            } else {
                var url = "https://maps.googleapis.com/maps/api/place/nearbysearch";
    
                doOpenApiCall({
                    url: url,
                    retType: "json",
                    key: key,
                    params: {
                        "pagetoken": pagetoken
                    }
                }, function(ret) {
                    console.log("getNextPage : ", ret);
                    callback({ results: ret.results, next_page_token: (ret.next_page_token||null) });
                });
            }
        }
    
        // Retrieve place details from placeid by google map API.
        function getPlaceDetailByPlaceid(placeid, callback) {
            // If googleMapsclient node.js library for google map is declared, use it.
            if (googleMapsClient) {
                googleMapsClient.place({
                    "placeid": placeid
                }, function(err, response) {
                    if (!err) {
                        console.log("getPlaceDetailByPlaceid : ", response.json.result);
                        callback(response.json.result);
                    } else if (err === 'timeout') {
                        // Handle timeout.
                        console.log(err);
                    } else if (err.json) {
                        // Inspect err.status for more info.
                        console.log(err);
                    } else {
                        // Handle network error.
                        console.log("err : other", err);
                    }
                    
                });
            } else {
                var url = "https://maps.googleapis.com/maps/api/place/details";
                
                doOpenApiCall({
                    url: url,
                    retType: "json",
                    key: key,
                    params: { "placeid": placeid }
                }, function(ret) {
                    callback(ret.result);
                });
            }
        }

        // Retrieve place details from placeid by google map API.
        function getRoutes({
            origin,
            destination,
            mode
        }, callback) {            
            var url = "https://maps.googleapis.com/maps/api/directions";
            
            doOpenApiCall({
                url: url,
                retType: "json",
                key: key,
                params: {
                    "origin": origin,
                    "destination": destination,
                    "mode": mode
                }
            }, function(ret) {
                callback(ret);
            });
        }
    
        // Retrieve photo url from photoreference by google map API.
        function getPhotoUrlByPhotoReference({
            maxheight,
            maxwidth,
            photoreference
        }, callback) {
            // If googleMapsclient node.js library for google map is declared, use it.
            // if (googleMapsClient) {
            //     googleMapsClient.placesPhoto({
            //         "maxheight": Number(maxheight),
            //         "maxwidth": Number(maxwidth),
            //         "photoreference": photoreference
                    
            //     }, function(err, response) {
            //         if (!err) {
            //             console.log("getPhotoUrlByPhotoReference : ", response.json.result);
            //             callback(response.json.result);
            //         } else if (err === 'timeout') {
            //             // Handle timeout.
            //             console.log(err);
            //         } else if (err.json) {
            //             // Inspect err.status for more info.
            //             console.log(err);
            //         } else {
            //             // Handle network error.
            //             console.log("err : other", err);
            //         }
            //     });
            // } else {            
                var url = "https://maps.googleapis.com/maps/api/place";
    
                doOpenApiCall({
                    url: url,
                    retType: "photo",
                    key: key,
                    params: { "maxheight": maxheight, "photoreference": photoreference }
                }, function(ret) {
                    console.log("getPhotoUrlByPhotoReference", ret);
                    callback(ret);
                });
            // }
        }
    
        // Retrieve reviews and photos for placeid.
        function getJsonOfReviewsAndPhotos(placeid, callback) {
            console.log(">>>>>>>>>>>>>>>>>>>>>>getJsonOfReviewsAndPhotos : "+placeid+">>>>>>>>>>>>>");
            getPlaceDetailByPlaceid(placeid, function(ret) {
                var imageArray = [];
    
                // Retrieve photo urls.
                if (ret.result.photos) {
                    var photos = ret.result.photos;
                    console.log(photos);
        
                    //date_default_timezone_set('UTC');
                    for (let i=0; i<photos.length; i++) {                
                        //var path = "./retImage$i.".date("YmdHis").".jpg";
                        getPhotoUrlByPhotoReference({
                            "maxheight": photos[i].height,
                            "maxwidth": photos[i].width,
                            "photoreference": photos[i].photo_reference
                        }, function(img) {
                            console.log(`>>>>>>>>>>>>>>>>>>>>>>image : ${i}>>>>>>>>>>>>>`);
                            console.log(img);
    
                            imageArray[i] = { 'path': img };/*,'data_uri'=>getDataUriFromImagePath($path)*/
                            var count = imageArray.filter(function() { return true; }).length
                            if (count==photos.length) {
                                var reviews = ret.reviews || {};
                                var retObj = { 'info': ret, 'name': ret.name, 'photos': imageArray, 'reviews': ret.reviews };
    
                                callback(retObj);
                            }
    
                        });                    
                    }
                }
        
            });
        }

        //Create googleMapClient object.
        // googleMapsClient = require('@google/maps').createClient({
        //     key: key
        // });
    
        // Initialize singleton object.
        singleObj = {
            getGeocodeByAddress: getGeocodeByAddress,
            getPlaces: getPlaces,
            getNextPage: getNextPage,
            getPlaceDetailByPlaceid: getPlaceDetailByPlaceid,
            getRoutes: getRoutes,
            getPhotoUrlByPhotoReference: getPhotoUrlByPhotoReference
        };

        // Replace createGoogleMapObj to Factory function for single Map.
        createGoogleMapApiObj = function() {
            return singleObj;
        }

        return singleObj;
    })();
};

router.get('/geocode', function(req, res, next) {
    console.log("GET ", "/geocode ", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getGeocodeByAddress(req.query.addr, function(ret) {
        res.send(ret);
    });
});

router.get('/nearby', function(req, res, next) {
    console.log("GET ", "/nearby ", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getPlaces({
        latitude: req.query.latitude,
        longitude: req.query.longitude,
        from: req.query.from,
        addr: req.query.addr,
        radius: req.query.radius,
        type: req.query.type,
        keyword: req.query.keyword        
    }, function(ret) {
        res.send(ret);
    });
});

router.get('/directions', function(req, res, next) {
    console.log("GET ", "/directions", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getRoutes({
        origin: req.query.origin,
        destination: req.query.destination,
        mode: req.query.mode
    }, function(ret) {
        console.log(ret);
        res.send(ret);
    });
});


router.get('/nearbyNext', function(req, res, next) {
    console.log("GET ", "/nearbyNext ", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getNextPage(req.query.pagetoken, function(ret) {
        res.send(ret);
    });
});

router.get('/placedetail', function(req, res, next) {
    console.log("GET ", "/placedetail", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getPlaceDetailByPlaceid(req.query.placeid, function(ret) {
        console.log(ret);
        res.send(ret);
    });
});

router.get('/photourl', function(req, res, next) {
    console.log("GET ", "/photourl ", req.query);
    var googleMapObj = createGoogleMapApiObj();
    googleMapObj.getPhotoUrlByPhotoReference({
        "maxheight": req.query.maxheight,
        "maxwidth": req.query.maxwidth,
        "photoreference": req.query.photo_reference
    }, function(ret) {
        console.log(ret);
        res.send(ret);
    });
});

module.exports = router;


// dump_arrap() function has an argument as an array and makes a string that 
// its format is {var1 = 'value1', var2 = 'value2', ''' } of the array.










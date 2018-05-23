<?php
    // dump_arrap() function has an argument as an array and makes a string that 
    // its format is {var1 = 'value1', var2 = 'value2', ''' } of the array.
    function dump_array($array) {
        if (is_array($array)) {
            $size = count($array);
            $string = "";
            if ($size) {
                $count = 0;
                $string .= "{";

                // Append each key and value to string.
                foreach ($array as $k => $v) {
                    $string .= $k." = ".$v;
                    if ($count++ < ($size-1)) {
                        $string .= ", ";                                    
                    }
                }
                $string .= "}";
            }

            return $string;
        } else {
            return $array;
        }
    }

    // Call openAPI.
    function doOpenApiCall($url, $retType, $key, $params) {
        $query = $url."/".$retType."?";
        foreach($params as $k => $v) {
            $query .= ("&".$k."=".str_replace(" ", "+", $v));
        }

        $query .= ("&key=".$key);
        error_log("doOpenApiCall : ".$query);
        $ret = file_get_contents($query);
        error_log("Result of doOpenApiCall : ".$ret);

        return $ret;
    }

    // Retrieve geocode from address by google map API.
    // Return an array which contains latitude and longitude.
    function getGeocodeByAddress($addr) {
        $url = "https://maps.googleapis.com/maps/api/geocode";
        $key = "google map api key for geocode";

        $ret = doOpenApiCall($url, "json", $key, array("address"=>$addr));
        $retJson = json_decode($ret);

        $lat = -1;
        $lng = -1;        
        if (0 < count($retJson->results)) {
            $geometry = $retJson->results[0]->geometry;
            $lat = $geometry->location->lat;
            $lng = $geometry->location->lng;
        }
        
        $retArray = array("latitude"=>$lat, "longitude"=>$lng);
        
        return $retArray;
    }

    // Retrieve place information from address by google map API.
    function getPlaceFromNearbysearch($location, $radius, $type, $keyword) {
        $url = "https://maps.googleapis.com/maps/api/place/nearbysearch";
        $key = "google map api key for place";

        // Google map API allows radius at most 50,000 meters.
        if (50000 < $radius) {
            $radius = 50000;
        }

        $params = array("location"=>$location, "radius"=>$radius, "type"=>("default" == $type ? "" : $type), "keyword"=>$keyword);
        $ret = doOpenApiCall($url, "json", $key, $params);
        $retJson = json_decode($ret);
        
        return $retJson->results;
    }

    // Retrieve places from google map OpenAPI.
    function getPlaces($latitude, $longitude, $from, $addr, $radius, $type, $keyword) {
        $geometry = array("latitude"=>$latitude, "longitude"=>$longitude);

        if ("location" == $from) {
            $geometry = getGeocodeByAddress($addr);
        }

        // convert mile to meter by multipling 1609.
        $places = getPlaceFromNearbysearch($geometry["latitude"].",".$geometry["longitude"], (null==$radius||""==$radius?10:$radius)*1609, $type, $keyword);
        $placeJson = json_encode(array("geometry"=>array("lat"=>$geometry["latitude"], "lng"=>$geometry["longitude"]), "results"=>$places));
        error_log("Result of nearbysearch : ".$placeJson);

        return $placeJson;
    }

    // Retrieve place details from placeid by google map API.
    function getPlaceDetailByPlaceid($placeid) {
        $url = "https://maps.googleapis.com/maps/api/place/details";
        $key = "google map api key for place";

        $ret = doOpenApiCall($url, "json", $key, array("placeid"=>$placeid));
        $retJson = json_decode($ret);
        
        return $retJson;
    }

    // Retrieve photo url from photoreference by google map API.
    function getPhotoUrlByPhotoReference($maxheight, $maxwidth, $photoreference) {
        $url = "https://maps.googleapis.com/maps/api/place";
        $key = "google map api key for place";

        $ret = doOpenApiCall($url, "photo", $key, array("maxheight"=>$maxheight, "photoreference"=>$photoreference));
        return $ret;
    }

    // Retrieve dataURI from a image file path.
    function getDataUriFromImagePath($path) {
        error_log("getDataUriFromImagePath : ".$path);
        $imgData = file_get_contents($path);
        return 'data:/'.mime_content_type($path).';base64,'.base64_encode($imgData);
    }

    // Retrieve reviews and photos for placeid.
    function getJsonOfReviewsAndPhotos($placeid) {
        error_log(">>>>>>>>>>>>>>>>>>>>>>placeDetailJson : ".$placeid.">>>>>>>>>>>>>");
        $placeDetails = getPlaceDetailByPlaceid($placeid);
        error_log(json_encode($placeDetails));

        $imageArray = Array();

        // Retrieve photo urls.
        if (isset($placeDetails->result->photos)) {
            $photos = $placeDetails->result->photos;
            error_log(json_encode($photos));

            date_default_timezone_set('UTC');
            for ($i=0; $i<count($photos) && $i<5; $i++) {                
                $path = "./retImage$i.".date("YmdHis").".jpg";
                error_log(">>>>>>>>>>>>>>>>>>>>>>image>>>>>>>>>>>>>");
                $img = getPhotoUrlByPhotoReference($photos[$i]->height, $photos[$i]->width, $photos[$i]->photo_reference);
                error_log($img);
                file_put_contents($path, $img);
                $imageArray[$i] = array('path'=>$path/*,'data_uri'=>getDataUriFromImagePath($path)*/);
            }
        }

        $reviews = isset($placeDetails->result->reviews) ? $placeDetails->result->reviews : array();
        $retObj = json_encode(array('name'=>$placeDetails->result->name, 'photos'=>$imageArray, 'reviews'=>$reviews));

        return $retObj;
    }

    error_log("POST : ".dump_array($_POST));
?>
<?php if (isset($_POST["keyword"])): ?>
    <?php 
    // Check if the image file exists in the path
    $path = "./";
    $files = array_values(array_diff(scandir($path), array(".", "..")));
    foreach ($files as $file) {
        if (preg_match("/^retImage[0-9]{1}\.[0-9]+\.jpg$/", $file) && !is_dir($path.$file)) {
            error_log("unlink(".$file.")");
            // When the file already exists
            unlink($file);  // Delete File
        }
    }
    ?> 
    <?php echo getPlaces($_POST["latitude"], $_POST["longitude"], $_POST["from"], $_POST["addr"], $_POST["radius"], $_POST["type"], $_POST["keyword"]); ?>
<?php elseif (isset($_POST["placeid"])): ?>
    <?php echo getJsonOfReviewsAndPhotos($_POST["placeid"]); ?>
<?php else: ?>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <style type="text/css">
            .content { }

            .searchDiv { background-color: #f2f2f2; border: 4px solid #999; padding: 15px; text-align: center; width: 800px; margin: 0 auto; }
            .header h1 { font-style: italic; }

            .inputForm { text-align: left; }
            .inputForm div { padding: 5px 0px; position: relative; }
            .inputForm span { font-family: serif; font-weight: bold; font-size: 20px; padding-right: 10px; }
            .inputForm input { margin-right: 10px; }
            .inputForm ul { position: absolute; left: 370px; top: -10px; }
            .inputForm ul li { list-style: none; }
            .inputForm ul li input[type="text"] { width: 300px; }
            .inputForm .buttonDiv { padding-left: 70px; margin-top: 50px; }

            .resultDiv { padding-top: 30px; }
            .resultTable { width: 100%; padding: 15px; text-align: center; border: 2px solid #999; border-collapse: collapse; display: none; }
            .resultTable th { border: 2px solid #999; }
            .resultTable td { border: 2px solid #999; }
            .resultTable a:hover { text-decoration-line: underline; cursor: pointer; }
            .resultTable a:active { }
            .resultTable a:visited { }
            .noRecordsFound { background-color: #f2f2f2; width: 100%; text-align: center; border: 2px solid #999; display: none; }
            
            #map { position: absolute; width: 500px; height: 400px; display: none; }
            #floating-panel { position: absolute; background-color: #fff; padding: 5px; border: 1px solid #999; text-align: center; font-family: 'Roboto','sans-serif'; line-height: 30px; padding-left: 10px; display: none; }
            #floating-panel a:hover { text-decoration-line: underline; cursor: pointer; }

            .detailDiv { display: none; text-align: center; width: 830px; margin: 0 auto; }

            .reviewTableArea { display: none; }
            .reviewDiv div { padding: 10px 0px; }
            .reviewDiv div img:hover{ cursor: pointer; }
            .reviewTable { border: 2px solid #999; border-collapse: collapse; text-align: center; display: none; }
            .reviewTable th { border: 2px solid #999; width: 900px; }
            .reviewTable th img { width: 30px; }
            .reviewTable td { border: 2px solid #999; text-align: left; height: 30px; }
            .noReviewFound { border: 2px solid #999; font-weight: bold; display: none; }
            
            .photoTableArea { display: none; }
            .photoDiv div { padding: 10px 0px; }
            .photoDiv div img:hover{ cursor: pointer; }
            .photoTable { border: 2px solid #999; border-collapse: collapse; text-align: center; display: none; }
            .photoTable td { border: 2px solid #999; text-align: center; }
            .photoTable td img { width: 800px; padding: 10px; }
            .photoTable td img:hover { cursor: pointer; }
            .noPhotoFound { border: 2px solid #999; font-weight: bold; display: none; }

            .arrowImg { width: 5%; }
            
        </style>
        <title>Travel and Entertainment Search</title>
        <script async defer src="https://maps.googleapis.com/maps/api/js?key=google_map_api_key_for_place&callback=initMap">
    </script>
        <script type="text/javascript">
            // Constructor -- pass a REST request URL to the constructor
            function JSONscriptRequest(fullUrl) {
                // REST request path
                this.fullUrl = fullUrl;
                
                // Keep IE from caching requests
                this.noCacheIE = '&noCacheIE=' + (new Date()).getTime();

                // Get the DOM location to put the script tag
                this.headLoc = document.getElementsByTagName("head").item(0);

                // Generate a unique script tag id
                this.scriptId = 'JscriptId' + JSONscriptRequest.scriptCounter++;
            }

            // Static script ID counter
            JSONscriptRequest.scriptCounter = 1;

            // buildScriptTag method
            JSONscriptRequest.prototype.buildScriptTag = function () {
                // Create the script tag
                this.scriptObj = document.createElement("script");
                
                // Add script object attributes
                this.scriptObj.setAttribute("type", "text/javascript");                
                this.scriptObj.setAttribute("charset", "utf-8");
                this.scriptObj.setAttribute("src", this.fullUrl);// + this.noCacheIE);
                this.scriptObj.setAttribute("id", this.scriptId);
            }

            // removeScriptTag method
            JSONscriptRequest.prototype.removeScriptTag = function () {
                // Destroy the script tag
                this.headLoc.removeChild(this.scriptObj);
            }

            // addScriptTag method
            JSONscriptRequest.prototype.addScriptTag = function () {
                // Create the script tag
                this.headLoc.appendChild(this.scriptObj);
            }

            // scriptObj for jsonp
            var scriptObj = null;
            window.onload = function() {                
                var radioNodes = document.getElementsByName("from");                
                for (var i=0; i<radioNodes.length; i++) {
                    radioNodes[i].addEventListener("change", function(e) {
                        if ("location" == this.value) {
                            document.getElementsByName("addr")[0].disabled = !(this.checked);
                        } else {
                            document.getElementsByName("addr")[0].disabled = this.checked;
                        }
                        console.log(this);
                    });                    
                }

                document.getElementsByName("searchForm")[0].addEventListener("submit", function(e) {
                    console.log(e);
                    console.log(this);
                    
                    var eleInputs = this.getElementsByTagName("input");
                    var eleSels = this.getElementsByTagName("select")[0];

                    var dataStr = eleSels.name+"="+eleSels.value;
                    for (var i=0; i<eleInputs.length; i++) {
                        if ("radio" == eleInputs[i].type) {
                            if (eleInputs[i].checked) {
                                dataStr = dataStr+"&"+eleInputs[i].name+"="+eleInputs[i].value;
                            }
                        } else {
                            dataStr = dataStr+"&"+eleInputs[i].name+"="+eleInputs[i].value;
                        }
                    }

                    // Call ajax
                    var retStr = loadJSON("<?php echo $_SERVER["PHP_SELF"] ?>", dataStr);
                    if (0 < retStr.length) {
                        try {        
                            document.getElementsByClassName("detailDiv")[0].style.display = "none";
                            var retObj = JSON.parse(retStr);
                            renderResult(retObj);
                        } catch (e) {
                            if (e instanceof SyntaxError) {
                                alert("Fail to parse JSON.");
                            }
                        }
                    }
                    
                    // Stops event bubbling.
                    if (e.preventDefault) {
                        e.preventDefault();
                    }

                    return false;
                });

                document.getElementById("Clear").addEventListener("click", function(e) {
                    var form = document.getElementsByName("searchForm")[0];
                    var latEle = document.getElementsByName("latitude")[0];
                    var lngEle = document.getElementsByName("longitude")[0];

                    var lat = latEle.value;
                    var lng = lngEle.value;

                    form.reset();
                    document.getElementsByName("addr")[0].disabled = true;
                    
                    latEle.value = lat;
                    lngEle.value = lng;
                    
                    document.getElementById("map").style.display = "none";
                    document.getElementById("floating-panel").style.display = "none";
                    document.getElementsByClassName("resultDiv")[0].style.display = "none";
                    document.getElementsByClassName("detailDiv")[0].style.display = "none";  
                });
            
                // Retrieve geolocation code of ip address.
                getIpGeo("http://ip-api.com/json/");
            
                // Retrive google map api script.
                // var googleObj = document.createElement("script");
                // googleObj.setAttribute("async", "");
                // googleObj.setAttribute("src", "https://maps.googleapis.com/maps/api/js?key=google_map_api_key_for_place&callback=initMap");
                // document.getElementsByTagName("head")[0].appendChild(googleObj);
            }

            // Retrieve geolocation code of ip address.
            function getIpGeo(url) {
                var query = url + "?callback=ipGeoCallback";
                
                scriptObj = document.createElement("script");
                scriptObj.setAttribute("type", "text/javascript");                
                scriptObj.setAttribute("charset", "utf-8");
                scriptObj.setAttribute("src", query + '&noCacheIE=' + (new Date()).getTime());
            
                // Disable submit button until the geolocation data is responsed.
                document.getElementById("send").disabled = true;
                document.getElementsByTagName("head")[0].appendChild(scriptObj);
            }

            // JSONP callback function
            function ipGeoCallback(jsonData) {
                console.log(jsonData);
                document.getElementsByTagName("head")[0].removeChild(scriptObj);
                if ("status" in jsonData) {    //http://ip-api.com/json/
                    if ("success" == jsonData.status) {
                        document.getElementsByName("latitude")[0].value = jsonData.lat;
                        document.getElementsByName("longitude")[0].value = jsonData.lon;
                    } else {
                        getIpGeo("https://ipapi.co/jsonp/");
                    }
                } else if ("postal" in jsonData) {  //https://ipapi.co/jsonp/
                    if (null != jsonData.latitude) {
                        document.getElementsByName("latitude")[0].value = jsonData.latitude;
                        document.getElementsByName("longitude")[0].value = jsonData.longitude;
                    } else {
                        getIpGeo("https://freegeoip.net/json/");
                    }
                } else if ("metro_code" in jsonData) {  //https://freegeoip.net/json/
                    if (null != jsonData.latitude) {
                        document.getElementsByName("latitude")[0].value = jsonData.latitude;
                        document.getElementsByName("longitude")[0].value = jsonData.longitude;
                    } else {
                        // Default location is geocode of University of Southern California.
                        document.getElementsByName("latitude")[0].value = "34.0223519";
                        document.getElementsByName("longitude")[0].value = "-118.285117";
                    }
                } 

                // Elable submit button when the geolocation data is responsed.
                document.getElementById("send").disabled = false;
            }

            // google map object retriver
            var getGoogleMap = null;
            // google map jsonp callback
            function initMap() {
                if (getGoogleMap == null) {
                    getGoogleMap = (function() {
                        var googleMapObj = createGoogleMapObj();
                        
                        return function() {
                            return googleMapObj;
                        };
                    })();
                }
            }

            // Render result table
            function renderResult(placeJson) {
                console.log(placeJson);

                // Get google a map object.
                var googleMapObj = getGoogleMap();
                googleMapObj.setOriginPosition(placeJson.geometry.lat, placeJson.geometry.lng);
                googleMapObj.showMap(false);

                if (0 < placeJson.results.length) {
                    var tableEle = document.getElementsByClassName("resultTable")[0];

                    // Resets table.
                    var tbodyEle = tableEle.getElementsByTagName("tbody");
                    if (0 < tbodyEle.length) {
                        tbodyEle[0].remove();
                    }
                    tbodyEle = document.createElement('tbody');

                    // Set orginated position.
                    tableEle.setAttribute("latitude", placeJson.geometry.lat);
                    tableEle.setAttribute("longitude", placeJson.geometry.lng);
                    for (var i=0; i<placeJson.results.length; i++) {
                        trEle = tbodyEle.insertRow(i);                    

                        // First column (icon)
                        trEle.insertCell(0).innerHTML = '<img src="' + placeJson.results[i].icon + '" />';
                        
                        // Second column (name)
                        var anchorEle = document.createElement("a");
                        anchorEle.innerHTML = placeJson.results[i].name;
                        anchorEle.setAttribute("placeid", placeJson.results[i].place_id);
                        anchorEle.addEventListener("click", function(e) {
                            console.log("placeid : " + this.getAttribute("placeid"));

                            // document.getElementsByName("placeid")[0].value = this.getAttribute("placeid");
                            var retStr = loadJSON("<?php echo $_SERVER["PHP_SELF"] ?>", "placeid="+this.getAttribute("placeid"));
                            if (0 < retStr.length) {
                                try {        
                                    document.getElementsByClassName("resultDiv")[0].style.display = "none";
                                    var retObj = JSON.parse(retStr);
                                    renderPlaceDetail(retObj);
                                } catch (e) {
                                    if (e instanceof SyntaxError) {
                                        alert("Fail to parse JSON.");
                                    }
                                }
                            }
                        });
                        trEle.insertCell(1).append(anchorEle);

                        // Third column (addr)
                        anchorEle = document.createElement("a");
                        anchorEle.innerHTML = placeJson.results[i].vicinity;
                        anchorEle.setAttribute("lat", placeJson.results[i].geometry.location.lat);
                        anchorEle.setAttribute("lng", placeJson.results[i].geometry.location.lng);                    
                        anchorEle.addEventListener("click", function(e) {
                            console.log(arguments);

                            var lat = this.getAttribute("lat");
                            var lng = this.getAttribute("lng");

                            if (true == googleMapObj.isVisible()) { // When google map is not visible, show the map.
                                if (googleMapObj.getLatitude() == lat && googleMapObj.getLongitude() == lng) {
                                    // If the same address is clicked, close the map.
                                    googleMapObj.showMap(false);
                                    return;
                                }
                            } 

                            googleMapObj.initMap();
                            googleMapObj.moveToMapPosition(this.parentElement.offsetLeft+50, e.clientY+10);
                            googleMapObj.setMapCenterPosition(lat, lng);
                            googleMapObj.setMapZoomLevel(15);
                            googleMapObj.setMarkerLocation(lat, lng);
                            googleMapObj.showMap(true);
                        });

                        var cell = trEle.insertCell(2);
                        cell.style.textAlign = "left";
                        cell.append(anchorEle);
                    }

                    tableEle.append(tbodyEle);
                    tableEle.style.display = "table";
                    document.getElementsByClassName("noRecordsFound")[0].style.display = "none";
                } else {
                    document.getElementsByClassName("resultTable")[0].style.display = "none";
                    document.getElementsByClassName("noRecordsFound")[0].style.display = "table";
                }

                document.getElementsByClassName("resultDiv")[0].style.display = "block";
            }

            function createGoogleMapObj() {                
                var mapDiv = document.getElementById("map");
                var panel = document.getElementById("floating-panel");

                var origin = { "lat" : null, "lng" : null };
                var dest = { "lat" : null, "lng" : null };
                var map = null;
                var marker = null;
                var directionsDisplay = null;

                var singleObj = null;
                
                // Initialize map object.
                // If a map object is not created, create map, marker, amd directionDisplay object,
                // else reset these object.
                // Return a map object for both cases.
                function initMap() {
                    if (null == singleObj) {

                        console.log("initMap");
                    
                        map = new google.maps.Map(mapDiv);
                        marker = new google.maps.Marker;
                        directionsDisplay = new google.maps.DirectionsRenderer;

                        var panelItems = document.getElementsByName("panelItem");
                        for (var i=0; i<panelItems.length; i++) {
                            panelItems[i].addEventListener("click", function(e) {
                                clearMarker();
                                displayRoute(this.getAttribute("value"));
                            });
                        }

                        // Create single object.
                        singleObj = {
                            "initMap" : initMap
                            , "moveToMapPosition" : moveToMapPosition
                            , "showMap" : showMap
                            , "isVisible" : isVisible
                            , "setOriginPosition" : setOriginPosition
                            , "setMapCenterPosition" : setMapCenterPosition
                            , "setMapZoomLevel" : setMapZoomLevel
                            , "setMarkerLocation" : setMarkerLocation
                            , "clearMarker" : clearMarker
                            , "getLatitude" : getLatitude
                            , "getLongitude" : getLongitude
                        };
                    } else {
                        clearMarker();
                        clearRoute();
                    }

                    return singleObj;
                }

                // Sets the position of a map on the screen.
                function moveToMapPosition(left, top) {
                    mapDiv.style.left = left;
                    mapDiv.style.top = top;

                    panel.style.left = left;
                    panel.style.top = top;
                }

                function showMap(show) {
                    var displays = ["none", "block"];
                    mapDiv.style.display = displays[(true == show ? 1 : 0)];
                    panel.style.display = displays[(true == show ? 1 : 0)];
                }

                function isVisible() {
                    return mapDiv.style.display != "none";
                }

                // Sets the origin location for the directionsDisplay
                function setOriginPosition(lat, lng) {
                    origin = { "lat" : Number(lat), "lng" : Number(lng) };
                }

                // Sets the center location of the map to argument location.
                function setMapCenterPosition(lat, lng) {
                    dest = { "lat" : Number(lat), "lng" : Number(lng) };
                    map.setCenter(dest);
                }

                // sets the zoom level of the map.
                function setMapZoomLevel(level) {
                    map.setZoom(level);
                }

                // Sets the location of a marker in the map to argument location.
                function setMarkerLocation(lat, lng) {
                    dest = { "lat" : Number(lat), "lng" : Number(lng) };
                    marker.setPosition(dest);
                    marker.setMap(map);
                }

                // Removes the marker from the map, but keeps it in the variable.
                function clearMarker() {
                    marker.setMap(null);
                }
                
                function displayRoute(travelMode) {
                    var directionsService = new google.maps.DirectionsService;

                    directionsService.route({
                        origin: origin,
                        destination: dest,
                        travelMode: google.maps.TravelMode[travelMode]
                    }, function(response, status) {
                        if (status == 'OK') {
                            directionsDisplay.setDirections(response);
                            directionsDisplay.setMap(map);
                        } else {
                            window.alert('Directions request failed due to ' + status);
                        }
                    });
                }

                function clearRoute() {
                    directionsDisplay.setMap(null);
                }

                function getLatitude() {
                    return dest.lat;
                }

                function getLongitude() {
                    return dest.lng;
                }
                
                return initMap();
            }

            function renderPlaceDetail(placeDetailJSON) {
                console.log(placeDetailJSON);

                var toggle = getToggle(false, false);
                
                var detailDiv = document.getElementsByClassName("detailDiv")[0];
                detailDiv.getElementsByTagName("h1")[0].innerHTML = placeDetailJSON.name;
                
                var reviewDiv = detailDiv.getElementsByClassName("reviewDiv")[0];
                var imgEle = reviewDiv.getElementsByTagName("img")[0];
                imgEle.addEventListener("click", function(e) {
                    toggle(this);                    
                });
                
                var tableEle = reviewDiv.getElementsByTagName("table")[0];
                var noFoundDiv = reviewDiv.getElementsByClassName("noReviewFound")[0];
                if (0 < placeDetailJSON.reviews.length) {
                    // Resets table.
                    var tbodyEle = tableEle.getElementsByTagName("tbody");
                    if (0 < tbodyEle.length) {
                        tbodyEle[0].remove();
                    }
                    tbodyEle = document.createElement('tbody');
                    
                    for (var i=0; i<placeDetailJSON.reviews.length && i<5; i++) {
                        var trEle = tbodyEle.insertRow(2*i);
                        var thStr = "";
                        if ("" != placeDetailJSON.reviews[i].profile_photo_url) {
                            thStr = "<img src='" + placeDetailJSON.reviews[i].profile_photo_url + "'>";                            
                        }
                        thStr += "<span><b>" + placeDetailJSON.reviews[i].author_name + "</b></span>";
                        trEle.innerHTML = "<th>" + thStr + "</th>";

                        trEle = tbodyEle.insertRow((2*i)+1);                        
                        trEle.innerHTML = "<td>" + placeDetailJSON.reviews[i].text + "</td>";
                    }
                    tableEle.append(tbodyEle);                    
                    tableEle.style.display = "table";
                    noFoundDiv.style.display = "none";
                } else {
                    tableEle.style.display = "none";
                    noFoundDiv.style.display = "block";
                }

                // Photo Div
                var photoDiv = detailDiv.getElementsByClassName("photoDiv")[0];                
                var imgEle = photoDiv.getElementsByTagName("img")[0];
                imgEle.addEventListener("click", function(e) {
                    toggle(this);
                });
                
                var tableEle = photoDiv.getElementsByTagName("table")[0];
                var noFoundDiv = photoDiv.getElementsByClassName("noPhotoFound")[0];
                if (0 < placeDetailJSON.photos.length) {

                    // Resets table.
                    var tbodyEle = tableEle.getElementsByTagName("tbody");
                    if (0 < tbodyEle.length) {
                        tbodyEle[0].remove();
                    }
                    tbodyEle = document.createElement('tbody');
                
                    for (var i=0; i<placeDetailJSON.photos.length; i++) {
                        var trEle = tbodyEle.insertRow(i);

                        var imgEle = document.createElement("img");
                        imgEle.setAttribute("src", placeDetailJSON.photos[i].path);

                        var anchorEle = document.createElement("a");
                        anchorEle.setAttribute("href", placeDetailJSON.photos[i].path);
                        anchorEle.setAttribute("target", "_blank");
                        anchorEle.append(imgEle);
                        
                        trEle.insertCell(0).append(anchorEle);
                        // trEle.insertCell(0).innerHTML("<a href='"+placeDetailJSON.photos[i].path+"' target='_blank'><img src='"+placeDetailJSON.photos[i].path+"' /></a>");
                    }
                    tableEle.append(tbodyEle);
                    tableEle.style.display = "table";
                    noFoundDiv.style.display = "none";
                } else {
                    tableEle.style.display = "none";
                    noFoundDiv.style.display = "block";
                }

                detailDiv.style.display = "block";
            }

            function getToggle(review, photo) {
                var arrowUp = "./arrow_up.png"
                var arrowDown = "./arrow_down.png";

                var reviewStatus = (review == true);
                var photoStatus = (photo == true);

                var reviewSpan = document.getElementsByName('reviewAnchor')[0];
                var reviewImg = document.getElementsByName('reviewArrow')[0];
                var reviewTableArea = document.getElementsByClassName('reviewTableArea')[0];
                var photoSpan = document.getElementsByName('photoAnchor')[0];
                var photoImg = document.getElementsByName('photoArrow')[0];
                var photoTableArea = document.getElementsByClassName('photoTableArea')[0];

                function showReviews(expand) {
                    if (expand) {
                        reviewSpan.innerHTML = "Click to hide reviews";                        
                        reviewImg.src = arrowUp;
                        reviewTableArea.style.display = "block";
                    } else {
                        reviewSpan.innerHTML = "Click to show reviews";                        
                        reviewImg.src = arrowDown;
                        reviewTableArea.style.display = "none";
                    }

                    return (true == expand);
                }

                function showPhotos(expand) {
                    if (expand) {
                        photoSpan.innerHTML = "Click to hide photos";
                        photoImg.src = arrowUp;
                        photoTableArea.style.display = "block";
                    } else {
                        photoSpan.innerHTML = "Click to show photos";                        
                        photoImg.src = arrowDown;
                        photoTableArea.style.display = "none";
                    }

                    return (true == expand);
                }

                showReviews(reviewStatus);
                showPhotos(photoStatus);

                return (function (ele) {
                    if (reviewImg == ele) {
                        reviewStatus = showReviews(false == reviewStatus);
                        photoStatus = showPhotos(false == reviewStatus);
                    } else if (photoImg == ele) {
                        photoStatus = showPhotos(false == photoStatus);
                        reviewStatus = showReviews(false == photoStatus);
                    }
                });
            }

            function loadJSON(url, data) {
                var xhr;
                if (window.XMLHttpRequest) { // code for IE7+, Firefox, Chrome, Opera, Safari
                    xhr = new XMLHttpRequest();
                } else { // code for IE6, IE5
                    xhr = new ActiveXObject("Microsoft.XMLHTTP");
                } 

                xhr.open("POST", url, false);
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                try {
                    xhr.send(data);
                    if (404 == xhr.status && 4 == xhr.readyState) {
                        alert("The json file doesn't exist on the url.");
                        return "";
                    }
                } catch (e) {                
                    if (e instanceof DOMException) {
                        if (0 == xhr.status && 4 == xhr.readyState) {
                            alert("Failed to load " + url + ": No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'null' is therefore not allowed access.");
                        } else {
                            console.log(e);
                            alert(e.message);
                        }
                        
                        return "";
                    }
                }

                return xhr.responseText;
            }

        </script>
    </head>
    <body>
        <div class="content">
            <div class="searchDiv">
                <div class="header">
                    <h1>Travel and Entertainment Search</h1>
                    <hr />
                </div>
                <div class="inputForm">
                    <form method="POST" name="searchForm" action="<?php echo $_SERVER["PHP_SELF"] ?>">
                        <div>
                            <span>Keyword</span><input name="keyword" type="text" size=40 required>
                        </div>
                        <div>
                            <span>category</span>
                            <select name="type" required>
                                <option value="default">default</option>
                                <option value="cafe">cafe</option>
                                <option value="bakery">bakery</option>
                                <option value="restaurant">restaurant</option>
                                <option value="beauty_salon">beauty salon</option>
                                <option value="casino">casino</option>
                                <option value="movie_theater">movie theater</option>
                                <option value="lodging">lodging</option>
                                <option value="airport">airport</option>
                                <option value="train_station">train station</option>
                                <option value="subway_station">subway station</option>
                                <option value="bus_station">bus station</option>
                            </select>
                        </div>
                        <div>
                            <span>Distance (miles)</span><input name="radius" type="number" placeholder="10" size=5><span>from</span>
                            <ul>
                                <li><input type="radio" name="from" value="Here" checked><span>Here</span></li>
                                <li><input type="radio" name="from" value="location"><input name="addr" type="text" placeholder="location" size="100" disabled="true" required></li>
                            </ul>
                        </div>
                        <input name="latitude" type="text" hidden="true">
                        <input name="longitude" type="text" hidden="true">
                        <!-- <input name="placeid" type="text" hidden="true"> -->
                        <div class="buttonDiv">
                            <input id="send" name="send" type="submit" value="Search" disabled="true">
                            <input id="Clear" type="button" value="Clear">
                        </div>
                    </form>
                </div>
            </div>
            <div class="resultDiv" style="display:none">
                <table class="resultTable">                    
                    <thead>
                        <tr><th>CATEGORY</th><th>NAME</th><th>ADDRESS</th></tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
                <table class="noRecordsFound">
                    <tr><th>No Records has been found</th></tr>
                </table>
                <div id="map">
                </div>
                <div id="floating-panel">
                    <div>
                        <a name="panelItem" value="WALKING"><b>Walk there</b></a>
                    </div>
                    <div>
                        <a name="panelItem" value="BICYCLING"><b>Bike there</b></a>
                    </div>
                    <div>
                        <a name="panelItem" value="DRIVING"><b>Drive there</b></a>
                    </div>
                </div>
            </div>            
            <div class="detailDiv">
                <h1>name</h1>
                <div class="reviewDiv">
                    <div>
                        <span name="reviewAnchor">Click to show reviews</span>
                    </div>
                    <div>
                        <img class="arrowImg" name="reviewArrow"></img>
                    </div>
                    <div class="reviewTableArea">
                        <table class="reviewTable">
                            <tbody>
                            </tbody>
                        </table>
                        <div class="noReviewFound">
                            <span>No Reviews Found</span>
                        </div>
                    </div>
                </div>
                <div class="photoDiv">
                    <div>
                        <span name="photoAnchor">Click to show photos</span>
                    </div>
                    <div>
                        <img class="arrowImg" name="photoArrow"></img>
                    </div>
                    <div class="photoTableArea">
                        <table class="photoTable">
                            <tbody>
                            </tbody>
                        </table>
                        <div class="noPhotoFound">
                            <span>No Photos Found</span>
                        </div>
                    </div>
                </div>
            </div>            
        </div>
    </body>
</html>
<?php endif; ?>
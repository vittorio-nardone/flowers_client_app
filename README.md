# Flowers classification mobile app

My really first [Flutter](https://flutter.io) project. A iOS/Android app to take a picture of a flower and use a Flask based web service to identify it.
Web service is hosted on AWS Elastic Beanstalk. Sources on GitHub [here](https://github.com/vittorio-nardone/AIPND/tree/master/mainproject-classify-flower-images).

## Demo

Application use camera to take a picture of a flower. These screenshots are from Android device simulator. Left button takes a picture and submits it to web service to get classification. Right button is used to switch between front/back cameras. 

<img src="https://github.com/vittorio-nardone/flowers_client_app/blob/master/_docs_/main_widget.png" alt="Main widget" width="200"/>

Result widget shows taken picture and top 5 categories.

<img src="https://github.com/vittorio-nardone/flowers_client_app/blob/master/_docs_/results.png" alt="Result widget" width="200"/>

Layout is changed according to device orientation.

<img src="https://github.com/vittorio-nardone/flowers_client_app/blob/master/_docs_/orientation.png" alt="Orientation" width="500"/>

## Issues

Flutter camera component seems to be affected by a bug: when image is taken, its orientation is not stored correctly. 

## To-Do

- Test application on real device
- Fix camera orientation bug
- Detect if device is offline 

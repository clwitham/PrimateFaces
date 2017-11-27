# PrimateFaces
Face Detection and Recognition Software for Primates

## Installing
### From Matlab command line (requires Matlab licence)
- Requires Image Processing and Computer Vision toolboxes (tested on Matlab 2017b release)
- Download m files and Detection_Models folder
- For viewer run PrimateFaces_Viewer in command line
- For main program type primatefaces_main in command line

### Standalone Application (no Matlab licence required)
- Download one of the two releases (either the viewer or the main)
- Run installer - you will be asked to download and install the Matlab runtime
- The program will appear in the application folder (double click to run)
- Program may take some time to load

## PrimateFaces_Viewer
### Program for testing face detection settings
- On start up you will be asked for location of folder containing detection models

### Main Screen
- Load an image file
- Choose one of the existing detectors from drop-down menu (default PrimateFaceModel.xml)
- Set minimum size (default 100)
- Use slider at bottom to change threshold of detector
- Any detected faces will appear as green boxes on image
- Save the image as a PNG or JPEG file

## PrimateFaces_Main
### Program for face detection and recognition
#### Face Detection
- Allows a new face detector to be trained
- Additional detectors for features such as eyes and noses can also be trained
- Face detection can be run on images and/or videos

#### Face Recognition
- Allows a new face recognition model to be trained
- Face recognition can be run on images and/or videos

#### See user guide (pdf) for more details

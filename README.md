# OrientationUniqueFeatureTracker

The purpose of this code is to track multiple subjects (crayfish, mice) and detect unique features on each object through object recognition, centroid production, ghost/previous frame comparison, binary image processing, and tracking in cluttered scene toolboxes for the purpose of orientation tracking based on the unique shape of the animal. 

Programs: 
- calculateMeanFrameBatch: Calculates a mean frame for the video input file to be used as a background subtract for object detection 

- track_in_cluttered_scene2: Calculate ghost frame and use as previous frame to track animal on subsequent frames. Capable of tracking multiple objects. Unique features determined with detectSURFFeatures and bounding box for between frame tracking of features. 

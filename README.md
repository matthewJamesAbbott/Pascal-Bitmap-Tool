Bitmap Factory in Pascal

This repository contains a bitmap factory application written in Pascal, showing the progression from procedural programming to object-oriented programming using various design patterns. The application is designed to perform various operations on bitmap images.
Repository Contents

    BitmapProcessing.pas: This is the starting point where bitmap processing functions such as rotation, scaling, or filtering are implemented using procedural programming.

    BitmapFactoryRecords.pas: Transition from procedural programming to object-oriented programming begins. In this stage, bitmap factories are introduced using OOP concepts. However, the pixel information is not fully encapsulated and is stored in a record structure.
    
    BitmapFactory.pas: Encapsulation of pixel from a record into an object with setters and getters

    MitigatedBitmapFactory.pas: Stability and reliability improvements are made to the program. This includes adding error handling functionality to handle unexpected conditions or exceptions, enhancing the resilience of the bitmap factory.

    BridgedMitigatedBitmapFactory.pas: The code is further refactored using the Bridge Design Pattern, which separates the abstraction (file transfers or image loading and saving) from its implementation (API for loading and saving of specific formats of image). This design allows both to vary independently.

    PreThreadedFacadeBridgedMitigatedBitmapFactory.pas: The code is prepared for the addion of multithreading capabilities by splitting images into parts and implementing a Facade over the split images. The split images allow for direct access of the image data with out fear of race conditions when multiple threads wish to work on the same image, improving the speed and efficiency of the program. The Facade Pattern simplifies the interface for the rotate concrete product as it does not read and write in a linear fashion on the y axis.

    ThreadedBitmapFactory.pas: The final version of the program that combines all of the enhancements, including OOP, design patterns, error handling, and multithreading.

The repository also includes executable files and other support files necessary to run the application.

QT = core bluetooth quick
SOURCES += qmlscanner.cpp \
    myobject1.cpp \
    myappgui.cpp

TARGET = ControlFreek
TEMPLATE = app

RESOURCES += \
    scanner.qrc

OTHER_FILES += \
    scanner.qml \
    Button.qml \
    default.png

#DEFINES += QMLJSDEBUGGER

target.path = $$[QT_INSTALL_EXAMPLES]/bluetooth/scanner
INSTALLS += target

HEADERS += \
    myobject1.h \
    myappgui.h

DISTFILES += \
    ../../../../media/scuba/A002BED402BEAEA2/Documents and Settings/scuba/My Documents/sjrtech/PedalController/pics/ads/ad_whiteboard.jpg \
    android/AndroidManifest.xml \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradlew \
    android/res/values/libs.xml \
    android/build.gradle \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew.bat \
    images/20170630_123903.jpg \
    images/20170630_123934.jpg \
    images/20170630_123955.jpg \
    images/20170630_124004.jpg \
    images/20170630_124025.jpg \
    images/20170630_124054.jpg \
    images/20170630_124059.jpg \
    images/ad_whiteboard.jpg \
    images/breakout_pedals.jpg \
    images/C2_Both.JPG \
    images/C3_Both.JPG \
    images/C3_Both_back.JPG \
    images/stomp.jpg \
    images/alien.png \
    images/App_0_7.png \
    images/App_0_7_Song.png \
    images/app_scrnshot.png \
    images/Control Freek Screenshot from v0.3.png

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

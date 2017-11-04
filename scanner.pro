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
    android/gradlew.bat

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

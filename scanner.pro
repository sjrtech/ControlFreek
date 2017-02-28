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

DISTFILES +=

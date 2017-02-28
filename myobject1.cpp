#include "myobject1.h"
#include <QBluetoothAddress>
#include <QtQuick/QQuickView>


MyObject1::MyObject1(QObject *parent) : QObject(parent)
{

}

void MyObject1::foo(QString MAC, QString name)
{
    QBluetoothAddress macAddr = QBluetoothAddress(MAC);
    QBluetoothDeviceInfo remoteDevice(macAddr, name, 0);

    // new QLowEnergyController(this);
    bleCentral = QLowEnergyController::createCentral(remoteDevice, this);//->connectToDevice();
    bleCentral->connectToDevice();
    connect(bleCentral, SIGNAL(connected()), this, SLOT(bleConnected()));
}

void MyObject1::bleConnected()
{
    qDebug() << "bleConnected()";


    bleCentral->discoverServices();
    connect(bleCentral, SIGNAL(serviceDiscovered(QBluetoothUuid)), this, SLOT(addService(QBluetoothUuid)));
    connect(bleCentral, SIGNAL(discoveryFinished()), this, SLOT(discoveryDone()));

}
void MyObject1::addService(QBluetoothUuid uuid)
{
    qDebug() << uuid.toString();

    //QList<QBluetoothUuid> QLowEnergyController::services() const
    //QList<QBluetoothUuid> bleServiceList = bleCentral->services();

    //SERVICE (0): 713d0000-503e-4c75-ba94-3148f18d941e
    //Characteristics:
    //READ (2):    713d0002-503e-4c75-ba94-3148f18d941e
    //WRITE (3):   713d0003-503e-4c75-ba94-3148f18d941e

    QString uuid2 = "{713d0000-503e-4c75-ba94-3148f18d941e}";
    if(uuid.toString() != uuid2) return;

    service = bleCentral->createServiceObject(uuid, this);

    if(!service)
    {
        qDebug() << "Couldn't create the service";
        return;
    }

    qDebug() << "Service Created: " << uuid2;

}
void MyObject1::discoveryDone()
{
    qDebug() << "discoveryDone()";

    //get characteristics
    service->discoverDetails();
    connect(service, SIGNAL(stateChanged(QLowEnergyService::ServiceState)), this, SLOT(bleServiceChanged(QLowEnergyService::ServiceState)) );
}
void MyObject1::bleServiceChanged(QLowEnergyService::ServiceState a)
{
    qDebug() << "bleServiceChanged()";

    //get the List of recently discovered characteristics
    bleIncludedChars = service->characteristics();

    //look for the correct values
    for(int i=0;i<bleIncludedChars.length();i++)
    {
        qDebug() << bleIncludedChars.value(i).uuid().toString();
        if(bleIncludedChars.value(i).uuid().toString() == "{713d0002-503e-4c75-ba94-3148f18d941e}") bleReadReady = true;
        if(bleIncludedChars.value(i).uuid().toString() == "{713d0003-503e-4c75-ba94-3148f18d941e}") bleWriteReady = true;
    }

    if( (bleWriteReady == false) || (bleWriteReady == false))
    {
        qDebug() << "did not find both read and write chars";
        return;
    }
    /*
    if(bleWriteReady == true)
    {
        qDebug() << "Found Write Characteristic";

        //Temp; get status
        QByteArray data = "$b0000F\r";

        service->writeCharacteristic(bleIncludedChars.value(1), data, QLowEnergyService::WriteWithoutResponse);

        //can't create one, have to use the one the service gave us
        //QLowEnergyCharacteristic writeChar;
        //QString uuid = "{713d0003-503e-4c75-ba94-3148f18d941e}";
        //writeChar.uuid() = QBluetoothUuid(uuid);
        //service->writeCharacteristic(writeChar, data, QLowEnergyService::WriteWithoutResponse);

        //no response expected!!
        //connect(service, SIGNAL(characteristicWritten(QLowEnergyCharacteristic, QByteArray)), this, SLOT(dataWritten(QLowEnergyCharacteristic, QByteArray)));
    }
    */
    if(bleReadReady == true)
    {
        qDebug() << "Found Read Characteristic - starting to read";
        //to do: start timer here?
        service->readCharacteristic(bleIncludedChars.value(0));
        connect(service, SIGNAL(characteristicRead(QLowEnergyCharacteristic,QByteArray)), this, SLOT(dataReadCB(QLowEnergyCharacteristic, QByteArray)));
    }

    //myApp(this);
    //MyAppGui retardedQTApp(this);       //make a temporary bastard Qt object,
    //myApp = &retardedQTApp;
    //OMG i can't believe I had to do that CRAP!!!!  just to get a global pointer to the object.. FUCK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! I DON"T HAVE ALL FUCKING DAY Qt!!! CAN I INVOICE YOU. YOU SOFTWARE TARDS?
    //C++ makes sure programmers keep their jobs.  Programmers are satistic fuckheads.
    //That took all fucking afternoon... now I don't rememeber why I needed it!!
    //connect(bleComm, SIGNAL(recdBLEdata(QByteArray packetArray)), this, SLOT(parseInData(QByteArray packetArray)) );
    //connect(this, SIGNAL(recdBLEdata(QByteArray packetArray)), myApp, SLOT(parseInData(QByteArray packetArray)) );

    myApp = new MyAppGui();
    connect(this, SIGNAL(recdBLEdata(QByteArray)), myApp, SLOT(parseInData(QByteArray)) );
    connect(myApp, SIGNAL(writeBLEdata(QByteArray)), this, SLOT(writeData(QByteArray)) );
    connect(myApp, SIGNAL(SongComplete()), this, SLOT(updateSongDisplay()) );
    connect(myApp, SIGNAL(ConfigComplete()), this, SLOT(updateConfigDisplay()) );


    //myApp->sendStatus();
    myApp->sendRequestForConfigBlock();

}
void MyObject1::dataReadCB(QLowEnergyCharacteristic c, QByteArray data)
{
    qDebug() << "dataRead()";
    qDebug() << "data in: " << data;

    m_RecvData = data;
    //parseInData(data);
    emit recdBLEdata(m_RecvData);

    //emit SongChanged();     //temp?? Where should I put this round about way of updating data Qt?  This is the ONLY place it works, but NOT CORRECT!!


    //temp -= READ AGAIN
    //to do: this should be called on a timer?
    service->readCharacteristic(bleIncludedChars.value(0));

}
void MyObject1::writeData(QByteArray data)
{
    //called externally to write data to the device.. THIS IS THE ONE!

    qDebug() << "writeData()";
    qDebug() << "data out: " << data;

    if(bleWriteReady == true)
        service->writeCharacteristic(bleIncludedChars.value(1), data, QLowEnergyService::WriteWithoutResponse);
    else
        qDebug() << "No Write Characteristic was discovered";

}



// //////////////////////////////////////////////////////////////////////////////////////////////////
//   SONG SCREEN OBJECTS

void MyObject1::updateSongDisplay(void)
{
    //aint Qt awesome!!
    emit SongChanged();     //temp?? Where should I put this round about way of updating data Qt?  This is the ONLY place it works, but NOT CORRECT??!!
}
void MyObject1::updateSongDevice(void)
{
    myApp->UpdateSongToDevice();
}
void MyObject1::selectNextSong(void)
{
    myApp->gotoNextSong();
    emit ConfigChanged();     //temp?? Where should I put this round about way of updating data Qt?

}
void MyObject1::selectPreviousSong(void)
{
    myApp->gotoPreviousSong();
    emit ConfigChanged();     //temp?? Where should I put this round about way of updating data Qt?
}


QString MyObject1::getSongName(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSong.name));
    }
    else
    {
        str = "Loading...";
    }
    return str;
}
void MyObject1::onSongNameChanged(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSong.name, buffer );
    }
}

QString MyObject1::getPartName(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSong.partname));
    }
    else
    {
        str = "";
    }
    return str;
}
void MyObject1::onSongPartNameChanged(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSong.partname, buffer );
    }
}

QString MyObject1::getMidiMsg1(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage1));
        str = temp.mid(0, 2);
    }
    else
    {
        str = "";
    }
    return str;
}
void MyObject1::onMidiMsg1Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
        strcpy((char*)myApp->ramSong.midiMessage1, buffer );
    }
}
QString MyObject1::getMidiMsg2(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage2));
        str = temp.mid(0, 2);
    }
    else
    {
        str = "";
    }
    return str;
}
void MyObject1::onMidiMsg2Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
        strcpy((char*)myApp->ramSong.midiMessage2, buffer );
    }
}
QString MyObject1::getMidiMsg3(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage3));
        str = temp.mid(0, 2);
    }
    else
    {
        str = "";
    }
    return str;
}
void MyObject1::onMidiMsg3Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
        strcpy((char*)myApp->ramSong.midiMessage3, buffer );
    }
}
QString MyObject1::getMidiMsg4(void) const
{
    QString str = "not this!!";
    if(myApp)
    {
        QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage4));
        str = temp.mid(0, 2);
    }
    else
    {
        str = "";
    }
    return str;
}
void MyObject1::onMidiMsg4Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
        strcpy((char*)myApp->ramSong.midiMessage4, buffer );
    }
}

QString MyObject1::getMidiMode(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.midiMsgMode);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMidiModeChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.midiMsgMode = val;
    }
}
QString MyObject1::getFswSongConfig(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.footswitch);
        str = QString(c);
    }
    return str;
}
void MyObject1::onSongFswChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.footswitch = val;
    }
}
QString MyObject1::getTrickMode(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.trickMode[0]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onTrickModeChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.trickMode[0] = val;
    }
}
QString MyObject1::getTrickData(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.trickData[0]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onTrickDataChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.trickData[0] = val;
    }
}
QString MyObject1::getSongBacklight(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.lcdBacklight);
        str = QString(c);
    }
    return str;
}
void MyObject1::onSongBacklightChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.lcdBacklight = val;
    }
}

QString MyObject1::getMatrix0(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[0]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix0Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[0] = val;
    }
}
QString MyObject1::getMatrix1(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[1]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix1Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[1] = val;
    }
}
QString MyObject1::getMatrix2(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[2]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix2Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[2] = val;
    }
}
QString MyObject1::getMatrix3(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[3]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix3Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[3] = val;
    }
}
QString MyObject1::getMatrix4(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[4]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix4Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[4] = val;
    }
}
QString MyObject1::getMatrix5(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[5]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix5Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[5] = val;
    }
}
QString MyObject1::getMatrix6(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[6]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix6Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[6] = val;
    }
}
QString MyObject1::getMatrix7(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[7]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix7Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[7] = val;
    }
}
QString MyObject1::getMatrix8(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[8]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix8Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[8] = val;
    }
}
QString MyObject1::getMatrix9(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[9]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix9Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[9] = val;
    }
}
QString MyObject1::getMatrix10(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[10]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix10Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[10] = val;
    }
}
QString MyObject1::getMatrix11(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSong.matrix[11]);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMatrix11Changed(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSong.matrix[11] = val;
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////
//   CONFIG SCREEN OBJECTS

void MyObject1::updateConfigDisplay(void)
{
    //aint Qt awesome!!
    emit ConfigChanged();     //temp?? Where should I put this round about way of updating data Qt?  This is the ONLY place it works, but NOT CORRECT??!!
}
void MyObject1::updateConfigDevice(void)
{
    myApp->UpdateConfigToDevice();
}

QString MyObject1::getBacklightMain(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSettings.lcdBacklight);
        str = QString(c);
    }
    return str;
}
void MyObject1::onMainBacklightChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSettings.lcdBacklight = val;
    }
}
QString MyObject1::getcurrentSong(void) const
{
    QString str = "";
    if(myApp)
    {
        char c[10];
        sprintf(c,"%d", myApp->ramSettings.currentSong);
        //sprintf(c,"%d", myApp->activeSong);
        //sprintf(c,"%d", myApp->getCurrentSong());
        str = QString(c);
    }
    return str;
}
void MyObject1::onCurrentSongChanged(QString str)
{
    if(myApp)
    {
        int val = str.toInt();
        myApp->ramSettings.currentSong = val;
    }
}
QString MyObject1::getLoopName1(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[0]));
    }
    return str;
}
void MyObject1::onLoopName1Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[0], buffer );
    }
}
QString MyObject1::getLoopName2(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[1]));
    }
    return str;
}
void MyObject1::onLoopName2Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[1], buffer );
    }
}
QString MyObject1::getLoopName3(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[2]));
    }
    return str;
}
void MyObject1::onLoopName3Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[2], buffer );
    }
}QString MyObject1::getLoopName4(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[3]));
    }
    return str;
}
void MyObject1::onLoopName4Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[3], buffer );
    }
}
QString MyObject1::getLoopName5(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[4]));
    }
    return str;
}
void MyObject1::onLoopName5Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[4], buffer );
    }
}
QString MyObject1::getLoopName6(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[5]));
    }
    return str;
}
void MyObject1::onLoopName6Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[5], buffer );
    }
}
QString MyObject1::getLoopName7(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.loopName[6]));
    }
    return str;
}
void MyObject1::onLoopName7Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.loopName[6], buffer );
    }
}
QString MyObject1::getFswName1(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[0]));
    }
    return str;
}
void MyObject1::onFswName1Changed(QString str)
{
    if(myApp)
    {
        //strcpy((char*)myApp->ramSettings.loopName[0], (char*)str.data() );
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[0], buffer );
    }
}
QString MyObject1::getFswName2(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[1]));
    }
    return str;
}
void MyObject1::onFswName2Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[1], buffer );
    }
}
QString MyObject1::getFswName3(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[2]));
    }
    return str;
}
void MyObject1::onFswName3Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[2], buffer );
    }
}
QString MyObject1::getFswName4(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[3]));
    }
    return str;
}
void MyObject1::onFswName4Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[3], buffer );
    }
}
QString MyObject1::getFswName5(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[4]));
    }
    return str;
}
void MyObject1::onFswName5Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[4], buffer );
    }
}
QString MyObject1::getFswName6(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.fswName[5]));
    }
    return str;
}
void MyObject1::onFswName6Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.fswName[5], buffer );
    }
}
QString MyObject1::getAuxName1(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[0]));
    }
    return str;
}
void MyObject1::onAuxName1Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.auxOutName[0], buffer );
    }
}
QString MyObject1::getAuxName2(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[1]));
    }
    return str;
}
void MyObject1::onAuxName2Changed(QString str)
{
    if(myApp)
    {
        //strcpy((char*)myApp->ramSettings.loopName[0], (char*)str.data() );
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.auxOutName[1], buffer );
    }
}
QString MyObject1::getAuxName3(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[2]));
    }
    return str;
}
void MyObject1::onAuxName3Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.auxOutName[2], buffer );
    }
}
QString MyObject1::getAuxName4(void) const
{
    QString str = "";
    if(myApp)
    {
        str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[3]));
    }
    return str;
}
void MyObject1::onAuxName4Changed(QString str)
{
    if(myApp)
    {
        QByteArray array = str.toLocal8Bit();
        char* buffer = array.data();
        buffer[str.length()] = 0;   //ensure it ends with NULL
        strcpy((char*)myApp->ramSettings.auxOutName[3], buffer );
    }
}

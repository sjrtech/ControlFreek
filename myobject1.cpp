#include "myobject1.h"
#include <QBluetoothAddress>
#include <QtQuick/QQuickView>


MyObject1::MyObject1(QObject *parent) : QObject(parent)
{
    myApp = new MyAppGui();

    //Initialize combo boxes
    m_comboListBacklight.clear();
    m_comboListBacklight.insert(0, "OFF");
    m_comboListBacklight.insert(1, "Red");
    m_comboListBacklight.insert(2, "Blue");
    m_comboListBacklight.insert(3, "Green");
    m_comboListBacklight.insert(4, "Red/Blue");     //purple
    m_comboListBacklight.insert(5, "Red/Green");    //Orange?
    m_comboListBacklight.insert(6, "Blue/Green");   //Yellow?
    m_comboListBacklight.insert(7, "White");

    m_comboListTrickMode1.clear();
    m_comboListTrickMode1.insert(0, "OFF");
    m_comboListTrickMode1.insert(1, "Momentary Footswitch");
    m_comboListTrickMode1.insert(2, "Latch Footswitch");
    m_comboListTrickMode1.insert(3, "Momentary Add Loop");
    m_comboListTrickMode1.insert(4, "Latch Add Loop");
    m_comboListTrickMode1.insert(5, "Momentary Jump to Song");
    m_comboListTrickMode1.insert(6, "Latch Jump to Song");

    m_comboListTrickMode2.clear();
    m_comboListTrickMode2.insert(0, "OFF");
    m_comboListTrickMode2.insert(1, "Momentary Footswitch");
    m_comboListTrickMode2.insert(2, "Latch Footswitch");
    m_comboListTrickMode2.insert(3, "Momentary Add Loop");
    m_comboListTrickMode2.insert(4, "Latch Add Loop");
    m_comboListTrickMode2.insert(5, "Momentary Jump to Song");
    m_comboListTrickMode2.insert(6, "Latch Jump to Song");


    // ////////////////////////////////////////////////////////
    //temp - load dummy config for testing
    loadDummyConfig();


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
    emit SongChanged();     //temp?? Where should I put this round about way of updating data?  This is the ONLY place it works, but NOT CORRECT??!!
}
void MyObject1::updateSongDevice(void)
{
    myApp->UpdateSongToDevice();
}
void MyObject1::selectNextSong(void)
{
    myApp->gotoNextSong();
    updateComboBoxes();
    emit comboListChanged();
    emit ConfigChanged();

}
void MyObject1::selectPreviousSong(void)
{
    myApp->gotoPreviousSong();
    updateComboBoxes();
    emit comboListChanged();
    emit ConfigChanged();
}


QString MyObject1::getSongName(void) const
{
    QString str = "Loading..";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSong.name));
        }
    }
    return str;
}
void MyObject1::onSongNameChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSong.name, buffer );
        }
    }
}

QString MyObject1::getPartName(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSong.partname));
        }
    }
    return str;
}
void MyObject1::onSongPartNameChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSong.partname, buffer );
        }
    }
}

QString MyObject1::getMidiMsg1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage1));
            str = temp.mid(0, SIZE_OF_MIDI_MSG);
        }
    }
    return str;
}
void MyObject1::onMidiMsg1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
            strcpy((char*)myApp->ramSong.midiMessage1, buffer );
        }
    }
}
/*
QString MyObject1::getMidiMsg2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage2));
            str = temp.mid(0, 2);
        }
    }
    return str;
}
void MyObject1::onMidiMsg2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
            strcpy((char*)myApp->ramSong.midiMessage2, buffer );
        }
    }
}
QString MyObject1::getMidiMsg3(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage3));
            str = temp.mid(0, 2);
        }
    }
    return str;

}
void MyObject1::onMidiMsg3Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
            strcpy((char*)myApp->ramSong.midiMessage3, buffer );
        }
    }
}
QString MyObject1::getMidiMsg4(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QString temp = QString(QByteArray((char*)myApp->ramSong.midiMessage4));
            str = temp.mid(0, 2);
        }
    }
    return str;
}
void MyObject1::onMidiMsg4Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[SIZE_OF_MIDI_MSG] = 0; //force to size of MIDI msg
            strcpy((char*)myApp->ramSong.midiMessage4, buffer );
        }
    }
}
*/
/*
QString MyObject1::getMidiMode(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.midiMsgMode);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMidiModeChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.midiMsgMode = val;
        }
    }
}
*/
QString MyObject1::getFswSongConfig(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.footswitch);
            str = QString(c);
        }
    }
    return str;
}

int MyObject1::isFswSongConfig1(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x01) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}
int MyObject1::isFswSongConfig2(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x02) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}
int MyObject1::isFswSongConfig3(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x04) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}
int MyObject1::isFswSongConfig4(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x08) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}
int MyObject1::isFswSongConfig5(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x10) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}
int MyObject1::isFswSongConfig6(void) const
{
    int n = 0;
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            if ( (myApp->ramSong.footswitch & 0x20) != 0)
            {
                n = 2;  //used as "state" to checkbox.. tells GUI to check that checkbox
            }
        }
    }
    return n;
}



void MyObject1::onSongFswChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.footswitch = val;
        }
    }
}
/*
QString MyObject1::getTrickMode(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.trickMode[0]);
            str = QString(c);
        }
    }
    return str;
}
*/
void MyObject1::onTrickMode1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.trickMode[0] = val;
        }
    }
}
void MyObject1::onTrickMode2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.trickMode[1] = val;
        }
    }
}
QString MyObject1::getTrickData1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.trickData[0]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onTrickData1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.trickData[0] = val;
        }
    }
}
QString MyObject1::getTrickData2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.trickData[1]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onTrickData2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.trickData[1] = val;
        }
    }
}
/*
QString MyObject1::getSongBacklight(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.lcdBacklight);
            str = QString(c);
        }
    }
    return str;
}
*/
void MyObject1::onSongBacklightChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.lcdBacklight = val;
        }
    }
}
QString MyObject1::getMatrix0(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[0]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix0Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[0] = val;
        }
    }

}
QString MyObject1::getMatrix1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[1]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[1] = val;
        }
    }

}
QString MyObject1::getMatrix2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[2]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[2] = val;
        }
    }

}
QString MyObject1::getMatrix3(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[3]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix3Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[3] = val;
        }
    }

}
QString MyObject1::getMatrix4(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[4]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix4Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[4] = val;
        }
    }

}
QString MyObject1::getMatrix5(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[5]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix5Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[5] = val;
        }
    }

}
QString MyObject1::getMatrix6(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[6]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix6Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[6] = val;
        }
    }

}
QString MyObject1::getMatrix7(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[7]);
            str = QString(c);
        }

    }
    return str;
}
void MyObject1::onMatrix7Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[7] = val;
        }
    }

}
QString MyObject1::getMatrix8(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[8]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix8Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[8] = val;
        }
    }

}
QString MyObject1::getMatrix9(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[9]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix9Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[9] = val;
        }
    }
}
QString MyObject1::getMatrix10(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[10]);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMatrix10Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[10] = val;
        }
    }
}
QString MyObject1::getMatrix11(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSong.matrix[11]);
            str = QString(c);
        }

    }
    return str;
}
void MyObject1::onMatrix11Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSong.matrix[11] = val;
        }
    }
}


// //////////////////////////////////////////////////////////////////////////////////////////////////
//   CONFIG SCREEN OBJECTS

void MyObject1::updateConfigDisplay(void)
{
    updateComboBoxes();
    emit comboListChanged();
    emit ConfigChanged();
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
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSettings.lcdBacklight);
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onMainBacklightChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSettings.lcdBacklight = val;
        }
    }
}
QString MyObject1::getcurrentSong(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            char c[10];
            sprintf(c,"%d", myApp->ramSettings.currentSong);
            //sprintf(c,"%d", myApp->activeSong);
            //sprintf(c,"%d", myApp->getCurrentSong());
            str = QString(c);
        }
    }
    return str;
}
void MyObject1::onCurrentSongChanged(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            int val = str.toInt();
            myApp->ramSettings.currentSong = val;
        }
    }
}
QString MyObject1::getLoopName1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[0]));
        }
    }
    return str;
}
void MyObject1::onLoopName1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[0], buffer );
        }
    }
}
QString MyObject1::getLoopName2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[1]));
        }
    }
    return str;
}
void MyObject1::onLoopName2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[1], buffer );
        }
    }
}
QString MyObject1::getLoopName3(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[2]));
        }
    }
    return str;
}
void MyObject1::onLoopName3Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[2], buffer );
        }
    }
}
QString MyObject1::getLoopName4(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[3]));
        }
    }
    return str;
}
void MyObject1::onLoopName4Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[3], buffer );
        }
    }
}
QString MyObject1::getLoopName5(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[4]));
        }
    }
    return str;
}
void MyObject1::onLoopName5Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[4], buffer );
        }
    }
}
QString MyObject1::getLoopName6(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[5]));
        }
    }
    return str;
}
void MyObject1::onLoopName6Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[5], buffer );
        }
    }
}
QString MyObject1::getLoopName7(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.loopName[6]));
        }
    }
    return str;
}
void MyObject1::onLoopName7Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.loopName[6], buffer );
        }
    }
}
QString MyObject1::getFswName1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[0]));
        }
    }
    return str;
}
void MyObject1::onFswName1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            //strcpy((char*)myApp->ramSettings.loopName[0], (char*)str.data() );
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[0], buffer );
        }
    }
}
QString MyObject1::getFswName2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[1]));
        }
    }
    return str;
}
void MyObject1::onFswName2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[1], buffer );
        }
    }
}
QString MyObject1::getFswName3(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[2]));
        }
    }
    return str;
}
void MyObject1::onFswName3Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[2], buffer );
        }
    }
}
QString MyObject1::getFswName4(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[3]));
        }
    }
    return str;
}
void MyObject1::onFswName4Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[3], buffer );
        }
    }
}
QString MyObject1::getFswName5(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[4]));
        }
    }
    return str;
}
void MyObject1::onFswName5Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[4], buffer );
        }
    }
}
QString MyObject1::getFswName6(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.fswName[5]));
        }
    }
    return str;
}
void MyObject1::onFswName6Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.fswName[5], buffer );
        }
    }
}
QString MyObject1::getAuxName1(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[0]));
        }
    }
    return str;
}
void MyObject1::onAuxName1Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
           strcpy((char*)myApp->ramSettings.auxOutName[0], buffer );
        }
    }
}
QString MyObject1::getAuxName2(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[1]));
        }
    }
    return str;
}
void MyObject1::onAuxName2Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            //strcpy((char*)myApp->ramSettings.loopName[0], (char*)str.data() );
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.auxOutName[1], buffer );
        }
    }
}
QString MyObject1::getAuxName3(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[2]));
        }
    }
    return str;
}
void MyObject1::onAuxName3Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.auxOutName[2], buffer );
        }
    }
}
QString MyObject1::getAuxName4(void) const
{
    QString str = "";
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            str = QString(QByteArray((char*)myApp->ramSettings.auxOutName[3]));
        }
    }
    return str;
}
void MyObject1::onAuxName4Changed(QString str)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            QByteArray array = str.toLocal8Bit();
            char* buffer = array.data();
            buffer[str.length()] = 0;   //ensure it ends with NULL
            strcpy((char*)myApp->ramSettings.auxOutName[3], buffer );
        }
    }
}


const QStringList MyObject1::comboList0()
{
    return m_comboList0;
}
const QStringList MyObject1::comboList1()
{
    return m_comboList1;
}
const QStringList MyObject1::comboList2()
{
    return m_comboList2;
}
const QStringList MyObject1::comboList3()
{
    return m_comboList3;
}
const QStringList MyObject1::comboList4()
{
    return m_comboList4;
}
const QStringList MyObject1::comboList5()
{
    return m_comboList5;
}
const QStringList MyObject1::comboList6()
{
    return m_comboList6;
}
const QStringList MyObject1::comboList7()
{
    return m_comboList7;
}
const QStringList MyObject1::comboList8()
{
    return m_comboList8;
}
const QStringList MyObject1::comboList9()
{
    return m_comboList9;
}
const QStringList MyObject1::comboList10()
{
    return m_comboList10;
}
const QStringList MyObject1::comboList11()
{
    return m_comboList11;
}


/*
const QStringList MyObject1::comboListMidiMode()
{
    return m_comboListMidiMode;
}
*/
const QStringList MyObject1::comboListBacklight()
{
    return m_comboListBacklight;
}
const QStringList MyObject1::comboListTrickMode1()
{
    return m_comboListTrickMode1;
}
const QStringList MyObject1::comboListTrickMode2()
{
    return m_comboListTrickMode2;
}

void MyObject1::updateComboBoxes(void)
{
    //update all the QStringLists with the correct values for each specific combobox:
    // - do not list a loop in itself, iow, Loop: BigMuff should not have BigMuff listed in its combobox
    // - only list values that exist - no black lines
    // - include a not-used option
    // TO DO:
    // - hide comboboxes (and "<--" text) when item name not defined
    // - set the combobox index to the setting stored for the current song


    //Update the string lists

    m_comboList0.clear();
    m_comboList0.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList0.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList0.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList0.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList0.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList0.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList0.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList0.insert(7, getLoopName7() );
    m_comboList0.insert(8, "not used");

    //do not include this number loop in the list
    m_comboList1.clear();
    m_comboList1.insert(0, "Main In" );
    if(getLoopName2().length() > 0) m_comboList1.insert(1, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList1.insert(2, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList1.insert(3, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList1.insert(4, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList1.insert(5, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList1.insert(6, getLoopName7() );
    m_comboList1.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList2.clear();
    m_comboList2.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList2.insert(1, getLoopName1() );
    if(getLoopName3().length() > 0) m_comboList2.insert(2, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList2.insert(3, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList2.insert(4, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList2.insert(5, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList2.insert(6, getLoopName7() );
    m_comboList2.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList3.clear();
    m_comboList3.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList3.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList3.insert(2, getLoopName2() );
    if(getLoopName4().length() > 0) m_comboList3.insert(3, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList3.insert(4, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList3.insert(5, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList3.insert(6, getLoopName7() );
    m_comboList3.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList4.clear();
    m_comboList4.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList4.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList4.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList4.insert(3, getLoopName3() );
    if(getLoopName5().length() > 0) m_comboList4.insert(4, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList4.insert(5, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList4.insert(6, getLoopName7() );
    m_comboList4.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList5.clear();
    m_comboList5.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList5.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList5.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList5.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList5.insert(4, getLoopName4() );
    if(getLoopName6().length() > 0) m_comboList5.insert(5, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList5.insert(6, getLoopName7() );
    m_comboList5.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList6.clear();
    m_comboList6.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList6.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList6.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList6.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList6.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList6.insert(5, getLoopName5() );
    if(getLoopName7().length() > 0) m_comboList6.insert(6, getLoopName7() );
    m_comboList6.insert(7, "not used" );

    //do not include this number loop in the list
    m_comboList7.clear();
    m_comboList7.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList7.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList7.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList7.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList7.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList7.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList7.insert(6, getLoopName6() );
    m_comboList7.insert(7, "not used" );

    //Aux out - can get anything (like Main)
    m_comboList8.clear();
    m_comboList8.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList8.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList8.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList8.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList8.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList8.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList8.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList8.insert(7, getLoopName7() );
    m_comboList8.insert(8, "not used" );

    //Aux out - can get anything (like Main)
    m_comboList9.clear();
    m_comboList9.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList9.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList9.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList9.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList9.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList9.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList9.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList9.insert(7, getLoopName7() );
    m_comboList9.insert(8, "not used" );

    //Aux out - can get anything (like Main)
    m_comboList10.clear();
    m_comboList10.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList10.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList10.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList10.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList10.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList10.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList10.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList10.insert(7, getLoopName7() );
    m_comboList10.insert(8, "not used" );

    //Aux out - can get anything (like Main)
    m_comboList11.clear();
    m_comboList11.insert(0, "Main In" );
    if(getLoopName1().length() > 0) m_comboList11.insert(1, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList11.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList11.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList11.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList11.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList11.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList11.insert(7, getLoopName7() );
    m_comboList11.insert(8, "not used" );


}

void MyObject1::fswOneCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x01;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}
void MyObject1::fswTwoCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x02;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}
void MyObject1::fswThreeCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x04;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}
void MyObject1::fswFourCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x08;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}
void MyObject1::fswFiveCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x10;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}
void MyObject1::fswSixCheckChanged(int checkedState)
{
    if(myApp)
    {
        if(myApp->isInitialized == 1)
        {
            // 0 = not check, 2 = checked
            int mask = 0x20;
            if(checkedState == 0)
            {
                //clear bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch & ~mask;
            }
            else
            {
                //set bit
                myApp->ramSong.footswitch = myApp->ramSong.footswitch | mask;
            }

        }
    }
}


void MyObject1::loadDummyConfig()
{
    myApp->ramSettings.isFilled = 0xa5;
    myApp->ramSettings.currentSong = 2;
    myApp->ramSettings.lcdBacklight = 4;

    myApp->ramSettings.auxBacklite[0] = 1;
    myApp->ramSettings.auxBacklite[1] = 1;
    myApp->ramSettings.auxBacklite[2] = 1;
    myApp->ramSettings.auxBacklite[3] = 1;
    sprintf((char*)myApp->ramSettings.auxOutName[0], "aux1");
    sprintf((char*)myApp->ramSettings.auxOutName[1], "aux2");
    sprintf((char*)myApp->ramSettings.auxOutName[2], "aux3");
    sprintf((char*)myApp->ramSettings.auxOutName[3], "aux4");

    myApp->ramSettings.fswBacklite[0] = 3;
    myApp->ramSettings.fswBacklite[1] = 3;
    myApp->ramSettings.fswBacklite[2] = 3;
    myApp->ramSettings.fswBacklite[3] = 3;
    myApp->ramSettings.fswBacklite[4] = 3;
    myApp->ramSettings.fswBacklite[5] = 3;
    sprintf((char*)myApp->ramSettings.fswName[0], "fsw1");
    sprintf((char*)myApp->ramSettings.fswName[1], "fsw2");
    sprintf((char*)myApp->ramSettings.fswName[2], "fsw3");
    sprintf((char*)myApp->ramSettings.fswName[3], "fsw4");
    sprintf((char*)myApp->ramSettings.fswName[4], "fsw5");
    sprintf((char*)myApp->ramSettings.fswName[5], "fsw6");

    myApp->ramSettings.loopBacklite[0] = 5;
    myApp->ramSettings.loopBacklite[1] = 5;
    myApp->ramSettings.loopBacklite[2] = 5;
    myApp->ramSettings.loopBacklite[3] = 5;
    myApp->ramSettings.loopBacklite[4] = 5;
    myApp->ramSettings.loopBacklite[5] = 5;
    myApp->ramSettings.loopBacklite[6] = 5;
    sprintf((char*)myApp->ramSettings.loopName[0], "loop1");
    sprintf((char*)myApp->ramSettings.loopName[1], "loop2");
    sprintf((char*)myApp->ramSettings.loopName[2], "loop3");
    sprintf((char*)myApp->ramSettings.loopName[3], "loop4");
    sprintf((char*)myApp->ramSettings.loopName[4], "loop5");
    sprintf((char*)myApp->ramSettings.loopName[5], "loop6");
    sprintf((char*)myApp->ramSettings.loopName[6], "loop7");

    // ////////////////////////////////////////////////////////////////////
    // song
    myApp->ramSong.isFilled = 0xa5;
    sprintf((char*)myApp->ramSong.name, "THIS SONG");
    sprintf((char*)myApp->ramSong.partname, "TESTER");
    myApp->ramSong.matrix[0] = 1;
    myApp->ramSong.matrix[1] = 2;
    myApp->ramSong.matrix[2] = 4;
    myApp->ramSong.matrix[3] = 8;
    myApp->ramSong.matrix[4] = 16;
    myApp->ramSong.matrix[5] = 32;
    myApp->ramSong.matrix[6] = 64;
    myApp->ramSong.matrix[7] = 128;
    myApp->ramSong.matrix[8] = 1;
    myApp->ramSong.matrix[9] = 0;
    myApp->ramSong.matrix[10] = 0;
    myApp->ramSong.matrix[11] = 16;
    myApp->ramSong.footswitch = 1;
    sprintf((char*)myApp->ramSong.midiMessage1, "Midi1");
    myApp->ramSong.midiMsgMode = 1;
    myApp->ramSong.lcdBacklight = 2;
    myApp->ramSong.trickMode[0] = 1;
    myApp->ramSong.trickData[0] = 1;
    myApp->ramSong.trickMode[1] = 2;
    myApp->ramSong.trickData[1] = 2;


    updateComboBoxes();
    emit comboListChanged();


}


/*
int MyObject1::count()
{
    return m_count;
}


void MyObject1::setCount(int cnt)
{
    if (cnt != m_count)
    {
        m_count = cnt;
        emit countChanged();
    }
}

void MyObject1::addElement(const QString &element)
{
    m_comboList.append(element);
    emit comboListChanged();
    setCount(m_comboList.count());
    emit countChanged();

    for (int i = 0; i<m_count; i++)
    {
        qDebug() << m_comboList.at(i);
    }
}

void MyObject1::removeElement(int index)
{
    if (index < m_comboList.count())
    {
        m_comboList.removeAt(index);
        emit comboListChanged();
        setCount(m_comboList.count());
        emit countChanged();
    }

    for (int i = 0; i<m_count; i++)
    {
        qDebug() << m_comboList.at(i);
    }
}
*/

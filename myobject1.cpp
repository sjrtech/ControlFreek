#include "myobject1.h"
#include <QBluetoothAddress>
#include <QtQuick/QQuickView>
#include <QDir>

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
    m_comboListTrickMode1.insert(1, "Latch new Song");
    m_comboListTrickMode1.insert(2, "Momentary new Song");
    m_comboListTrickMode1.insert(3, "Latch Add Loop");
    m_comboListTrickMode1.insert(4, "Momentary Add Loop");
    m_comboListTrickMode1.insert(5, "Latch Footswitch");
    m_comboListTrickMode1.insert(6, "Momentary Footswitch");
    m_comboListTrickMode1.insert(7, "Send MIDI Msg");

    m_comboListTrickMode2.clear();
    m_comboListTrickMode2.insert(0, "OFF");
    m_comboListTrickMode2.insert(1, "Latch new Song");
    m_comboListTrickMode2.insert(2, "Momentary new Song");
    m_comboListTrickMode2.insert(3, "Latch Add Loop");
    m_comboListTrickMode2.insert(4, "Momentary Add Loop");
    m_comboListTrickMode2.insert(5, "Latch Footswitch");
    m_comboListTrickMode2.insert(6, "Momentary Footswitch");
    m_comboListTrickMode2.insert(7, "Send MIDI Msg");



    // ////////////////////////////////////////////////////////
    //temp - load dummy config for testing
    //loadDummyConfig();


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

    connect(this, SIGNAL(recdBLEdata(QByteArray)), myApp, SLOT(parseInData(QByteArray)) );
    connect(myApp, SIGNAL(writeBLEdata(QByteArray)), this, SLOT(writeData(QByteArray)) );
    connect(myApp, SIGNAL(SongComplete()), this, SLOT(updateSongDisplay()) );
    connect(myApp, SIGNAL(ConfigComplete()), this, SLOT(updateConfigDisplay()) );

    //Start timer to read serial data from motor
    m_timerBLE = new QTimer(this);
    connect(m_timerBLE, SIGNAL(timeout()), this, SLOT(readBLE()));
    //m_timerBLE->start(50); //mSec

    //myApp->sendStatus();
    myApp->sendRequestForConfigBlock();

}

void MyObject1::readBLE(void)
{
    service->readCharacteristic(bleIncludedChars.value(0));

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
    emit SongChanged();
    updateComboBoxes();
    emit comboListChanged();
}
void MyObject1::updateSongDevice(void)
{
    myApp->UpdateSongToDevice();
    updateComboBoxes();
    emit comboListChanged();

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
void MyObject1::saveSong(void)
{
/*
typedef struct
{
    unsigned char isFilled;                         // this song has been programmed, or is empty=0xff (default flash erase value)
    unsigned char name[32];                         //name the song... slow select?
    unsigned char partname[32];                     // part (solo, bridge chorus, verse, etc.) of the song.... rapid select
    unsigned char midiMessage1[SIZE_OF_MIDI_MSG];   //MIDI messages, Chan & Program .. for "program change" messages to MIDI pedals, etc.
    //unsigned char midiMessage2[SIZE_OF_MIDI_MSG];   //MIDI messages, Chan & Program .. for "program change" messages to MIDI pedals, etc.
    //unsigned char midiMessage3[SIZE_OF_MIDI_MSG];   //MIDI messages, Chan & Program .. for "program change" messages to MIDI pedals, etc.
    //unsigned char midiMessage4[SIZE_OF_MIDI_MSG];   //MIDI messages, Chan & Program .. for "program change" messages to MIDI pedals, etc.
    unsigned char midiMsgMode;                      //describe when to send msg, at song load? on trick button press? probably only those two?
    unsigned char matrix[12];                       //twelve bytes to setup up the Matrix
    unsigned char footswitch;                       //state of 6 footswitches
    unsigned char trickMode[3];                     //Solo/Boost/Trick button - what is doing?
    unsigned char trickData[3];                     //Solo/Boost/Trick button - any data that needs to be stored (song, loop, fsw, etc.)
    unsigned char lcdBacklight;                     //4-5 bits of RGB backlight control (different color for each song) - solo mode??pulse color? throbber?
    unsigned char Dummy[2];                         //add bytes to ensure Size is divisable by 4. 99/4=24.75 so add 1
} SONG;
*/

    //QString filename = "data.txt";//(QString)myApp->ramSong.name;// + myApp->ramSong.partname + ".txt";
    QString str1= (const char*)myApp->ramSong.name;
    QString str2= (const char*)myApp->ramSong.partname;
    QString filename= str1 + "_" + str2 + ".dat";

    QFile file(filename);
    if (file.open(QIODevice::ReadWrite))
    {
        QDataStream stream(&file);
        unsigned int i;
        stream << myApp->ramSong.isFilled;
        for(i=0; i<sizeof(myApp->ramSong.name);i++)
        {
            stream << myApp->ramSong.name[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.partname);i++)
        {
            stream << myApp->ramSong.partname[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.midiMessage1);i++)
        {
            stream << myApp->ramSong.midiMessage1[i];
        }
        stream << myApp->ramSong.midiMsgMode;
        for(i=0; i<sizeof(myApp->ramSong.matrix);i++)
        {
            stream << myApp->ramSong.matrix[i];
        }
        stream << myApp->ramSong.footswitch;
        for(i=0; i<sizeof(myApp->ramSong.trickMode);i++)
        {
            stream << myApp->ramSong.trickMode[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.trickData);i++)
        {
            stream << myApp->ramSong.trickData[i];
        }
        stream << myApp->ramSong.lcdBacklight;
        for(i=0; i<sizeof(myApp->ramSong.Dummy);i++)
        {
            stream << myApp->ramSong.Dummy[i];
        }
    }

}
void MyObject1::restoreSong(QString filename)
{
    QFile file;//(filename);
    QString path = filename.right( filename.length() - 7 );   //remove "file://"
    int last = path.lastIndexOf('/', -1, Qt::CaseInsensitive);
    QString dir = path.left( path.length() - (path.length() - last) );
    QDir::setCurrent(dir);
    QString fileName = path.right(path.length() - last - 1);
    file.setFileName(fileName);
    file.setTextModeEnabled(true);
    if (file.open(QIODevice::ReadWrite))
    {
        QDataStream stream(&file);
        unsigned int i;
        stream >> myApp->ramSong.isFilled;
        for(i=0; i<sizeof(myApp->ramSong.name);i++)
        {
            stream >> myApp->ramSong.name[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.partname);i++)
        {
            stream >> myApp->ramSong.partname[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.midiMessage1);i++)
        {
            stream >> myApp->ramSong.midiMessage1[i];
        }
        stream >> myApp->ramSong.midiMsgMode;
        for(i=0; i<sizeof(myApp->ramSong.matrix);i++)
        {
            stream >> myApp->ramSong.matrix[i];
        }
        stream >> myApp->ramSong.footswitch;
        for(i=0; i<sizeof(myApp->ramSong.trickMode);i++)
        {
            stream >> myApp->ramSong.trickMode[i];
        }
        for(i=0; i<sizeof(myApp->ramSong.trickData);i++)
        {
            stream >> myApp->ramSong.trickData[i];
        }
        stream >> myApp->ramSong.lcdBacklight;
        for(i=0; i<sizeof(myApp->ramSong.Dummy);i++)
        {
            stream >> myApp->ramSong.Dummy[i];
        }
    }

    updateSongDisplay();

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
            //To DO: compare text?  send the combo index instead of text?
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
            //int val = str.toInt();
            /*
            #define BACKLIGHT_RED                       48
            #define BACKLIGHT_BLUE                      03
            #define BACKLIGHT_GREEN                     12
            #define BACKLIGHT_REDBLUE                   51
            #define BACKLIGHT_REDGREEN                  60
            #define BACKLIGHT_BLUEGREEN                 15
            #define BACKLIGHT_WHITE                     0x3f

            m_comboListBacklight.clear();
            m_comboListBacklight.insert(0, "OFF");
            m_comboListBacklight.insert(1, "Red");
            m_comboListBacklight.insert(2, "Blue");
            m_comboListBacklight.insert(3, "Green");
            m_comboListBacklight.insert(4, "Red/Blue");     //purple
            m_comboListBacklight.insert(5, "Red/Green");    //Orange?
            m_comboListBacklight.insert(6, "Blue/Green");   //Yellow?
            m_comboListBacklight.insert(7, "White");
            */
            int val = BACKLIGHT_RED;
            if(str == "Red") val = BACKLIGHT_RED;
            else if(str == "Blue") val = BACKLIGHT_BLUE;
            else if(str == "Green") val = BACKLIGHT_GREEN;
            else if(str == "Red/Blue") val = BACKLIGHT_REDBLUE;
            else if(str == "Red/Green") val = BACKLIGHT_REDGREEN;
            else if(str == "Blue/Green") val = BACKLIGHT_BLUEGREEN;
            else if(str == "White") val = BACKLIGHT_WHITE;
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
            if(val == 0) myApp->ramSong.matrix[0] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[0] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[0] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[0] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[0] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[0] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[0] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[0] = 0x40;
            else if(val == 8) myApp->ramSong.matrix[0] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[1] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[1] = 0x01;
            //else if(val == 2) myApp->ramSong.matrix[1] = 0x02;
            else if(val == 2) myApp->ramSong.matrix[1] = 0x04;
            else if(val == 3) myApp->ramSong.matrix[1] = 0x08;
            else if(val == 4) myApp->ramSong.matrix[1] = 0x10;
            else if(val == 5) myApp->ramSong.matrix[1] = 0x20;
            else if(val == 6) myApp->ramSong.matrix[1] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[1] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[2] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[2] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[2] = 0x02;
            //else if(val == 3) myApp->ramSong.matrix[2] = 0x04;
            else if(val == 3) myApp->ramSong.matrix[2] = 0x08;
            else if(val == 4) myApp->ramSong.matrix[2] = 0x10;
            else if(val == 5) myApp->ramSong.matrix[2] = 0x20;
            else if(val == 6) myApp->ramSong.matrix[2] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[2] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[3] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[3] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[3] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[3] = 0x04;
            //else if(val == 4) myApp->ramSong.matrix[3] = 0x08;
            else if(val == 4) myApp->ramSong.matrix[3] = 0x10;
            else if(val == 5) myApp->ramSong.matrix[3] = 0x20;
            else if(val == 6) myApp->ramSong.matrix[3] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[3] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[4] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[4] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[4] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[4] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[4] = 0x08;
            //else if(val == 5) myApp->ramSong.matrix[4] = 0x10;
            else if(val == 5) myApp->ramSong.matrix[4] = 0x20;
            else if(val == 6) myApp->ramSong.matrix[4] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[4] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[5] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[5] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[5] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[5] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[5] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[5] = 0x10;
            //else if(val == 6) myApp->ramSong.matrix[5] = 0x20;
            else if(val == 6) myApp->ramSong.matrix[5] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[5] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[6] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[6] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[6] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[6] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[6] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[6] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[6] = 0x20;
            //else if(val == 7) myApp->ramSong.matrix[6] = 0x40;
            else if(val == 7) myApp->ramSong.matrix[6] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[7] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[7] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[7] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[7] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[7] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[7] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[7] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[7] = 0x40;
            //else if(val == 8) myApp->ramSong.matrix[7] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[8] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[8] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[8] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[8] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[8] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[8] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[8] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[8] = 0x40;
            else if(val == 8) myApp->ramSong.matrix[8] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[9] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[9] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[9] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[9] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[9] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[9] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[9] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[9] = 0x40;
            else if(val == 8) myApp->ramSong.matrix[9] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[10] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[10] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[10] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[10] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[10] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[10] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[10] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[10] = 0x40;
            else if(val == 8) myApp->ramSong.matrix[10] = 0x80;
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
            if(val == 0) myApp->ramSong.matrix[11] = 0x00;
            else if(val == 1) myApp->ramSong.matrix[11] = 0x01;
            else if(val == 2) myApp->ramSong.matrix[11] = 0x02;
            else if(val == 3) myApp->ramSong.matrix[11] = 0x04;
            else if(val == 4) myApp->ramSong.matrix[11] = 0x08;
            else if(val == 5) myApp->ramSong.matrix[11] = 0x10;
            else if(val == 6) myApp->ramSong.matrix[11] = 0x20;
            else if(val == 7) myApp->ramSong.matrix[11] = 0x40;
            else if(val == 8) myApp->ramSong.matrix[11] = 0x80;
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
    updateComboBoxes();
    emit comboListChanged();
    //emit ConfigChanged();
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
    // - hide comboboxes (and "<--" text) when item name not defined (in .qml logic)


    //TEmp - move this or rename this function to SetSongScreenControls() or something
    fswSong1CheckedState = 0;
    fswSong2CheckedState = 0;
    fswSong3CheckedState = 0;
    fswSong4CheckedState = 0;
    fswSong5CheckedState = 0;
    fswSong6CheckedState = 0;
    if ( (myApp->ramSong.footswitch & 0x01) != 0) fswSong1CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox
    if ( (myApp->ramSong.footswitch & 0x02) != 0) fswSong2CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox
    if ( (myApp->ramSong.footswitch & 0x04) != 0) fswSong3CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox
    if ( (myApp->ramSong.footswitch & 0x08) != 0) fswSong4CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox
    if ( (myApp->ramSong.footswitch & 0x10) != 0) fswSong5CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox
    if ( (myApp->ramSong.footswitch & 0x20) != 0) fswSong6CheckedState = 2;  //"2" used as "state" to checkbox.. tells GUI to check that checkbox

    //Set the combobox index to the setting stored for the current song
    //EACH one is different so just write out the code longhand so it's clear!!
    if(myApp->ramSong.matrix[0] == 0) Combo0_index = 0;
    else if(myApp->ramSong.matrix[0] == 1) Combo0_index = 1;
    else if(myApp->ramSong.matrix[0] == 2) Combo0_index = 2;
    else if(myApp->ramSong.matrix[0] == 4) Combo0_index = 3;
    else if(myApp->ramSong.matrix[0] == 8) Combo0_index = 4;
    else if(myApp->ramSong.matrix[0] == 16) Combo0_index = 5;
    else if(myApp->ramSong.matrix[0] == 32) Combo0_index = 6;
    else if(myApp->ramSong.matrix[0] == 64) Combo0_index = 7;
    else if(myApp->ramSong.matrix[0] == 128) Combo0_index = 8;

    //Skip 0x02
    if(myApp->ramSong.matrix[1] == 0) Combo1_index = 0;
    else if(myApp->ramSong.matrix[1] == 1) Combo1_index = 1;
    else if(myApp->ramSong.matrix[1] == 4) Combo1_index = 2;
    else if(myApp->ramSong.matrix[1] == 8) Combo1_index = 3;
    else if(myApp->ramSong.matrix[1] == 16) Combo1_index = 4;
    else if(myApp->ramSong.matrix[1] == 32) Combo1_index = 5;
    else if(myApp->ramSong.matrix[1] == 64) Combo1_index = 6;
    else if(myApp->ramSong.matrix[1] == 128) Combo1_index = 7;

    //skip 0x04
    if(myApp->ramSong.matrix[2] == 0) Combo2_index = 0;
    else if(myApp->ramSong.matrix[2] == 1) Combo2_index = 1;
    else if(myApp->ramSong.matrix[2] == 2) Combo2_index = 2;
    else if(myApp->ramSong.matrix[2] == 8) Combo2_index = 3;
    else if(myApp->ramSong.matrix[2] == 16) Combo2_index = 4;
    else if(myApp->ramSong.matrix[2] == 32) Combo2_index = 5;
    else if(myApp->ramSong.matrix[2] == 64) Combo2_index = 6;
    else if(myApp->ramSong.matrix[2] == 128) Combo2_index = 7;

    //skip 0x08
    if(myApp->ramSong.matrix[3] == 0) Combo3_index = 0;
    else if(myApp->ramSong.matrix[3] == 1) Combo3_index = 1;
    else if(myApp->ramSong.matrix[3] == 2) Combo3_index = 2;
    else if(myApp->ramSong.matrix[3] == 4) Combo3_index = 3;
    else if(myApp->ramSong.matrix[3] == 16) Combo3_index = 4;
    else if(myApp->ramSong.matrix[3] == 32) Combo3_index = 5;
    else if(myApp->ramSong.matrix[3] == 64) Combo3_index = 6;
    else if(myApp->ramSong.matrix[3] == 128) Combo3_index = 7;

    //skip 0x10
    if(myApp->ramSong.matrix[4] == 0) Combo4_index = 0;
    else if(myApp->ramSong.matrix[4] == 1) Combo4_index = 1;
    else if(myApp->ramSong.matrix[4] == 2) Combo4_index = 2;
    else if(myApp->ramSong.matrix[4] == 4) Combo4_index = 3;
    else if(myApp->ramSong.matrix[4] == 8) Combo4_index = 4;
    else if(myApp->ramSong.matrix[4] == 32) Combo4_index = 5;
    else if(myApp->ramSong.matrix[4] == 64) Combo4_index = 6;
    else if(myApp->ramSong.matrix[4] == 128) Combo4_index = 7;

    //skip 0x20
    if(myApp->ramSong.matrix[5] == 0) Combo5_index = 0;
    else if(myApp->ramSong.matrix[5] == 1) Combo5_index = 1;
    else if(myApp->ramSong.matrix[5] == 2) Combo5_index = 2;
    else if(myApp->ramSong.matrix[5] == 4) Combo5_index = 3;
    else if(myApp->ramSong.matrix[5] == 8) Combo5_index = 4;
    else if(myApp->ramSong.matrix[5] == 16) Combo5_index = 5;
    else if(myApp->ramSong.matrix[5] == 64) Combo5_index = 6;
    else if(myApp->ramSong.matrix[5] == 128) Combo5_index = 7;

    //skip 0x40
    if(myApp->ramSong.matrix[6] == 0) Combo6_index = 0;
    else if(myApp->ramSong.matrix[6] == 1) Combo6_index = 1;
    else if(myApp->ramSong.matrix[6] == 2) Combo6_index = 2;
    else if(myApp->ramSong.matrix[6] == 4) Combo6_index = 3;
    else if(myApp->ramSong.matrix[6] == 8) Combo6_index = 4;
    else if(myApp->ramSong.matrix[6] == 16) Combo6_index = 5;
    else if(myApp->ramSong.matrix[6] == 32) Combo6_index = 6;
    else if(myApp->ramSong.matrix[6] == 128) Combo6_index = 7;

    //skip 0x80
    if(myApp->ramSong.matrix[7] == 0) Combo7_index = 0;
    else if(myApp->ramSong.matrix[7] == 1) Combo7_index = 1;
    else if(myApp->ramSong.matrix[7] == 2) Combo7_index = 2;
    else if(myApp->ramSong.matrix[7] == 4) Combo7_index = 3;
    else if(myApp->ramSong.matrix[7] == 8) Combo7_index = 4;
    else if(myApp->ramSong.matrix[7] == 16) Combo7_index = 5;
    else if(myApp->ramSong.matrix[7] == 32) Combo7_index = 6;
    else if(myApp->ramSong.matrix[7] == 64) Combo7_index = 7;

    if(myApp->ramSong.matrix[8] == 0) Combo8_index = 0;
    else if(myApp->ramSong.matrix[8] == 1) Combo8_index = 1;
    else if(myApp->ramSong.matrix[8] == 2) Combo8_index = 2;
    else if(myApp->ramSong.matrix[8] == 4) Combo8_index = 3;
    else if(myApp->ramSong.matrix[8] == 8) Combo8_index = 4;
    else if(myApp->ramSong.matrix[8] == 16) Combo8_index = 5;
    else if(myApp->ramSong.matrix[8] == 32) Combo8_index = 6;
    else if(myApp->ramSong.matrix[8] == 64) Combo8_index = 7;
    else if(myApp->ramSong.matrix[8] == 128) Combo8_index = 8;
    if(myApp->ramSong.matrix[9] == 0) Combo9_index = 0;
    else if(myApp->ramSong.matrix[9] == 1) Combo9_index = 1;
    else if(myApp->ramSong.matrix[9] == 2) Combo9_index = 2;
    else if(myApp->ramSong.matrix[9] == 4) Combo9_index = 3;
    else if(myApp->ramSong.matrix[9] == 8) Combo9_index = 4;
    else if(myApp->ramSong.matrix[9] == 16) Combo9_index = 5;
    else if(myApp->ramSong.matrix[9] == 32) Combo9_index = 6;
    else if(myApp->ramSong.matrix[9] == 64) Combo9_index = 7;
    else if(myApp->ramSong.matrix[9] == 128) Combo9_index = 8;
    if(myApp->ramSong.matrix[10] == 0) Combo10_index = 0;
    else if(myApp->ramSong.matrix[10] == 1) Combo10_index = 1;
    else if(myApp->ramSong.matrix[10] == 2) Combo10_index = 2;
    else if(myApp->ramSong.matrix[10] == 4) Combo10_index = 3;
    else if(myApp->ramSong.matrix[10] == 8) Combo10_index = 4;
    else if(myApp->ramSong.matrix[10] == 16) Combo10_index = 5;
    else if(myApp->ramSong.matrix[10] == 32) Combo10_index = 6;
    else if(myApp->ramSong.matrix[10] == 64) Combo10_index = 7;
    else if(myApp->ramSong.matrix[10] == 128) Combo10_index = 8;
    if(myApp->ramSong.matrix[11] == 0) Combo11_index = 0;
    else if(myApp->ramSong.matrix[11] == 1) Combo11_index = 1;
    else if(myApp->ramSong.matrix[11] == 2) Combo11_index = 2;
    else if(myApp->ramSong.matrix[11] == 4) Combo11_index = 3;
    else if(myApp->ramSong.matrix[11] == 8) Combo11_index = 4;
    else if(myApp->ramSong.matrix[11] == 16) Combo11_index = 5;
    else if(myApp->ramSong.matrix[11] == 32) Combo11_index = 6;
    else if(myApp->ramSong.matrix[11] == 64) Combo11_index = 7;
    else if(myApp->ramSong.matrix[11] == 128) Combo11_index = 8;

    //Backlight
    if(myApp->ramSong.lcdBacklight == 0) ComboBacklight_index = 0;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_RED) ComboBacklight_index = 1;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_BLUE) ComboBacklight_index = 2;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_GREEN) ComboBacklight_index = 3;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_REDBLUE) ComboBacklight_index = 4;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_REDGREEN) ComboBacklight_index = 5;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_BLUEGREEN) ComboBacklight_index = 6;
    else if(myApp->ramSong.lcdBacklight == BACKLIGHT_WHITE) ComboBacklight_index = 7;
    else ComboBacklight_index = 0;    //on error -OFF

    // Trick shot 1
    if(myApp->ramSong.trickMode[0] == TRICK_MODE_NONE) ComboTrickMode1_index = 0;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_SONG) ComboTrickMode1_index = 1;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_SONG_MOMENT) ComboTrickMode1_index = 2;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_LOOP_LATCH) ComboTrickMode1_index = 3;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_LOOP_MOMENT) ComboTrickMode1_index = 4;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_FSW_LATCH) ComboTrickMode1_index = 5;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_FSW_MOMENT) ComboTrickMode1_index = 6;
    else if(myApp->ramSong.trickMode[0] == TRICK_MODE_MIDI_MSG) ComboTrickMode1_index = 7;
    else ComboTrickMode1_index = 0;    //on error -OFF

    // Trick shot 2 (Dive bomb)
    if(myApp->ramSong.trickMode[1] == TRICK_MODE_NONE) ComboTrickMode2_index = 0;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_SONG) ComboTrickMode2_index = 1;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_SONG_MOMENT) ComboTrickMode2_index = 2;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_LOOP_LATCH) ComboTrickMode2_index = 3;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_LOOP_MOMENT) ComboTrickMode2_index = 4;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_FSW_LATCH) ComboTrickMode2_index = 5;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_FSW_MOMENT) ComboTrickMode2_index = 6;
    else if(myApp->ramSong.trickMode[1] == TRICK_MODE_MIDI_MSG) ComboTrickMode2_index = 7;
    else ComboTrickMode2_index = 0;    //on error -OFF

    //Update the string lists
    m_comboList0.clear();
    m_comboList0.insert(0, STRING_NOT_USED);
    m_comboList0.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList0.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList0.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList0.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList0.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList0.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList0.insert(7, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList0.insert(8, getLoopName7() );

    //do not include this number loop in the list
    m_comboList1.clear();
    m_comboList1.insert(0, STRING_NOT_USED);
    m_comboList1.insert(1, STRING_MAIN_IN);
    if(getLoopName2().length() > 0) m_comboList1.insert(2, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList1.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList1.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList1.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList1.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList1.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList2.clear();
    m_comboList2.insert(0, STRING_NOT_USED);
    m_comboList2.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList2.insert(2, getLoopName1() );
    if(getLoopName3().length() > 0) m_comboList2.insert(3, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList2.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList2.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList2.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList2.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList3.clear();
    m_comboList3.insert(0, STRING_NOT_USED);
    m_comboList3.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList3.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList3.insert(3, getLoopName2() );
    if(getLoopName4().length() > 0) m_comboList3.insert(4, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList3.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList3.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList3.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList4.clear();
    m_comboList4.insert(0, STRING_NOT_USED);
    m_comboList4.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList4.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList4.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList4.insert(4, getLoopName3() );
    if(getLoopName5().length() > 0) m_comboList4.insert(5, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList4.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList4.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList5.clear();
    m_comboList5.insert(0, STRING_NOT_USED);
    m_comboList5.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList5.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList5.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList5.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList5.insert(5, getLoopName4() );
    if(getLoopName6().length() > 0) m_comboList5.insert(6, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList5.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList6.clear();
    m_comboList6.insert(0, STRING_NOT_USED);
    m_comboList6.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList6.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList6.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList6.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList6.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList6.insert(6, getLoopName5() );
    if(getLoopName7().length() > 0) m_comboList6.insert(7, getLoopName7() );

    //do not include this number loop in the list
    m_comboList7.clear();
    m_comboList7.insert(0, STRING_NOT_USED);
    m_comboList7.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList7.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList7.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList7.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList7.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList7.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList7.insert(7, getLoopName6() );

    //Aux out - can get anything (like Main)
    m_comboList8.clear();
    m_comboList8.insert(0, STRING_NOT_USED);
    m_comboList8.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList8.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList8.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList8.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList8.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList8.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList8.insert(7, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList8.insert(8, getLoopName7() );

    //Aux out - can get anything (like Main)
    m_comboList9.clear();
    m_comboList9.insert(0, STRING_NOT_USED);
    m_comboList9.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList9.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList9.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList9.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList9.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList9.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList9.insert(7, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList9.insert(8, getLoopName7() );

    //Aux out - can get anything (like Main)
    m_comboList10.clear();
    m_comboList10.insert(0, STRING_NOT_USED);
    m_comboList10.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList10.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList10.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList10.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList10.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList10.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList10.insert(7, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList10.insert(8, getLoopName7() );

    //Aux out - can get anything (like Main)
    m_comboList11.clear();
    m_comboList11.insert(0, STRING_NOT_USED);
    m_comboList11.insert(1, STRING_MAIN_IN);
    if(getLoopName1().length() > 0) m_comboList11.insert(2, getLoopName1() );
    if(getLoopName2().length() > 0) m_comboList11.insert(3, getLoopName2() );
    if(getLoopName3().length() > 0) m_comboList11.insert(4, getLoopName3() );
    if(getLoopName4().length() > 0) m_comboList11.insert(5, getLoopName4() );
    if(getLoopName5().length() > 0) m_comboList11.insert(6, getLoopName5() );
    if(getLoopName6().length() > 0) m_comboList11.insert(7, getLoopName6() );
    if(getLoopName7().length() > 0) m_comboList11.insert(8, getLoopName7() );



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
    sprintf((char*)myApp->ramSettings.auxOutName[0], "Polytune");
    //sprintf((char*)myApp->ramSettings.auxOutName[1], "");
    //sprintf((char*)myApp->ramSettings.auxOutName[2], "");
    //sprintf((char*)myApp->ramSettings.auxOutName[3], "");

    myApp->ramSettings.fswBacklite[0] = 3;
    myApp->ramSettings.fswBacklite[1] = 3;
    myApp->ramSettings.fswBacklite[2] = 3;
    myApp->ramSettings.fswBacklite[3] = 3;
    myApp->ramSettings.fswBacklite[4] = 3;
    myApp->ramSettings.fswBacklite[5] = 3;
    sprintf((char*)myApp->ramSettings.fswName[0], "Bypass Delay");
    sprintf((char*)myApp->ramSettings.fswName[1], "Harmonist");
    sprintf((char*)myApp->ramSettings.fswName[2], "Looper");
    //sprintf((char*)myApp->ramSettings.fswName[3], "");
    //sprintf((char*)myApp->ramSettings.fswName[4], "");
    //sprintf((char*)myApp->ramSettings.fswName[5], "");

    myApp->ramSettings.loopBacklite[0] = 5;
    myApp->ramSettings.loopBacklite[1] = 5;
    myApp->ramSettings.loopBacklite[2] = 5;
    myApp->ramSettings.loopBacklite[3] = 5;
    myApp->ramSettings.loopBacklite[4] = 5;
    myApp->ramSettings.loopBacklite[5] = 5;
    myApp->ramSettings.loopBacklite[6] = 5;
    sprintf((char*)myApp->ramSettings.loopName[0], "Big Muff");
    sprintf((char*)myApp->ramSettings.loopName[1], "Distortion");
    sprintf((char*)myApp->ramSettings.loopName[2], "MXR EQ");
    sprintf((char*)myApp->ramSettings.loopName[3], "M5 Modeler");
    sprintf((char*)myApp->ramSettings.loopName[4], "Harmonist");
    sprintf((char*)myApp->ramSettings.loopName[5], "Tremolo");
    //sprintf((char*)myApp->ramSettings.loopName[6], "");

    // ////////////////////////////////////////////////////////////////////
    // song
    myApp->ramSong.isFilled = 0xa5;
    sprintf((char*)myApp->ramSong.name, "THIS SONG");
    sprintf((char*)myApp->ramSong.partname, "TESTER");
    myApp->ramSong.matrix[0] = 64;
    myApp->ramSong.matrix[1] = 1;
    myApp->ramSong.matrix[2] = 0;
    myApp->ramSong.matrix[3] = 0;
    myApp->ramSong.matrix[4] = 0;
    myApp->ramSong.matrix[5] = 0;
    myApp->ramSong.matrix[6] = 2;
    myApp->ramSong.matrix[7] = 0;
    myApp->ramSong.matrix[8] = 1;
    myApp->ramSong.matrix[9] = 0;
    myApp->ramSong.matrix[10] = 0;
    myApp->ramSong.matrix[11] = 0;
    myApp->ramSong.footswitch = 3;
    sprintf((char*)myApp->ramSong.midiMessage1, "Midi1");
    myApp->ramSong.midiMsgMode = 1;
    myApp->ramSong.lcdBacklight = BACKLIGHT_REDBLUE;
    myApp->ramSong.trickMode[0] = 1;
    myApp->ramSong.trickData[0] = 6;
    myApp->ramSong.trickMode[1] = 1;
    myApp->ramSong.trickData[1] = 5;


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

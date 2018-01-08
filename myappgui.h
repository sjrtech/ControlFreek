#ifndef MYAPPGUI_H
#define MYAPPGUI_H

#include <QQuickItem>
//#include "myobject1.h"




#define SIZE_OF_MIDI_MSG        12


//create a main/global settings structure (to make it easier to read/write system settings from flash)
typedef struct
{
    unsigned char isFilled;                         // this struct has been programmed, or is empty=0xff (default flash erase value)
    unsigned char lcdBacklight;                     //4-5 bits of RGB backlight control For Main Menus, etc.  User configurable!!
    unsigned char currentSong;                      // save the last song selected
    unsigned char loopName[7][12];                  //name for each pedal (or whatever) connected to a loop
    unsigned char loopBacklite[7];                  //Color LED for each pedal (or whatever) connected to a loop
    unsigned char fswName[6][12];                   //name for each footswitch
    unsigned char fswBacklite[6];                   //Color LED for each footswitch
    unsigned char auxOutName[4][12];                //name for each aux output
    unsigned char auxBacklite[4];                   //Color LED for each aux output
} SETTINGS;
#define SIZE_OF_SETTINGS (sizeof(SETTINGS) >> 2)    //DIV by 4. In 32 bit words!! for comm xfer


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
#define SIZE_OF_SONG (sizeof(SONG) >> 2)            //DIV by 4. In 32 bit words!! for comm xfer

#define TRICK_MODE_NONE         0   //Trick shot button does nothing
#define TRICK_MODE_SONG         1   //switch to a particulatar song, and then back when pressed again
//#define TRICK_MODE_SONG_MOMENT  2   //switch to a particulatar song, and then back when pressed again
//#define TRICK_MODE_LOOP_LATCH   3   //turn on a certain pedal loop - leave on until button pressed again
//#define TRICK_MODE_LOOP_MOMENT  4   //turn on a certain pedal loop - turn off when button *released*
#define TRICK_MODE_FSW_LATCH    2   //turn on a footswitch - leave on until button pressed again
#define TRICK_MODE_FSW_MOMENT   3   //turn on a footswitch - turn off when button *released*
//#define TRICK_MODE_MIDI_MSG     7   //send a MIDI message
//more?

//Error Codes:
#define UNKNOWN_PACKET_INVALID_TYPE         1
#define PACKET_START_NOT_FOUND              2
#define BREAKOUT_UNKNOWN_PACKET_TYPE_8      3
#define BREAKOUT_UNKNOWN_PACKET_TYPE_14     4
#define STOMPBOX_UNKNOWN_PACKET_TYPE_8      5
#define STOMPBOX_UNKNOWN_PACKET_TYPE_14     6
#define PACKET_TYPE_NOT_SUPPORTED           7
#define NV_INIT_FAILURE                     8
#define NV_READ_FAILURE                     9
#define NV_WRITE_FAILURE                    10
#define NV_GETCONFIG_FAILURE                11

//MODES:
#define MODE_IDLE                           0
#define MODE_RETRIEVE_SONG                  1
#define MODE_RETRIEVE_CONFIG                2
#define MODE_WRITE_SONG                     3
#define MODE_WRITE_CONFIG                   4
#define MODE_CHANGE_SONG                    5

//Backlight
#define BACKLIGHT_RED                       48
#define BACKLIGHT_BLUE                      03
#define BACKLIGHT_GREEN                     12
#define BACKLIGHT_REDBLUE                   51
#define BACKLIGHT_REDGREEN                  60
#define BACKLIGHT_BLUEGREEN                 15
#define BACKLIGHT_WHITE                     0x3f


class MyAppGui : public QQuickItem
{
    Q_OBJECT

public:
    MyAppGui();
   // void setParent(MyObject1*);
    void sendStatus(void);
    void sendRequestForConfigBlock(void);

    SONG ramSong;
    SETTINGS ramSettings;

    //unsigned char activeSong = 1;   //1-120 only
    qint8 test1 = 1;
    unsigned char isInitialized = 1;

private:
    QByteArray m_bleRecvData;

    unsigned char m_block;
    char outPacket[16];
    unsigned char* pData;
    unsigned char chksum;
    unsigned short scratch16;

    unsigned char lastSong = 1;

    //uint8 trickButtonMode = 0;// trick - force silent
    unsigned char trickButtonState = 0;

    int m_mode;


    void parsePacket8(unsigned char* packet);
    void parsePacket14(unsigned char* packet);
    void SendBlockGetSong(void);
    void SendBlockGetConfig(void);
    void SendBlockSetSong(void);
    void SendBlockSetConfig(void);
    void receiveSongBlock(unsigned char* packet);
    void receiveConfigBlock(unsigned char* packet);
    void receiveStatus(unsigned char* packet);
    void sendOutBuffer(unsigned char len);
    void sendRequestForSongBlock(void);
    void sendErrorPacket(unsigned char errorCode);
    char ConvertHexToASCiiChar(unsigned char num);
    void ConvertHexToASCii(unsigned char num, char *ch);
    unsigned char ConvertASCiiToHex(char ch);
    unsigned short ConvertASCii16ToHex16(unsigned char *packet);
    unsigned char calculateChecksum(unsigned char *data, unsigned char len);

    void dumpSongInfo();
    void dumpConfigInfo();

signals:
    void writeBLEdata(QByteArray);
    void SongComplete();
    void ConfigComplete();

public slots:
    void parseInData(QByteArray);
    void UpdateSongToDevice(void);
    void UpdateConfigToDevice(void);
    void gotoNextSong();
    void gotoPreviousSong();
};

#endif // MYAPPGUI_H




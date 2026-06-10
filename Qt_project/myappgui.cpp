#include <QObject>
#include <QGuiApplication>
#include "myappgui.h"
#include <QDataStream>


MyAppGui::MyAppGui()
{

    lastSong = -1; //force loading the first song # read in Status

    m_mode = MODE_IDLE;
}

void MyAppGui::parseInData(QByteArray packetArray)
{

    unsigned char packet[16];

    for(int i=0;i<packetArray.length();i++)
    {
        packet[i] = (unsigned char)packetArray[i];

    }

    //check for start byte
    if(packet[0] == '$')
    {
        //check upper or lower case
        if(packet[1] >= 'a')
        {
            //8 byte packet
            parsePacket8(packet);
        }
        else if(packet[1] >= 'A')
        {
            //14 byte packet
            parsePacket14(packet);
        }
        else
        {
            //not a packet??
            sendErrorPacket(UNKNOWN_PACKET_INVALID_TYPE);
        }
    }
    else
    {
        //no start of packet byte found at [0]
        //TO DO: find '$' and call this function recursively with offset?
        //this could run forever if a CR wasn't found!!
        //if(packet[1] != 13) parseInData(&packet[1]);
        //else sendErrorPacket(PACKET_START_NOT_FOUND);
        //sendErrorPacket(PACKET_START_NOT_FOUND);
    }


}
void MyAppGui::parsePacket8(unsigned char* packet)
{
//TO DO: check for correct checksum and CR
    if(packet[1] == 'a')
    {
        //Request song info - Breakout is receiving an updated song and is ready for the next block
        m_block = ConvertASCii16ToHex16(&packet[2]);
        SendBlockSetSong();
    }
    else if(packet[1] == 'b')
    {
        receiveStatus(packet);
    }
    else if(packet[1] == 'c')
    {
        //Request Config block - Breakout is receiving a NEW config and is ready for the next block
        m_block = ConvertASCii16ToHex16(&packet[2]);
        SendBlockSetConfig();
    }
    else
    {
        //packet type not recognized
        sendErrorPacket(STOMPBOX_UNKNOWN_PACKET_TYPE_8);
   }

    /*
     * breakout
    if(packet[1] == 'a')
    {
        //Request song info
        m_block = ConvertASCii16ToHex16(&packet[2]);
        SendBlockGetSong();
    }
    else if(packet[1] == 'b')
    {
        receiveStatus(packet);
    }
    else if(packet[1] == 'c')
    {
        //request config
        m_block = ConvertASCii16ToHex16(&packet[2]);
        SendBlockGetConfig();
   }
    else
    {
        //packet type not recognized
        sendErrorPacket(BREAKOUT_UNKNOWN_PACKET_TYPE_8);
   }
   */
}
void MyAppGui::parsePacket14(unsigned char* packet)
{
    //static unsigned char newBlock;


//TO DO: check for correct checksum and CR
    if(packet[1] == 'A')
    {
        if(m_mode == MODE_RETRIEVE_SONG)
        {
            //the App is receiving a modified song structure
            receiveSongBlock(packet);
        }
        else
        {
            //we weren't expecting that... request status
            sendStatus();
        }
    }
    else if(packet[1] == 'B')
    {
        //STOMPBOX does not repond to this packet
        sendErrorPacket(PACKET_TYPE_NOT_SUPPORTED);
    }
    else if(packet[1] == 'C')
    {
        if(m_mode == MODE_RETRIEVE_CONFIG)
        {
            //the App is receiving a Settings/Config structure
            receiveConfigBlock(packet);
        }
        else
        {
            //we weren't expecting that... request status
            sendStatus();
        }
    }
    else if(packet[1] == 'D')
    {
        //STOMPBOX does not repond to this packet
        sendErrorPacket(PACKET_TYPE_NOT_SUPPORTED);
    }
    else
    {
        //packet type not recognized
        //TODO: send an error packet?
        sendErrorPacket(STOMPBOX_UNKNOWN_PACKET_TYPE_14);
    }


}
void MyAppGui::SendBlockGetSong(void)
{
    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'A';
    ConvertHexToASCii(m_block, &outPacket[2]);  //include in packet

    //get block data - 4 bytes
    pData = (unsigned char*)&ramSong;
    pData += m_block * 4;
    ConvertHexToASCii(*pData, &outPacket[4]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[6]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[8]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[10]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 12);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[12]);  //include in packet
    outPacket[12] = chksum;  //include in packet
    outPacket[13] = 13;

    sendOutBuffer(14);
}
void MyAppGui::SendBlockGetConfig(void)
{
    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'C';
    ConvertHexToASCii(m_block, &outPacket[2]);  //include in packet

    //get block data - 4 bytes
    pData = (unsigned char*)&ramSettings;
    pData += m_block * 4;
    ConvertHexToASCii(*pData, &outPacket[4]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[6]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[8]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[10]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 12);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[12]);  //include in packet
    outPacket[12] = chksum;  //include in packet
    outPacket[13] = 13;

    sendOutBuffer(14);
}
void MyAppGui::SendBlockSetSong(void)
{
    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'B';
    ConvertHexToASCii(m_block, &outPacket[2]);  //include in packet

    //get block data - 4 bytes
    pData = (unsigned char*)&ramSong;
    pData += m_block * 4;
    ConvertHexToASCii(*pData, &outPacket[4]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[6]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[8]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[10]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 12);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[12]);  //include in packet
    outPacket[12] = chksum;  //include in packet
    outPacket[13] = 13;

    sendOutBuffer(14);
}
void MyAppGui::SendBlockSetConfig(void)
{
    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'D';
    ConvertHexToASCii(m_block, &outPacket[2]);  //include in packet

    //get block data - 4 bytes
    pData = (unsigned char*)&ramSettings;
    pData += m_block * 4;
    ConvertHexToASCii(*pData, &outPacket[4]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[6]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[8]);  //include in packet
    pData ++; //next byte
    ConvertHexToASCii(*pData, &outPacket[10]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 12);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[12]);  //include in packet
    outPacket[12] = chksum;  //include in packet
    outPacket[13] = 13;

    sendOutBuffer(14);
}
void MyAppGui::receiveSongBlock(unsigned char* packet)
{
    //the BREAKOUT will Save this song to flash when the whole thing as arrived
    //received a Set Song block
    //store in RAM temp buffer
    //point to correct block
    pData = (unsigned char*)&ramSong;
    pData += m_block * 4;

    //copy the first WORD
    scratch16 = ConvertASCii16ToHex16(&packet[4]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);
    pData++;

    //copy the second WORD
    scratch16 = ConvertASCii16ToHex16(&packet[8]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);

    //go to next block or if last then write RAM to flash
    if(m_block < SIZE_OF_SONG-1)
    {
        //go to next block
        m_block++;
    }
    else
    {
        //done
        dumpSongInfo();
        m_mode = MODE_IDLE;
        sendStatus();
        return;
    }
    sendRequestForSongBlock();
}
void MyAppGui::receiveConfigBlock(unsigned char* packet)
{
    //the BREAKOUT will Save this song to flash when the whole thing as arrived
    //received a Set Song block
    //store in RAM temp buffer
    //point to correct block
    pData = (unsigned char*)&ramSettings;
    pData += m_block * 4;

    //copy the first WORD
    scratch16 = ConvertASCii16ToHex16(&packet[4]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);
    pData++;

    //copy the second WORD
    scratch16 = ConvertASCii16ToHex16(&packet[8]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);

    //go to next block or if last then write RAM to flash
    if(m_block < SIZE_OF_SETTINGS-1)
    {
        //go to next block
        m_block++;
    }
    else
    {
        //done
        dumpConfigInfo();
        m_mode = MODE_IDLE;
        sendStatus();
        return;
    }
    sendRequestForConfigBlock();




    /*
    //unsigned short scratch16;

    //received a Set Config block
    //store in RAM temp buffer
    //point to correct block
    pData = (unsigned char*)&ramSettings;
    pData += m_block * 4;

    //copy the first WORD
    scratch16 = ConvertASCii16ToHex16(&packet[4]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);
    pData++;

    //copy the second WORD
    scratch16 = ConvertASCii16ToHex16(&packet[8]);
    *pData = (unsigned char)(scratch16 >> 8);
    pData++;
    *pData = (unsigned char)(scratch16 & 0x00ff);

    //go to next block or if last then write RAM to flash
    if(m_block < SIZE_OF_SETTINGS)
    {
        m_block++;
    }
    else
    {
        //done
        dumpConfigInfo();
        m_mode = MODE_IDLE;
        sendStatus();
        return;
    }
    sendRequestForConfigBlock();
    */
}
void MyAppGui::receiveStatus(unsigned char* packet)
{
    //if we didn't change it - set the local "song" number to what the Status says (if we set it, there may be old packets comin in, we should ignore)
    if(m_mode == MODE_CHANGE_SONG)
    {
        //does Song in status match what we set??
        if(ramSettings.currentSong == ConvertASCii16ToHex16(&packet[2]) )
        {
            //It's set..load it
            lastSong = ramSettings.currentSong;
            sendRequestForSongBlock();
        }
    }
    else
    {
        //Set Current Song # - STATUS - trickshot button, etc
        ramSettings.currentSong = ConvertASCii16ToHex16(&packet[2]);
        if((ramSettings.currentSong < 1) || (ramSettings.currentSong > 120)) ramSettings.currentSong = 1;

        //Get Config ??  (temp?)
        if(ramSettings.isFilled != 0xa5)
        {
            //we don't have a valid config loaded locally - get it now.
            sendRequestForConfigBlock();
        }
        else if(lastSong != ramSettings.currentSong)
        {
            //new active song..load it
            lastSong = ramSettings.currentSong;
            sendRequestForSongBlock();
        }
        //TO DO: extract the rest of the STATUS WORD - Trickshot button, etc,

        //and send STATUS packet back out
        qDebug() << "receiveStatus(); Song=" << ramSettings.currentSong << "TS=" << trickButtonState;
    }
}
void MyAppGui::sendOutBuffer(unsigned char len)
{
    //convert data to QByteArray
    QByteArray data;
    for(int i=0;i<len;i++)
    {
        data[i] = outPacket[i];
    }

    //bleComm->writeData(data);
    emit writeBLEdata(data);


}
void MyAppGui::sendRequestForSongBlock(void)
{
    if(m_mode != MODE_RETRIEVE_SONG)
    {
        //first block request
        m_block = 0;
        m_mode = MODE_RETRIEVE_SONG;
    }

    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'a';
    ConvertHexToASCii(ramSettings.currentSong, &outPacket[2]);  //include in packet
    ConvertHexToASCii(m_block, &outPacket[4]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 6);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[6]);  //include in packet
    outPacket[6] = chksum;  //include in packet
    outPacket[7] = 13;

    sendOutBuffer(8);
}
void MyAppGui::sendStatus(void)
{
    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'b';
    ConvertHexToASCii(trickButtonState, &outPacket[2]);  //include in packet
    ConvertHexToASCii(ramSettings.currentSong, &outPacket[4]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 6);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[6]);  //include in packet
    outPacket[6] = chksum;  //include in packet
    outPacket[7] = 13;

    sendOutBuffer(8);
}
void MyAppGui::sendRequestForConfigBlock(void)
{
    if(m_mode != MODE_RETRIEVE_CONFIG)
    {
        //first block request
        m_block = 0;
        m_mode = MODE_RETRIEVE_CONFIG;
    }

    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'c';
    ConvertHexToASCii(0, &outPacket[2]);  //include in packet
    ConvertHexToASCii(m_block, &outPacket[4]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 6);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[6]);  //include in packet
    outPacket[6] = chksum;  //include in packet
    outPacket[7] = 13;

    sendOutBuffer(8);
}
void MyAppGui::sendErrorPacket(unsigned char errorCode)
{
    qDebug() << "ERROR CODE: " << errorCode;
    //sendStatus();   //temp?  start things up

    //build packet
    outPacket[0] = '$';
    outPacket[1] = 'E';
    outPacket[2] = '0';
    outPacket[3] = '0';
    ConvertHexToASCii(errorCode, &outPacket[4]);  //include in packet

    chksum = calculateChecksum((unsigned char*)outPacket, 6);  //checksum of 14 byte packet
    //ConvertHexToASCii(chksum, &outPacket[6]);  //include in packet
    outPacket[6] = chksum;  //include in packet
    outPacket[7] = 13;

    sendOutBuffer(8);
}
char MyAppGui::ConvertHexToASCiiChar(unsigned char num)
{
    char ch;

    //TO DO: PUT in a const array
    switch ( num )
    {
        case 0: ch = '0'; break;
        case 1: ch = '1'; break;
        case 2: ch = '2'; break;
        case 3: ch = '3'; break;
        case 4: ch = '4'; break;
        case 5: ch = '5'; break;
        case 6: ch = '6'; break;
        case 7: ch = '7'; break;
        case 8: ch = '8'; break;
        case 9: ch = '9'; break;
        case 0x0a: ch = 'A'; break;
        case 0x0b: ch = 'B'; break;
        case 0x0c: ch = 'C'; break;
        case 0x0d: ch = 'D'; break;
        case 0x0e: ch = 'E'; break;
        case 0x0f: ch = 'F'; break;
        default: ch = ' '; break;
    }

    return ch;
}
void MyAppGui::ConvertHexToASCii(unsigned char num, char *ch)
{
    unsigned char temp;

    //upper nibble first
    temp = (num >> 4 ) & 0x0f;
    ch[0] = ConvertHexToASCiiChar(temp);
    //then add lower nibble
    temp = num & 0x0f;
    ch[1] = ConvertHexToASCiiChar(temp);
}
unsigned char MyAppGui::ConvertASCiiToHex(char ch)
{
    unsigned char num;

    switch ( ch )
    {
        case '0': num = 0; break;
        case '1': num = 1; break;
        case '2': num = 2; break;
        case '3': num = 3; break;
        case '4': num = 4; break;
        case '5': num = 5; break;
        case '6': num = 6; break;
        case '7': num = 7; break;
        case '8': num = 8; break;
        case '9': num = 9; break;
        case 'a': case 'A': num = 0x0a; break;
        case 'b': case 'B': num = 0x0b; break;
        case 'c': case 'C': num = 0x0c; break;
        case 'd': case 'D': num = 0x0d; break;
        case 'e': case 'E': num = 0x0e; break;
        case 'f': case 'F': num = 0x0f; break;
        default: num = 0x0f; break;
    }

    return num;
}
unsigned short MyAppGui::ConvertASCii16ToHex16(unsigned char *packet)
{
    unsigned short result;

    result = ConvertASCiiToHex(*packet++) << 12;
    result += ConvertASCiiToHex(*packet++) << 8;
    result += ConvertASCiiToHex(*packet++) << 4;
    result += ConvertASCiiToHex(*packet++);

    return result;
}
unsigned char MyAppGui::calculateChecksum(unsigned char *data, unsigned char len)
{
    unsigned char sum = 0;

    for (unsigned char i = 0; i < len; i++)
    {
        sum += data[i];
    }

    sum &= 0x0f;

    return ConvertHexToASCiiChar(sum);
}
void MyAppGui::dumpSongInfo()
{

    QByteArray song = QByteArray((char*)ramSong.name);
    QByteArray part = QByteArray((char*)ramSong.partname);

    qDebug() << "**NEW SONG LOADED**";
    qDebug() << "isFilled:" << ramSong.isFilled;
    qDebug() << "footswitch:" << ramSong.footswitch;
    qDebug() << "lcdBacklight:" << ramSong.lcdBacklight;
    qDebug() << "matrix:" << ramSong.matrix[0] << ramSong.matrix[1] << ramSong.matrix[2] << ramSong.matrix[3] << ramSong.matrix[4] << ramSong.matrix[5] << ramSong.matrix[6] << ramSong.matrix[7] << ramSong.matrix[8] << ramSong.matrix[9] << ramSong.matrix[10] << ramSong.matrix[11];
    qDebug() << "midiMessage1:" << (char*)ramSong.midiMessage1;
    //qDebug() << "midiMessage2:" << (char*)ramSong.midiMessage2;
    //qDebug() << "midiMessage3:" << (char*)ramSong.midiMessage3;
    //qDebug() << "midiMessage4:" << (char*)ramSong.midiMessage4;
    qDebug() << "midiMsgMode:" << ramSong.midiMsgMode;
    qDebug() << "name:" << song;
    qDebug() << "partname:" << part;
    qDebug() << "trickMode:" << ramSong.trickMode[0];
    qDebug() << "trickData:" << ramSong.trickData[0];
    qDebug() << "DiveMode:" << ramSong.trickMode[1];
    qDebug() << "DiveData:" << ramSong.trickData[1];

    emit SongComplete();
}
void MyAppGui::dumpConfigInfo()
{

    /*
    unsigned char isFilled;                     // this struct has been programmed, or is empty=0xff (default flash erase value)
    unsigned short lcdBacklight;                //4-5 bits of RGB backlight control For Main Menus, etc.  User configurable!!
    unsigned char currentSong;                  // save the last song selected
    unsigned char loopName[7][12];              //name for each pedal (or whatever) connected to a loop
    unsigned char fswName[6][12];               //name for each footswitch
    unsigned char auxOutName[4][12];            //name for each aux output
    */

    qDebug() << "**CONFIG LOADED**";
    qDebug() << "isFilled:" << ramSettings.isFilled;
    qDebug() << "lcdBacklight:" << ramSettings.lcdBacklight;
    qDebug() << "currentSong:" << ramSettings.currentSong;
    qDebug() << "loopName0:" << QByteArray((char*)ramSettings.loopName[0]);
    qDebug() << "loopName1:" << QByteArray((char*)ramSettings.loopName[1]);
    qDebug() << "loopName2:" << QByteArray((char*)ramSettings.loopName[2]);
    qDebug() << "loopName3:" << QByteArray((char*)ramSettings.loopName[3]);
    qDebug() << "loopName4:" << QByteArray((char*)ramSettings.loopName[4]);
    qDebug() << "loopName5:" << QByteArray((char*)ramSettings.loopName[5]);
    qDebug() << "loopName6:" << QByteArray((char*)ramSettings.loopName[6]);
    qDebug() << "fswName0:" << QByteArray((char*)ramSettings.fswName[0]);
    qDebug() << "fswName1:" << QByteArray((char*)ramSettings.fswName[1]);
    qDebug() << "fswName2:" << QByteArray((char*)ramSettings.fswName[2]);
    qDebug() << "fswName3:" << QByteArray((char*)ramSettings.fswName[3]);
    qDebug() << "fswName4:" << QByteArray((char*)ramSettings.fswName[4]);
    qDebug() << "fswName5:" << QByteArray((char*)ramSettings.fswName[5]);
    qDebug() << "auxOutName0:" << QByteArray((char*)ramSettings.auxOutName[0]);
    qDebug() << "auxOutName1:" << QByteArray((char*)ramSettings.auxOutName[1]);
    qDebug() << "auxOutName2:" << QByteArray((char*)ramSettings.auxOutName[2]);
    qDebug() << "auxOutName3:" << QByteArray((char*)ramSettings.auxOutName[3]);

    emit ConfigComplete();
}
void MyAppGui::UpdateSongToDevice()
{
    //temp: change something and see if it went thru
    //sprintf((char*)ramSong.name, "SongWhoA!");

    qDebug() << "Sending Song:";
    dumpSongInfo();

    m_block = 0;
    m_mode = MODE_WRITE_SONG;
    SendBlockSetSong();

}
void MyAppGui::UpdateConfigToDevice()
{
    //temp: change something and see if it went thru
    //sprintf((char*)ramSettings.loopName[6], "Fixed?");

    qDebug() << "Sending Config:";
    dumpConfigInfo();

    m_block = 0;
    m_mode = MODE_WRITE_CONFIG;
    SendBlockSetConfig();

}
void MyAppGui::gotoNextSong()
{
    qDebug() << "Changing Song (from):" << ramSettings.currentSong;
    m_mode = MODE_CHANGE_SONG;
    dumpSongInfo();
    //NEXT
    if(ramSettings.currentSong < 120) ramSettings.currentSong++;
    qDebug() << "Changing Song (to):" << ramSettings.currentSong;
    sendStatus();   //update the song number on the device - processing the return packet will trigger loading the new song's info
}
void MyAppGui::gotoPreviousSong()
{
    qDebug() << "Changing Song (from):" << ramSettings.currentSong;
    m_mode = MODE_CHANGE_SONG;
    dumpSongInfo();
    //PREVIOUS
    if(ramSettings.currentSong > 1) ramSettings.currentSong--;
    qDebug() << "Changing Song (to):" << ramSettings.currentSong;
    sendStatus();   //update the song number on the device - processing the return packet will trigger loading the new song's info
}

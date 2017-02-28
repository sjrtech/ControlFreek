#ifndef MYOBJECT1_H
#define MYOBJECT1_H

#include <QObject>
//#include <QBluetoothSocket>
#include <QLowEnergyController>
#include "myappgui.h"



class MyObject1 : public QObject
{
    Q_OBJECT

    //Song
    Q_PROPERTY(QString SongName READ getSongName NOTIFY SongChanged)
    Q_PROPERTY(QString PartName READ getPartName NOTIFY SongChanged)

    Q_PROPERTY(QString MidiMsg1 READ getMidiMsg1 NOTIFY SongChanged)
    Q_PROPERTY(QString MidiMsg2 READ getMidiMsg2 NOTIFY SongChanged)
    Q_PROPERTY(QString MidiMsg3 READ getMidiMsg3 NOTIFY SongChanged)
    Q_PROPERTY(QString MidiMsg4 READ getMidiMsg4 NOTIFY SongChanged)

    Q_PROPERTY(QString MidiMode READ getMidiMode NOTIFY SongChanged)
    Q_PROPERTY(QString FswSongConfig READ getFswSongConfig NOTIFY SongChanged)
    Q_PROPERTY(QString TrickMode READ getTrickMode NOTIFY SongChanged)
    Q_PROPERTY(QString TrickData READ getTrickData NOTIFY SongChanged)
    Q_PROPERTY(QString SongBacklight READ getSongBacklight NOTIFY SongChanged)

    Q_PROPERTY(QString Matrix0 READ getMatrix0 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix1 READ getMatrix1 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix2 READ getMatrix2 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix3 READ getMatrix3 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix4 READ getMatrix4 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix5 READ getMatrix5 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix6 READ getMatrix6 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix7 READ getMatrix7 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix8 READ getMatrix8 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix9 READ getMatrix9 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix10 READ getMatrix10 NOTIFY SongChanged)
    Q_PROPERTY(QString Matrix11 READ getMatrix11 NOTIFY SongChanged)


    //Settings
    Q_PROPERTY(QString BacklightMain READ getBacklightMain NOTIFY ConfigChanged)
    Q_PROPERTY(QString currentSong READ getcurrentSong NOTIFY ConfigChanged)

    Q_PROPERTY(QString LoopName1 READ getLoopName1 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName2 READ getLoopName2 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName3 READ getLoopName3 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName4 READ getLoopName4 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName5 READ getLoopName5 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName6 READ getLoopName6 NOTIFY ConfigChanged)
    Q_PROPERTY(QString LoopName7 READ getLoopName7 NOTIFY ConfigChanged)

    Q_PROPERTY(QString FswName1 READ getFswName1 NOTIFY ConfigChanged)
    Q_PROPERTY(QString FswName2 READ getFswName2 NOTIFY ConfigChanged)
    Q_PROPERTY(QString FswName3 READ getFswName3 NOTIFY ConfigChanged)
    Q_PROPERTY(QString FswName4 READ getFswName4 NOTIFY ConfigChanged)
    Q_PROPERTY(QString FswName5 READ getFswName5 NOTIFY ConfigChanged)
    Q_PROPERTY(QString FswName6 READ getFswName6 NOTIFY ConfigChanged)

    Q_PROPERTY(QString AuxName1 READ getAuxName1 NOTIFY ConfigChanged)
    Q_PROPERTY(QString AuxName2 READ getAuxName2 NOTIFY ConfigChanged)
    Q_PROPERTY(QString AuxName3 READ getAuxName3 NOTIFY ConfigChanged)
    Q_PROPERTY(QString AuxName4 READ getAuxName4 NOTIFY ConfigChanged)


public:
    explicit MyObject1(QObject *parent = 0);
    Q_INVOKABLE void foo(QString MAC, QString name);

    //QBluetoothSocket *socket;
    QLowEnergyController *bleCentral;
    QLowEnergyService *service;

    //QBluetoothUuid WRITE_CHAR;
    QList<QLowEnergyCharacteristic> bleIncludedChars;
    bool bleReadReady = false;
    bool bleWriteReady = false;

    QByteArray m_RecvData;

private:
    MyAppGui* myApp;

signals:
    void recdBLEdata(QByteArray);
    void SongChanged(void);
    void ConfigChanged(void);

public slots:
    void addService(QBluetoothUuid);
    void discoveryDone();
    void dataReadCB(QLowEnergyCharacteristic, QByteArray);
    void writeData(QByteArray);
    void bleConnected();
    void bleServiceChanged(QLowEnergyService::ServiceState);

    //Song Data
    QString getSongName(void) const;
    QString getPartName(void) const;

    QString getMidiMsg1(void) const;
    QString getMidiMsg2(void) const;
    QString getMidiMsg3(void) const;
    QString getMidiMsg4(void) const;

    QString getMidiMode(void) const;
    QString getFswSongConfig(void) const;
    QString getTrickMode(void) const;
    QString getTrickData(void) const;
    QString getSongBacklight(void) const;

    QString getMatrix0(void) const;
    QString getMatrix1(void) const;
    QString getMatrix2(void) const;
    QString getMatrix3(void) const;
    QString getMatrix4(void) const;
    QString getMatrix5(void) const;
    QString getMatrix6(void) const;
    QString getMatrix7(void) const;
    QString getMatrix8(void) const;
    QString getMatrix9(void) const;
    QString getMatrix10(void) const;
    QString getMatrix11(void) const;

    void onSongNameChanged(QString);
    void onSongPartNameChanged(QString);

    void onMidiMsg1Changed(QString);
    void onMidiMsg2Changed(QString);
    void onMidiMsg3Changed(QString);
    void onMidiMsg4Changed(QString);

    void onMidiModeChanged(QString);
    void onSongFswChanged(QString);
    void onTrickModeChanged(QString);
    void onTrickDataChanged(QString);
    void onSongBacklightChanged(QString);

    void onMatrix0Changed(QString);
    void onMatrix1Changed(QString);
    void onMatrix2Changed(QString);
    void onMatrix3Changed(QString);
    void onMatrix4Changed(QString);
    void onMatrix5Changed(QString);
    void onMatrix6Changed(QString);
    void onMatrix7Changed(QString);
    void onMatrix8Changed(QString);
    void onMatrix9Changed(QString);
    void onMatrix10Changed(QString);
    void onMatrix11Changed(QString);

    //Config Data
    QString getBacklightMain(void) const;
    QString getcurrentSong(void) const;

    QString getLoopName1(void) const;
    QString getLoopName2(void) const;
    QString getLoopName3(void) const;
    QString getLoopName4(void) const;
    QString getLoopName5(void) const;
    QString getLoopName6(void) const;
    QString getLoopName7(void) const;

    QString getFswName1(void) const;
    QString getFswName2(void) const;
    QString getFswName3(void) const;
    QString getFswName4(void) const;
    QString getFswName5(void) const;
    QString getFswName6(void) const;

    QString getAuxName1(void) const;
    QString getAuxName2(void) const;
    QString getAuxName3(void) const;
    QString getAuxName4(void) const;

    void onMainBacklightChanged(QString);
    void onCurrentSongChanged(QString);

    void onLoopName1Changed(QString);
    void onLoopName2Changed(QString);
    void onLoopName3Changed(QString);
    void onLoopName4Changed(QString);
    void onLoopName5Changed(QString);
    void onLoopName6Changed(QString);
    void onLoopName7Changed(QString);

    void onFswName1Changed(QString);
    void onFswName2Changed(QString);
    void onFswName3Changed(QString);
    void onFswName4Changed(QString);
    void onFswName5Changed(QString);
    void onFswName6Changed(QString);

    void onAuxName1Changed(QString);
    void onAuxName2Changed(QString);
    void onAuxName3Changed(QString);
    void onAuxName4Changed(QString);


    void updateSongDisplay(void);
    void updateSongDevice(void);

    void selectNextSong(void);
    void selectPreviousSong(void);

    void updateConfigDisplay(void);
    void updateConfigDevice(void);

};





#endif // MYOBJECT1_H

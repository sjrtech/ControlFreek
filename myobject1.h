#ifndef MYOBJECT1_H
#define MYOBJECT1_H

#include <QObject>
//#include <QBluetoothSocket>
#include <QLowEnergyController>
//#include <QAbstractItemModel>
#include "myappgui.h"
#include <QStringListModel>



class MyObject1 : public QObject
{
    Q_OBJECT

    //Q_PROPERTY(QStringList comboList READ comboList WRITE setComboList NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList0 READ comboList0 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList1 READ comboList1 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList2 READ comboList2 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList3 READ comboList3 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList4 READ comboList4 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList5 READ comboList5 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList6 READ comboList6 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList7 READ comboList7 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList8 READ comboList8 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList9 READ comboList9 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList10 READ comboList10 NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList11 READ comboList11 NOTIFY comboListChanged)
    //Q_PROPERTY(int count READ count NOTIFY countChanged)

    //Q_PROPERTY(QStringList comboListMidiMode READ comboListMidiMode NOTIFY SongChanged)
    Q_PROPERTY(QStringList comboListBacklight READ comboListBacklight NOTIFY SongChanged)
    Q_PROPERTY(QStringList comboListTrickMode1 READ comboListTrickMode1 NOTIFY SongChanged)
    Q_PROPERTY(QStringList comboListTrickMode2 READ comboListTrickMode2 NOTIFY SongChanged)

    //Song
    Q_PROPERTY(QString SongName READ getSongName NOTIFY SongChanged)
    Q_PROPERTY(QString PartName READ getPartName NOTIFY SongChanged)

    Q_PROPERTY(QString MidiMsg1 READ getMidiMsg1 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg2 READ getMidiMsg2 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg3 READ getMidiMsg3 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg4 READ getMidiMsg4 NOTIFY SongChanged)

    //Q_PROPERTY(QString MidiMode READ getMidiMode NOTIFY SongChanged)
    Q_PROPERTY(QString FswSongConfig READ getFswSongConfig NOTIFY SongChanged)

    //Q_PROPERTY(QString TrickMode READ getTrickMode NOTIFY SongChanged)
    Q_PROPERTY(QString TrickData1 READ getTrickData1 NOTIFY SongChanged)
    Q_PROPERTY(QString TrickData2 READ getTrickData2 NOTIFY SongChanged)
    //Q_PROPERTY(QString SongBacklight READ getSongBacklight NOTIFY SongChanged)

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

    const QStringList comboList0();
    const QStringList comboList1();
    const QStringList comboList2();
    const QStringList comboList3();
    const QStringList comboList4();
    const QStringList comboList5();
    const QStringList comboList6();
    const QStringList comboList7();
    const QStringList comboList8();
    const QStringList comboList9();
    const QStringList comboList10();
    const QStringList comboList11();

    //const QStringList comboListMidiMode();
    const QStringList comboListBacklight();
    const QStringList comboListTrickMode1();
    const QStringList comboListTrickMode2();


private:
    MyAppGui* myApp;

    QStringList m_comboList0;
    QStringList m_comboList1;
    QStringList m_comboList2;
    QStringList m_comboList3;
    QStringList m_comboList4;
    QStringList m_comboList5;
    QStringList m_comboList6;
    QStringList m_comboList7;
    QStringList m_comboList8;
    QStringList m_comboList9;
    QStringList m_comboList10;
    QStringList m_comboList11;

    //QStringList m_comboListMidiMode;
    QStringList m_comboListBacklight;
    QStringList m_comboListTrickMode1;
    QStringList m_comboListTrickMode2;

    void loadDummyConfig();

signals:
    void recdBLEdata(QByteArray);
    void SongChanged(void);
    void ConfigChanged(void);
    void modelChanged(void);

    void comboListChanged();
    //void countChanged();

public slots:
    void addService(QBluetoothUuid);
    void discoveryDone();
    void dataReadCB(QLowEnergyCharacteristic, QByteArray);
    void writeData(QByteArray);
    void bleConnected();
    void bleServiceChanged(QLowEnergyService::ServiceState);

    void updateComboBoxes(void);

    //QAbstractItemModel* model(void) const;

    //Song Data
    QString getSongName(void) const;
    QString getPartName(void) const;

    QString getMidiMsg1(void) const;
    //QString getMidiMsg2(void) const;
    //QString getMidiMsg3(void) const;
    //QString getMidiMsg4(void) const;

    //QString getMidiMode(void) const;
    QString getFswSongConfig(void) const;
    int isFswSongConfig1(void) const;
    int isFswSongConfig2(void) const;
    int isFswSongConfig3(void) const;
    int isFswSongConfig4(void) const;
    int isFswSongConfig5(void) const;
    int isFswSongConfig6(void) const;

    //QString getTrickMode(void) const;
    QString getTrickData1(void) const;
    QString getTrickData2(void) const;
    //QString getSongBacklight(void) const;

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
    //void onMidiMsg2Changed(QString);
    //void onMidiMsg3Changed(QString);
    //void onMidiMsg4Changed(QString);

    //void onMidiModeChanged(QString);
    void onSongFswChanged(QString);
    void onTrickMode1Changed(QString);
    void onTrickData1Changed(QString);
    void onTrickMode2Changed(QString);
    void onTrickData2Changed(QString);
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

    void fswOneCheckChanged(int);
    void fswTwoCheckChanged(int);
    void fswThreeCheckChanged(int);
    void fswFourCheckChanged(int);
    void fswFiveCheckChanged(int);
    void fswSixCheckChanged(int);

};





#endif // MYOBJECT1_H

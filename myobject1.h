#ifndef MYOBJECT1_H
#define MYOBJECT1_H

#include <QObject>
//#include <QBluetoothSocket>
#include <QLowEnergyController>
//#include <QAbstractItemModel>
#include "myappgui.h"
#include <QStringListModel>


#define STRING_NOT_USED         "*not used*"
#define STRING_MAIN_IN          "MAIN IN"


class MyObject1 : public QObject
{
    Q_OBJECT

    //Q_PROPERTY(QStringList comboList READ comboList WRITE setComboList NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList0 READ comboList0 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo0_index READ combo0Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList1 READ comboList1 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo1_index READ combo1Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList2 READ comboList2 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo2_index READ combo2Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList3 READ comboList3 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo3_index READ combo3Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList4 READ comboList4 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo4_index READ combo4Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList5 READ comboList5 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo5_index READ combo5Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList6 READ comboList6 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo6_index READ combo6Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList7 READ comboList7 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo7_index READ combo7Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList8 READ comboList8 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo8_index READ combo8Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList9 READ comboList9 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo9_index READ combo9Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList10 READ comboList10 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo10_index READ combo10Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboList11 READ comboList11 NOTIFY comboListChanged)
    Q_PROPERTY(int Combo11_index READ combo11Index NOTIFY comboListChanged)
    //Q_PROPERTY(int count READ count NOTIFY countChanged)

    //Q_PROPERTY(QStringList comboListMidiMode READ comboListMidiMode NOTIFY SongChanged)
    Q_PROPERTY(QStringList comboListBacklight READ comboListBacklight NOTIFY SongChanged)
    Q_PROPERTY(int ComboBacklight_index READ comboBacklightIndex NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboListTrickMode1 READ comboListTrickMode1 NOTIFY SongChanged)
    Q_PROPERTY(int ComboTrickMode1_index READ comboTrickMode1Index NOTIFY comboListChanged)
    Q_PROPERTY(QStringList comboListTrickMode2 READ comboListTrickMode2 NOTIFY SongChanged)
    Q_PROPERTY(int ComboTrickMode2_index READ comboTrickMode2Index NOTIFY comboListChanged)

    Q_PROPERTY(int fswSong1CheckedState READ fswSong1CheckedStateRead NOTIFY comboListChanged)
    Q_PROPERTY(int fswSong2CheckedState READ fswSong2CheckedStateRead NOTIFY comboListChanged)
    Q_PROPERTY(int fswSong3CheckedState READ fswSong3CheckedStateRead NOTIFY comboListChanged)
    Q_PROPERTY(int fswSong4CheckedState READ fswSong4CheckedStateRead NOTIFY comboListChanged)
    Q_PROPERTY(int fswSong5CheckedState READ fswSong5CheckedStateRead NOTIFY comboListChanged)
    Q_PROPERTY(int fswSong6CheckedState READ fswSong6CheckedStateRead NOTIFY comboListChanged)


    //Song
    Q_PROPERTY(QString SongName READ getSongName NOTIFY SongChanged)
    Q_PROPERTY(QString PartName READ getPartName NOTIFY SongChanged)

    Q_PROPERTY(QString MidiMsg1 READ getMidiMsg1 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg2 READ getMidiMsg2 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg3 READ getMidiMsg3 NOTIFY SongChanged)
    //Q_PROPERTY(QString MidiMsg4 READ getMidiMsg4 NOTIFY SongChanged)

    //Q_PROPERTY(QString MidiMode READ getMidiMode NOTIFY SongChanged)
    //Q_PROPERTY(QString FswSongConfig READ getFswSongConfig NOTIFY SongChanged)


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
    int combo0Index() { return Combo0_index;  }
    const QStringList comboList1();
    int combo1Index() { return Combo1_index;  }
    const QStringList comboList2();
    int combo2Index() { return Combo2_index;  }
    const QStringList comboList3();
    int combo3Index() { return Combo3_index;  }
    const QStringList comboList4();
    int combo4Index() { return Combo4_index;  }
    const QStringList comboList5();
    int combo5Index() { return Combo5_index;  }
    const QStringList comboList6();
    int combo6Index() { return Combo6_index;  }
    const QStringList comboList7();
    int combo7Index() { return Combo7_index;  }
    const QStringList comboList8();
    int combo8Index() { return Combo8_index;  }
    const QStringList comboList9();
    int combo9Index() { return Combo9_index;  }
    const QStringList comboList10();
    int combo10Index() { return Combo10_index;  }
    const QStringList comboList11();
    int combo11Index() { return Combo11_index;  }

    //const QStringList comboListMidiMode();
    const QStringList comboListBacklight();
    int comboBacklightIndex() { return ComboBacklight_index;  }
    const QStringList comboListTrickMode1();
    int comboTrickMode1Index() { return ComboTrickMode1_index;  }
    const QStringList comboListTrickMode2();
    int comboTrickMode2Index() { return ComboTrickMode2_index;  }

    int fswSong1CheckedStateRead() { return fswSong1CheckedState;  }
    int fswSong2CheckedStateRead() { return fswSong2CheckedState;  }
    int fswSong3CheckedStateRead() { return fswSong3CheckedState;  }
    int fswSong4CheckedStateRead() { return fswSong4CheckedState;  }
    int fswSong5CheckedStateRead() { return fswSong5CheckedState;  }
    int fswSong6CheckedStateRead() { return fswSong6CheckedState;  }

private:
    MyAppGui* myApp;

    QStringList m_comboList0;
    int Combo0_index = 1;
    QStringList m_comboList1;
    int Combo1_index = 2;
    QStringList m_comboList2;
    int Combo2_index = 3;
    QStringList m_comboList3;
    int Combo3_index = 4;
    QStringList m_comboList4;
    int Combo4_index = 5;
    QStringList m_comboList5;
    int Combo5_index = 6;
    QStringList m_comboList6;
    int Combo6_index = 7;
    QStringList m_comboList7;
    int Combo7_index = 8;
    QStringList m_comboList8;
    int Combo8_index = 9;
    QStringList m_comboList9;
    int Combo9_index = 10;
    QStringList m_comboList10;
    int Combo10_index = 11;
    QStringList m_comboList11;
    int Combo11_index = 0;

    //QStringList m_comboListMidiMode;
    QStringList m_comboListBacklight;
    int ComboBacklight_index = 1;
    QStringList m_comboListTrickMode1;
    int ComboTrickMode1_index = 2;
    QStringList m_comboListTrickMode2;
    int ComboTrickMode2_index = 3;

    int fswSong1CheckedState = 0;
    int fswSong2CheckedState = 0;
    int fswSong3CheckedState = 0;
    int fswSong4CheckedState = 0;
    int fswSong5CheckedState = 0;
    int fswSong6CheckedState = 0;

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

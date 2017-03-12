/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Copyright (C) 2013 BlackBerry Limited. All rights reserved.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the examples of the QtBluetooth module.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.0
import QtBluetooth 5.2
import QtQuick.Controls 1.5

Item
{
    id: top

    property BluetoothService currentService

    BluetoothDiscoveryModel
    {
        id: btModel
        running: true
        discoveryMode: BluetoothDiscoveryModel.DeviceDiscovery
        onDiscoveryModeChanged: console.log("Discovery mode: " + discoveryMode)
        onServiceDiscovered: console.log("Found new service " + service.deviceAddress + " " + service.deviceName + " " + service.serviceName);
        onDeviceDiscovered: console.log("New device: " + device)
        onErrorChanged:
        {
                switch (btModel.error)
                {
                case BluetoothDiscoveryModel.PoweredOffError:
                    console.log("Error: Bluetooth device not turned on"); break;
                case BluetoothDiscoveryModel.InputOutputError:
                    console.log("Error: Bluetooth I/O Error"); break;
                case BluetoothDiscoveryModel.InvalidBluetoothAdapterError:
                    console.log("Error: Invalid Bluetooth Adapter Error"); break;
                case BluetoothDiscoveryModel.NoError:
                    break;
                default:
                    console.log("Error: Unknown Error"); break;
                }
        }
   }


    Rectangle {
        id: mainwindow
        width: 320
        height: 640
        Flickable {
            anchors.fill: parent
            contentWidth: 960
            contentHeight: 640
            //Flickable.width: 320
            //Flickable.height: 0
            Rectangle
            {
                // ////////////////////////////////////////////////////////////////////////
                // BLE CONNECTION SCREEN
                id:connectscreen
                anchors.left: parent.left
                anchors.leftMargin: 20
                //anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top;
                width: 320
                height: 640
                border.width: 1
                Rectangle
                {
                    id: busy

                    width: parent.width * 0.7;
                    anchors.horizontalCenter: connectscreen.horizontalCenter
                    //anchors.top: top.top;
                    anchors.top: connectscreen.top;
                    height: text.height*1.2;
                    radius: 5
                    color: "#1c56f3"
                    visible: btModel.running

                    Text
                    {
                        id: text
                        text: "Scanning"
                        font.bold: true
                        font.pointSize: 20
                        anchors.centerIn: parent
                    }

                    SequentialAnimation on color
                    {
                        id: busyThrobber
                        ColorAnimation { easing.type: Easing.InOutSine; from: "#1c56f3"; to: "white"; duration: 1000; }
                        ColorAnimation { easing.type: Easing.InOutSine; to: "#1c56f3"; from: "white"; duration: 1000 }
                        loops: Animation.Infinite
                    }
                }

                ListView
                {
                    id: mainList
                    width: parent.width
                    anchors.top: busy.bottom
                    anchors.bottom: buttonGroup.top
                    anchors.bottomMargin: 10
                    anchors.topMargin: 10
                    anchors.horizontalCenter: connectscreen.horizontalCenter
                    clip: true

                    model: btModel
                    delegate: Rectangle
                    {
                        id: btDelegate
                        width: parent.width
                        height: column.height + 10

                        property bool expended: false;
                        clip: true
                        Image
                        {
                            id: bticon
                            source: "qrc:/default.png";
                            width: bttext.height;
                            height: bttext.height;
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 5
                        }

                        Column
                        {
                            id: column
                            anchors.left: bticon.right
                            anchors.leftMargin: 5
                            Text
                            {
                                id: bttext
                                text: deviceName ? deviceName : name
                                font.family: "FreeSerif"
                                font.pointSize: 16
                            }

                            Text
                            {
                                id: details
                                function get_details(s) {
                                    if (btModel.discoveryMode == BluetoothDiscoveryModel.DeviceDiscovery) {
                                        //We are doing a device discovery
                                        var str = "Address: " + remoteAddress;
                                        return str;
                                    } else {
                                        var str = "Address: " + s.deviceAddress;
                                        if (s.serviceName) { str += "<br>Service: " + s.serviceName; }
                                        if (s.serviceDescription) { str += "<br>Description: " + s.serviceDescription; }
                                        if (s.serviceProtocol) { str += "<br>Protocol: " + s.serviceProtocol; }
                                        return str;
                                    }
                                }
                                visible: opacity !== 0
                                opacity: btDelegate.expended ? 1 : 0.0
                                text: get_details(service)
                                font.family: "FreeSerif"
                                font.pointSize: 14
                                Behavior on opacity {
                                    NumberAnimation { duration: 200}
                                }
                            }
                        }
                        Behavior on height { NumberAnimation { duration: 200} }

                        MouseArea
                        {
                            anchors.fill: column
                            onClicked:
                            {
                                btDelegate.expended = !btDelegate.expended
                                theObject.foo(remoteAddress, deviceName);
                                songview.visible=true;
                                //mainList.visible=false;
                                //buttonGroup.visible = false;
                            }

                        }
                    }
                    focus: true

                }

                Row
                {
                    id: buttonGroup
                    property var activeButton: devButton

                    anchors.bottom: connectscreen.bottom
                    anchors.horizontalCenter: connectscreen.horizontalCenter
                    anchors.bottomMargin: 5
                    spacing: 10

                    Button
                    {
                        id: fdButton
                        width: connectscreen.width/3*0.9
                        //mdButton has longest text
                        height: mdButton.height
                        text: "Full Discovery"
                        visible: false
                        onClicked: btModel.discoveryMode = BluetoothDiscoveryModel.FullServiceDiscovery
                    }
                    Button
                    {
                        id: mdButton
                        width: connectscreen.width/3*0.9
                        text: "Minimal Discovery"
                        visible: false
                        onClicked: btModel.discoveryMode = BluetoothDiscoveryModel.MinimalServiceDiscovery
                    }
                    Button
                    {
                        id: devButton
                        width: connectscreen.width/2//*0.9
                        //mdButton has longest text
                        height: mdButton.height
                        text: "Device Discovery"
                        onClicked: btModel.discoveryMode = BluetoothDiscoveryModel.DeviceDiscovery
                    }
                }
            }
            Rectangle
            {
                // ////////////////////////////////////////////////////////////////////////
                // Breakout box SCREENS
                border.width: 1
                width: 320
                height: 640
                anchors.left: connectscreen.right
                anchors.top: connectscreen.top;
                GridView
                {
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    //
                    // CONFIG  SCREEN
                    //
                    id: settingsview;
                    //visible: false;
                    y:0
                    width: parent.width
                    height: parent.height
                    Text
                    {
                        id: textLabelSettingsTitle
                        x:40
                        y:0
                        text: qsTr("SYSTEM INFO v0.1")
                        font.pixelSize: 20
                        font.bold: true
                        font.underline: true
                    }
                    Text
                    {
                        id: text1
                        x:0
                        y:textLabelSettingsTitle.y + 30
                        text: qsTr("Backlight: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textBacklightMain
                        text: theObject.BacklightMain
                        anchors.left: text1.right
                        y:text1.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onMainBacklightChanged(textBacklightMain.text);
                        }
                    }
                    Text
                    {
                        id: text2
                        x:0
                        y:textBacklightMain.y+20
                        text: qsTr("Current Song #: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textCurrentSong
                        text: theObject.currentSong
                        anchors.left: text2.right
                        y:text2.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onCurrentSongChanged(textCurrentSong.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop1
                        x:0
                        y:textCurrentSong.y+20
                        text: qsTr("Loop 1 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop1Name
                        text: theObject.LoopName1
                        anchors.left: textLabelLoop1.right
                        y:textLabelLoop1.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName1Changed(textLoop1Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop2
                        x:0
                        y:textLabelLoop1.y + 18
                        text: qsTr("Loop 2 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop2Name
                        text: theObject.LoopName2
                        anchors.left: textLabelLoop2.right
                        y:textLabelLoop2.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName2Changed(textLoop2Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop3
                        x:0
                        y:textLabelLoop2.y+18
                        text: qsTr("Loop 3 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop3Name
                        text: theObject.LoopName3
                        anchors.left: textLabelLoop3.right
                        y:textLabelLoop3.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName3Changed(textLoop3Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop4
                        x:0
                        y:textLabelLoop3.y+18
                        text: qsTr("Loop 4 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop4Name
                        text: theObject.LoopName4
                        anchors.left: textLabelLoop4.right
                        y:textLabelLoop4.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName4Changed(textLoop4Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop5
                        x:0
                        y:textLabelLoop4.y+18
                        text: qsTr("Loop 5 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop5Name
                        text: theObject.LoopName5
                        anchors.left: textLabelLoop5.right
                        y:textLabelLoop5.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName5Changed(textLoop5Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop6
                        x:0
                        y:textLabelLoop5.y+18
                        text: qsTr("Loop 6 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop6Name
                        text: theObject.LoopName6
                        anchors.left: textLabelLoop6.right
                        y:textLabelLoop6.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName6Changed(textLoop6Name.text);
                        }
                    }
                    Text
                    {
                        id: textLabelLoop7
                        x:0
                        y:textLabelLoop6.y+18
                        text: qsTr("Loop 7 Name: ")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textLoop7Name
                        text: theObject.LoopName7
                        anchors.left: textLabelLoop7.right
                        y:textLabelLoop7.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onLoopName7Changed(textLoop7Name.text);
                        }
                    }

                    Text
                    {
                        id: textLabelFsw1
                        x:0
                        y:textLabelLoop7.y+24
                        text: qsTr("Fsw1 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw1
                        text: theObject.FswName1
                        anchors.left: textLabelFsw1.right
                        y:textLabelFsw1.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName1Changed(textNameFsw1.text);
                        }
                    }
                    Text
                    {
                        id: textLabelFsw2
                        x:0
                        y:textLabelFsw1.y+18
                        text: qsTr("Fsw2 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw2
                        text: theObject.FswName2
                        anchors.left: textLabelFsw2.right
                        y:textLabelFsw2.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName2Changed(textNameFsw2.text);
                        }
                    }
                    Text
                    {
                        id: textLabelFsw3
                        x:0
                        y:textLabelFsw2.y+18
                        text: qsTr("Fsw3 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw3
                        text: theObject.FswName3
                        anchors.left: textLabelFsw3.right
                        y:textLabelFsw3.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName3Changed(textNameFsw3.text);
                        }
                    }
                    Text
                    {
                        id: textLabelFsw4
                        x:0
                        y:textLabelFsw3.y+18
                        text: qsTr("Fsw4 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw4
                        text: theObject.FswName4
                        anchors.left: textLabelFsw4.right
                        y:textLabelFsw4.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName4Changed(textNameFsw4.text);
                        }
                    }
                    Text
                    {
                        id: textLabelFsw5
                        x:0
                        y:textLabelFsw4.y+18
                        text: qsTr("Fsw5 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw5
                        text: theObject.FswName5
                        anchors.left: textLabelFsw5.right
                        y:textLabelFsw5.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName5Changed(textNameFsw5.text);
                        }


                    }
                    Text
                    {
                        id: textLabelFsw6
                        x:0
                        y:textLabelFsw5.y+18
                        text: qsTr("Fsw6 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameFsw6
                        text: theObject.FswName6
                        anchors.left: textLabelFsw6.right
                        y:textLabelFsw6.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onFswName6Changed(textNameFsw6.text);
                        }
                    }

                    Text
                    {
                        id: textLabelAux1
                        x:0
                        y:textLabelFsw6.y+24
                        text: qsTr("Aux1 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameAux1
                        text: theObject.AuxName1
                        anchors.left: textLabelAux1.right
                        y:textLabelAux1.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onAuxName1Changed(textNameAux1.text);
                        }
                    }
                    Text
                    {
                        id: textLabelAux2
                        x:0
                        y:textLabelAux1.y+18
                        text: qsTr("Aux2 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameAux2
                        text: theObject.AuxName2
                        anchors.left: textLabelAux2.right
                        y:textLabelAux2.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onAuxName2Changed(textNameAux2.text);
                        }
                    }
                    Text
                    {
                        id: textLabelAux3
                        x:0
                        y:textLabelAux2.y+18
                        text: qsTr("Aux3 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameAux3
                        text: theObject.AuxName3
                        anchors.left: textLabelAux3.right
                        y:textLabelAux3.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onAuxName3Changed(textNameAux3.text);
                        }
                    }
                    Text
                    {
                        id: textLabelAux4
                        x:0
                        y:textLabelAux3.y+18
                        text: qsTr("Aux4 Name:")
                        font.pixelSize: 12
                    }
                    TextInput
                    {
                        id: textNameAux4
                        text: theObject.AuxName4
                        anchors.left: textLabelAux4.right
                        y:textLabelAux4.y
                        width: 150
                        height: 16
                        visible: true
                        font.pixelSize: 16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onAuxName4Changed(textNameAux4.text);
                        }
                    }

                    Button
                    {
                        id: buttonUpdateSettings
                        y:552
                        x:60
                        width: 200
                        //mdButton has longest text
                        height: 80
                        text: "Update Settings"
                        visible: true
                        onClicked: theObject.updateConfigDevice()
                    }
                }

                Rectangle
                {
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    // ////////////////////////////////////////////////////////////////////////
                    //
                    //  SONG  SCREEN
                    //
                    border.width: 1
                    width: 320
                    height: 640
                    anchors.left: settingsview.right
                    anchors.top: settingsview.top;
                    GridView
                    {
                        id: songview;
                        //visible: false;
                        y:0
                        width: 320
                        height: 640
                        Text
                        {
                            id: textLabelSongTitle
                            x:20
                            y:0
                            text: qsTr("SONG INFO for #") +  qsTr(theObject.currentSong)
                            font.pixelSize: 20
                            font.bold: true
                            font.underline: true
                        }
                        Text
                        {
                            id: textLabelSongName
                            x:0
                            y:textLabelSongTitle.y+30
                            text: qsTr("Name line 1: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textSongName
                            text: theObject.SongName
                            y:textLabelSongName.y+20
                            x:5
                            width: songview.width-10
                            //anchors.left: songview.left+10
                            anchors.top: textLabelSongName.bottom
                            height: 25
                            visible: true
                            font.pixelSize: 14
                            font.bold: true
                            maximumLength: 9
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongNameChanged(textSongName.text);
                            }
                        }
                        Text
                        {
                            id: textLabelPartName
                            x:100
                            y:textLabelSongName.y//+20
                            text: qsTr("Name line 2: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textPartName
                            text: theObject.PartName
                            y:textLabelPartName.y+20
                            x:105
                            width: songview.width-10
                            //anchors.left: songview.left+10
                            anchors.top: textLabelPartName.bottom
                            height: 25
                            visible: true
                            font.pixelSize: 14
                            font.bold: true
                            maximumLength: 9
                            wrapMode: TextInput.NoWrap
                            /*
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 14
                            maximumLength: 9
                            wrapMode: TextInput.NoWrap
                            */
                            onTextChanged:
                            {
                                theObject.onSongPartNameChanged(textPartName.text);
                            }
                        }
                        // ///////////////////////////////////////////
                        // THE MATRIX
                        Text
                        {
                            id: textLabelMatrix0
                            x:10
                            //y:100
                            anchors.top: textPartName.bottom
                            anchors.topMargin: 3
                            text: qsTr("Main out<---")
                            font.pixelSize: 12
                        }
                        ComboBox {
                            id: comboBox0
                            anchors.left: textLabelMatrix0.right
                            anchors.bottom: textLabelMatrix0.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList0
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix0Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix1
                            x:10
                            y:textLabelMatrix0.y+28
                            text: textLoop1Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox1
                            anchors.left: textLabelMatrix1.right
                            anchors.bottom: textLabelMatrix1.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList1
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix1Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix2
                            x:10
                            y:textLabelMatrix1.y+28
                            text: textLoop2Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox2
                            anchors.left: textLabelMatrix2.right
                            anchors.bottom: textLabelMatrix2.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList2
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix2Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix3
                            x:10
                            y:textLabelMatrix2.y+28
                            text: textLoop3Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox3
                            anchors.left: textLabelMatrix3.right
                            anchors.bottom: textLabelMatrix3.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList3
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix3Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix4
                            x:10
                            y:textLabelMatrix3.y+28
                            text: textLoop4Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox4
                            anchors.left: textLabelMatrix4.right
                            anchors.bottom: textLabelMatrix4.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList4
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix4Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix5
                            x:10
                            y:textLabelMatrix4.y+28
                            text: textLoop5Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox5
                            anchors.left: textLabelMatrix5.right
                            anchors.bottom: textLabelMatrix5.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList5
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix5Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix6
                            x:10
                            y:textLabelMatrix5.y+28
                            text: textLoop6Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox6
                            anchors.left: textLabelMatrix6.right
                            anchors.bottom: textLabelMatrix6.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList6
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix6Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix7
                            x:10
                            y:textLabelMatrix6.y+28
                            text: textLoop7Name.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox7
                            anchors.left: textLabelMatrix7.right
                            anchors.bottom: textLabelMatrix7.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList7
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix7Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix8
                            x:10
                            y:textLabelMatrix7.y+28
                            text: textNameAux1.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox8
                            anchors.left: textLabelMatrix8.right
                            anchors.bottom: textLabelMatrix8.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList8
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix8Changed(currentText)
                            }
                        }

                        Text
                        {
                            id: textLabelMatrix9
                            x:10
                            y:textLabelMatrix8.y+28
                            text: textNameAux2.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox9
                            anchors.left: textLabelMatrix9.right
                            anchors.bottom: textLabelMatrix9.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList9
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix9Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix10
                            x:10
                            y:textLabelMatrix9.y+28
                            text: textNameAux3.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox10
                            anchors.left: textLabelMatrix10.right
                            anchors.bottom: textLabelMatrix10.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList10
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix10Changed(currentText)
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix11
                            x:10
                            y:textLabelMatrix10.y+28
                            text: textNameAux4.text + qsTr(" <--- ");
                            font.pixelSize: 12
                        }
                        ComboBox
                        {
                            id: comboBox11
                            anchors.left: textLabelMatrix11.right
                            anchors.bottom: textLabelMatrix11.bottom
                            anchors.bottomMargin: -3
                            width: 150
                            model: theObject.comboList11
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix11Changed(currentText)
                            }
                        }
                        /////////////////////////////////////////////////////////////////////////////
                        //MIDI
                        Text
                        {
                            id: textLabelMidiMsg1
                            x:10
                            y:425
                            text: qsTr("MIDI Msg 1: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textMidiMsg1
                            text: theObject.MidiMsg1
                            y:textLabelMidiMsg1.y
                            anchors.left: textLabelMidiMsg1.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg1Changed(textMidiMsg1.text);
                            }
                        }

                        /*
                        Text
                        {
                            id: textLabelMidiMsg2
                            x:10
                            y:textMidiMsg1.y+18
                            text: qsTr("MIDI Msg 2: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textMidiMsg2
                            text: theObject.MidiMsg2
                            y:textLabelMidiMsg2.y
                            anchors.left: textLabelMidiMsg2.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg2Changed(textMidiMsg2.text);
                            }
                        }

                        Text
                        {
                            id: textLabelMidiMsg3
                            x:10
                            y:textMidiMsg2.y+18
                            text: qsTr("MIDI Msg 3: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textMidiMsg3
                            text: theObject.MidiMsg3
                            y:textLabelMidiMsg3.y
                            anchors.left: textLabelMidiMsg3.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg3Changed(textMidiMsg3.text);
                            }
                        }

                        Text
                        {
                            id: textLabelMidiMsg4
                            x:10
                            y:textMidiMsg3.y+18
                            text: qsTr("MIDI Msg 4: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textMidiMsg4
                            text: theObject.MidiMsg4
                            y:textLabelMidiMsg4.y
                            anchors.left: textLabelMidiMsg4.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg4Changed(textMidiMsg4.text);
                            }
                        }
                        */
                        Text
                        {
                            id: textLabelMidiMode
                            x:10
                            y:textMidiMsg1.y+18
                            text: qsTr("MIDI Mode: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textMidiMode
                            text: theObject.MidiMode
                            y:textLabelMidiMode.y
                            anchors.left: textLabelMidiMode.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiModeChanged(textMidiMode.text);
                            }
                        }
                        Text
                        {
                            id: textLabelSongFsw
                            x:10
                            y:textMidiMode.y+18
                            text: qsTr("Footswitch Config: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textSongFsw
                            text: theObject.FswSongConfig
                            y:textLabelSongFsw.y
                            anchors.left: textLabelSongFsw.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongFswChanged(textSongFsw.text);
                            }
                        }
                        Text
                        {
                            id: textLabelSongBacklight
                            x:10
                            y:textSongFsw.y+18
                            text: qsTr("Backlight(song): ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textSongBacklight
                            text: theObject.SongBacklight
                            y:textLabelSongBacklight.y
                            anchors.left: textLabelSongBacklight.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongBacklightChanged(textSongBacklight.text);
                            }
                        }

                        Text
                        {
                            id: textLabelTrickMode
                            x:10
                            y:textLabelSongBacklight.y+18
                            text: qsTr("Trick Mode: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textTrickMode
                            text: theObject.TrickMode
                            y:textLabelTrickMode.y
                            anchors.left: textLabelTrickMode.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onTrickModeChanged(textTrickMode.text);
                            }
                        }

                        Text
                        {
                            id: textLabelTrickData
                            x:10
                            y:textTrickMode.y+18
                            text: qsTr("Trick Data: ")
                            font.pixelSize: 12
                        }
                        TextInput
                        {
                            id: textTrickData
                            text: theObject.TrickData
                            y:textLabelTrickData.y
                            anchors.left: textLabelTrickData.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: 12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onTrickDataChanged(textTrickData.text);
                            }
                        }


                        Button
                        {
                            id: buttonPreviousSong
                            y:552
                            x:0
                            width: 120
                            //mdButton has longest text
                            height: 80
                            text: "Previous Song"
                            visible: true
                            onClicked: theObject.selectPreviousSong()
                        }
                        Button
                        {
                            id: buttonUpdateSong
                            y:552
                            anchors.horizontalCenter: songview.horizontalCenter
                            anchors.horizontalCenterOffset: 20
                            width: 100
                            //mdButton has longest text
                            height: 80
                            text: "Update Song"
                            visible: true
                            onClicked: theObject.updateSongDevice()
                        }
                        Button
                        {
                            id: buttonNextSong
                            y:552
                            anchors.right: parent.right
                            width: 80
                            //mdButton has longest text
                            height: 80
                            text: "Next Song"
                            visible: true
                            onClicked: theObject.selectNextSong()
                        }
                    }
                }
            }
        }
    }

}

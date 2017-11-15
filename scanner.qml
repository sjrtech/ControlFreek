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
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.0

Item
{
    //id: top

    property BluetoothService currentService
    property int nScratch

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
        property int windowWidth:parent.width
        width: windowWidth//640//320
        height: parent.height
        Flickable {
            anchors.fill: parent
            //contentWidth: mainwindow.windowWidth+(mainwindow.windowWidth/2)//1380-640+parent.width
            contentWidth: mainwindow.windowWidth*2
            contentHeight: parent.height
            Rectangle
            {
                // ////////////////////////////////////////////////////////////////////////
                // BLE CONNECTION SCREEN
                id:connectscreen
                anchors.left: parent.left
                anchors.leftMargin: 0
                //anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top;
                width: mainwindow.windowWidth/2
                height: parent.height
                border.width: 1
                color: "#66b2ff"
                Rectangle
                {
                    id: busy

                    width: parent.width * 0.7;
                    anchors.horizontalCenter: connectscreen.horizontalCenter
                    //anchors.top: top.top;
                    anchors.top: connectscreen.top;
                    height: textTHING.height*1.2;
                    radius: 5
                    color: "#1c56f3"
                    visible: btModel.running

                    Text
                    {
                        id: textTHING
                        text: "Scanning"
                        font.bold: true
                        font.pointSize: 20
                        anchors.centerIn: parent
                    }

                    SequentialAnimation on color
                    {
                        id: busyThrobber
                        ColorAnimation { easing.type: Easing.InOutSine; from: "#1c56f3"; to: "white"; duration: 300; }//parent.height; }
                        ColorAnimation { easing.type: Easing.InOutSine; to: "#1c56f3"; from: "white"; duration: 300 }//parent.height }
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
                        color: "#66b2ff"

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
                                font.pointSize: 20//16
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
                                font.pointSize: 24//18//14
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
                width: mainwindow.windowWidth/2
                height: parent.height
                anchors.left: connectscreen.right
                anchors.top: connectscreen.top;
                color: "#ff9933"
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
                        text: qsTr("SYSTEM INFO v0.7")
                        font.pixelSize: parent.height*0.0175//20
                        font.bold: true
                        font.underline: true
                    }
                    Text
                    {
                        id: text1
                        x:2
                        y:textLabelSettingsTitle.y + 20
                        text: qsTr("Backlight: ")
                        visible: false
                        font.pixelSize: parent.height*0.0175//18//16//12
                    }
                    /*
                    TextInput
                    {
                        id: textBacklightMain
                        text: theObject.BacklightMain
                        anchors.left: text1.right
                        y:text1.y
                        width: parent.width/2//250//150
                        height: 20//16
                        visible: false
                        font.pixelSize: parent.height*0.0175//20//16
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
                        x:2
                        y:textBacklightMain.y+20
                        text: qsTr("Current Song #: ")
                        font.pixelSize: parent.height*0.0175//18//16//12
                        visible: false
                    }
                    TextInput
                    {
                        id: textCurrentSong
                        text: theObject.currentSong
                        anchors.left: text2.right
                        y:text2.y
                        width: parent.width/2//250//150
                        height: 20//16
                        visible: false
                        font.pixelSize: parent.height*0.0175//20//16
                        font.bold: true
                        maximumLength: 11
                        wrapMode: TextInput.NoWrap
                        onTextChanged:
                        {
                            theObject.onCurrentSongChanged(textCurrentSong.text);
                        }
                    }
                    */
                    Text
                    {
                        id: textLabelLoop1
                        x:2
                        y:textLabelMatrix1.y //textCurrentSong.y+50
                        text: qsTr("Loop 1 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop1.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop1.right
                        anchors.leftMargin: 1
                        width: mainwindow.windowWidth/5
                        id: textLoop1Name
                        text: theObject.LoopName1
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName1Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix1.visible = false;
                                comboBox1.visible = false;
                            }
                            else
                            {
                                textLabelMatrix1.visible = true;
                                comboBox1.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }
                    Text
                    {
                        id: textLabelLoop2
                        x:2
                        y:textLabelMatrix2.y
                        text: qsTr("Loop 2 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop2.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop2.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width
                        id: textLoop2Name
                        text: theObject.LoopName2
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName2Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix2.visible = false;
                                comboBox2.visible = false;
                            }
                            else
                            {
                                textLabelMatrix2.visible = true;
                                comboBox2.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelLoop3
                        x:2
                        y:textLabelMatrix3.y
                        text: qsTr("Loop 3 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop3.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop3.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width
                        id: textLoop3Name
                        text: theObject.LoopName3
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName3Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix3.visible = false;
                                comboBox3.visible = false;
                            }
                            else
                            {
                                textLabelMatrix3.visible = true;
                                comboBox3.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelLoop4
                        x:2
                        y:textLabelMatrix4.y
                        text: qsTr("Loop 4 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop4.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop4.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textLoop4Name
                        text: theObject.LoopName4
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName4Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix4.visible = false;
                                comboBox4.visible = false;
                            }
                            else
                            {
                                textLabelMatrix4.visible = true;
                                comboBox4.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelLoop5
                        x:2
                        y:textLabelMatrix5.y
                        text: qsTr("Loop 5 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop5.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop5.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textLoop5Name
                        text: theObject.LoopName5
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName5Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix5.visible = false;
                                comboBox5.visible = false;
                            }
                            else
                            {
                                textLabelMatrix5.visible = true;
                                comboBox5.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelLoop6
                        x:2
                        y:textLabelMatrix6.y
                        text: qsTr("Loop 6 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop6.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop6.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textLoop6Name
                        text: theObject.LoopName6
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName6Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix6.visible = false;
                                comboBox6.visible = false;
                            }
                            else
                            {
                                textLabelMatrix6.visible = true;
                                comboBox6.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelLoop7
                        x:2
                        y:textLabelMatrix7.y
                        text: qsTr("Loop 7 Name: ")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelLoop7.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelLoop7.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textLoop7Name
                        text: theObject.LoopName7
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onLoopName7Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix7.visible = false;
                                comboBox7.visible = false;
                            }
                            else
                            {
                                textLabelMatrix7.visible = true;
                                comboBox7.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelAux1
                        x:2
                        y:textLabelMatrix8.y
                        //anchors.top: textLabelMatrix8.top
                        text: qsTr("Aux1 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelAux1.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelAux1.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textAux1Name
                        text: theObject.AuxName1
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onAuxName1Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix8.visible = false;
                                comboBox8.visible = false;
                            }
                            else
                            {
                                textLabelMatrix8.visible = true;
                                comboBox8.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelAux2
                        x:2
                        y:textLabelMatrix9.y
                        text: qsTr("Aux2 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelAux2.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelAux2.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textAux2Name
                        text: theObject.AuxName2
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onAuxName2Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix9.visible = false;
                                comboBox9.visible = false;
                            }
                            else
                            {
                                textLabelMatrix9.visible = true;
                                comboBox9.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelAux3
                        x:2
                        y:textLabelMatrix10.y
                        text: qsTr("Aux3 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelAux3.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelAux3.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textAux3Name
                        text: theObject.AuxName3
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onAuxName3Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix10.visible = false;
                                comboBox10.visible = false;
                            }
                            else
                            {
                                textLabelMatrix10.visible = true;
                                comboBox10.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelAux4
                        x:2
                        y:textLabelMatrix11.y
                        text: qsTr("Aux4 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelAux4.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelAux4.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textAux4Name
                        text: theObject.AuxName4
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onAuxName4Changed(text);
                            if(text.length <= 0)
                            {
                                textLabelMatrix11.visible = false;
                                comboBox11.visible = false;
                            }
                            else
                            {
                                textLabelMatrix11.visible = true;
                                comboBox11.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw1
                        x:2
                        //y:textLabelSongFsw.y
                        anchors.top: textLabelAux4.bottom
                        anchors.topMargin: mainwindow.height/50
                        text: qsTr("Fsw1 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw1.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw1.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw1
                        text: theObject.FswName1
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName1Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw1.visible = false;
                            }
                            else
                            {
                                checkBoxFsw1.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw2
                        x:2
                        y:textLabelFsw1.y+60
                        text: qsTr("Fsw2 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw2.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw2.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw2
                        text: theObject.FswName2
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName2Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw2.visible = false;
                            }
                            else
                            {
                                checkBoxFsw2.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw3
                        x:2
                        y:textLabelFsw2.y+60
                        text: qsTr("Fsw3 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw3.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw3.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw3
                        text: theObject.FswName3
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName3Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw3.visible = false;
                            }
                            else
                            {
                                checkBoxFsw3.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw4
                        x:2
                        y:textLabelFsw3.y+60
                        text: qsTr("Fsw4 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw4.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw4.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw4
                        text: theObject.FswName4
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName4Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw4.visible = false;
                            }
                            else
                            {
                                checkBoxFsw4.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw5
                        x:2
                        y:textLabelFsw4.y+60
                        text: qsTr("Fsw5 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw5.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw5.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw5
                        text: theObject.FswName5
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName5Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw5.visible = false;
                            }
                            else
                            {
                                checkBoxFsw5.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Text
                    {
                        id: textLabelFsw6
                        x:2
                        y:textLabelFsw5.y+60
                        text: qsTr("Fsw6 Name:")
                        font.pixelSize: parent.height*0.0175//20//16
                    }
                    TextField
                    {
                        placeholderText: "type here..."
                        anchors.bottom: textLabelFsw6.bottom
                        anchors.bottomMargin: 0
                        anchors.left: textLabelFsw6.right
                        anchors.leftMargin: 1
                        width: textLoop1Name.width

                        id: textNameFsw6
                        text: theObject.FswName6
                        font.pixelSize: parent.height*0.0175//24//18//14
                        font.bold: true
                        maximumLength: 11
                        onTextChanged:
                        {
                            theObject.onFswName6Changed(text);
                            if(text.length <= 0)
                            {
                                checkBoxFsw6.visible = false;
                            }
                            else
                            {
                                checkBoxFsw6.visible = true;
                            }
                        }
                        style:
                            TextFieldStyle
                            {
                                textColor: "black"
                                background:
                                    Rectangle
                                    {
                                        radius: 5
                                        color: "light blue"
                                        implicitWidth: 90
                                        implicitHeight: mainwindow.height/37//25
                                        border.color: "#333"
                                        border.width: 1
                                    }
                            }
                    }

                    Button
                    {
                        id: buttonUpdateSettings
                        //y:552
                        //x:60
                        //width: 200
                        //height: 80
                        width: mainwindow.windowWidth/2-30
                        height: mainwindow.height/10
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 5
                        anchors.bottom: parent.bottom
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
                    id: rectSong
                    objectName: "rectSongWindow"
                    border.width: 1
                    width: mainwindow.windowWidth//620//320
                    height: parent.height
                    anchors.left: settingsview.right
                    anchors.top: settingsview.top;
                    color: "#30c0e0"
                    GridView
                    {
                        id: songview;
                        //visible: false;
                        y:0
                        width: parent.width
                        height: parent.height
                        Text
                        {
                            id: textLabelSongTitle
                            x:80
                            y:0
                            text: qsTr("SONG INFO (#") +  qsTr(theObject.currentSong) +qsTr(")")
                            //text: qsTr("SONG INFO")
                            font.pixelSize: parent.height*0.0175//20
                            font.bold: true
                            font.underline: true
                        }

                        Text
                        {
                            id: textLabelSongName
                            x:2
                            //y:textLabelSongTitle.y+mainwindow.height/50
                            anchors.top: textLabelSongTitle.bottom
                            anchors.topMargin: 10
                            text: qsTr("Name line 1: ")
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        TextField
                        {
                            id: textSongName
                            placeholderText: "type here..."
                            anchors.bottom: textLabelSongName.bottom
                            anchors.left: textLabelSongName.right
                            width: 250
                            text: theObject.SongName
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            onTextChanged:
                            {
                                theObject.onSongNameChanged(textSongName.text);
                            }
                            style:
                                TextFieldStyle
                                {
                                    textColor: "black"
                                    background:
                                        Rectangle
                                        {
                                            radius: 5
                                            color: "light blue"
                                            implicitWidth: 90
                                            implicitHeight: mainwindow.height/37//30//25
                                            border.color: "#333"
                                            border.width: 1
                                        }
                                }
                        }
                        /*
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
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongNameChanged(textSongName.text);
                            }
                        }
                        */
                        Text
                        {
                            id: textLabelPartName
                            anchors.left: textSongName.right
                            y:textLabelSongName.y//+20
                            text: qsTr("Name line 2: ")
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        TextField
                        {
                            placeholderText: "type here..."
                            anchors.bottom: textSongName.bottom//y:textLabelPartName.y+20//16
                            anchors.left: textLabelPartName.right
                            width: 250
                            id: textPartName
                            text: theObject.PartName
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            onTextChanged:
                            {
                                theObject.onSongPartNameChanged(textPartName.text);
                            }
                            style:
                                TextFieldStyle
                                {
                                    textColor: "black"
                                    background:
                                        Rectangle
                                        {
                                            radius: 5
                                            color: "light blue"
                                            implicitWidth: 90
                                            implicitHeight: mainwindow.height/37//30//25
                                            border.color: "#333"
                                            border.width: 1
                                        }
                                }
                        }
                        /*
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
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongPartNameChanged(textPartName.text);
                            }
                        }
                        */
                        // ///////////////////////////////////////////
                        // THE MATRIX
                        Text
                        {
                            id: textLabelMatrix0
                            x:10
                            //y:100
                            anchors.top: textPartName.bottom
                            anchors.topMargin: mainwindow.height/37//17//5
                            text: qsTr("Main out<---")
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox {
                            id: comboBox0
                            anchors.left: textLabelMatrix0.right
                            anchors.bottom: textLabelMatrix0.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//parent.width/2//250//150
                            model: theObject.comboList0
                            editable: false
                            onCurrentIndexChanged:
                            {
                                //theObject.onMatrix0Changed(currentText)
                                theObject.onMatrix0Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo0_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix1
                            x:10
                            visible: false
                            //y:textLabelMatrix0.y+40
                            anchors.top: textLabelMatrix0.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textLoop1Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox1
                            anchors.left: textLabelMatrix1.right
                            anchors.bottom: textLabelMatrix1.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            visible: false
                            model: theObject.comboList1
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix1Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo1_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix2
                            x:10
                            //y:textLabelMatrix1.y+mainwindow.height/25//40
                            anchors.top: textLabelMatrix1.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            visible: false
                            text: textLoop2Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox2
                            anchors.left: textLabelMatrix2.right
                            anchors.bottom: textLabelMatrix2.bottom
                            anchors.bottomMargin: -3
                            visible: false
                            width: parent.width/2//250//150
                            model: theObject.comboList2
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix2Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo2_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix3
                            x:10
                            visible: false
                            //y:textLabelMatrix2.y+mainwindow.height/25//40
                            anchors.top: textLabelMatrix2.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textLoop3Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox3
                            anchors.left: textLabelMatrix3.right
                            anchors.bottom: textLabelMatrix3.bottom
                            visible: false
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList3
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix3Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo3_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix4
                            x:10
                            //y:textLabelMatrix3.y+mainwindow.height/25//40
                            anchors.top: textLabelMatrix3.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            visible: false
                            text: textLoop4Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox4
                            anchors.left: textLabelMatrix4.right
                            anchors.bottom: textLabelMatrix4.bottom
                            anchors.bottomMargin: -3
                            visible: false
                            width: parent.width/2//250//150
                            model: theObject.comboList4
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix4Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo4_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix5
                            x:10
                            visible: false
                            //y:textLabelMatrix4.y+40
                            anchors.top: textLabelMatrix4.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textLoop5Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox5
                            anchors.left: textLabelMatrix5.right
                            visible: false
                            anchors.bottom: textLabelMatrix5.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList5
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix5Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo5_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix6
                            x:10
                            visible: false
                            //y:textLabelMatrix5.y+40
                            anchors.top: textLabelMatrix5.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textLoop6Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox6
                            anchors.left: textLabelMatrix6.right
                            visible: false
                            anchors.bottom: textLabelMatrix6.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList6
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix6Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo6_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix7
                            x:10
                            //y:textLabelMatrix6.y+40
                            anchors.top: textLabelMatrix6.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textLoop7Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                            visible: false
                        }
                        ComboBox
                        {
                            id: comboBox7
                            anchors.left: textLabelMatrix7.right
                            visible: false
                            anchors.bottom: textLabelMatrix7.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList7
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix7Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo7_index} )
                            }
                        }
                        /////////////////////////////////////////////////////////////////////////////
                        //  AUX
                        Text
                        {
                            id: textLabelMatrix8
                            x:10
                            visible: false
                            //y:textLabelMatrix7.y+45
                            anchors.top: textLabelMatrix7.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textAux1Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox8
                            anchors.left: textLabelMatrix8.right
                            anchors.bottom: textLabelMatrix8.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            visible: false
                            model: theObject.comboList8
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix8Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo8_index} )
                            }
                        }

                        Text
                        {
                            id: textLabelMatrix9
                            x:10
                            //y:textLabelMatrix8.y+40
                            anchors.top: textLabelMatrix8.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            visible: false
                            text: textAux2Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox9
                            anchors.left: textLabelMatrix9.right
                            anchors.bottom: textLabelMatrix9.bottom
                            visible: false
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList9
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix9Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo9_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix10
                            x:10
                            visible: false
                            //y:textLabelMatrix9.y+40
                            anchors.top: textLabelMatrix9.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: textAux3Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox10
                            anchors.left: textLabelMatrix10.right
                            anchors.bottom: textLabelMatrix10.bottom
                            visible: false
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboList10
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix10Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo10_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelMatrix11
                            x:10
                            //y:textLabelMatrix10.y+40
                            anchors.top: textLabelMatrix10.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            visible: false
                            text: textAux4Name.text + qsTr(" <--- ");
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBox11
                            anchors.left: textLabelMatrix11.right
                            anchors.bottom: textLabelMatrix11.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            visible: false
                            model: theObject.comboList11
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMatrix11Changed(currentIndex.toString())
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.Combo11_index} )
                            }
                        }
                        /*
                        /////////////////////////////////////////////////////////////////////////////
                        //MIDI
                        Text
                        {
                            id: textLabelMidiMsg1
                            x:10
                            y:textLabelMatrix11.y+40
                            text: qsTr("MIDI Msg: ")
                            font.pixelSize: parent.height*0.0175//18//16//12
                            visible: false
                        }
                        TextField
                        {
                            placeholderText: "type here..."
                            //x:5
                            width: 140
                            id: textMidiMsg1
                            text: theObject.MidiMsg1
                            y:textLabelMidiMsg1.y
                            anchors.left: textLabelMidiMsg1.right
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            visible: false
                            onTextChanged:
                            {
                                theObject.onMidiMsg1Changed(text);
                            }
                            style:
                                TextFieldStyle
                                {
                                    textColor: "black"
                                    background:
                                        Rectangle
                                        {
                                            radius: 5
                                            color: "light blue"
                                            implicitWidth: 90
                                            implicitHeight: mainwindow.height/37//25
                                            border.color: "#333"
                                            border.width: 1
                                        }
                                }
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
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg1Changed(textMidiMsg1.text);
                            }
                        }
                        */
                        /*
                        Text
                        {
                            id: textLabelMidiMsg2
                            x:10
                            y:textMidiMsg1.y+18
                            text: qsTr("MIDI Msg 2: ")
                            font.pixelSize: parent.height*0.0175//18//16//12
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
                            font.pixelSize: parent.height*0.0175//18//16//12
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
                            font.pixelSize: parent.height*0.0175//18//16//12
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
                            font.pixelSize: parent.height*0.0175//18//16//12
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
                            font.pixelSize: parent.height*0.0175//18//16//12
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
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiMsg4Changed(textMidiMsg4.text);
                            }
                        }
                        */
                        /*
                        Text
                        {
                            id: textLabelMidiMode
                            x:10
                            y:textMidiMsg1.y+18
                            text: qsTr("MIDI Mode: ")
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBoxMidiMode
                            anchors.left: textLabelMidiMode.right
                            anchors.bottom: textLabelMidiMode.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboListMidiMode
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onMidiModeChanged(currentText);
                            }
                        }
                        */
                        /*
                        TextInput
                        {
                            id: textMidiMode
                            text: theObject.MidiMode
                            y:textLabelMidiMode.y
                            anchors.left: textLabelMidiMode.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onMidiModeChanged(textMidiMode.text);
                            }
                        }
                        */
                        Text
                        {
                            id: textLabelSongFsw
                            x:10
                            anchors.top: textLabelMatrix11.bottom
                            anchors.topMargin: mainwindow.height/100//5
                            //y:textLabelMatrix11.y+35
                            text: qsTr("Footswitch Outputs (FORCE ON): ")
                            font.pixelSize: parent.height*0.0175//18//16//12
                        }
                        CheckBox {
                            id: checkBoxFsw1
                            x: textLabelSongFsw.x
                            anchors.top: textLabelSongFsw.bottom
                            //anchors.topMargin: 1
                            visible: false
                            text: textNameFsw1.text
                            onCheckedChanged: theObject.fswOneCheckChanged(checkedState);
                            checkedState:theObject.fswSong1CheckedState

                        }
                        CheckBox {
                            id: checkBoxFsw2
                            x: checkBoxFsw1.x
                            anchors.top: checkBoxFsw1.bottom
                            anchors.topMargin: -40
                            visible: false
                            text: textNameFsw2.text
                            onCheckedChanged: theObject.fswTwoCheckChanged(checkedState);
                            onParentChanged:
                            {
                                nScratch = Qt.binding( function(){return theObject.fswSong2CheckedState} );
                            }
                            checkedState:nScratch
                        }
                        CheckBox {
                            id: checkBoxFsw3
                            anchors.left: checkBoxFsw1.right
                            visible: false
                            anchors.leftMargin: 5
                            anchors.top: checkBoxFsw1.top
                            text: textNameFsw3.text
                            onCheckedChanged: theObject.fswThreeCheckChanged(checkedState);
                            onParentChanged:
                            {
                                nScratch = Qt.binding( function(){return theObject.fswSong3CheckedState} );
                            }
                            checkedState:nScratch
                        }
                        CheckBox {
                            id: checkBoxFsw4
                            anchors.left: checkBoxFsw2.right
                            anchors.leftMargin: 5
                            visible: false
                            anchors.top: checkBoxFsw2.top
                            text: textNameFsw4.text
                            onCheckedChanged: theObject.fswFourCheckChanged(checkedState);
                            onParentChanged:
                            {
                                nScratch = Qt.binding( function(){return theObject.fswSong4CheckedState} );
                            }
                            checkedState:nScratch
                        }
                        CheckBox {
                            id: checkBoxFsw5
                            visible: false
                            anchors.left: checkBoxFsw3.right
                            anchors.leftMargin: 5
                            anchors.top: checkBoxFsw1.top
                            text: textNameFsw5.text
                            onCheckedChanged: theObject.fswFiveCheckChanged(checkedState);
                            onParentChanged:
                            {
                                nScratch = Qt.binding( function(){return theObject.fswSong5CheckedState} );
                            }
                            checkedState:nScratch
                        }
                        CheckBox {
                            id: checkBoxFsw6
                            anchors.left: checkBoxFsw4.right
                            anchors.leftMargin: 5
                            anchors.top: checkBoxFsw2.top
                            visible: false
                            text: textNameFsw6.text
                            onCheckedChanged: theObject.fswSixCheckChanged(checkedState);
                            onParentChanged:
                            {
                                nScratch = Qt.binding( function(){return theObject.fswSong6CheckedState} );
                            }
                            checkedState:nScratch
                        }
                        /*
                        TextInput
                        {
                            id: textSongFsw
                            text: theObject.FswSongConfig
                            y:textLabelSongFsw.y
                            anchors.left: textLabelSongFsw.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onSongFswChanged(textSongFsw.text);
                            }
                        }
                        */
                        Text
                        {
                            id: textLabelSongBacklight
                            x:10
                            anchors.top: checkBoxFsw2.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            text: qsTr("Backlight(song): ")
                            font.pixelSize: parent.height*0.02//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBoxSongBacklight
                            anchors.left: textLabelSongBacklight.right
                            anchors.bottom: textLabelSongBacklight.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//150
                            model: theObject.comboListBacklight
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onSongBacklightChanged(currentText)
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.ComboBacklight_index} )
                            }
                        }


                        Text
                        {
                            id: textLabelTrickMode
                            x:10
                            anchors.top: textLabelSongBacklight.bottom
                            anchors.topMargin: mainwindow.height/50//5
                            //textLabelSongBacklight.y+18
                            text: qsTr("Trick Shot Mode: ")
                            font.pixelSize: parent.height*0.02//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBoxTrickMode
                            anchors.left: textLabelTrickMode.right
                            anchors.bottom: textLabelTrickMode.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//1
                            model: theObject.comboListTrickMode1
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onTrickMode1Changed(currentIndex)
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.ComboTrickMode1_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelTrickData
                            x:10
                            anchors.top: textLabelTrickMode.bottom
                            anchors.topMargin: mainwindow.height/200//5
                            text: qsTr("Trick Shot Data: ")
                            font.pixelSize: parent.height*0.02//18//16//12
                        }
                        TextField
                        {
                            placeholderText: "type here..."
                            x:5
                            width: 140
                            id: textTrickData
                            text: theObject.TrickData1
                            y:textLabelTrickData.y
                            anchors.left: textLabelTrickData.right
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            onTextChanged:
                            {
                                theObject.onTrickData1Changed(text);
                            }
                            style:
                                TextFieldStyle
                                {
                                    textColor: "black"
                                    background:
                                        Rectangle
                                        {
                                            radius: 5
                                            color: "light blue"
                                            implicitWidth: 90
                                            implicitHeight: mainwindow.height/37//25
                                            border.color: "#333"
                                            border.width: 1
                                        }
                                }
                        }
                        /*
                        TextInput
                        {
                            id: textTrickData
                            text: theObject.TrickData1
                            anchors.top : textLabelTrickData.top
                            anchors.topMargin: 0
                            anchors.left: textLabelTrickData.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onTrickData1Changed(text);
                            }
                        }
                        */
                        Text
                        {
                            id: textLabelDiveBombMode
                            x:10
                            anchors.top : textLabelTrickData.bottom
                            anchors.topMargin: mainwindow.height/30//5
                            text: qsTr("Dive Bomb Mode: ")
                            font.pixelSize: parent.height*0.02//18//16//12
                        }
                        ComboBox
                        {
                            id: comboBoxDiveBombMode
                            anchors.left: textLabelDiveBombMode.right
                            anchors.bottom: textLabelDiveBombMode.bottom
                            anchors.bottomMargin: -3
                            width: parent.width/2//250//1
                            model: theObject.comboListTrickMode2
                            editable: false
                            onCurrentIndexChanged:
                            {
                                theObject.onTrickMode2Changed(currentIndex)
                            }
                            onModelChanged: {
                                 currentIndex = Qt.binding( function(){return theObject.ComboTrickMode2_index} )
                            }
                        }
                        Text
                        {
                            id: textLabelDiveBombData
                            x:10
                            anchors.top : textLabelDiveBombMode.bottom
                            anchors.topMargin: mainwindow.height/200//5
                            text: qsTr("Dive Bomb Data: ")
                            font.pixelSize: parent.height*0.02//18//16//12
                        }
                        TextField
                        {
                            placeholderText: "type here..."
                            x:5
                            width: 140
                            id: textDiveBombData
                            text: theObject.TrickData2
                            y:textLabelDiveBombData.y
                            anchors.left: textLabelDiveBombData.right
                            font.pixelSize: parent.height*0.0175//24//18//14
                            font.bold: true
                            maximumLength: 9
                            onTextChanged:
                            {
                                theObject.onTrickData2Changed(text);
                            }
                            style:
                                TextFieldStyle
                                {
                                    textColor: "black"
                                    background:
                                        Rectangle
                                        {
                                            radius: 5
                                            color: "light blue"
                                            implicitWidth: 90
                                            implicitHeight: mainwindow.height/37//25
                                            border.color: "#333"
                                            border.width: 1
                                        }
                                }
                        }
                        /*
                        TextInput
                        {
                            id: textDiveBombData
                            text: theObject.TrickData1
                            y:textLabelDiveBombData.y
                            anchors.left: textLabelDiveBombData.right
                            width: top.width-10
                            height: 25
                            visible: true
                            font.pixelSize: parent.height*0.0175//18//16//12
                            maximumLength: 31
                            wrapMode: TextInput.NoWrap
                            onTextChanged:
                            {
                                theObject.onTrickData2Changed(text);
                            }
                        }
                        */

                        Button
                        {
                            id: buttonPreviousSong
                            anchors.top: textDiveBombData.bottom
                            //anchors.topMargin: mainwindow.height/50//5
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            //anchors.bottomMargin: 5
                            width: mainwindow.windowWidth/6
                            height: mainwindow.height/15
                            text: "<<"
                            visible: true
                            onClicked: {
                                theObject.selectPreviousSong()
                            }
                        }
                        Button
                        {
                            id: buttonUpdateSong
                            anchors.top: buttonPreviousSong.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            //anchors.bottomMargin: 5
                            anchors.horizontalCenterOffset: 20
                            width: mainwindow.windowWidth/2+20
                            height: mainwindow.height/15
                            text: "Update to Device"
                            visible: true
                            onClicked: theObject.updateSongDevice()
                        }
                        Button
                        {
                            id: buttonNextSong
                            anchors.top: buttonPreviousSong.top
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            width: mainwindow.windowWidth/6
                            height: mainwindow.height/15
                            text: ">>"
                            visible: true
                            onClicked: theObject.selectNextSong()
                        }
                        Rectangle
                        {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            anchors.left: parent.left
                            anchors.leftMargin: 1
                            width: parent.width - 2
                            height:  mainwindow.height/15
                            border.width: 2
                            Label
                            {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "LOCAL \nBACKUP"
                                font.pixelSize: mainwindow.height*0.02

                            }

                            Button
                            {
                                id: buttonSaveSong
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.left: parent.left
                                anchors.leftMargin: 3
                                width: parent.width/3+50
                                height: parent.height-4
                                text: "Backup Song"
                                visible: true
                                onClicked: theObject.saveSong()
                            }
                            Button
                            {
                                id: buttonRestoreSong
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.right: parent.right
                                anchors.rightMargin: 3
                                width: parent.width/3+50
                                height: parent.height-4
                                text: "Restore Song"
                                visible: true
                                //onClicked: theObject.restoreSong()
                                onClicked: {
                                    fileDialog.visible = true
                                    //testSetupController.loadScript();
                                }
                                FileDialog {
                                    id: fileDialog
                                    title: "Please choose a file"
                                    onAccepted: {
                                        console.log("You chose: " + fileDialog.fileUrls)
                                        //Qt.quit()
                                        //testSetupController.loadScript(fileDialog.fileUrls);
                                        theObject.restoreSong(fileDialog.fileUrls);
                                    }
                                    onRejected: {
                                        console.log("Canceled")
                                        //Qt.quit()
                                    }
                                    Component.onCompleted: visible = false
                                    folder: shortcuts.home
                                }
                            }
                        }

                   }
                }
            }
        }
    }

}

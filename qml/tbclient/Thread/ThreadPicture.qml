import QtQuick 1.1
import com.nokia.symbian 1.1
import "../Component"
import "../Floor" as Floor
import "../../js/main.js" as Script

MyPage {
    id: page;

    property string threadId;
    property string forumName;
    onThreadIdChanged: internal.getlist();

    tools: ToolBarLayout {
        BackButton {}
        ToolButtonWithTip {
            toolTipText: qsTr("Refresh");
            iconSource: "toolbar-refresh";
            enabled: view.currentItem != null;
            onClicked: view.currentItem.getlist();
        }
        ToolButtonWithTip {
            toolTipText: qsTr("Reply");
            iconSource: "../../gfx/edit"+constant.invertedString+".svg";
            enabled: view.currentItem != null;
            onClicked: toolsArea.state = "Input";
        }
        ToolButtonWithTip {
            toolTipText: qsTr("Save");
            iconSource: "../../gfx/save"+constant.invertedString+".svg";
            enabled: view.currentItem != null;
        }
    }

    QtObject {
        id: internal;

        property variant forum: null;
        property int picAmount;

        function getlist(option){
            option = option||"renew";
            var opt = {
                page: internal,
                model: view.model,
                tid: threadId,
                kw: forum?forum.name:forumName
            };
            if (option == "renew"){
                opt.pic_id = "";
                opt.renew = true;
            } else {
                opt.pic_id = view.model.get(view.count-1).pic_id;
            }
            loading = true;
            function s(){ loading = false; }
            function f(err){ loading = false; signalCenter.showMessage(err); }
            Script.getPicturePage(opt, s, f);
        }

        function addPost(){
            var opt = {
                tid: threadId,
                fid: forum.id,
                quote_id: view.model.get(view.currentIndex).post_id,
                content: toolsArea.text,
                kw: forum.name
            }
            var c = view.currentItem;
            c.loading = true;
            var s = function(){
                if (c) {
                    c.loading = false;
                    c.getlist();
                }
                signalCenter.showMessage(qsTr("Success"));
                toolsArea.text = "";
                toolsArea.state = "";
            }
            var f = function(err, obj){
                if (c) c.loading = false;
                signalCenter.showMessage(err);
            }
            Script.floorReply(opt, s, f);
        }
    }

    ViewHeader {
        id: viewHeader;
        title: (view.currentIndex+1)+"/"+internal.picAmount;
        onClicked: if (view.currentItem) view.currentItem.scrollToTop();
        BusyIndicator {
            anchors.right: parent.right;
            anchors.rightMargin: constant.paddingMedium;
            anchors.verticalCenter: parent.verticalCenter;
            running: true;
            visible: view.currentItem != null && view.currentItem.loading;
        }
    }

    ListView {
        id: view;
        focus: true;
        anchors { fill: parent; topMargin: viewHeader.height; }
        cacheBuffer: 1;
        highlightFollowsCurrentItem: true;
        highlightMoveDuration: 300;
        highlightRangeMode: ListView.StrictlyEnforceRange;
        preferredHighlightBegin: 0;
        preferredHighlightEnd: view.width;
        snapMode: ListView.SnapOneItem;
        orientation: ListView.Horizontal;
        boundsBehavior: Flickable.StopAtBounds;
        model: ListModel {}
        delegate: ThreadPictureDelegate{}
        onMovementEnded: {
            if (!atXEnd || loading) return;
            var d = view.model.get(view.count-1);
            if (!d) return;
            if (view.count >= internal.picAmount) return;
            internal.getlist("next");
        }
    }

    Floor.ToolsArea {
        id: toolsArea;
    }

    // For keypad
    onStatusChanged: {
        if (status === PageStatus.Active){
            view.forceActiveFocus();
        } else if (status === PageStatus.Deactivating){
            toolsArea.state = "";
        }
    }

    Keys.onPressed: {
        switch (event.key){
        case Qt.Key_R:
            if (view.currentItem)
                view.currentItem.getlist();
            event.accepted = true;
            break;
        case Qt.Key_E:
            if (view.currentItem)
                toolsArea.state = "Input";
            event.accepted = true;
            break;
        }
    }
}

import bb.cascades 1.0
import bb.system 1.2
import bb.cascades.pickers 1.0
import com.canadainc.data 1.0

Page
{
    id: dashPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    titleBar: SafeTitleBar {}
    
    onCreationCompleted: {
        if (!security.authenticated) {
            loginPrompt.show();
        } else {
            guardianContainer.opacity = 1;
        }
    }
    
    onActionMenuVisualStateChanged: {
        if (actionMenuVisualState == ActionMenuVisualState.VisibleFull)
        {
            tutorial.execOverFlow( "changePassword", qsTr("If you want to change the administrative password, you can choose the '%1' item from the menu."), changePassword );
            tutorial.execOverFlow( "viewLogs", qsTr("You can use the '%1' from the menu to see all the list of websites that were accessed, blocked, and the failed login attempts to have occurred."), viewLogs );
            tutorial.execOverFlow( "backup", qsTr("You can use the '%1' action at the bottom if you want to save your blocked websites, and keywords to a file."), backup );
            tutorial.execOverFlow( "restore", qsTr("At a later date you can use the '%1' action to reimport the backup file to restore your database or you can apply it to other devices you want to port these settings into!"), restore);
            
            if (modeDropDown.selectedOption == passive) {
                tutorial.execOverFlow("blockedKeywords", qsTr("To block websites depending on keywords that appear in their website title, tap on the '%1' action."), blockedKeywords);
            }
        }
        
        reporter.record("SettingsMenuOpened", actionMenuVisualState.toString());
    }
    
    actions: [
        ActionItem
        {
            id: addAction
            imageSource: "images/menu/ic_add.png"
            title: qsTr("Add") + Retranslate.onLanguageChanged
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.CreateNew
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: AddSite");
                reporter.record("AddSite");
                addPrompt.show();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: addPrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the host address (ie: youtube.com). Don't append any http:// or www.") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "youtube.com"
                    inputOptions: SystemUiInputOption.None
                    
                    onFinished: {
                        console.log( "UserEvent: NewAddressToBlockEntered", value, inputFieldTextEntry() );

                        if (value == SystemUiResult.ConfirmButtonSelection)
                        {
                            reporter.record("BlockedHostEntered");
                            
                            var request = inputFieldTextEntry().trim();
                            helper.blockSite(listView, modeDropDown.selectedValue, request);
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            imageSource: "images/ic_home.png"
            title: qsTr("Set Home") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: SetHome");
                reporter.record("SetHome");
                homePrompt.showPrompt();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: homePrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the homepage address (ie: http://dar-as-sahaba.com)") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "http://canadainc.org"
                    inputOptions: SystemUiInputOption.None
                    
                    function showPrompt()
                    {
                        inputField.defaultText = persist.getValueFor("home");
                        show();
                    }
                    
                    onFinished: {
                        console.log( "UserEvent: HomepageAddressEntered", value, inputFieldTextEntry() );
                        
                        if (value == SystemUiResult.ConfirmButtonSelection)
                        {
                            var request = inputFieldTextEntry().trim();
                            reporter.record("HomepageAddressEntered", request);

                            persist.saveValueFor("home", request, false);
                            persist.showToast( qsTr("Successfully set homepage to %1").arg(request), "images/ic_home.png" );
                            
                            helper.blockSite(listView, "controlled", request);
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            id: safeRun
            imageSource: "images/menu/ic_safe_run.png"
            title: qsTr("Safe Run") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            function onPopTransitionEnded(page)
            {
                if ( tutorial.isTopPane(dashPage.parent, dashPage) )
                {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                    dashPage.parent.popTransitionEnded.disconnect(onPopTransitionEnded);
                }
            }
            
            function onFinished(ok)
            {
                if (ok)
                {
                    definition.source = "SafeRunPage.qml";
                    var safeRunPage = definition.createObject();
                    dashPage.parent.push(safeRunPage);
                    
                    safeRunPage.browseField.requestFocus();
                    dashPage.parent.popTransitionEnded.connect(onPopTransitionEnded);
                }
            }
            
            onTriggered: {
                console.log("UserEvent: SafeRun");
                reporter.record("SafeRun");
                var message;
                
                if (helper.mode == "passive") {
                    message = qsTr("Go through and browse all the pages that you want to block. They will be added one by one automatically. When you finish simply close the page.");
                } else {
                    message = qsTr("Go through and browse all the pages that you want to allow. They will be added one by one automatically. When you finish simply close the page.");
                }
                
                persist.showDialog( safeRun, title, message, qsTr("OK"), "" );
            }
        },
        
        ActionItem
        {
            id: changePassword
            imageSource: "images/ic_password.png"
            title: qsTr("Change Password") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ChangePassword");
                reporter.record("ChangePassword");
                definition.source = "SignupSheet.qml";
                var sheet = definition.createObject();
                sheet.open();
            }
        },
        
        ActionItem
        {
            id: viewLogs
            imageSource: "images/menu/ic_logs.png"
            title: qsTr("View Logs") + Retranslate.onLanguageChanged
            
            shortcuts: [
                Shortcut {
                    key: qsTr("V") + Retranslate.onLanguageChanged
                    
                    onTriggered: {
                        reporter.record("ViewLogsShortcut");
                    }
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: ViewLogs");
                reporter.record("ViewLogs");
                definition.source = "ViewLogsPage.qml";
                var page = definition.createObject();
                dashPage.parent.push(page);
            }
        },
        
        ActionItem
        {
            id: backup
            title: qsTr("Backup") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_backup.png"
            
            onTriggered: {
                console.log("UserEvent: Backup");
                filePicker.title = qsTr("Select Destination");
                filePicker.mode = FilePickerMode.Saver
                filePicker.defaultSaveFileNames = ["safe_browse_backup.sb"]
                filePicker.allowOverwrite = true;
                filePicker.open();
                
                reporter.record("Backup");
            }
            
            function onSaved(result)
            {
                if (result.length > 0) {
                    persist.showToast( qsTr("Successfully backed up to %1").arg(result), imageSource.toString() );
                } else {
                    persist.showToast( qsTr("The database could not be backed up. Please file a bug report."), "images/toast/error.png" );
                }
                
                reporter.record("BackupResult", result);
            }
        },
        
        ActionItem
        {
            id: restore
            title: qsTr("Restore") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_restore.png"
            
            onTriggered: {
                console.log("UserEvent: Restore");
                filePicker.title = qsTr("Select File");
                filePicker.mode = FilePickerMode.Picker
                filePicker.open();
                
                reporter.record("Restore");
            }
            
            function onFinished(ok)
            {
                if (ok) {
                    Application.requestExit();
                }
            }
            
            function onRestored(result)
            {
                if (result.length > 0) {
                    persist.showDialog( restore, qsTr("Restore Complete"), qsTr("The database was successfully restored. The app will close now so it can restart with the changes applied."), qsTr("OK"), "" );
                } else {
                    persist.showToast( qsTr("The database could not be restored. Please re-check the backup file to ensure it is valid, and if the problem persists please file a bug report. Make sure to attach the backup file with your report!"), "images/toast/error.png" );
                }
                
                reporter.record("RestoreResult", result.toString());
            }
        }
    ]
    
    function cleanUp() {
        dashPage.parent.popTransitionEnded.disconnect(safeRun.onPopTransitionEnded);
    }
    
    Container
    {
        id: guardianContainer
        opacity: 0
        
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]
        
        onOpacityChanged: {
            if (opacity == 1)
            {
                var primary = persist.getValueFor("mode");
                
                for (var i = modeDropDown.count()-1; i >= 0; i--)
                {
                    if ( modeDropDown.at(i).value == primary )
                    {
                        modeDropDown.selectedIndex = i;
                        break;
                    }
                }
                
                modeDropDown.selectedValueChanged(modeDropDown.selectedValue);
                
                tutorial.execCentered( "parental", qsTr("To disable the native Browser, Swipe-down from the BlackBerry 10 home screen and choose Settings.\nThen scroll down in the list and go to 'Security & Privacy.\nSelect 'Parental Controls'.\nEnable the parental controls toggle button.\nChoose a password.\nDisallow the browser toggle button.\n\nYou can also access this Parental Controls screen by tapping on the Help from the top-menu in Safe Browse."), "images/toast/ic_instructions.png" );
                tutorial.execCentered( "installApp", qsTr("For added security you might also want to disable the 'Install Application' toggle button from the Parental Controls so that no one can download additional web browsing apps."), "images/toast/prevent_install.png" );
                tutorial.execCentered( "removeApp", qsTr("For added security you might also want to disable the 'Remove Application' toggle button from the Parental Controls so that no one can delete this app and get rid of all your blocking settings."), "images/toast/prevent_app_remove.png" );
                tutorial.execActionBar( "moreAdminOptions", qsTr("Tap here for additional administrative options."), "x" );
                tutorial.execActionBar( "homepage", qsTr("Tap here to set the website that shows up when the app first loads.\n\nNote that if you are in the '%1' mode, you need to ensure that you allow this homepage.").arg(controlled.text), "l" );
                tutorial.execBelowTitleBar("passive", qsTr("If you want to allow all websites except certain ones, choose '%1' in the segmented control.").arg(passive.text), 0, "l");
                tutorial.execBelowTitleBar("controlled", qsTr("If you want to block all websites except certain ones, choose '%1' in the segmented control").arg(controlled.text), 0, "r");
                tutorial.execActionBar("settingsBack", qsTr("To return to the main browsing page tap on the Back button here."), "b" );

                deviceUtils.attachTopBottomKeys(dashPage, listView);
            }
        }
        
        background: back.imagePaint
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        
        SegmentedControl
        {
            id: modeDropDown
            horizontalAlignment: HorizontalAlignment.Fill
            bottomMargin: 0
            selectedOption: null
            
            Option {
                id: passive
                text: qsTr("Passive") + Retranslate.onLanguageChanged
                description: qsTr("Allow all sites except certain ones") + Retranslate.onLanguageChanged
                value: "passive"
                imageSource: "images/dropdown/ic_passive.png"
            }
            
            Option {
                id: controlled
                text: qsTr("Controlled") + Retranslate.onLanguageChanged
                description: qsTr("Block all sites except certain ones") + Retranslate.onLanguageChanged
                value: "controlled"
                imageSource: "images/dropdown/ic_controlled.png"
            }
            
            onSelectedValueChanged: {
                if (guardianContainer.opacity == 1)
                {
                    var diff = persist.saveValueFor("mode", selectedValue);
                    
                    if (diff)
                    {
                        reporter.record("BrowsingMode", selectedValue);
                        
                        if (selectedValue == controlled.value) {
                            persist.showToast( qsTr("All websites will be allowed except the ones you choose to block."), passive.imageSource.toString() );
                        } else if (selectedValue == passive.value) {
                            persist.showToast( qsTr("All websites will be blocked except the ones you choose to allow."), controlled.imageSource.toString() );
                        }
                    }
                    
                    dashPage.removeAction(blockedKeywords);
                    
                    if (selectedValue == controlled.value)
                    {
                        dashPage.addAction(safeRun);
                        tutorial.execActionBar( "addAllowed", qsTr("Tap here to add an allowed website.") );
                        tutorial.execActionBar("safeRun", qsTr("To quickly add a bunch of allowed websites tap on the '%1' icon from the menu.").arg(safeRun.title), "r");
                    } else if (selectedValue == passive.value) {
                        dashPage.addAction(blockedKeywords);
                        tutorial.execActionBar( "addBlocked", qsTr("Tap here to add a domain you wish to disallow and prevent users from accessing.") );
                        tutorial.execActionBar("safeRun", qsTr("To quickly add a bunch of disallowed websites tap on the '%1' icon from the menu.").arg(safeRun.title), "r");
                    }
                    
                    helper.fetchAllBlocked(listView, selectedValue);
                }
            }
        }
        
        Divider {
            topMargin: 0; bottomMargin: 0
        }
        
        EmptyDelegate
        {
            id: noElements
            graphic: "images/placeholder/blocked_empty.png"
            labelText: modeDropDown.selectedOption == passive ? qsTr("There are no websites currently blocked. Tap here to add one.") + Retranslate.onLanguageChanged : qsTr("There are no websites currently allowed. Tap here to add one.") + Retranslate.onLanguageChanged
            
            onImageTapped: {
                console.log("UserEvent: AddExceptionUrlTapped")
                reporter.record("AddExceptionUrlTapped");
                addAction.triggered();
            }
        }
        
        ListView
        {
            id: listView
            scrollRole: ScrollRole.Main
            property alias filterMode: modeDropDown.selectedValue
            
            dataModel: ArrayDataModel {
                id: adm
            }
            
            onTriggered: {
                console.log("UserEvent: BlockedListItemTapped", indexPath);
                reporter.record("ExceptionUrlTapped");
                multiSelectHandler.active = true;
                toggleSelection(indexPath);
            }
            
            multiSelectHandler
            {
                onActiveChanged: {
                    if (active) {
                        tutorial.execActionBar( "unblock", qsTr("Tap here to remove these elements from the list."), "x" );
                    }
                }
                
                actions: [
                    DeleteActionItem 
                    {
                        id: unblockAction
                        title: qsTr("Unblock") + Retranslate.onLanguageChanged
                        imageSource: "images/menu/ic_unblock.png"
                        enabled: false
                        
                        onTriggered: {
                            console.log("UserEvent: UnblockMultiExceptions");
                            reporter.record("UnblockMultiExceptions");
                            var selected = listView.selectionList();
                            var blocked = [];
                            
                            for (var i = selected.length-1; i >= 0; i--) {
                                blocked.push( adm.data(selected[i]) );
                            }
                            
                            helper.unblockSite(listView, modeDropDown.selectedValue, blocked);
                        }
                    }
                ]
                
                status: qsTr("None selected") + Retranslate.onLanguageChanged
            }
            
            onSelectionChanged: {
                var n = selectionList().length;
                unblockAction.enabled = n > 0;
                multiSelectHandler.status = qsTr("%n addresses to remove", "", n);
            }
            
            listItemComponents:
            [
                ListItemComponent
                {
                    StandardListItem
                    {
                        id: rootItem
                        imageSource: ListItem.view.filterMode == "controlled" ? "images/list/site_allowed.png" : "images/list/site_blocked.png"
                        title: ListItemData.uri
                        
                        ListItem.onInitializedChanged: {
                            if (initialized) {
                                showAnim.play();
                            }
                        }
                        
                        animations: [
                            ParallelAnimation
                            {
                                id: showAnim
                                ScaleTransition
                                {
                                    fromX: 0.8
                                    toX: 1
                                    fromY: 0.8
                                    toY: 1
                                    duration: 600
                                    easingCurve: StockCurve.ElasticOut
                                }
                                
                                FadeTransition {
                                    fromOpacity: 0
                                    toOpacity: 1
                                    duration: 200
                                }
                                
                                delay: Math.min(rootItem.ListItem.indexInSection*100, 1000)
                            }
                        ]
                    }
                }
            ]

            function onDataLoaded(id, data)
            {
                if (id == QueryId.GetAll)
                {
                    adm.clear()
                    adm.append(data);
                    
                    listView.visible = !adm.isEmpty();
                    noElements.delegateActive = !listView.visible;

                    if ( !adm.isEmpty() )
                    {
                        if (modeDropDown.selectedValue == controlled.value) {
                            tutorial.execBelowTitleBar( "removeException", qsTr("To remove an allowed website from this list, simply tap on it and choose the '%1' action from the menu.").arg(unblockAction.title), deviceUtils.du(8) );
                        } else if (modeDropDown.selectedValue == passive.value) {
                            tutorial.execBelowTitleBar( "removeBlocked", qsTr("To remove an blocked website from this list, simply tap on it and choose the '%1' action from the menu.").arg(unblockAction.title), deviceUtils.du(8) );
                        }
                    }
                } else if (id == QueryId.InsertEntry) {
                    persist.showToast( qsTr("Successfully added entries!"), "images/menu/ic_select_more.png" );
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                } else if (id == QueryId.DeleteEntry) {
                    persist.showToast( qsTr("Successfully removed entries!"), unblockAction.imageSource.toString() );
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                }
            }
        }
    }
    
    attachedObjects: [
        SystemPrompt
        {
            id: loginPrompt
            body: qsTr("Please enter your password:") + Retranslate.onLanguageChanged
            title: qsTr("Login") + Retranslate.onLanguageChanged
            inputOptions: SystemUiInputOption.None
            inputField.emptyText: qsTr("Password cannot be empty...") + Retranslate.onLanguageChanged
            inputField.maximumLength: 20
            inputField.inputMode: SystemUiInputMode.Password
            
            onFinished: {
                console.log( "UserEvent: PasswordEntered", value, inputFieldTextEntry() );

                if (value == SystemUiResult.ConfirmButtonSelection)
                {
                    var password = inputFieldTextEntry().trim();
                    var loggedIn = security.login(password);
                    console.log("LoginResult", loggedIn);

                    if (!loggedIn)
                    {
                        helper.logFailedLogin(listView, password);
                        reporter.record("FailedAuthentication");
                        persist.showToast( qsTr("Wrong password entered. Please try again."), "images/common/dropdown/set_password.png" );
                        dashPage.parent.pop();
                    } else {
                        guardianContainer.opacity = 1;
                        reporter.record("AuthenticationSuccess");
                    }
                } else {
                    reporter.record("CanceledAuthentication");
                    
                    dashPage.removeAllActions();
                    dashPage.parent.pop();
                }
            }
        },
        
        FilePicker {
            id: filePicker
            defaultType: FileType.Other
            filter: ["*.sb"]
            
            directories :  {
                return ["/accounts/1000/removable/sdcard", "/accounts/1000/shared/misc"]
            }
            
            onFileSelected : {
                console.log("UserEvent: FileSelected", selectedFiles[0]);
                
                if (mode == FilePickerMode.Picker) {
                    app.backup(restore, "onRestored", selectedFiles[0], true);
                } else {
                    app.backup(backup, "onSaved", selectedFiles[0], false);
                }
            }
        },
        
        ActionItem
        {
            id: blockedKeywords
            imageSource: "images/menu/ic_keywords.png"
            title: qsTr("Blocked Keywords") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: BlockedKeywords");
                reporter.record("BlockedKeywords");
                definition.source = "BlockedKeywordPage.qml";
                var keywords = definition.createObject();
                dashPage.parent.push(keywords);
            }
        }
    ]
}
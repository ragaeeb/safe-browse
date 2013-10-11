import bb.cascades 1.0

DropDown
{
    title: qsTr("Browsing Mode") + Retranslate.onLanguageChanged
    
    Option {
        text: qsTr("Passive") + Retranslate.onLanguageChanged
        description: qsTr("Allow all sites except certain ones") + Retranslate.onLanguageChanged
        value: "passive"
        imageSource: "images/ic_passive.png"
    }
    
    Option {
        text: qsTr("Controlled") + Retranslate.onLanguageChanged
        description: qsTr("Block all sites except certain ones") + Retranslate.onLanguageChanged
        value: "controlled"
        imageSource: "images/ic_controlled.png"
    }
    
    onCreationCompleted: {
        var mode = persist.getValueFor("mode");
        
        for (var i = 0; i < options.length; i ++) {
            if (options[i].value == mode) {
                options[i].selected = true;
                break;
            }
        }
    }
    
    onSelectedValueChanged: {
        var changed = persist.saveValueFor("mode", selectedValue);
        
        if (changed)
        {
            if (selectedValue == "passive") {
                persist.showToast("All websites will be allowed except the ones you choose to block.");
            } else if (selectedValue == "controlled") {
                persist.showToast("All websites will be blocked except the ones you choose to allow.");
            }
        }
    }
}
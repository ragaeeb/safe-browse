import bb.cascades 1.0
import bb 1.0

Page
{
    attachedObjects: [
        ApplicationInfo {
            id: appInfo
        },

        PackageInfo {
            id: packageInfo
        }
    ]
    
    actions: [
        ActionItem {
            title: qsTr("Parental Control") + Retranslate.onLanguageChanged
            imageSource: "images/ic_instructions.png"
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar

            onTriggered: {
                var page = instructionsDefinition.createObject();
                properties.navPane.push(page);
            }
            
            attachedObjects: [
                ComponentDefinition {
                    id: instructionsDefinition
                    source: "Instructions.qml"
                }
            ]
        }
    ]

    paneProperties: NavigationPaneProperties {
        property variant navPane: navigationPane
        id: properties
    }
    
    titleBar: SafeTitleBar {}

    Container
    {
        leftPadding: 20; rightPadding: 20;
        background: back.imagePaint
        
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]

        horizontalAlignment: HorizontalAlignment.Center
        verticalAlignment: VerticalAlignment.Fill

        ScrollView {
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Fill

            Label {
                multiline: true
                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
                textStyle.textAlign: TextAlign.Center
                textStyle.fontSize: FontSize.Small
                content.flags: TextContentFlag.ActiveText
                text: qsTr("\n\n(c) 2013 %1. All Rights Reserved.\n%2 %3\n\nPlease report all bugs to:\nsupport@canadainc.org\n\nInstructions:\n1) Enable BB10 Parental controls (see instructions below).\n2) Make sure you disable the Browser in BB10 Parental Controls.\n3) Go into the Safe Browse app settings and log in.\n4) Choose the browsing mode you want to allow for your child. For example, you might want to restrict your child to only access certain domains which you know are safe and block all other ones (so choose Controlled), or you might want to give your child more freedom and browse all websites except the ones you know are bad (so choose 'Controlled').\n5) Make sure you set a homepage that is not blocked!\n6) That's it. Your child should now be able to browse safely!\n\nThere is a lot of great and educational content on the web. However, there is also equally, if not more bad sites on the web that is not suitable for our children to experience. Safe Browse makes it easy to keep your children free of these harmful websites that can influence them in a negative way. This app gives you a lot of control to monitor your child's activity on the Internet and restrict exactly what websites they can browse.\n\n").arg(packageInfo.author).arg(appInfo.title).arg(appInfo.version)
            }
        }
    }
}
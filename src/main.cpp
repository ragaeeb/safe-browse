#include "precompiled.h"

#include "Logger.h"
#include "applicationui.hpp"

using namespace bb::cascades;

void redirectedMessageOutput(QtMsgType type, const char *msg) {
	Q_UNUSED(type);
	fprintf(stderr, "%s\n", msg);
}

Q_DECL_EXPORT int main(int argc, char **argv)
{
    qInstallMsgHandler(redirectedMessageOutput);

    Application app(argc, argv);
    safebrowse::ApplicationUI::create(&app);

    return Application::exec();
}

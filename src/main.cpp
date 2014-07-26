#include "precompiled.h"

#include "applicationui.hpp"

using namespace bb::cascades;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);
    safebrowse::ApplicationUI::create(&app);

    return Application::exec();
}

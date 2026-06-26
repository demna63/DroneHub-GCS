#include "CustomOptions.h"

CustomOptions::CustomOptions(QGCCorePlugin* corePlugin, QObject* parent)
    : QGCOptions(parent)
{
    Q_UNUSED(corePlugin)
}

QColor CustomOptions::toolbarBackgroundLight() const
{
    return QColor("#151A23"); // mirrors Theme.bgSurface
}

QColor CustomOptions::toolbarBackgroundDark() const
{
    return QColor("#0B0E14"); // mirrors Theme.bgBase
}

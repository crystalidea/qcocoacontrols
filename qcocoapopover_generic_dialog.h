#pragma once

class QPopoverDialog : public QDialog
{
    Q_OBJECT

public:

    explicit QPopoverDialog(QWidget* contentWidget, QWidget* parent = nullptr);

protected:

    void paintEvent(QPaintEvent*) override;

private:

    QWidget* m_content = nullptr;
};
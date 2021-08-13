#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <qcocoacontrols/qcocoaslider.h>
#include <qcocoacontrols/qcocoapopover.h>

QWidget *popupContents()
{
    QWidget *w = new QWidget(0);

    QLabel *label = new QLabel(w);
    label->setText("Hello World");
    label->setGeometry(0, 0, 200, 100);
    label->setVisible(true);

    QVBoxLayout *l = new QVBoxLayout();
    w->setLayout(l);
    l->addWidget(label);

    QCocoaButton *btn = new QCocoaButton(w);
     btn->setBezelStyle(QCocoaButton::TexturedRounded);
    btn->setText("Close");

    QObject::connect(btn, &QCocoaButton::clicked, w, [=] {

       w->close();

    });

    l->addWidget(btn);

    //w->adjustSize();

    w->setGeometry(0, 0, 200, 200);

    return w;
}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    // sliders

    connect(ui->sliderHorizontal, SIGNAL(valueChanged(int)), this, SLOT(sliderChanged(int)) );
    connect(ui->sliderCircular, SIGNAL(valueChanged(int)), this, SLOT(sliderChanged(int)) );

    ui->sliderHorizontal->setRange(0, 100);
    ui->sliderHorizontal->setValue(79);
    ui->sliderHorizontal->setAllowsTickMarkValuesOnly(true);
    ui->sliderHorizontal->setTickInterval(10);

    ui->sliderVertical->setRange(1, 100);
    ui->sliderVertical->setValue(10);
    ui->sliderVertical->setSliderType(QCocoaSlider::LinearVertical);
    ui->sliderVertical->setAltIncrementValue(10);

    ui->sliderCircular->setRange(1, 180);
    ui->sliderCircular->setSliderType(QCocoaSlider::CircularSlider);

    // buttons tab

    ui->buttonRounded->setText("Rounded");

    ui->buttonRegularSquare->setBezelStyle(QCocoaButton::RegularSquare);
    ui->buttonRegularSquare->setText("RegularSquare");

    ui->buttonDislosure->setBezelStyle(QCocoaButton::Disclosure);

    ui->buttonShadowLessSquare->setBezelStyle(QCocoaButton::ShadowlessSquare);
    ui->buttonShadowLessSquare->setText("ShadowlessSquare");

    ui->buttonTexturedSquare->setBezelStyle(QCocoaButton::TexturedSquare);
    ui->buttonTexturedSquare->setText("TexturedSquare");

    ui->buttonSmallSquare->setBezelStyle(QCocoaButton::SmallSquare);
    ui->buttonSmallSquare->setText("SmallSquare");

    ui->buttonTexturedRounded->setBezelStyle(QCocoaButton::TexturedRounded);
    ui->buttonTexturedRounded->setText("TexturedRounded");

    ui->buttonRoundRect->setBezelStyle(QCocoaButton::RoundRect);
    ui->buttonRoundRect->setText("RoundRect");

    ui->buttonCircular->setBezelStyle(QCocoaButton::Circular);

    ui->buttonRecessed->setBezelStyle(QCocoaButton::Recessed);
    ui->buttonRecessed->setText("Recessed");

    ui->buttonRoundedDisclosure->setBezelStyle(QCocoaButton::RoundedDisclosure);

    //ui->buttonInline->setBezelStyle(QCocoaButton::Inline); // TODO: wtf CRASH !
    ui->buttonInline->setText("Inline");

    QCocoaButton *helpButton = new QCocoaButton(this);
    helpButton->setBezelStyle(QCocoaButton::HelpButton);
    ui->buttonBox->addButton(helpButton->abstractButton(), QDialogButtonBox::HelpRole);

    // popover

    QObject::connect(ui->buttonPopover, &QAbstractButton::clicked, this, [this] {
        QWidget *w = popupContents();

        QCocoaPopover *_popOver = new QCocoaPopover(this, w);

        _popOver->setTimeout(ui->spinBoxPopover->value());

        _popOver->setPopoverBehavior(QCocoaPopover::PopoverBehavior::ApplicationDefined);
        _popOver->setAnimate(true);
        //_popOver->setTimeout(8000);

        _popOver->show(ui->buttonPopover);
    });

    // GradientButton

    ui->gradientButton->setSegmentCount(2);
    ui->gradientButton->setSegmentIcon(0, QCocoaIcon::Add);
    ui->gradientButton->setSegmentIcon(1, QCocoaIcon::Remove);

    // segmented button

    ui->segmentedButton->setSegmentCount(3);
    ui->segmentedButton->setSegmentIcon(0, QCocoaIcon::StandardIcon::Add);
    ui->segmentedButton->setTitle(1, "Btn1");
    ui->segmentedButton->setTitle(2, "Btn2");

}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::sliderChanged(int )
{
    ui->labelSliderValue->setText(QString::number(ui->sliderHorizontal->value()));
    ui->labelVertSlider->setText(QString::number(ui->sliderVertical->value()));
    ui->labelCircularValue->setText(QString::number(ui->sliderCircular->value()));
}

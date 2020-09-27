#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "../qcocoaslider.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    connect(ui->sliderHorizontal, SIGNAL(valueChanged(int)), this, SLOT(sliderChanged(int)) );
    connect(ui->sliderVertical, SIGNAL(valueChanged(int)), this, SLOT(sliderChanged(int)) );
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

    ui->buttonInline->setBezelStyle(QCocoaButton::Inline);
    ui->buttonInline->setText("Inline");

    QCocoaButton *helpButton = new QCocoaButton(this);
    helpButton->setBezelStyle(QCocoaButton::HelpButton);
    ui->buttonBox->addButton(helpButton->abstractButton(), QDialogButtonBox::HelpRole);

    // GradientButton

    ui->gradientButton->setSegmentCount(2);
    ui->gradientButton->setSegmentIcon(0, QCocoaWidget::Plus);
    ui->gradientButton->setSegmentIcon(1, QCocoaWidget::Minus);

    ui->gradientWidget->setSegmentCount(2);
    ui->gradientWidget->setSegmentIcon(0, QCocoaWidget::Plus);
    ui->gradientWidget->setSegmentIcon(1, QCocoaWidget::Minus);
    ui->gradientWidget->attachToWidget(ui->tableWidget); // must be after initializing
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
